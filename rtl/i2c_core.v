module i2c_core(
    input           clk,
    input           rstn,

    input           sta,
    input           sto,

    input   [9:0]   slv_adr,

    input   [7:0]   cr,
    output  [7:0]   sr,
    output  [7:0]   irq_req,
    input   [4:0]   rx_fifo_pirq,
    output  [4:0]   tx_fifo_ocy,
    output  [4:0]   rx_fifo_ocy,
    input           tx_fifo_wr,
    input   [9:0]   tx_fifo_wdat,
    input           rx_fifo_rd,
    input   [7:0]   rx_fifo_rdat,

    inout           sda,
    inout           scl
);


/*autodef*/
    //Start of automatic define
    //Start of automatic reg
    //Define flip-flop registers here
    //Define combination registers here
    //End of automatic reg
    //Start of automatic wire
    //Define assign wires here
    wire                        rx_fifo_pfull                   ;
    //Define instance wires here
    wire                        tx_fifo_rd                      ;
    wire [9:0]                  tx_fifo_rdat                    ;
    wire                        tx_fifo_empty                   ;
    wire                        tx_fifo_full                    ;
    wire                        rx_fifo_empty                   ;
    wire                        rx_fifo_wr                      ;
    wire [7:0]                  rx_fifo_wdat                    ;
    wire                        rx_fifo_full                    ;
    wire                        busy                            ;
    wire                        scl_rising                      ;
    wire                        scl_faling                      ;
    wire                        scl_o                           ;
    wire                        scl_i                           ;
    wire                        sda_o                           ;
    wire                        sda_i                           ;
    wire                        cr_en                           ;
    wire                        cr_gcen                         ;
    wire                        cr_txak                         ;
    wire                        sr_aas                          ;
    wire                        sr_abgc                         ;
    wire                        sr_srw                          ;
    wire                        sr_bb                           ;
    wire                        irq_nas                         ;
    wire                        irq_tx_empty                    ;
    wire                        irq_tx_done                     ;
    wire                        irq_rx_err                      ;
    wire                        slv_tx_rd                       ; // WIRE_NEW
    wire [7:0]                  slv_tx_dat                      ; // WIRE_NEW
    wire                        slv_rx_wr                       ; // WIRE_NEW
    wire [7:0]                  slv_rx_dat                      ; // WIRE_NEW
    wire                        mst_tx_rd                       ; // WIRE_NEW
    wire [7:0]                  mst_tx_dat                      ; // WIRE_NEW
    wire                        mst_rx_wr                       ; // WIRE_NEW
    wire [7:0]                  mst_rx_dat                      ; // WIRE_NEW

    //End of automatic wire
    //End of automatic define



assign sr_bb = busy;

assign rx_fifo_pfull = (rx_fifo_ocy[4:0] == rx_fifo_pirq[4:0]) &&
                        |rx_fifo_pirq[4:0];

assign {
    cr_gcen,
    cr_rsta,
    cr_txak,
    cr_tx,
    cr_msms,
    cr_txfifo_rst,
    cr_en } = cr;

assign sr = {
    tx_fifo_empty,
    rx_fifo_empty,
    rx_fifo_full,
    tx_fifo_full,
    sr_srw,
    sr_bb,
    sr_aas,
    sr_abgc
    };

assign irq_req = {
    !tx_fifo_ocy[3],
    irq_nas,
    sr_aas,
    !sr_bb,
    rx_fifo_pfull,
    tx_fifo_empty,
    2'b0
        };

assign tx_fifo_rd = cr_msms ? mst_tx_rd : slv_tx_rd;
assign slv_tx_dat = tx_fifo_rdat[7:0];

sync_fifo#(.DW(10), .DEPTH(16)) u_tx_fifo (/*autoinst*/
        .clk                    (clk                            ), //input
        .rstn                   (rstn && (!cr_txfifo_rst)       ), //input
        .rd                     (tx_fifo_rd                     ), //input
        .dout                   (tx_fifo_rdat[9:0]              ), //output
        .empty                  (tx_fifo_empty                  ), //output
        .wr                     (tx_fifo_wr                     ), //input
        .din                    (tx_fifo_wdat[9:0]              ), //input
        .full                   (tx_fifo_full                   ), //output
        .usedw                  (tx_fifo_ocy[4:0]               )  //output // INST_NEW
    );


assign rx_fifo_wr   = cr_msms ? mst_rx_wr : slv_rx_wr;
assign rx_fifo_wdat = cr_msms ? mst_rx_dat : slv_rx_dat;

sync_fifo #( .DW(8), .DEPTH(16)) u_rx_fifo (/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .rd                     (rx_fifo_rd                     ), //I
        .dout                   (rx_fifo_rdat[7:0]              ), //O
        .empty                  (rx_fifo_empty                  ), //O
        .wr                     (rx_fifo_wr                     ), //I
        .din                    (rx_fifo_wdat[7:0]              ), //I
        .full                   (rx_fifo_full                   ), //O
        .usedw                  (rx_fifo_ocy[4:0]               )  //O
    );

i2c_debounce u_i2c_debounce ( /*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .scl                    (scl                            ), //IO
        .sda                    (sda                            ), //IO
        .sta_det                (sta                            ), //O
        .sto_det                (sto                            ), //O
        .busy                   (busy                           ), //O
        .scl_rising             (scl_rising                     ), //O
        .scl_faling             (scl_faling                     ), //O
        .scl_o                  (scl_o                          ), //I
        .scl_i                  (scl_i                          ), //O
        .sda_o                  (sda_o                          ), //I
        .sda_i                  (sda_i                          )  //O
    );


i2c_slv u_i2c_slv(/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .address                (slv_adr[6:0]                   ), //I
        .cr_en                  (cr_en                          ), //I
        .cr_gcen                (cr_gcen                        ), //I
        .cr_txak                (cr_txak                        ), //I
        .sr_aas                 (sr_aas                         ), //O
        .sr_abgc                (sr_abgc                        ), //O
        .sr_srw                 (sr_srw                         ), //O
        .sr_bb                  (sr_bb                          ), //O
        .irq_nas                (irq_nas                        ), //O
        .irq_tx_empty           (irq_tx_empty                   ), //O
        .irq_tx_done            (irq_tx_done                    ), //O
        .irq_rx_err             (irq_rx_err                     ), //O
        .tx_empty               (tx_fifo_empty                  ), //I
        .tx_rd                  (slv_tx_rd                      ), //O
        .tx_dat                 (slv_tx_dat[7:0]                ), //I
        .rx_full                (rx_fifo_full                   ), //I
        .rx_wr                  (slv_rx_wr                      ), //O
        .rx_dat                 (slv_rx_dat[7:0]                ), //O
        .sta                    (sta                            ), //I
        .sto                    (sto                            ), //I
        .scl_rising             (scl_rising                     ), //I
        .scl_faling             (scl_faling                     ), //I
        .sda_o                  (sda_o                          ), //O
        .sda_i                  (sda_i                          ), //I
        .scl_o                  (scl_o                          ), //O
        .scl_i                  (scl_i                          )  //I
    );


endmodule
//Local Variables:
//verilog-library-directories (".")
//verilog-library-directories-recursive:0
//End: 
