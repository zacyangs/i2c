module i2c_reg(
    input               clk,
    input               rstn,

    input               apb_sel,
    input               apb_en,
    input               apb_write,
    output reg          apb_ready = 1,
    input       [31:0]  apb_addr,
    input       [31:0]  apb_wdata,
    output reg  [31:0]  apb_rdata = 0,

    output              irq,

    input       [4:0]   tx_fifo_ocy,
    output              tx_fifo_wr,
    output      [9:0]   tx_fifo_wdat,
    input       [4:0]   rx_fifo_ocy,
    output              rx_fifo_rd,
    input       [7:0]   rx_fifo_rdat,
    output      [4:0]   rx_fifo_pirq,
    output      [9:0]   slv_adr,
    output reg          srstn = 1'b1,

    output reg  [6:0]   cr,
    input       [6:0]   cr_clr,
    input       [7:0]   sr,
    input       [7:0]   irq_req,

    output reg  [31:0]  tsusta,
    output reg  [31:0]  tsusto,
    output reg  [31:0]  thdsta,
    output reg  [31:0]  tsudat,
    output reg  [31:0]  tbuf,
    output reg  [31:0]  thigh,
    output reg  [31:0]  tlow,
    output reg  [31:0]  thddat
);

reg         gie = 0;
reg  [7:0]  isr = 0;
wire [7:0]  isr_nxt;
wire [7:0]  isr_clr;
wire [7:0]  isr_set;

reg  [7:0]  ier;
reg  [9:0]  txr;
reg  [6:0]  adr;
reg  [2:0]  ten_adr;
reg  [4:0]  rx_pirq;

wire        srst_set;
wire        srst_clr;
reg  [3:0]  srst_cnt = 0;

wire        wr_en;
wire        rd_en;
wire        wr_isr;

assign rx_fifo_pirq[4:0] = rx_pirq[4:0];
assign slv_adr      = {ten_adr, adr};

assign wr_en =  apb_write & apb_en & apb_sel;
assign rd_en = ~apb_write & apb_en & apb_sel;


always @(posedge clk or negedge rstn)
begin
    if (!rstn) begin
        gie         <= #10 1'b0;
        ier         <= #10 8'h0;
        cr          <= #10 7'b0;
        adr         <= #10 7'b0;
        ten_adr     <= #10 3'b0;
        rx_pirq     <= #10 5'b1;
        txr         <= #10 10'b0;
        tsusta      <= #10 50;
        tsusto      <= #10 50;
        thdsta      <= #10 50;
        tsudat      <= #10 50;
        tbuf        <= #10 50;
        thigh       <= #10 50;
        tlow        <= #10 50;
        thddat      <= #10 50;
    end else if (wr_en) begin
        case (apb_addr[8:0])
            9'h01c : gie        <= #10 apb_wdata[31];
            9'h028 : ier        <= #10 apb_wdata[7:0];
            9'h100 : cr         <= #10 apb_wdata[6:0];
            9'h108 : txr        <= #10 apb_wdata[9:0];
            9'h110 : adr        <= #10 apb_wdata[7:0];
            9'h11c : ten_adr    <= #10 apb_wdata[2:0];
            9'h120 : rx_pirq    <= #10 apb_wdata[4:0];
            9'h128 : tsusta     <= #10 apb_wdata[31:0];
            9'h12c : tsusto     <= #10 apb_wdata[31:0];
            9'h130 : thdsta     <= #10 apb_wdata[31:0];
            9'h134 : tsudat     <= #10 apb_wdata[31:0];
            9'h138 : tbuf       <= #10 apb_wdata[31:0];
            9'h13c : thigh      <= #10 apb_wdata[31:0];
            9'h140 : tlow       <= #10 apb_wdata[31:0];
            9'h144 : thddat     <= #10 apb_wdata[31:0];
            default: ;
        endcase
    end
    else begin
        cr[6:0] <= cr[6:0] & (~cr_clr);
    end
end

always @(posedge clk)
begin
    case (apb_addr[8:0]) 
        9'h01c: apb_rdata <= #10 {gie, 31'b0 };
        9'h020: apb_rdata <= #10 {24'b0, isr };
        9'h028: apb_rdata <= #10 {24'b0, ier }; 
        9'h100: apb_rdata <= #10 {25'b0, cr  }; 
        9'h104: apb_rdata <= #10 {24'b0, sr  }; 
        9'h108: apb_rdata <= #10 {24'b0, txr };
        9'h10c: apb_rdata <= #10 {26'b0, rx_fifo_rdat};
        9'h110: apb_rdata <= #10 {26'b0, adr, 1'b0};
        9'h114: apb_rdata <= #10 {27'b0, tx_fifo_ocy};
        9'h118: apb_rdata <= #10 {27'b0, rx_fifo_ocy};
        9'h11c: apb_rdata <= #10 {29'b0, ten_adr};
        9'h120: apb_rdata <= #10 {27'b0, rx_pirq};
        9'h128: apb_rdata <= #10 tsusta;
        9'h12c: apb_rdata <= #10 tsusto;
        9'h130: apb_rdata <= #10 thdsta;
        9'h134: apb_rdata <= #10 tsudat;
        9'h138: apb_rdata <= #10 tbuf;
        9'h13c: apb_rdata <= #10 thigh;
        9'h140: apb_rdata <= #10 tlow;
        9'h144: apb_rdata <= #10 thddat;
        default : apb_rdata <= #10 32'hdeadbeef;
    endcase
end

assign srst_set = wr_en && 
                  apb_addr[8:0] == 9'h040 &&
                  apb_wdata[31:0] == 32'ha;

assign srst_clr = srst_cnt == 0;

always@(posedge clk)
begin
    if(srst_set)
        srst_cnt <= #10 4'ha;
    else if(|srst_cnt)
        srst_cnt <= #10 srst_cnt - 1'b1;

    if(srst_set)
        srstn <= #10 1'b0;
    else if(srst_clr)
        srstn <= #10 1'b1;

    isr <= #10 isr_nxt;
end



// fifo 
assign tx_fifo_wr   = wr_en && (apb_addr[8:0] == 9'h108);
assign tx_fifo_wdat = apb_wdata[9:0];

assign rx_fifo_rd   = rd_en && (apb_addr[8:0] == 9'h10c);


// interrupt handler
assign wr_isr       = wr_en && (apb_addr[8:0] == 9'h020);
assign isr_clr[7:0] = {8{wr_isr}} & apb_wdata[7:0];


assign isr_set[7:0] = irq_req[7:0];

assign isr_nxt[7:0] = (isr[7:0] & (~isr_clr[7:0])) | isr_set[7:0];

assign irq          = |(isr | ier) & gie;

endmodule
