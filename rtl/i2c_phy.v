module i2c_phy(
    input               clk,
    input               rstn,

    input               ena,
    input      [ 3:0]   cmd,
    output              cmd_ack,
    output              al,
    output              rsta_det,

    input               din,
    output              dout,

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

    output              sta_det,
    output              sto_det,
    output              busy,
    output              scl_rising,
    output              scl_faling,
    input               scl_gauge_en,

    inout               scl,
    inout               sda
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
    //wire                        scl_gauge_en                    ; // WIRE_NEW
    wire [31:0]                 thigh_gauge                     ;
    wire [31:0]                 tlow_gauge                      ;
    wire                        scl_o                           ;
    wire                        scl_i                           ;
    wire                        sda_o                           ;
    wire                        sda_i                           ;
    wire [31:0]                 tlow_mux                        ;
    wire [31:0]                 thigh_mux                       ;
    //End of automatic wire
    //End of automatic define

assign tlow_mux  = cr_msms ? tlow  : tlow_gauge;
assign thigh_mux = cr_msms ? thigh : thigh_gauge;
//assign scl_gauge_en = !cr_msms;


i2c_debounce u_i2c_phy_debounce(/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .scl                    (scl                            ), //IO
        .sda                    (sda                            ), //IO
        .debounce_cnt           (debounce_cnt[13:0]             ), //I // INST_NEW
        .sta_det                (sta_det                        ), //O
        .sto_det                (sto_det                        ), //O
        .busy                   (busy                           ), //O
        .scl_rising             (scl_rising                     ), //O
        .scl_faling             (scl_faling                     ), //O
        .scl_gauge_en           (scl_gauge_en                   ), //I // INST_NEW
        .thigh                  (thigh_gauge[31:0]              ), //O // INST_NEW
        .tlow                   (tlow_gauge[31:0]               ), //O // INST_NEW
        .scl_o                  (scl_o                          ), //I
        .scl_i                  (scl_i                          ), //O
        .sda_o                  (sda_o                          ), //I
        .sda_i                  (sda_i                          )  //O
    );

i2c_mst_ctrl_bit u_i2c_phy_bit_ctrl(/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .ena                    (ena                            ), //I
        .msms                   (cr_msms                        ), //I
        .cmd                    (cmd[3:0]                       ), //I
        .cmd_ack                (cmd_ack                        ), //O
        .al                     (al                             ), //O
        .rsta_det               (rsta_det                       ), //O // INST_NEW
        .din                    (din                            ), //I
        .dout                   (dout                           ), //O
        .tsusta                 (tsusta[31:0]                   ), //I
        .thdsta                 (thdsta[31:0]                   ), //I
        .tsusto                 (tsusto[31:0]                   ), //I
        .tsudat                 (tsudat[31:0]                   ), //I
        .thddat                 (thddat[31:0]                   ), //I
        .tlow                   (tlow_mux[31:0]                 ), //I
        .thigh                  (thigh_mux[31:0]                ), //I
        .tbuf                   (tbuf[31:0]                     ), //I
        .sto_det                (sto_det                        ), //I
        .sta_det                (sta_det                        ), //I
        .scl_rising             (scl_rising                     ), //I
        .scl_falling            (scl_faling                     ), //I
        .scl_i                  (scl_i                          ), //I
        .sda_i                  (sda_i                          ), //I
        .scl_o                  (scl_o                          ), //O
        .sda_o                  (sda_o                          )  //O
    );


endmodule
//Local Variables:
//verilog-library-directories (".")
//verilog-library-directories-recursive:0
//End:
