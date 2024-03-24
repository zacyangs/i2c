`include "i2c_master_defines.v"
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
    wire [9:0]                  tx_fifo_din                     ;
    wire [4:0]                  rx_fifo_ocy                     ;
    wire                        rx_fifo_rd                      ;
    wire [7:0]                  rx_fifo_dout                    ;
    wire [4:0]                  rx_fifo_pirq                    ;
    wire [6:0]                  slv_adr                         ;
    wire                        srstn                           ;
    wire [7:0]                  cr                              ;
    wire [7:0]                  cr_clr                          ;
    wire [6:0]                  cr_set                          ; // WIRE_NEW
    wire [7:0]                  sr                              ;
    wire [7:0]                  irq_req                         ;
    wire [31:0]                 tsusta                          ;
    wire [31:0]                 tsusto                          ;
    wire [31:0]                 thdsta                          ;
    wire [31:0]                 tsudat                          ;
    wire [31:0]                 tbuf                            ;
    wire [31:0]                 thigh                           ;
    wire [31:0]                 tlow                            ;
    wire [31:0]                 thddat                          ;
    wire                        cr_msms                         ;
    //End of automatic wire
    //End of automatic define


i2c_reg u_i2c_reg (/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .apb_sel                (apb_sel                        ), //I
        .apb_en                 (apb_en                         ), //I
        .apb_write              (apb_write                      ), //I
        .apb_ready              (apb_ready                      ), //O
        .apb_addr               (apb_addr[31:0]                 ), //I
        .apb_wdata              (apb_wdata[31:0]                ), //I
        .apb_rdata              (apb_rdata[31:0]                ), //O
        .irq                    (i2c_irq                        ), //O
        .tx_fifo_ocy            (tx_fifo_ocy[4:0]               ), //I
        .tx_fifo_wr             (tx_fifo_wr                     ), //O
        .tx_fifo_wdat           (tx_fifo_din[9:0]               ), //O
        .rx_fifo_ocy            (rx_fifo_ocy[4:0]               ), //I
        .rx_fifo_rd             (rx_fifo_rd                     ), //O
        .rx_fifo_rdat           (rx_fifo_dout[7:0]              ), //I
        .rx_fifo_pirq           (rx_fifo_pirq[4:0]              ), //O
        .slv_adr                (slv_adr[6:0]                   ), //O
        .srstn                  (srstn                          ), //O
        .cr                     (cr[6:0]                        ), //O
        .cr_clr                 (cr_clr[6:0]                    ), //I
        .cr_set                 (cr_set[6:0]                    ), //I // INST_NEW
        .sr                     (sr[7:0]                        ), //I
        .irq_req                (irq_req[7:0]                   ), //I
        .tsusta                 (tsusta[31:0]                   ), //O
        .tsusto                 (tsusto[31:0]                   ), //O
        .thdsta                 (thdsta[31:0]                   ), //O
        .tsudat                 (tsudat[31:0]                   ), //O
        .tbuf                   (tbuf[31:0]                     ), //O
        .thigh                  (thigh[31:0]                    ), //O
        .tlow                   (tlow[31:0]                     ), //O
        .thddat                 (thddat[31:0]                   )  //O
    );

i2c_core u_i2c_core(/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .slv_adr                (slv_adr[6:0]                   ), //I
        .cr                     (cr[7:0]                        ), //I
        .cr_clr                 (cr_clr[7:0]                    ), //O
        .cr_set                 (cr_set[6:0]                    ), //O // INST_NEW
        .sr                     (sr[7:0]                        ), //O
        .irq_req                (irq_req[7:0]                   ), //O
        .tx_fifo_ocy            (tx_fifo_ocy[4:0]               ), //O
        .tx_fifo_wr             (tx_fifo_wr                     ), //I
        .tx_fifo_din            (tx_fifo_din[9:0]               ), //I
        .rx_fifo_pirq           (rx_fifo_pirq[4:0]              ), //I
        .rx_fifo_ocy            (rx_fifo_ocy[4:0]               ), //O
        .rx_fifo_rd             (rx_fifo_rd                     ), //I
        .rx_fifo_dout           (rx_fifo_dout[7:0]              ), //I
        .debounce_cnt           ('d10                           ), //I
        .tsusta                 (tsusta[31:0]                   ), //I
        .thdsta                 (thdsta[31:0]                   ), //I
        .tsusto                 (tsusto[31:0]                   ), //I
        .tsudat                 (tsudat[31:0]                   ), //I
        .thddat                 (thddat[31:0]                   ), //I
        .tlow                   (tlow[31:0]                     ), //I
        .thigh                  (thigh[31:0]                    ), //I
        .tbuf                   (tbuf[31:0]                     ), //I
        .cr_msms                (cr_msms                        ), //I
        .sda                    (i2c_sda                        ), //IO
        .scl                    (i2c_scl                        )  //IO
    );

endmodule
//Local Variables:
//verilog-library-directories (".")
//verilog-library-directories-recursive:0
//End: 
