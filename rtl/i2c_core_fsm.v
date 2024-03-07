`include "i2c_master_defines.v"

module i2c_core_fsm(
    input               clk,
    input               rstn,

    input       [7:0]   slv_addr,
    input               cr_msms,
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
    output              msms_int,

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

localparam [1:0] WSMT = 2'b00;
localparam [1:0] WSMR = 2'b01;
localparam [1:0] WSST = 2'b10;
localparam [1:0] WSSR = 2'b11;





    reg  [2:0]  cstate;
    reg  [2:0]  nstate;
    reg  [2:0]  pstate;
    reg  [2:0]  dcnt;
    reg  [7:0]  sr;
    wire [2:0]  dcnt_x;
    reg         cr_txak_hold;
    wire        tx_ack;
    reg         req_sta;
    wire        req_sta_x;
    wire        req_sta_set;
    wire        req_sta_clr;
    wire        mst_tx;
    reg         dynamic_mode;
    wire        dynamic_tx;
    wire        dynamic_rlast;
    reg  [7:0]  dynamic_rcnt;
    wire [7:0]  dynamic_rcnt_x;
    wire        dynamic_sta;
    wire        dynamic_sto;
    reg         dynamic_tlast;
    reg  [1:0]  mode_sel;
    wire [1:0]  mode_sel_x;
    wire        mode_sel_clr;
    wire        mode_sel_set;
    wire        tx_ready;
    wire        rx_ready;
    reg         cr_msms_r;
    wire        cr_msms_rising;
    wire        active_abort;
    wire        rsta_req;
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
    wire                        cnt_add;
    wire                        dcnt_done                       ;
    //Define instance wires here
    //End of automatic wire
    //End of automatic define

assign msms_int = mode_sel[1];
assign mst_tx   = dynamic_sta ? dynamic_tx : cr_tx;

// work as master and software request a start condition
// or working as slave, a recongnised call is received
assign mode_sel_set = req_sta_set || aas_set;

// working as slave, i2c core needs to clear mode select
// when receives a start signal 
assign mode_sel_clr = (rcv_sto || !mode_sel[1] & rcv_sta);

// 2'b00 : slave receiver
// 2'b01 : slave transmitter
// 2'b10 : master receiver
// 2'b11 : master transmitter
assign mode_sel_x   = req_sta_set  ? {1'b1, mst_tx} :
                      aas_set      ? {1'b0, phy_rx} :
                      mode_sel_clr ? 2'b00 :
                      mode_sel;
assign scl_gauge_en = !mode_sel[1] && cstate == ST_ADDR;

// status & interrupts
assign gc_set  = !mode_sel[1] & (cstate == ST_ADDR) & dcnt_done & (sr[6:0] == 7'b0);
assign aas_set = !mode_sel[1] & (cstate == ST_ADDR) & dcnt_done & (sr[6:0] == slv_addr[7:1]);

assign aas_x   = mode_sel_clr  ? 1'b0 : 
                 aas_set       ? 1'b1 : 
                 sr_aas;

assign abgc_x  = mode_sel_clr  ? 1'b0 :
                 gc_set        ? 1'b1 :
                 sr_abgc;

assign nas_clr = aas_set | gc_set;
assign nas_set = mode_sel_clr & (!mode_sel[1]);

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

assign tx_ack         = dynamic_mode ? dynamic_rlast : cr_txak;

assign dynamic_tx     = !tx_fifo_dout[0];
assign dynamic_sta    = !tx_fifo_empty && tx_fifo_dout[8];
assign dynamic_sto    = !tx_fifo_empty && tx_fifo_dout[9];
assign dynamic_rcnt_x = mode_sel_clr ? 8'b0 : 
                        dynamic_rcnt + rx_fifo_wr;
assign dynamic_rlast  = dynamic_sto && !mode_sel[0] &&
                        (dynamic_rcnt == tx_fifo_dout[7:0] - 1'b1);

assign active_abort   = dynamic_mode ? dynamic_tlast : !cr_msms & (&mode_sel);

// Fsm
always@(*)
begin
    nstate = cstate;
    cmd    = `I2C_CMD_NOP;
    load   = 1'b0;
    phy_tx = 1'b0;
    //tx_fifo_rd = 1'b0;
    case(cstate)
        ST_IDLE : begin
            if(req_sta && tx_ready) nstate = ST_START;
            if(rcv_sta) begin nstate = ST_ADDR;; end // high priority
        end

        ST_START : begin
            cmd = `I2C_CMD_START;
            if(cmd_ack) begin nstate = ST_ADDR; load = 1'b1; end
        end

        ST_ADDR : begin
            if(mode_sel[1]) cmd = `I2C_CMD_WRITE;
            else            cmd = `I2C_CMD_READ;

            phy_tx = sr[7];

            if(dcnt_done) nstate = ST_ACK;
        end

        ST_READ  : begin
            cmd = `I2C_CMD_READ;
            if(cmd_ack && rcv_rsta)
                nstate = ST_ADDR;
            if(dcnt_done) 
                nstate = ST_ACK;
        end

        ST_WRITE : begin
            cmd = `I2C_CMD_WRITE;

            phy_tx = sr[7];

            if(dcnt_done) nstate = ST_ACK;
        end

        ST_ACK : begin
            if(adr_ack & !mode_sel[1] | !adr_ack & !mode_sel[0]) begin
                cmd        = `I2C_CMD_WRITE;
            end else begin
                cmd        = `I2C_CMD_READ;
            end

            phy_tx = adr_ack & !(sr_aas | sr_abgc) | !adr_ack & tx_ack;

            if(cmd_ack) begin
                if(dynamic_sta)
                    nstate = ST_START;
                else if(phy_rx | active_abort) begin
                    if(mode_sel[1]) // mst mode
                        nstate = ST_STOP;
                    else
                        nstate = ST_IDLE;
                end
                else begin
                    if(mode_sel[0]) begin // data tx
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
                //tx_fifo_rd = mode_sel[0] & (mode_sel[1] | !adr_ack);
                load       = !(phy_rx | active_abort) & mode_sel[0] & tx_ready && (!dynamic_sta);

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
            if(!mode_sel[0] && !rx_fifo_pfull)
                if(cr_rsta) nstate = ST_START; // restore
                else        nstate = ST_READ;
            else if(mode_sel[0] && tx_ready) 
                if(cr_rsta) nstate = ST_START; // restore
                else begin
                        nstate = ST_WRITE ;
                        load = 1'b1;
                    end
        end
        default:;
    endcase
end

assign cr_rsta_clr = cr_rsta && !tx_fifo_empty;

//assign rsta_req    = dynamic_mode ? dynamic_rsta : cr_rsta;

assign shift =  (cstate == ST_READ || cstate == ST_WRITE || cstate == ST_ADDR) && cmd_ack;
// generate counter
assign cnt_clr = dcnt_done || rcv_rsta;
assign cnt_add = shift;
assign dcnt_x  = cnt_clr ? 3'h7 :
                 cnt_add ? dcnt - 1'b1 : dcnt;

assign dcnt_done = ~(|dcnt) & cmd_ack;

assign cr_msms_rising = cr_msms & !cr_msms_r;
assign req_sta_set = cr_msms_rising || dynamic_sta;
assign req_sta_clr = !tx_fifo_empty;
assign req_sta_x   = req_sta_set ? 1'b1 :
                     req_sta_clr ? 1'b0 :
                     req_sta;
assign tx_ready      = !tx_fifo_empty;
assign rx_ready      = rx_fifo_ocy[4:0] < rx_fifo_pirq[4:0];
assign rx_fifo_wr    = cstate == ST_ACK && cmd_ack &&
                       pstate == ST_READ;
assign rx_fifo_din   = sr[7:0];

assign rx_fifo_pfull = (rx_fifo_ocy[4:0] == rx_fifo_pirq[4:0]) && |rx_fifo_pirq[4:0];
assign tx_fifo_rd    = load;



// sequential with async reset
always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        cstate      <= #10 ST_IDLE;
        pstate      <= #10 ST_IDLE;
        dcnt        <= #10 3'h7; 
        irq_nas     <= #10 1'b1;
        sr_aas      <= #10 1'b0;
        sr_abgc     <= #10 1'b0;
        sr_srw      <= #10 1'b0;
        cr_txak_hold<= #10 1'b0;
        dynamic_mode<= #10 1'b0;
        req_sta     <= #10 1'b0;
        dynamic_rcnt[7:0]  <= #10 8'b0;
        cr_msms_r   <= cr_msms;
        mode_sel[1:0] <= 2'b00;
        dynamic_tlast <= 1'b0;
    end
    else begin
        cstate  <= #10 nstate;
        dcnt    <= #10 dcnt_x;
        if(nstate != cstate) pstate <= #10 cstate;
        if(dcnt_done & cmd_ack & (cstate == ST_ADDR)) sr_srw <= #10 phy_rx;
        irq_nas <= #10 nas_x;
        sr_aas  <= #10 aas_x;
        sr_abgc <= #10 abgc_x;
        req_sta <= #10 req_sta_x;
        cr_msms_r <= cr_msms;
        mode_sel[1:0] <= mode_sel_x[1:0];
        if(tx_fifo_rd)
            dynamic_tlast <= tx_fifo_dout[9];

        if(cmd_ack && (cstate == ST_ACK)) begin
            cr_txak_hold <= #10 cr_txak;
        end
        if(dynamic_sta) begin
            dynamic_mode <= #10 1'b1;
        end
        else if(cstate == ST_STOP && cmd_ack) begin
            dynamic_mode <= #10 1'b0;
        end
        dynamic_rcnt[7:0]  <= #10 dynamic_rcnt_x;
    end
end

// sequential without reset
always @(posedge clk)
begin
    if (load)       sr <= #10 tx_fifo_dout[7:0];
    else if(shift)  sr <= #10 {sr[6:0], phy_rx};
end


endmodule
