interface apb(input clk, input rstn);

logic           psel;
logic           pen;
logic           pwrite;
logic           pready;
logic [31:0]    pwdata;
logic [31:0]    prdata;
logic [31:0]    paddr;

task init();
    psel = 0;
    pen  = 0;
    pwrite = 0;
    pwdata = 0;
    paddr  = 0;
endtask

task wr(input [31:0] addr, data, print = 0);
    psel = 0;
    pen = 0;
    pwrite = 0;
    pwdata = 0;

    @(posedge clk) begin
        psel = 1;
        pwrite = 1;
        pwdata = data;
        paddr  = addr;
    end

    @(posedge clk)
        pen = 1;

    wait(pready);
    if(print) $display("[APB][WRITE] Addr:%08h, data:%08h", addr, data);
    @(posedge clk)
        pen = 0;
        psel = 0;

    repeat(2)@(posedge clk);
endtask

task rd(input [31:0] addr, output [31:0] data, input print = 0);
    psel = 0;
    pen = 0;
    pwrite = 0;

    @(posedge clk)
        psel = 1;
        paddr = addr;

    @(posedge clk)
        pen = 1;

    wait(pready);
    @(posedge clk)
        psel = 0;
        pen = 0;

    if(print) $display("[APB][READ] Addr:%08h, data:%08h", addr, prdata);
    data = prdata;
endtask

endinterface
