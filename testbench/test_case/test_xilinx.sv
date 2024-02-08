class test_xilinx extends test_base;


    function new(virtual apb apb, virtual axi_lite axi []);
        super.new(apb, axi);
    endfunction

    task run();
        $display("[TEST_XILINX] ---Test Init begins to run -----");
        apb.init();
        axi[0].init();
        axi[1].init();
        wait(apb.rstn);
        fork
            run_slave();
            run_master();
        join
        $display("[TEST_XILINX] --- Test completed! -----");
    endtask

    task run_slave();
        int tmp;
        $display("[TEST_XILINX] --- slave run -----");
        axi[1].wr(`I2C_SOFTR_ADDR, 32'ha); // reset
        enb(2);
        axi[1].wr(`I2C_ADR_ADDR, {7'h01, 1'b0}); // adr,read
        globa_interrupt_en(2);
        axi[1].wr(`I2C_RX_FIFO_PIRQ_ADDR, 15); // rx fifo pirq
        axi[1].wr(`I2C_IER_ADDR, 8'hff);
        // wait aas
        tmp = 32'h0000;
        do begin
            axi[1].rd(`I2C_ISR_ADDR, tmp, 0);
        end while(!tmp[5]);
        $display("[TEST_XILINX] --- slave intrrupt -----");
        axi[1].wr(`I2C_CR_ADDR, 8'h11); // cr.en
    endtask

    task run_master();
        int tmp;
        $display("[TEST_XILINX] --- configure master -----");
        axi[0].wr(`I2C_SOFTR_ADDR, 32'ha);
        globa_interrupt_en(1);
        axi[0].wr(`I2C_IER_ADDR, 8'hff); 
        enb(1);
        axi[0].wr(`I2C_TX_FIFO_ADDR, {7'h1, 1'b0});
        axi[0].wr(`I2C_TX_FIFO_ADDR, {8'h5a});
        axi[0].wr(`I2C_CR_ADDR, 8'h0d);
        tmp = 32'h0000;
        do begin
            axi[0].rd(`I2C_ISR_ADDR, tmp, 1);
        end while(!tmp[2]);
        $display("[TEST_XILINX] --- master intrrupt -----");
        axi[0].wr(`I2C_CR_ADDR, 8'h2d);
        axi[0].wr(`I2C_TX_FIFO_ADDR, {8'ha5});

        do begin
            axi[0].rd(`I2C_ISR_ADDR, tmp, 0);
        end while(1);

    endtask


endclass
