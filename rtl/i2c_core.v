module i2c_core(
    input           clk,
    input           rstn,

    input   [9:0]   slv_adr,

    input   [7:0]   cr,
    output  [7:0]   cr_clr,
    output  [6:0]   cr_set,
    output  [7:0]   sr,
    output  [7:0]   irq_req,
    output  [4:0]   tx_fifo_ocy,
    input           tx_fifo_wr,
    input   [9:0]   tx_fifo_din,
    input   [4:0]   rx_fifo_pirq,
    output  [4:0]   rx_fifo_ocy,
    input           rx_fifo_rd,
    input   [7:0]   rx_fifo_dout,

    input      [13:0]   debounce_cnt,
    input      [31:0]   tsusta,
    input      [31:0]   thdsta,
    input      [31:0]   tsusto,
    input      [31:0]   tsudat,
    input      [31:0]   thddat,
    input      [31:0]   tlow,
    input      [31:0]   thigh,
    input      [31:0]   tbuf,
    input               cr_msms,

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
    wire                        sr_bb                           ;
    wire                        cr_rsta_set                     ;
    wire                        cr_tx_set                       ;
    wire                        cr_tx_clr                       ;
    wire                        cr_txak_set                     ;
    wire                        cr_txak_clr                     ;
    wire                        cr_msms_set                     ;
    wire                        cr_msms_clr                     ;
    //Define instance wires here
    wire                        tx_fifo_rd                      ;
    wire [9:0]                  tx_fifo_dout                    ;
    wire                        tx_fifo_empty                   ;
    wire                        tx_fifo_full                    ;
    wire                        rx_fifo_empty                   ;
    wire                        rx_fifo_wr                      ;
    wire [7:0]                  rx_fifo_din                     ;
    wire                        rx_fifo_full                    ;
    wire                        cr_en                           ;
    wire                        dyna_msms_set                   ;
    wire                        dyna_msms_clr                   ;
    wire                        dyna_txak_set                   ;
    wire                        dyna_txak_clr                   ;
    wire                        dyna_tx_set                     ;
    wire                        dyna_tx_clr                     ;
    wire                        dyna_rsta_set                   ;
    wire                        fsm_msms_clr                    ; // WIRE_NEW
    wire                        cr_tx                           ;
    wire                        cr_gcen                         ;
    wire                        cr_txak                         ;
    wire                        cr_rsta                         ;
    wire                        cr_rsta_clr                     ;
    wire                        sr_abgc                         ;
    wire                        sr_aas                          ;
    wire                        sr_srw                          ;
    wire                        irq_nas                         ;
    wire                        irq_tx_err                      ;
    wire                        irq_tx_empty                    ;
    wire [3:0]                  cmd                             ;
    wire                        cmd_ack                         ;
    wire                        phy_rx                          ;
    wire                        phy_tx                          ;
    wire                        al                              ;
    wire                        rx_fifo_pfull                   ;
    wire                        scl_gauge_en                    ;
    wire                        msms                            ;
    wire                        rsta_det                        ;
    wire                        sta_det                         ;
    wire                        sto_det                         ;
    wire                        busy                            ;
    wire                        scl_rising                      ;
    wire                        scl_faling                      ;
    //End of automatic wire
    //End of automatic define



assign sr_bb = busy;


assign {
    cr_gcen,
    cr_rsta,
    cr_txak,
    cr_tx,
    cr_msms,
    cr_txfifo_rst,
    cr_en } = cr;

assign cr_clr = {
    1'b0,
    cr_rsta_clr,
    cr_txak_clr,
    cr_tx_clr,
    cr_msms_clr, 2'b0};

assign cr_set = {
    1'b0,
    cr_rsta_set,
    cr_txak_set,
    cr_tx_set,
    cr_msms_set,
    2'b0
    };

assign cr_rsta_set = dyna_rsta_set;
assign cr_tx_set   = dyna_tx_set;
assign cr_tx_clr   = dyna_tx_clr;
assign cr_txak_set = dyna_txak_set;
assign cr_txak_clr = dyna_txak_clr;
assign cr_msms_set = dyna_msms_set;
assign cr_msms_clr = al || dyna_msms_clr || fsm_msms_clr;

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
    irq_tx_empty,
    irq_tx_err,
    al};


sync_fifo#(.DW(10), .DEPTH(16)) u_tx_fifo (/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn && (!cr_txfifo_rst)       ), //I
        .rd                     (tx_fifo_rd                     ), //I
        .dout                   (tx_fifo_dout[9:0]              ), //O
        .empty                  (tx_fifo_empty                  ), //O
        .wr                     (tx_fifo_wr                     ), //I
        .din                    (tx_fifo_din[9:0]               ), //I
        .full                   (tx_fifo_full                   ), //O
        .usedw                  (tx_fifo_ocy[4:0]               )  //O
        //INST_DEL: Port DW has been deleted.
        //INST_DEL: Port DEPTH has been deleted.
    );


sync_fifo #( .DW(8), .DEPTH(16)) u_rx_fifo (/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .rd                     (rx_fifo_rd                     ), //I
        .dout                   (rx_fifo_dout[7:0]              ), //O
        .empty                  (rx_fifo_empty                  ), //O
        .wr                     (rx_fifo_wr                     ), //I
        .din                    (rx_fifo_din[7:0]               ), //I
        .full                   (rx_fifo_full                   ), //O
        .usedw                  (rx_fifo_ocy[4:0]               )  //O
    );


i2c_dynamic_ctrl u_i2c_dynamic_ctrl(/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .cr_en                  (cr_en                          ), //I
        .cr_msms                (cr_msms                        ), //I
        .dyna_msms_set          (dyna_msms_set                  ), //O
        .dyna_msms_clr          (dyna_msms_clr                  ), //O
        .dyna_txak_set          (dyna_txak_set                  ), //O
        .dyna_txak_clr          (dyna_txak_clr                  ), //O
        .dyna_tx_set            (dyna_tx_set                    ), //O
        .dyna_tx_clr            (dyna_tx_clr                    ), //O
        .dyna_rsta_set          (dyna_rsta_set                  ), //O
        .tx_fifo_empty          (tx_fifo_empty                  ), //I
        .tx_fifo_rd             (tx_fifo_rd                     ), //I
        .tx_fifo_dout           (tx_fifo_dout[9:0]              ), //I
        .tx_fifo_wr             (tx_fifo_wr                     ), //I
        .tx_fifo_din            (tx_fifo_din[9:0]               ), //I
        .rx_fifo_wr             (rx_fifo_wr                     )  //I
    );


i2c_core_fsm u_i2c_core_fsm(/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .slv_addr               (slv_adr[7:0]                   ), //I
        .cr_msms                (cr_msms                        ), //I
        .cr_msms_clr            (fsm_msms_clr                   ), //O // INST_NEW
        .cr_tx                  (cr_tx                          ), //I
        .cr_gcen                (cr_gcen                        ), //I
        .cr_txak                (cr_txak                        ), //I
        .cr_en                  (cr_en                          ), //I
        .cr_rsta                (cr_rsta                        ), //I
        .cr_rsta_clr            (cr_rsta_clr                    ), //O
        .sr_abgc                (sr_abgc                        ), //O
        .sr_aas                 (sr_aas                         ), //O
        .sr_srw                 (sr_srw                         ), //O
        .irq_nas                (irq_nas                        ), //O
        .irq_tx_err             (irq_tx_err                     ), //O
        .irq_tx_empty           (irq_tx_empty                   ), //O
        .cmd                    (cmd[3:0]                       ), //O
        .cmd_ack                (cmd_ack                        ), //I
        .phy_rx                 (phy_rx                         ), //I
        .phy_tx                 (phy_tx                         ), //O
        .phy_abort              (al                             ), //I
        .rx_fifo_pirq           (rx_fifo_pirq[4:0]              ), //I
        .rx_fifo_pfull          (rx_fifo_pfull                  ), //O
        .rx_fifo_wr             (rx_fifo_wr                     ), //O
        .rx_fifo_din            (rx_fifo_din[7:0]               ), //O
        .rx_fifo_ocy            (rx_fifo_ocy[4:0]               ), //I
        .tx_fifo_empty          (tx_fifo_empty                  ), //I
        .tx_fifo_rd             (tx_fifo_rd                     ), //O
        .tx_fifo_dout           (tx_fifo_dout[9:0]              ), //I
        .tx_fifo_ocy            (tx_fifo_ocy[4:0]               ), //I
        .scl_gauge_en           (scl_gauge_en                   ), //O
        .msms                   (msms                           ), //O
        .rcv_rsta               (rsta_det                       ), //I
        .rcv_sta                (sta_det                        ), //I
        .rcv_sto                (sto_det                        )  //I
    );

i2c_phy u_i2c_phy(/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .ena                    (cr_en                          ), //I
        .cmd                    (cmd[3:0]                       ), //I
        .cmd_ack                (cmd_ack                        ), //O
        .al                     (al                             ), //O
        .rsta_det               (rsta_det                       ), //O // INST_NEW
        .din                    (phy_tx                         ), //I
        .dout                   (phy_rx                         ), //O
        .debounce_cnt           (debounce_cnt[13:0]             ), //I
        .tsusta                 (tsusta[31:0]                   ), //I
        .thdsta                 (thdsta[31:0]                   ), //I
        .tsusto                 (tsusto[31:0]                   ), //I
        .tsudat                 (tsudat[31:0]                   ), //I
        .thddat                 (thddat[31:0]                   ), //I
        .tlow                   (tlow[31:0]                     ), //I
        .thigh                  (thigh[31:0]                    ), //I
        .tbuf                   (tbuf[31:0]                     ), //I
        .cr_msms                (msms                           ), //I
        .sta_det                (sta_det                        ), //O
        .sto_det                (sto_det                        ), //O
        .busy                   (busy                           ), //O
        .scl_rising             (scl_rising                     ), //O
        .scl_faling             (scl_faling                     ), //O
        .scl_gauge_en           (scl_gauge_en                   ), //I
        .scl                    (scl                            ), //IO
        .sda                    (sda                            )  //IO
    );


endmodule
//Local Variables:
//verilog-library-directories (".")
//verilog-library-directories-recursive:0
//End: 
