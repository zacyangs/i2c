interface axi_lite(input clk, input rstn);

    logic awready;
    logic awvalid;
    logic [31:0] awaddr;

    logic wvalid;
    logic wready;
    logic [3:0]  wstrb;
    logic [31:0] wdata; 

    logic arready;
    logic arvalid;
    logic [31:0] araddr;
    logic rready;
    logic rvalid;
    logic [31:0] rdata;
    logic [1:0] rresp;

    logic bready;
    logic bvalid;
    logic [1:0] bresp;


    task init();
        awvalid = 0;
        awaddr  = 0;
        wvalid  = 0;
        wdata   = 0;
        wstrb   = 4'hf;
        bready  = 1;
        arvalid = 0;
        araddr  = 0;
        rready  = 1;
    endtask

    task wr(input [31:0] addr, dat);
        @(posedge clk)
        awvalid <= 1'b1;
        awaddr  <= addr;
        wvalid  <= 1'b1;
        wdata   <= dat;

        fork
            wait(awready) @(posedge clk) awvalid <= 1'b0;
            wait(wready)  @(posedge clk) wvalid  <= 1'b0;
        join
        repeat(4) @(posedge clk);
    endtask

    task rd(input [31:0] addr, output logic [31:0] dat, input logic print = 0);
        @(posedge clk)
        arvalid <= 1'b1;
        araddr  <= addr;
        wait(arready) @(posedge clk) arvalid <= 1'b0;
        
        do begin @(posedge clk); end
        while(!(rvalid & rready)) ;
        dat <= rdata;
        
        @(posedge clk);
        if(print) $display("[AXI-LITE] data read @%08h -> %08h", addr, dat);
    endtask

endinterface
