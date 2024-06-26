module sync_fifo#(
    parameter DW = 8,
    parameter DEPTH = 128,
    parameter AW = clog2(DEPTH)
)(
    input               clk,
    input               rstn,

    input               rd,
    output      [DW-1:0]dout,
    output  reg         empty,

    input               wr,
    input       [DW-1:0]din,
    output  reg         full,

    output  reg  [AW:0] usedw
);

reg  [DW-1:0]   mem [DEPTH-1:0];
wire [AW-1:0]   rptr_nxt;
wire [AW-1:0]   wptr_nxt;
reg  [AW-1:0]   rptr;
reg  [AW-1:0]   wptr;
wire            empty_set;
wire            empty_clr;
wire            empty_nxt;
wire            full_set;
wire            full_clr;
wire            full_nxt;
reg  [DW-1:0]   q_cache;
reg  [DW-1:0]   q_tmp;
reg             show_ahead;

assign wr_int     = wr & (!full);
assign rd_int     = rd & (!empty);

assign wptr_nxt   = wr_int? wptr + 1 : wptr;
assign rptr_nxt   = rd_int? rptr + 1 : rptr;

// set has higher priority over clear
assign empty_set  = rd_int && !wr_int && (usedw == 1);
assign empty_clr  = wr_int;
assign empty_nxt  = empty_set ? 1'b1 :
                    empty_clr ? 1'b0 : empty;

// set has higher priority over clear
assign full_set = wr_int && !rd_int && (usedw == DEPTH - 1);
assign full_clr = rd_int;
assign full_nxt = full_set ? 1'b1 : 
                  full_clr ? 1'b0 : (usedw == DEPTH);

always @(posedge clk or negedge rstn) 
begin
    if(!rstn) begin
        wptr        <= 0;
        rptr        <= 0;
        empty       <= 1'b1;
        full        <= 1'b0;
        show_ahead  <= 1'b0;
    end
    else begin
        wptr        <= wptr_nxt;
        rptr        <= rptr_nxt;
        empty       <= empty_nxt;
        full        <= full_nxt;

        if(wr_int && (usedw == {{AW-1{1'b0}}, rd_int}))
            show_ahead <= 1'b1;
        else 
            show_ahead <= 1'b0;
    end
end



// used word_ints in the fifo
always @(posedge clk or negedge rstn) begin : proc_usedw
    if(!rstn) begin
        usedw <= 0;
    end else if(rd_int && !wr_int) begin
        usedw <= usedw - 1;
    end else if(!rd_int && wr_int) begin
        usedw <= usedw + 1;
    end
end

always @(posedge clk) begin
    if(wr_int)
        mem[wptr] <= din;

    q_tmp   <= mem[rptr_nxt];

    q_cache <= din;

end

assign dout = show_ahead ? q_cache : q_tmp;


function integer clog2;
    input integer depth;
begin
    depth = depth - 1;
    for(clog2 = 1; depth > 1; depth = depth >> 1)
        clog2 = clog2 + 1;
end
endfunction

endmodule // sync_fifo
