module i2c_top(
    input           clk,
    input           rstn,

    input           apb_sel,
    input           apb_en,
    input           apb_write,
    output          apb_ready,
    input  [31:0]   apb_addr,
    input  [31:0]   apb_wdata,
    output [31:0]   apb_rdata,

    output          i2c_irq,

    inout           i2c_scl,
    inout           i2c_sda
);

/*autodef*/
    //Start of automatic define
    //Start of automatic reg
    //Define flip-flop registers here
    //Define combination registers here
    //End of automatic reg
    //Start of automatic wire
    //Define assign wires here
    //Define instance wires here
    wire [4:0]                  tx_fifo_ocy                     ;
    wire                        tx_fifo_wr                      ;
    wire [9:0]                  tx_fifo_wdat                    ;
    wire [4:0]                  rx_fifo_ocy                     ;
    wire                        rx_fifo_rd                      ;
    wire [7:0]                  rx_fifo_rdat                    ;
    wire [4:0]                  rx_fifo_pirq                    ;
    wire [9:0]                  slv_adr                         ;
    wire [7:0]                  cr                              ;
    wire [7:0]                  sr                              ;
    wire [7:0]                  irq_req                         ;
    wire                        sta_det                         ;
    wire                        sto_det                         ;
    //End of automatic wire
    //End of automatic define


i2c_reg u_i2c_reg (/*autoinst*/
        .clk                    (clk                            ), //input
        .rstn                   (rstn                           ), //input
        .apb_sel                (apb_sel                        ), //input
        .apb_en                 (apb_en                         ), //input
        .apb_write              (apb_write                      ), //input
        .apb_ready              (apb_ready                      ), //output
        .apb_addr               (apb_addr[31:0]                 ), //input
        .apb_wdata              (apb_wdata[31:0]                ), //input
        .apb_rdata              (apb_rdata[31:0]                ), //output
        .irq                    (i2c_irq                        ), //output
        .tx_fifo_ocy            (tx_fifo_ocy[4:0]               ), //input
        .tx_fifo_wr             (tx_fifo_wr                     ), //output
        .tx_fifo_wdat           (tx_fifo_wdat[9:0]              ), //output
        .rx_fifo_ocy            (rx_fifo_ocy[4:0]               ), //input
        .rx_fifo_rd             (rx_fifo_rd                     ), //output
        .rx_fifo_rdat           (rx_fifo_rdat[7:0]              ), //input
        .rx_fifo_pirq           (rx_fifo_pirq[4:0]              ), //output // INST_NEW
        .slv_adr                (slv_adr[9:0]                   ), //output // INST_NEW
        .cr                     (cr[6:0]                        ), //output // INST_NEW
        .sr                     (sr[7:0]                        ), //input // INST_NEW
        .irq_req                (irq_req[7:0]                   )  //input // INST_NEW
    );

i2c_core u_i2c_core(/*autoinst*/
        .clk                    (clk                            ), //input
        .rstn                   (rstn                           ), //input
        .sta                    (sta_det                        ), //input
        .sto                    (sto_det                        ), //input
        .slv_adr                (slv_adr[9:0]                   ), //input
        .cr                     (cr[7:0]                        ), //input
        .sr                     (sr[7:0]                        ), //output
        .irq_req                (irq_req[7:0]                   ), //output
        .rx_fifo_pirq           (rx_fifo_pirq[4:0]              ), //input
        .tx_fifo_ocy            (tx_fifo_ocy[4:0]               ), //output
        .rx_fifo_ocy            (rx_fifo_ocy[4:0]               ), //output
        .tx_fifo_wr             (tx_fifo_wr                     ), //input // INST_NEW
        .tx_fifo_wdat           (tx_fifo_wdat[9:0]              ), //input // INST_NEW
        .rx_fifo_rd             (rx_fifo_rd                     ), //input // INST_NEW
        .rx_fifo_rdat           (rx_fifo_rdat[7:0]              ), //input // INST_NEW
        .sda                    (i2c_sda                        ), //inout
        .scl                    (i2c_scl                        )  //inout
    );

endmodule
//Local Variables:
//verilog-library-directories (".")
//verilog-library-directories-recursive:0
//End: 
