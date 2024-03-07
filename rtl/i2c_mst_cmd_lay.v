// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Device        : Xilinx
// Author        : Zack
// Email         : zacyang@foxmail.com
// Created On    : 2024/02/24 14:12
// Last Modified : 2024/03/07 14:14
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
    output          cr_msms_set,
    output          cr_msms_clr,
    output          cr_txnk_set,

    input           tx_fifo_empty,
    input           tx_fifo_rd,
    input   [9:0]   tx_fifo_dout,
    input           tx_fifo_wr,
    input   [9:0]   tx_fifo_din

    input           rx_fifo_wr
);


reg [7:0]   rcnt;
reg         load;

assign cr_msms_set = !tx_fifo_empty && tx_fifo_dout[8] && cr_en;

assign cr_msms_clr = !tx_fifo_empty && tx_fifo_dout[9] && cr_en;

assign cr_txnk_set = rx_fifo_wr && rcnt == 2;

always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        rcnt <= 8'b0;
        load <= 1'b0;
    end
    else begin
        load <= tx_fifo_rd && tx_fifo_dout[8] && tx_fifo_dout[0];
        if(load)
            rcnt <= tx_fifo_dout[7:0];
        else if(rx_fifo_wr)
            rcnt <= rcnt - 1;
    end
end

endmodule
