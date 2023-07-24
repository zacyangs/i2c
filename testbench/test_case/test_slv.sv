class test_slv extends test_base;

    int tmp;

    function new(virtual apb apb, virtual axi_lite axi);
        super.new(apb, axi);
    endfunction

    task run();
        $display("[TEST_SLV] ---Test Init begins to run -----");
        apb.init();
        axi.init();
        wait(apb.rstn);
        //run_rcv_test();
        run_xmit_test();
        $display("[TEST_SLV] --- run completed! -----");
    endtask


    task run_rcv_test();
        apb.wr(32'h100, 8'h41);
        apb.wr(32'h110, {7'h01, 1'b0});

        $display("[TEST_SLV] --- configure GOLDEN model -----");
        axi.wr(32'h040, 32'ha);
        axi.wr(32'h01c, 32'h8000_0000);
        axi.wr(32'h110, {7'h01, 1'b0});
        axi.wr(32'h100, 8'h01);
        axi.wr(32'h108, {2'b01, 7'h1, 1'b0});
        axi.wr(32'h108, {2'b10, 8'h5a});
        axi.rd(32'h144, tmp, 1);
        axi.wr(32'h144, 20);
        axi.wr(32'h028, 8'h06);
    endtask

    task run_xmit_test();
        apb.wr(32'h100, 8'h41);
        apb.wr(32'h110, {7'h01, 1'b0});
        apb.wr(32'h108, {2'b10, 8'h5a});

        axi.wr(32'h040, 32'ha);
        axi.wr(32'h01c, 32'h8000_0000);
        axi.wr(32'h110, {7'h01, 1'b0});
        axi.wr(32'h120, 15);
        axi.wr(32'h100, 8'h01);
        axi.wr(32'h108, {2'b01, 7'h1, 1'b1});
        axi.wr(32'h108, {2'b10, 8'h1});
        axi.rd(32'h144, tmp, 1);
        axi.wr(32'h144, 20);

        tmp = 32'hffff;
        do begin
            axi.rd(32'h104, tmp, 1);
        end while(tmp[6]);
        axi.rd(32'h10c, tmp, 1);
    endtask

endclass
