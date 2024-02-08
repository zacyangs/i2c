class test_slv extends test_base;

    int tmp;

    function new(virtual apb apb, virtual axi_lite axi[]);
        super.new(apb, axi);
    endfunction

    task run();
        $display("[TEST_SLV] ---Test Init begins to run -----");
        apb.init();
        axi[0].init();
        wait(apb.rstn);
        //run_rcv_test();
        run_xmit_test();
        $display("[TEST_SLV] --- run completed! -----");
    endtask


    task run_rcv_test();
        apb.wr(`I2C_CR_ADDR, 8'h41);
        apb.wr(`I2C_ADR_ADDR, {7'h01, 1'b0});

        $display("[TEST_SLV] --- configure GOLDEN model -----");
        reset(1);
        globa_interrupt_en(1);
        axi[0].wr(`I2C_ADR_ADDR, {7'h01, 1'b0});
        axi[0].wr(`I2C_CR_ADDR, 8'h01);
        axi[0].wr(32'h108, {2'b01, 7'h1, 1'b0});
        axi[0].wr(32'h108, {2'b10, 8'h5a});
        axi[0].rd(32'h144, tmp, 1);
        axi[0].wr(32'h144, 20);
        axi[0].wr(32'h028, 8'h06);
    endtask

    task run_xmit_test();
        apb.wr(`I2C_CR_ADDR, 8'h41);
        apb.wr(`I2C_ADR_ADDR, {7'h01, 1'b0});
        apb.wr(32'h108, {2'b10, 8'h5a});

        reset(1);
        globa_interrupt_en(1);
        axi[0].wr(`I2C_ADR_ADDR, {7'h01, 1'b0});
        axi[0].wr(32'h120, 15);
        axi[0].wr(`I2C_CR_ADDR, 8'h01);
        axi[0].wr(32'h108, {2'b01, 7'h1, 1'b1});
        axi[0].wr(32'h108, {2'b10, 8'h1});
        axi[0].rd(32'h144, tmp, 1);
        axi[0].wr(32'h144, 20);

        tmp = 32'hffff;
        do begin
            axi[0].rd(32'h104, tmp, 1);
        end while(tmp[6]);
        axi[0].rd(32'h10c, tmp, 1);
    endtask

endclass
