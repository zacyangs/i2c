class test_mst extends test_base;

    int tmp;

    function new(virtual apb apb, virtual axi_lite axi[], virtual interrupt irq);
        super.new(apb, axi, irq);
    endfunction

    task run();
        $display("[TEST_MST] ---Test Init begins to run -----");
        apb.init();
        axi[0].init();
        wait(apb.rstn);
        fork
            run_golden_rx();
            begin
                run_tx_standard();
                repeat(200)@(posedge apb.clk);
                run_tx_dynamic();
                repeat(200)@(posedge apb.clk);
                run_tx_dynamic_rsta();
                repeat(200)@(posedge apb.clk);
                run_tx_rsta();
                //run_xmit_test();
                $display("[TEST_MST] --- run completed! -----");
            end
        join
    endtask

    task run_golden_rx();
        $display("[TEST_MST] --- golden rx running -----");
        reset(1);
        axi[0].wr(`I2C_CR_ADDR, 8'h41);
        axi[0].wr(`I2C_ADR_ADDR, {7'h01, 1'b0});
        // enable aas interrupt
        axi[0].wr(`I2C_IER_ADDR, 32'h20);
        axi[0].wr(`I2C_RX_FIFO_PIRQ_ADDR, 32'hff);
        globa_interrupt_en(1);
        $display("[TEST_MST] --- GOLDEN model receive enabled -----");

        while(1) begin
            wait(irq.irq_gold);
            // clear all interrupts
            axi[0].wr(`I2C_ISR_ADDR, 32'hff);
            // enable nas interrupt
            axi[0].wr(`I2C_IER_ADDR, 32'h40);
            wait(irq.irq_gold);
            read_fifo(1);
        end
    endtask

    task run_tx_dynamic();
        $display("[TEST_MST] test begin in dynamic mode ");
        globa_interrupt_en(0);
        reset(0);
        apb.wr(`I2C_ADR_ADDR, {7'h01, 1'b0});
        apb.wr(`I2C_CR_ADDR, 8'h1);
        apb.wr(32'h108, {2'b01, 7'h1, 1'b0});
        apb.wr(32'h108, {2'b00, 8'h5a});
        apb.wr(32'h108, {2'b10, 8'ha5});
        $display("[TEST_MST] test end in dynamic mode ");
    endtask

    task run_tx_standard();
        $display("[TEST_MST] test begin in standard mode ");
        globa_interrupt_en(0);
        reset(0);
        apb.wr(`I2C_ADR_ADDR, {7'h01, 1'b0});
        apb.wr(32'h108, {2'b00, 7'h1, 1'b0});
        apb.wr(32'h108, {2'b00, 8'h5a});
        // clear tx fifo empty interrupt
        apb.wr(`I2C_ISR_ADDR, 4);
        apb.wr(`I2C_CR_ADDR, 8'hd);
        // wait tx fifo empty interrupt
        irq_poll(0, 2);
        apb.wr(`I2C_CR_ADDR, 8'h9);
        apb.wr(`I2C_TX_FIFO_ADDR, {2'b00, 8'ha5});
        // clear tx fifo empty interrupt
        apb.wr(`I2C_ISR_ADDR, 'hffff);
        irq_poll(0, 4);
        apb.wr(`I2C_ISR_ADDR, 'hffff);
        $display("[TEST_MST] test finish in standard mode ");
    endtask


    task run_tx_dynamic_rsta();
        globa_interrupt_en(0);
        reset(0);
        apb.wr(`I2C_ADR_ADDR, {7'h01, 1'b0});
        apb.wr(`I2C_CR_ADDR, 8'h1);
        apb.wr(32'h108, {2'b01, 7'h1, 1'b0});
        apb.wr(32'h108, {2'b00, 8'h5a});
        apb.wr(32'h108, {2'b01, 7'h1, 1'b0});
        apb.wr(32'h108, {2'b10, 8'ha5});
    endtask

    task run_tx_rsta();
        globa_interrupt_en(0);
        reset(0);
        apb.wr(`I2C_ADR_ADDR, {7'h01, 1'b0});
        apb.wr(32'h108, {2'b00, 7'h1, 1'b0});
        apb.wr(32'h108, {2'b00, 8'h5a});
        // clear tx fifo empty interrupt
        apb.wr(`I2C_ISR_ADDR, 4);
        apb.wr(`I2C_CR_ADDR, 8'hd);
        // wait tx fifo empty interrupt
        irq_poll(0, 2);
        apb.wr(`I2C_CR_ADDR, 8'h2d);
        apb.wr(`I2C_TX_FIFO_ADDR, {2'b00, 7'h1, 1'b0});
        // clear tx fifo empty interrupt
        apb.wr(`I2C_ISR_ADDR, 'hffff);
        irq_poll(0, 2);
        apb.wr(`I2C_CR_ADDR, 8'h09);
        apb.wr(`I2C_TX_FIFO_ADDR, {2'b00, 8'ha5});
        apb.wr(`I2C_ISR_ADDR, 'hffff);
        irq_poll(0, 4);
        apb.wr(`I2C_ISR_ADDR, 'hffff);
        axi[0].wr(`I2C_CR_ADDR, 8'h00);
        axi[0].wr(`I2C_ISR_ADDR, 'hffff);

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
        axi[0].wr(32'h108, {2'b00, 8'h5a});
        axi[0].wr(32'h108, {2'b10, 8'h2});
        axi[0].rd(32'h144, tmp, 1);
        axi[0].wr(32'h144, 20);

        tmp = 32'hffff;
        do begin
            axi[0].rd(32'h104, tmp, 1);
        end while(tmp[6]);
        axi[0].rd(32'h10c, tmp, 1);
    endtask

endclass
