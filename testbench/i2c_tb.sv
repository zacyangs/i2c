module i2c_tb;
import pkg::*;

wire sda_i ;
wire sda_o ;
wire sda_t ;
wire scl_i ;
wire scl_o ;
wire scl_t ;
logic clk = 0;
logic rstn = 0;
apb apb(clk, rstn);
axi_lite axi(clk);
env env_h;

initial begin
    #100 rstn = 1;
end

always #5 clk = ~clk;

i2c_top DUT (
    .clk       (clk),
    .rstn      (rstn),

    .apb_sel                (apb.psel                        ), //input
    .apb_en                 (apb.pen                         ), //input
    .apb_write              (apb.pwrite                      ), //input
    .apb_ready              (apb.pready                      ), //output
    .apb_addr               (apb.paddr[31:0]                 ), //input
    .apb_wdata              (apb.pwdata[31:0]                ), //input
    .apb_rdata              (apb.prdata[31:0]                ), //output

    .i2c_irq   (),

    .i2c_scl   (i2c_scl),
    .i2c_sda   (i2c_sda)
);

axi_iic_0 u0_axi_iic_0 (
    .s_axi_aclk    (clk),
    .s_axi_aresetn (rstn),
    .iic2intc_irpt (irq_req),
    .s_axi_awaddr  (axi.awaddr ),
    .s_axi_awvalid (axi.awvalid),
    .s_axi_awready (axi.awready),
    .s_axi_wdata   (axi.wdata  ),
    .s_axi_wstrb   (axi.wstrb  ),
    .s_axi_wvalid  (axi.wvalid ),
    .s_axi_wready  (axi.wready ),
    .s_axi_bresp   (axi.bresp  ),
    .s_axi_bvalid  (axi.bvalid ),
    .s_axi_bready  (axi.bready ),
    .s_axi_araddr  (axi.araddr ),
    .s_axi_arvalid (axi.arvalid),
    .s_axi_arready (axi.arready),
    .s_axi_rdata   (axi.rdata  ),
    .s_axi_rresp   (axi.rresp  ),
    .s_axi_rvalid  (axi.rvalid ),
    .s_axi_rready  (axi.rready ),
    .sda_i         (sda_i),
    .sda_o         (sda_o),
    .sda_t         (sda_t),
    .scl_i         (scl_i),
    .scl_o         (scl_o),
    .scl_t         (scl_t),
    .gpo           ()
);

   IOBUF IOBUF_inst (
      .O  ( scl_i),     // Buffer output
      .IO ( i2c_scl),   // Buffer inout port                             ( connect directly to top-level port)
      .I  ( scl_o),     // Buffer input
      .T  ( scl_t)      // 3-state enable input, high=input, low=output
   );

   IOBUF IOBUF_inst1 (
      .O  ( sda_i),     // Buffer output
      .IO ( i2c_sda),   // Buffer inout port                             ( connect directly to top-level port)
      .I  ( sda_o),     // Buffer input
      .T  ( sda_t)      // 3-state enable input, high=input, low=output
   );

pullup p1(i2c_scl);
pullup p2(i2c_sda);



initial begin
    env_h = new(apb, axi);
    env_h.run();
end



endmodule
