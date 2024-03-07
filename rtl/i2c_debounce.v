module i2c_debounce (
    input               clk,
    input               rstn,

    inout               scl,
    inout               sda,

    input       [13:0]  debounce_cnt,
    output              sta_det,
    output              sto_det,
    output  reg         busy,
    output              scl_rising,
    output              scl_faling,

    input               scl_gauge_en,
    output  reg [31:0]  thigh,
    output  reg [31:0]  tlow,

    input               scl_o,
    output              scl_i,

    input               sda_o,
    output              sda_i
);

reg [ 1:0] cSCL, cSDA;      // capture SCL and SDA
reg [ 2:0] fSCL, fSDA;      // SCL and SDA filter inputs
reg        sSCL, sSDA;      // filtered and synchronized SCL and SDA inputs
reg        dSCL, dSDA;      // delayed versions of sSCL and sSDA
reg [13:0] filter_cnt;      // clock divider for filter
reg [31:0] timing_cnt;


assign scl = scl_o ? 1'bz : 1'b0;
assign sda = sda_o ? 1'bz : 1'b0;

always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        timing_cnt <= #10 32'b0;
        thigh      <= #10 32'hffff_ffff;
        tlow       <= #10 32'hffff_ffff;
    end
    else if(scl_gauge_en) begin
        if(scl_rising || scl_faling)
            timing_cnt <= #10 32'b0;
        else if(busy)
            timing_cnt <= #10 timing_cnt + 1'b1;

        if(scl_rising) tlow  <= #10 timing_cnt;
        if(scl_faling) thigh <= #10 timing_cnt;
    end
end



// capture SDA and SCL
// reduce metastability risk
always @(posedge clk or negedge rstn)
    if (!rstn) begin
        cSCL <= #10 2'b00;
        cSDA <= #10 2'b00;
    end else begin
        cSCL <= #10 {cSCL[0],scl};
        cSDA <= #10 {cSDA[0],sda};
    end


// filter SCL and SDA signals; (attempt to) remove glitches
always @(posedge clk or negedge rstn)
    if (!rstn) 
        filter_cnt <= #10 14'h0;
    else if (~|filter_cnt)
        filter_cnt <= #10 debounce_cnt; //16x I2C bus frequency
    else
        filter_cnt <= #10 filter_cnt -1;


always @(posedge clk or negedge rstn)
    if (!rstn) begin
        fSCL <= #10 3'b111;
        fSDA <= #10 3'b111;
    end else if (~|filter_cnt) begin
        fSCL <= #10 {fSCL[1:0],cSCL[1]};
        fSDA <= #10 {fSDA[1:0],cSDA[1]};
    end


// generate filtered SCL and SDA signals
always @(posedge clk or negedge rstn)
    if (~rstn) begin
        sSCL <= #10 1'b1;
        sSDA <= #10 1'b1;

        dSCL <= #10 1'b1;
        dSDA <= #10 1'b1;
    end else begin
        sSCL <= #10 &fSCL[2:1] | &fSCL[1:0] | (fSCL[2] & fSCL[0]);
        sSDA <= #10 &fSDA[2:1] | &fSDA[1:0] | (fSDA[2] & fSDA[0]);

        dSCL <= #10 sSCL;
        dSDA <= #10 sSDA;
    end

always @(posedge clk or negedge rstn)
    if (~rstn)
        busy <= #10 1'b0;
    else if(sta_det)
        busy <= #10 1'b1;
    else if(sto_det)
        busy <= #10 1'b0;


assign sta_det = sSCL && (!sSDA) && dSDA;
assign sto_det = sSCL && sSDA && (!dSDA);
assign scl_i   = dSCL;
assign sda_i   = dSDA;
assign scl_faling = dSCL && (!sSCL);
assign scl_rising = (!dSCL) && sSCL;

endmodule
