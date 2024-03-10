// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Device        : Xilinx
// Author        : Zack
// Email         : zacyang@foxmail.com
// Created On    : 2024/02/24 14:12
// Last Modified : 2024/03/10 16:53
// File Name     : i2c_mst_cmd_lay.v
// Description   :
//         
// Copyright (c) 2024 NB Co.,Ltd..
// ALL RIGHTS RESERVED
// 
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2024/02/24   Zack             1.0                     Original
// -FHDR----------------------------------------------------------------------------
module i2c_dynamic_ctrl(
    input           clk,
    input           rstn,
    
    input           cr_en,
    input           cr_msms,
    output          dyna_msms_set,
    output          dyna_msms_clr,
    output          dyna_txak_set,
    output          dyna_txak_clr,
    output          dyna_tx_set,
    output          dyna_tx_clr,
    output          dyna_rsta_set,

    input           tx_fifo_empty,
    input           tx_fifo_rd,
    input   [9:0]   tx_fifo_dout,
    input           tx_fifo_wr,
    input   [9:0]   tx_fifo_din,

    input           rx_fifo_wr
);


reg [7:0]   rcnt;
reg         load;

reg         start_hold;
wire        start_set;

assign start         = !tx_fifo_empty & tx_fifo_dout[8] |
                        tx_fifo_empty & tx_fifo_wr & tx_fifo_din[8];
assign start_set     = !start_hold & start;

assign dyna_msms_set = start_set & cr_en & !cr_msms;
assign dyna_rsta_set = start_set & cr_en &  cr_msms;
assign dyna_msms_clr = (tx_fifo_rd | dyna_txak_set) & tx_fifo_dout[9];
assign dyna_txak_set = rx_fifo_wr && rcnt == 2;
assign dyna_txak_clr = start_set & cr_en;
assign dyna_tx_set   = tx_fifo_rd && tx_fifo_dout[8] && tx_fifo_dout[0];
assign dyna_tx_clr   = tx_fifo_rd && tx_fifo_dout[9] || 
                       tx_fifo_rd && tx_fifo_dout[8] && tx_fifo_dout[0];;

always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        rcnt <=8'b0;
        load <=1'b0;
        start_hold <= 1'b0;
    end
    else begin
        load <= tx_fifo_rd && tx_fifo_dout[8] && tx_fifo_dout[0];
        start_hold <= start;
        if(load)
            rcnt <=tx_fifo_dout[7:0];
        else if(rx_fifo_wr)
            rcnt <=rcnt - 1;
    end
end

endmodule
