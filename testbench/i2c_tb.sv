module i2c_tb;
import pkg::*;

wire sda_i ;
wire sda_o ;
wire sda_t ;
wire scl_i ;
wire scl_o ;
wire scl_t ;

wire sda0_i ;
wire sda0_o ;
wire sda0_t ;
wire scl0_i ;
wire scl0_o ;
wire scl0_t ;
wire   irq_golden;
wire   irq_dut;


logic clk = 0;
logic rstn = 0;
apb apb(clk, rstn);
interrupt irq(clk);
axi_lite axi0(clk), axi1(clk);
virtual axi_lite  axi[];
env env_h;

initial begin
    #100 rstn = 1;
end

always #5 clk = ~clk;


`ifdef USE_DUT

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

    .i2c_irq   (irq.irq_dut),

    .i2c_scl   (i2c_scl),
    .i2c_sda   (i2c_sda)
);

`else  

axi_iic_0 u0_axi_iic_1 (
    .s_axi_aclk    (clk),
    .s_axi_aresetn (rstn),
    .iic2intc_irpt (),
    .s_axi_awaddr  (axi1.awaddr ),
    .s_axi_awvalid (axi1.awvalid),
    .s_axi_awready (axi1.awready),
    .s_axi_wdata   (axi1.wdata  ),
    .s_axi_wstrb   (axi1.wstrb  ),
    .s_axi_wvalid  (axi1.wvalid ),
    .s_axi_wready  (axi1.wready ),
    .s_axi_bresp   (axi1.bresp  ),
    .s_axi_bvalid  (axi1.bvalid ),
    .s_axi_bready  (axi1.bready ),
    .s_axi_araddr  (axi1.araddr ),
    .s_axi_arvalid (axi1.arvalid),
    .s_axi_arready (axi1.arready),
    .s_axi_rdata   (axi1.rdata  ),
    .s_axi_rresp   (axi1.rresp  ),
    .s_axi_rvalid  (axi1.rvalid ),
    .s_axi_rready  (axi1.rready ),
    .sda_i         (sda0_i),
    .sda_o         (sda0_o),
    .sda_t         (sda0_t),
    .scl_i         (scl0_i),
    .scl_o         (scl0_o),
    .scl_t         (scl0_t),
    .gpo           ()
);
   IOBUF IOBUF_inst2 (
      .O  ( scl0_i),     // Buffer output
      .IO ( i2c_scl),   // Buffer inout port                             ( connect directly to top-level port)
      .I  ( scl0_o),     // Buffer input
      .T  ( scl0_t)      // 3-state enable input, high=input, low=output
   );

   IOBUF IOBUF_inst3 (
      .O  ( sda0_i),     // Buffer output
      .IO ( i2c_sda),   // Buffer inout port                             ( connect directly to top-level port)
      .I  ( sda0_o),     // Buffer input
      .T  ( sda0_t)      // 3-state enable input, high=input, low=output
   );


`endif

axi_iic_0 u0_axi_iic_0 (
    .s_axi_aclk    (clk),
    .s_axi_aresetn (rstn),
    .iic2intc_irpt (irq.irq_gold),
    .s_axi_awaddr  (axi0.awaddr ),
    .s_axi_awvalid (axi0.awvalid),
    .s_axi_awready (axi0.awready),
    .s_axi_wdata   (axi0.wdata  ),
    .s_axi_wstrb   (axi0.wstrb  ),
    .s_axi_wvalid  (axi0.wvalid ),
    .s_axi_wready  (axi0.wready ),
    .s_axi_bresp   (axi0.bresp  ),
    .s_axi_bvalid  (axi0.bvalid ),
    .s_axi_bready  (axi0.bready ),
    .s_axi_araddr  (axi0.araddr ),
    .s_axi_arvalid (axi0.arvalid),
    .s_axi_arready (axi0.arready),
    .s_axi_rdata   (axi0.rdata  ),
    .s_axi_rresp   (axi0.rresp  ),
    .s_axi_rvalid  (axi0.rvalid ),
    .s_axi_rready  (axi0.rready ),
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
    axi = new[2];
    axi[0] = axi0;
    axi[1] = axi1;
    env_h = new(apb, axi, irq);
    env_h.run();
end



endmodule
