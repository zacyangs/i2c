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
    output reg          sr_abgc,
    output reg          sr_aas,
    output reg          sr_srw,
    output reg          irq_nas,// not addressed as slave
    output reg          irq_tx_err,

    output reg [ 3:0]   cmd,      // command (from byte controller)
    input               cmd_ack,  // command complete acknowledge
    input               phy_rx,
    output reg          phy_tx,

    input               rx_fifo_full,
    output reg          rx_fifo_wr, 
    output      [7:0]   rx_fifo_din,
    input               tx_fifo_empty,
    output              tx_fifo_rd,
    input       [7:0]   tx_fifo_dout,
    output              scl_gauge_en,

    input               req_sta,
    input               req_sto,
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
localparam ST_WAIT  = 3'h7;

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
/*autodef*/
    //Start of automatic define
    //Start of automatic reg
    //Define flip-flop registers here
    reg                         dcnt_done_r                     ;
    //Define combination registers here
    reg                         load                            ;
    //REG_DEL: Register slv_rw has been deleted.
    //End of automatic reg
    //Start of automatic wire
    //Define assign wires here
    wire [1:0]                  work_stat                       ; // WIRE_NEW
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

// there could be 4 working status, which are:
// 2'b00 : master transmitter (also known as master write) 
// 2'b01 : master receiver    (also known as master read)
// 2'b10 : slave transmitter  (also known as slave read)
// 2'b11 : slave receiver     (also known as slave write)
assign work_stat[1:0] = cr_msms ? (cr_tx ? WSMT : WSMR) : (sr_srw ? WSST : WSSR);
assign scl_gauge_en  = work_stat[1] && cstate == ST_ADDR;

// status & interrupts
assign aas_set = dcnt_done_r & (sr[7:1] == slv_addr[7:1]);
assign gc_set  = dcnt_done_r & (sr[7:0] == 8'b0);


assign aas_x   = (rcv_sto || rcv_sta)  ? 1'b0 : 
                      aas_set          ? 1'b1 : sr_aas;

assign abgc_x  = (rcv_sto || rcv_sta)  ? 1'b0 :
                      gc_set           ? 1'b1 : sr_abgc;


assign nas_clr = aas_set | gc_set;
assign nas_set = (rcv_sto || rcv_sta);

assign nas_x = nas_clr ? 1'b0 : 
                 nas_set ? 1'b1 : irq_nas ;

// interrupt bit 2
// 1. WSMT:
//      a. no slave respond for address call
//      b. the slave issure nak to signal that it is not accepting anymore date
// 2. WSMR: transfer ended with txak = 1
// 3. WSST: nak recieved from master
// 4. WSSR: txak = 1

assign adr_ack =  (pstate == ST_ADDR);
// Fsm
always@(*)
begin
    nstate = cstate;
    cmd    = `I2C_CMD_NOP;
    load   = 1'b0;
    phy_tx = 1'b0;
    irq_tx_err = 1'b0;
    case(cstate)
        ST_IDLE : begin
            if(req_sta) nstate = ST_START;
            if(rcv_sta) begin nstate = ST_ADDR; load = !work_stat[1]; end // high priority
        end

        ST_START : begin
            cmd = `I2C_CMD_START;
            if(cmd_ack) begin nstate = ST_ADDR; load = 1'b1; end
        end

        ST_ADDR : begin
            if(cr_msms) cmd = `I2C_CMD_WRITE;
            else        cmd = `I2C_CMD_READ;

            phy_tx = sr[7];

            if(dcnt_done) nstate = ST_ACK;
        end

        ST_READ  : begin
            cmd = `I2C_CMD_READ;

            if(rcv_sta) nstate = ST_ADDR; // repeat start condition
            if(rcv_sto) nstate = ST_IDLE; // stop anyway
            if(dcnt_done) nstate = ST_ACK;
        end

        ST_WRITE : begin
            cmd = `I2C_CMD_WRITE;

            phy_tx = sr[7];

            if(dcnt_done) nstate = ST_ACK;
        end

        ST_ACK : begin
            if(adr_ack & work_stat[1] | !adr_ack & work_stat[0]) begin
                cmd        = `I2C_CMD_WRITE;
                irq_tx_err = cmd_ack & phy_tx;
            end else begin
                cmd        = `I2C_CMD_READ;
                irq_tx_err = cmd_ack & phy_rx;
            end

            
            phy_tx = adr_ack & !(sr_aas | sr_abgc) | cr_txak;

            if(cmd_ack) begin
                case({adr_ack, work_stat[1:0]})
                    3'h0, 3'h4, 3'h5:
                        if(phy_rx)
                            nstate = ST_STOP; 
                        else if(tx_fifo_empty) 
                            nstate = ST_WAIT; 
                        else begin
                            nstate = ST_WRITE;
                            load   = 1;
                        end

                    3'h2, 3'h6 : 
                        if(phy_rx)
                            nstate = ST_IDLE; 
                        else if(tx_fifo_empty) 
                            nstate = ST_WAIT; 
                        else begin
                            nstate = ST_WRITE;
                            load   = 1;
                        end

                    3'h1:
                        if(phy_tx | rx_fifo_full)
                            nstate = ST_WAIT;
                        else 
                            nstate = ST_READ;

                    3'h3, 3'h7 :
                        if(phy_tx) 
                            nstate = ST_IDLE; 
                        else if(rx_fifo_full) 
                            nstate = ST_WAIT; 
                        else 
                            nstate = ST_READ;
                    default: ;
                endcase
            end
        end

        ST_STOP : begin
            cmd = `I2C_CMD_STOP;
            if(cmd_ack) nstate = ST_IDLE;
        end

        ST_WAIT : begin
            cmd = `I2C_CMD_WAIT;
            if(work_stat[0] && !rx_fifo_full)  nstate = ST_READ; // restore
            if(!work_stat[0] && !tx_fifo_empty) begin nstate = ST_WRITE ; load = 1'b1; end
        end
        default:;
    endcase
end

assign shift =  (cstate == ST_READ || cstate == ST_WRITE || cstate == ST_ADDR) && cmd_ack;
// generate counter
assign cnt_clr = dcnt_done;
assign cnt_add = shift;
assign dcnt_x  = dcnt_done ? 3'h7 :
                 cnt_add ? dcnt - 1'b1 : dcnt;

assign dcnt_done = ~(|dcnt) & cmd_ack;

assign tx_fifo_rd = load;
assign rx_fifo_din = sr[7:0];



// sequential with async reset
always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        cstate      <= ST_IDLE;
        pstate      <= ST_IDLE;
        dcnt        <= 3'h7; 
        rx_fifo_wr  <= 1'b0;
        dcnt_done_r <= 1'b0;
        irq_nas     <= 1'b1;
        sr_aas      <= 1'b0;
        sr_abgc     <= 1'b0;
        sr_srw      <= 1'b0;
    end
    else begin
        dcnt_done_r <= dcnt_done;
        rx_fifo_wr <= dcnt_done && (cstate == ST_READ);
        cstate  <= nstate;
        dcnt    <= dcnt_x;
        if(nstate != cstate) pstate <= cstate;
        if(dcnt_done_r & (pstate == ST_ADDR)) sr_srw <= sr[0];
        irq_nas <= nas_x;
        sr_aas  <= aas_x;
        sr_abgc <= abgc_x;
    end
end

// sequential without reset
always @(posedge clk)
begin
    if (load)       sr <= tx_fifo_dout;
    else if(shift)  sr <= {sr[6:0], phy_rx};
end


endmodule
