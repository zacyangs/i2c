module i2c_debounce (
    input   clk,
    input   rstn,

    inout   scl,
    inout   sda,

    output  sta_det,
    output  sto_det,
    output  reg busy,
    output  scl_rising,
    output  scl_faling,

    input   scl_o,
    output  scl_i,

    input   sda_o,
    output  sda_i
);

reg [ 1:0] cSCL, cSDA;      // capture SCL and SDA
reg [ 2:0] fSCL, fSDA;      // SCL and SDA filter inputs
reg        sSCL, sSDA;      // filtered and synchronized SCL and SDA inputs
reg        dSCL, dSDA;      // delayed versions of sSCL and sSDA
reg [13:0] filter_cnt;      // clock divider for filter

assign scl = scl_o ? 1'bz : 1'b0;
assign sda = sda_o ? 1'bz : 1'b0;


// capture SDA and SCL
// reduce metastability risk
always @(posedge clk or negedge rstn)
    if (!rstn) begin
        cSCL <= #1 2'b00;
        cSDA <= #1 2'b00;
    end else begin
        cSCL <= {cSCL[0],scl};
        cSDA <= {cSDA[0],sda};
    end


// filter SCL and SDA signals; (attempt to) remove glitches
always @(posedge clk or negedge rstn)
    if (!rstn) 
        filter_cnt <= 14'h0;
    else if (~|filter_cnt)
        filter_cnt <= 8; //16x I2C bus frequency
    else                   
        filter_cnt <= filter_cnt -1;


always @(posedge clk or negedge rstn)
    if (!rstn) begin
        fSCL <= 3'b111;
        fSDA <= 3'b111;
    end else if (~|filter_cnt) begin
        fSCL <= {fSCL[1:0],cSCL[1]};
        fSDA <= {fSDA[1:0],cSDA[1]};
    end


// generate filtered SCL and SDA signals
always @(posedge clk or negedge rstn)
    if (~rstn) begin
        sSCL <= 1'b1;
        sSDA <= 1'b1;

        dSCL <= 1'b1;
        dSDA <= 1'b1;
    end else begin
        sSCL <= &fSCL[2:1] | &fSCL[1:0] | (fSCL[2] & fSCL[0]);
        sSDA <= &fSDA[2:1] | &fSDA[1:0] | (fSDA[2] & fSDA[0]);

        dSCL <= sSCL;
        dSDA <= sSDA;
    end

always @(posedge clk or negedge rstn)
    if (~rstn)
        busy <= 1'b0;
    else if(sta_det)
        busy <= 1'b1;
    else if(sto_det)
        busy <= 1'b0;


assign sta_det = dSCL && (!sSDA) && dSDA;
assign sto_det = dSCL && sSDA && (!dSDA);
assign scl_i   = dSCL;
assign sda_i   = dSDA;
assign scl_faling = dSCL && (!sSCL);
assign scl_rising = (!dSCL) && sSCL;

endmodule
