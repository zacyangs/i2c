class test_reg extends test_base;

    int tmp;

    function new(virtual apb apb, virtual axi_lite axi[], virtual interrupt irq);
        super.new(apb, axi, irq);
    endfunction

    task run();
        $display("[TEST_REG] --- begins to run -----");
        apb.wr(32'h01c, 1);
        apb.wr(32'h020, 8'hff);
        apb.wr(32'h028, 8'hff);
        apb.wr(32'h040, 8'h0a);
        apb.wr(32'h100, 8'hf);
        apb.wr(32'h108, 10'h3ff);
        apb.wr(32'h110, 8'hff);
        apb.wr(32'h11c, 2'b11);
        apb.wr(32'h120, 15);

        apb.rd(32'h01c, tmp, 1);
        apb.rd(32'h020, tmp, 1);
        apb.rd(32'h028, tmp, 1);
        apb.rd(32'h100, tmp, 1);
        apb.rd(32'h104, tmp, 1);
        apb.rd(32'h108, tmp, 1);
        apb.rd(32'h10c, tmp, 1);
        apb.rd(32'h110, tmp, 1);
        apb.rd(32'h114, tmp, 1);
        apb.rd(32'h118, tmp, 1);
        apb.rd(32'h11c, tmp, 1);
        apb.rd(32'h120, tmp, 1);
        $display("[TEST_REG] --- run completed! -----");
    endtask

endclass
