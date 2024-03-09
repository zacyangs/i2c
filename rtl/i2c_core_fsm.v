`include "i2c_master_defines.v"

module i2c_core_fsm(
    input               clk,
    input               rstn,

    input       [7:0]   slv_addr,
    input               cr_msms,
    output reg          cr_msms_clr,
    input               cr_tx,
    input               cr_gcen,
    input               cr_txak,
    input               cr_en,
    input               cr_rsta,
    output              cr_rsta_clr,
    output reg          sr_abgc,
    output reg          sr_aas,
    output reg          sr_srw,
    output reg          irq_nas,// not addressed as slave
    output              irq_tx_err,
    output              irq_tx_empty,

    output reg [ 3:0]   cmd,      // command (from byte controller)
    input               cmd_ack,  // command complete acknowledge
    input               phy_rx,
    output reg          phy_tx,
    input               phy_abort,

    input       [4:0]   rx_fifo_pirq,
    output              rx_fifo_pfull,
    output              rx_fifo_wr, 
    output      [7:0]   rx_fifo_din,
    input       [4:0]   rx_fifo_ocy,

    input               tx_fifo_empty,
    output              tx_fifo_rd,
    input       [9:0]   tx_fifo_dout,
    input       [4:0]   tx_fifo_ocy,

    output              scl_gauge_en,
    output reg          msms,

    input               rcv_rsta,
    input               rcv_sta,
    input               rcv_sto
);

    localparam ST_IDLE  = 3'h0;
    localparam ST_START = 3'h1;
    localparam ST_ADDR  = 3'h2;
    localparam ST_READ  = 3'h3;
    localparam ST_WRITE = 3'h4;
    localparam ST_ACK   = 3'h5;
    localparam ST_STOP  = 3'h6;
    localparam ST_SUSP  = 3'h7;

    reg  [2:0]  cstate;
    reg  [2:0]  nstate;
    reg  [2:0]  pstate;
    reg  [2:0]  dcnt;
    reg  [7:0]  sr;
    wire [2:0]  dcnt_x;
    wire        tx_ack;
    reg         req_sta;
    wire        req_sta_x;
    wire        req_sta_set;
    wire        req_sta_clr;
    wire        mst_tx;
    wire        tx_ready;
    wire        rx_ready;
    reg         cr_msms_r;
    wire        msms_set;
    wire        msms_clr;
    wire        msms_x;
    wire        active_abort;
    wire        rsta_req;
    wire        tx; 
/*autodef*/
    //Start of automatic define
    //Start of automatic reg
    //Define flip-flop registers here
    //Define combination registers here
    reg                         load                            ;
    //REG_DEL: Register slv_rw has been deleted.
    //End of automatic reg
    //Start of automatic wire
    //Define assign wires here
    wire                        aas_set                         ;
    wire                        gc_set                          ;
    wire                        aas_x                           ;
    wire                        abgc_x                          ;
    wire                        nas_clr                         ;
    wire                        nas_set                         ;
    wire                        nas_x                           ;
    wire                        adr_ack                         ; // WIRE_NEW
    wire                        shift                           ;
    wire                        dcnt_done                       ;
    //Define instance wires here
    //End of automatic wire
    //End of automatic define



assign msms_set = cr_msms && !cr_msms_r;
assign msms_clr = cstate == ST_STOP && cmd_ack;
assign msms_x   = msms_set ? 1'b1:
                  msms_clr ? 1'b0:
                  msms;

assign tx       = msms? cr_tx : (aas_set? phy_rx : sr_srw);

assign scl_gauge_en = !msms && cstate == ST_ADDR;

// status & interrupts
assign gc_set  = !msms & (cstate == ST_ADDR) & dcnt_done & (sr[6:0] == 7'b0) & cr_gcen;
assign aas_set = !msms & (cstate == ST_ADDR) & dcnt_done & (sr[6:0] == slv_addr[7:1]);

assign aas_x   = rcv_sto ? 1'b0 : 
                 aas_set ? 1'b1 : 
                 sr_aas;

assign abgc_x  = rcv_sto  ? 1'b0 :
                 gc_set   ? 1'b1 :
                 sr_abgc;

assign nas_clr = aas_set | gc_set;
assign nas_set = rcv_sto;

assign nas_x = nas_clr ? 1'b0 : 
               nas_set ? 1'b1 :
               irq_nas ;

// interrupt bit 2
// 1. WSMT:
//      a. no slave respond for address call
//      b. the slave issure nak to signal that it is not accepting anymore data
// 2. WSMR: transfer ended with txak = 1
// 3. WSST: nak recieved from master
// 4. WSSR: txak = 1

assign irq_tx_err = cstate == ST_ACK && phy_rx && cmd_ack;
assign irq_tx_empty = (cstate == ST_SUSP) && tx_fifo_empty;

assign adr_ack =  (pstate == ST_ADDR);

assign active_abort   = !cr_msms & msms & (pstate == ST_WRITE);

// Fsm
always@(*)
begin
    nstate = cstate;
    cmd    = `I2C_CMD_NOP;
    load   = 1'b0;
    phy_tx = 1'b0;
    cr_msms_clr = 1'b0;
    //tx_fifo_rd = 1'b0;
    case(cstate)
        ST_IDLE : begin
            if(msms && tx_ready)
                nstate = ST_START;
            else if(rcv_sta)
                nstate = ST_ADDR;
        end

        ST_START : begin
            cmd  = `I2C_CMD_START;
            load = cmd_ack;
            if(cmd_ack) nstate = ST_ADDR; 
        end

        ST_ADDR : begin
            if(msms) cmd = `I2C_CMD_WRITE;
            else            cmd = `I2C_CMD_READ;

            phy_tx = sr[7];

            if(dcnt_done) nstate = ST_ACK;
        end

        ST_READ  : begin
            cmd = `I2C_CMD_READ;
            if(cmd_ack && rcv_rsta)
                nstate = ST_ADDR;
            else if(dcnt_done) 
                nstate = ST_ACK;
        end

        ST_WRITE : begin
            cmd = `I2C_CMD_WRITE;

            phy_tx = sr[7];

            if(dcnt_done) nstate = ST_ACK;
        end

        ST_ACK : begin
            if(adr_ack & !msms | !adr_ack & !tx) begin
                cmd        = `I2C_CMD_WRITE;
            end else begin
                cmd        = `I2C_CMD_READ;
            end

            phy_tx = adr_ack & !(sr_aas | sr_abgc) | !adr_ack & cr_txak;

            if(cmd_ack) begin
                if(phy_rx | active_abort) begin
                    if(msms) // mst mode
                        nstate = ST_STOP;
                    else
                        nstate = ST_IDLE;
                end
                else if(cr_rsta)
                    nstate = ST_START;
                else begin
                    if(tx) begin // data tx
                        if(tx_ready)
                            nstate = ST_WRITE;
                        else
                            nstate = ST_SUSP;
                    end else begin
                        if(rx_ready)
                            nstate = ST_READ;
                        else
                            nstate = ST_SUSP;
                    end
                end
                //tx_fifo_rd = mode_sel[0] & (msms | !adr_ack);
                load = !(phy_rx | active_abort | cr_rsta) & tx & tx_ready;
                cr_msms_clr = phy_rx & tx & msms;

//                case(mode_sel[1:0])
//                    2'b11: begin
//                        tx_fifo_rd = 1'b1;
//                        if(phy_rx || !cr_msms && !dynamic_mode || dynamic_sto)
//                            nstate = ST_STOP; 
//                        else if(tx_fifo_ocy[4:0] == 1) 
//                            nstate = ST_SUSP; 
//                        else begin
//                            nstate = ST_WRITE;
//                            load   = 1;
//                        end
//                    end
//
//                    2'b10:
//                        if(phy_rx)
//                            nstate = ST_STOP;
//                        else if(rx_fifo_ocy[4:0] + 1'b1 == rx_fifo_pirq[4:0])
//                            nstate = ST_SUSP;
//                        else 
//                            nstate = ST_READ;
//
//                    2'b01: begin
//                        tx_fifo_rd = !adr_ack;
//                        if(phy_rx)
//                            nstate = ST_IDLE; 
//                        else if(tx_fifo_ocy[4:0] == 1) 
//                            nstate = ST_SUSP; 
//                        else begin
//                            nstate = ST_WRITE;
//                            load   = 1;
//                        end
//                    end
//
//                    3'b00:
//                        if(phy_rx) 
//                            nstate = ST_IDLE; 
//                        else if(rx_fifo_ocy[4:0] + 1'b1 == rx_fifo_pirq[4:0]) 
//                            nstate = ST_SUSP; 
//                        else 
//                            nstate = ST_READ;
//                    default: ;
//                endcase
            end
        end

        ST_STOP : begin
            cmd = `I2C_CMD_STOP;
            if(cmd_ack) nstate = ST_IDLE;
        end

        ST_SUSP : begin
            cmd = `I2C_CMD_WAIT;
            if(!tx && !rx_fifo_pfull)
                if(cr_rsta) 
                    nstate = ST_START; // restore
                else
                    nstate = ST_READ;
            else if(tx && tx_ready) 
                if(cr_rsta)
                    nstate = ST_START; // restore
                else begin
                    nstate = ST_WRITE ;
                    load = 1'b1;
                end
        end
        default:;
    endcase
end

assign cr_rsta_clr = cr_rsta && (cstate == ST_START) && cmd_ack;

assign shift =  (cstate == ST_READ || cstate == ST_WRITE || cstate == ST_ADDR) && cmd_ack;
// generate counter
assign cnt_clr = dcnt_done || rcv_rsta;
assign dcnt_x  = cnt_clr ? 3'h7 :
                 shift   ? dcnt - 1'b1 : dcnt;

assign dcnt_done = ~(|dcnt) & cmd_ack;

assign req_sta_set = cr_msms & !cr_msms_r;
assign req_sta_clr = !tx_fifo_empty;
assign req_sta_x   = req_sta_set ? 1'b1 :
                     req_sta_clr ? 1'b0 :
                     req_sta;

assign rx_ready      = rx_fifo_ocy[4:0]+1 < rx_fifo_pirq[4:0];
assign rx_fifo_wr    = cstate == ST_ACK && cmd_ack && pstate == ST_READ;
assign rx_fifo_din   = sr[7:0];
assign rx_fifo_pfull = (rx_fifo_ocy[4:0] >= rx_fifo_pirq[4:0]) && |rx_fifo_pirq[4:0];

assign tx_ready      = !tx_fifo_empty;
assign tx_fifo_rd    = load;


// sequential with async reset
always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        cstate          <=ST_IDLE;
        pstate          <=ST_IDLE;
        dcnt            <=3'h7; 
        irq_nas         <=1'b1;
        sr_aas          <=1'b0;
        sr_abgc         <=1'b0;
        sr_srw          <=1'b0;
        req_sta         <=1'b0;
        cr_msms_r       <=cr_msms;
        msms            <=1'b0;
    end
    else begin
        cstate          <=nstate;
        dcnt            <=dcnt_x;
        pstate          <=(nstate == cstate)? pstate : cstate;
        sr_srw          <=aas_set ? phy_rx : sr_srw;
        irq_nas         <=nas_x;
        sr_aas          <=aas_x;
        sr_abgc         <=abgc_x;
        req_sta         <=req_sta_x;
        cr_msms_r       <=cr_msms;
        msms            <=msms_x;
    end
end

// sequential without reset
always @(posedge clk)
begin
    if (load)       sr <= tx_fifo_dout[7:0];
    else if(shift)  sr <= {sr[6:0], phy_rx};
end


endmodule
