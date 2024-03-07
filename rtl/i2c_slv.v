module i2c_slv(
    input           clk,
    input           rstn,

    input   [6:0]   address,

    input           cr_en,
    input           cr_gcen,
    input           cr_txak,
    output reg      sr_aas, // addressed as slave
    output reg      sr_abgc,
    output reg      sr_srw,
    output reg      irq_nas,// not addressed as slave
    output          irq_tx_empty,
    output          irq_tx_done,
    output          irq_rx_err,

    input           tx_empty,
    output          tx_rd,
    input   [7:0]   tx_dat,

    input           rx_full,
    output reg      rx_wr,
    output  [7:0]   rx_dat,

    input           sta,
    input           sto,
    input           scl_rising, // TODO, this should be adjustable
    input           scl_faling,
    output reg      sda_o,
    input           sda_i,
    output reg      scl_o,
    input           scl_i
);


localparam IDLE      = 3'b000,
           HEADER    = 3'b001,
           RECV_DATA = 3'b010,
           NAK       = 3'b011,
           ACK       = 3'b100,
           XMIT_DATA = 3'b101,
           SUSPEND   = 3'b110;

reg [2:0] state, nstate;
reg [3:0] cnt;
reg [3:0] cnt_nxt;
reg [7:0] rx_shift;
wire[7:0] rx_shift_nxt;
reg [7:0] tx_shift;
wire[7:0] tx_shift_nxt;
wire      aas_set;
wire      nas_set;
wire      nas_clr;
wire      srw_set;
wire      gc_set;
wire      ack_set;
wire      aas_nxt;
wire      abgc_nxt;
wire      rx_wr_nxt;
wire      cnt_8;
wire      header_ack_set;
wire      header_ack_clr;
reg       header_ack;

assign cnt_8   = cnt[3:0] == 8;

assign aas_set = cnt_8 && scl_faling && rx_shift[7:1] == address;
assign gc_set  = cnt_8 && scl_faling && rx_shift[7:1] == 7'b0 && cr_gcen;

assign srw_set = (aas_set || gc_set) && state == HEADER;

assign rx_shift_nxt = scl_rising ? {rx_shift[6:0], sda_i} : rx_shift[7:0];

assign ack_set = srw_set;

assign aas_nxt = (sto || sta)  ? 1'b0 : 
                 aas_set       ? 1'b1 : sr_aas;

assign abgc_nxt= (sto || sta) ? 1'b0 :
                 gc_set       ? 1'b1 : sr_abgc;

assign nas_clr = aas_set || gc_set;
assign nas_set = sto || sta;

assign nas_nxt = nas_clr ? 1'b0 : 
                 nas_set ? 1'b1 : 
                 irq_nas ;

assign irq_rx_err  = (aas_set || gc_set) && cr_txak;
assign irq_tx_done = (sr_srw) && (state == ACK) && scl_rising && sda_i;
assign irq_tx_empty= state == SUSPEND && tx_empty;


assign rx_wr_nxt = state == RECV_DATA && cnt_8 && scl_faling;
assign rx_dat    = rx_shift;

assign tx_rd     = state == ACK && nstate == XMIT_DATA ||
                   state == SUSPEND && nstate == XMIT_DATA ;

assign tx_shift_nxt = tx_rd ? tx_dat :
                      state == XMIT_DATA && scl_faling ? tx_shift << 1 :
                      tx_shift;

assign header_ack_set = state == HEADER && scl_faling;
assign header_ack_clr = state == ACK && scl_faling;

always@(*)
begin
    nstate[2:0]  = state[2:0];
    cnt_nxt[3:0] = 0;
    sda_o        = 1'b1;
    scl_o        = 1'b1;
    case(state)
        IDLE : begin
            if(cr_en && sta)
                nstate[2:0] = HEADER;
        end
        
        HEADER : begin
            cnt_nxt[3:0] = cnt[3:0] + scl_rising;
            if(cnt_8 && scl_faling)
                nstate[2:0] = ACK;
        end

        RECV_DATA : begin
            cnt_nxt[3:0] = cnt[3:0] + scl_rising;
            if(sto||sta)
                nstate[2:0] = IDLE;
            else if(cnt_8 && scl_faling) begin
                nstate[2:0] = ACK;
            end
        end

        ACK : begin
            cnt_nxt[3:0] = scl_rising ? 4'b0 : cnt[3:0];
            sda_o = header_ack && !(sr_aas || sr_abgc) ||
                    (!header_ack) && (sr_srw || cr_txak);

            if(scl_faling) begin
                if(sr_srw) begin
                    if(sda_i)
                        nstate[2:0] = IDLE;
                    else if(tx_empty && (!cr_txak))
                        nstate[2:0] = SUSPEND;
                    else
                        nstate[2:0] = XMIT_DATA;
                end
                else begin
                    if(rx_full && (!cr_txak))
                        nstate[2:0] = SUSPEND;
                    else
                        nstate[2:0] = RECV_DATA; 
                end
            end
        end

        XMIT_DATA : begin
            cnt_nxt[3:0] = cnt[3:0] + scl_rising;
            sda_o = tx_shift[7];
            if(sto)
                nstate[2:0] = IDLE;
            else if(cnt_8 && scl_faling) begin
                nstate[2:0] = ACK;
            end
        end

        SUSPEND : begin
            scl_o = 0;
            if(!sr_srw && (!rx_full || cr_txak))
                nstate[2:0] = RECV_DATA; 
            else if(sr_srw && (!tx_empty || cr_txak))
                nstate[2:0] = XMIT_DATA;
        end

        default : ;
    endcase
end



always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        state[2:0]      <= #10 IDLE;
        rx_shift[7:0]   <= #10 8'b0;
        tx_shift[7:0]   <= #10 8'b0;
        sr_srw          <= #10 1'b0;
        sr_aas          <= #10 1'b0;
        sr_abgc         <= #10 1'b0;
        irq_nas         <= #10 1'b1;
        rx_wr           <= #10 1'b0;
        cnt[3:0]        <= #10 3'b0;
        header_ack      <= #10 1'b0;
    end
    else begin
        state[2:0]      <= #10 nstate[2:0];
        rx_shift[7:0]   <= #10 rx_shift_nxt[7:0];
        tx_shift[7:0]   <= #10 tx_shift_nxt[7:0];
        if(srw_set)
            sr_srw      <= #10 rx_shift_nxt[0];
        sr_aas          <= #10 aas_nxt;
        sr_abgc         <= #10 abgc_nxt;
        irq_nas         <= #10 nas_nxt;
        rx_wr           <= #10 rx_wr_nxt;
        if(scl_rising) 
            cnt[3:0]        <= #10 cnt_nxt[3:0];

        header_ack      <= #10 (header_ack || header_ack_set) & (~header_ack_clr);
    end
end

endmodule
