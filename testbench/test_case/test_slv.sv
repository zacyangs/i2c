class test_slv extends test_base;

    int tmp;
    bit [6:0] adr;
    bit [7:0] txq [$], rxq [$];
    bit [7:0] tx, rx, gold;

    function new(virtual apb apb, virtual axi_lite axi[], virtual interrupt irq);
        super.new(apb, axi, irq);
        adr = $urandom_range(0,127);
    endfunction

    task run();
        bit[7:0] dat [$];
        $display("[TEST_SLV] ---Test begins to run -----");
        apb.init();
        axi[0].init();
        wait(apb.rstn);
        $display("[TEST_SLV] reset released !");
        fork
            run_golden(dat, $urandom_range(0,255), 1);
            run_dut();
        join
        repeat(200)@(posedge apb.clk);
        fork
            run_golden(dat, $urandom_range(0,255), 0);
            run_dut();
        join
        $display("[TEST_SLV] --- run completed! -----");
    endtask

    task run_golden(ref bit [7:0] dat [$], input [7:0] len, input rw);
        int rcnt = len+1;
        int tcnt = len;
        axi[0].wr(`I2C_CR_ADDR, 1);
        reset(1);
        globa_interrupt_en(1);
        $display("[TEST_SLV] axi write cr == 1");
        if(rw) begin
            $display("[TEST_SLV] receiving of %0d bytes begin", len);
            axi[0].wr(`I2C_RX_FIFO_PIRQ_ADDR, 32'd15);
            axi[0].wr(`I2C_TX_FIFO_ADDR, {2'b01, adr, 1'b1});
            axi[0].wr(`I2C_TX_FIFO_ADDR, {2'b00, len});
            axi[0].wr(`I2C_IER_ADDR, 32'h08);
            while(rcnt > 0) begin
                wait(irq.irq_gold);
                axi[0].rd(`I2C_RX_FIFO_OCY_ADDR, rx_fifo_ocy);
                repeat(rx_fifo_ocy.fields.occupacy_value+1) begin
                    axi[0].rd(`I2C_RX_FIFO_ADDR, rx);
                    //if(rcnt != len)begin
                        gold = txq.pop_front();
                        $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, rx);
                        assert(rx == gold)
                        else 
                        $display("[TEST_MST][RX][ERROR] data compare: gold[%02h], dut[%02h]", gold, rx);
                    //end
                    rcnt--;
                end
                if(rcnt < 15)
                    axi[0].wr(`I2C_IER_ADDR, 32'h18);
                axi[0].wr(`I2C_ISR_ADDR, 255);
                $display("[TEST_SLV] receive of %d bytes", rcnt);
            end
            $display("[TEST_SLV] receive of %0d bytes end", len);
        end
        else begin
            $display("[TEST_SLV] transmit of %0d bytes begin", len);
            axi[0].wr(`I2C_TX_FIFO_ADDR, {2'b01, adr, 1'b0});
            axi[0].wr(`I2C_IER_ADDR, 32'h4);
            while(tcnt > 0) begin
                wait(irq.irq_gold);
                if(tcnt > 15) begin
                    repeat(15) begin
                        tx = $urandom_range(0,255);
                        rxq.push_back(tx);
                        axi[0].wr(`I2C_TX_FIFO_ADDR, tx);
                    end
                end
                else begin
                    repeat(tcnt-1) begin
                        tx = $urandom_range(0,255);
                        rxq.push_back(tx);
                        axi[0].wr(`I2C_TX_FIFO_ADDR, tx);
                    end
                    tx = $urandom_range(0,255);
                    rxq.push_back(tx);
                    axi[0].wr(`I2C_TX_FIFO_ADDR, {2'b10, tx});
                end
                axi[0].rd(`I2C_SR_ADDR, sr);
                axi[0].wr(`I2C_ISR_ADDR, 255);
            end
        end
    endtask

    task run_dut();
        $display("[TEST_SLV] --- DUT run -----");
        reset(0);
        globa_interrupt_en(1);
        globa_interrupt_en(0);
        cr = 0;
        cr.fields.EN = 1;
        cr.fields.GCEN = 1;
        apb.wr(`I2C_CR_ADDR, cr);
        apb.wr(`I2C_ADR_ADDR, {adr, 1'b0});
        apb.wr(`I2C_ISR_ADDR, 32'hffff);
        apb.wr(`I2C_IER_ADDR, 'h20);
        wait(irq.irq_dut);
        apb.rd(`I2C_ISR_ADDR, isr);
        apb.rd(`I2C_SR_ADDR,sr);
        if(sr.fields.SRW) begin
            while(!isr.fields.int1) begin
                wait(irq.irq_dut);
                apb.rd(`I2C_ISR_ADDR, isr);
                repeat(16) begin
                    tx = $urandom_range(0,255);
                    txq.push_back(tx);
                    apb.wr(`I2C_TX_FIFO_ADDR, tx);
                end
                apb.wr(`I2C_IER_ADDR, 'h6);
                apb.wr(`I2C_ISR_ADDR, 255);
            end
        end
        else begin
            apb.wr(`I2C_RX_FIFO_PIRQ_ADDR, 32'd15);
            while(!isr.fields.int1) begin
                wait(irq.irq_dut);
                apb.rd(`I2C_RX_FIFO_OCY_ADDR, rx_fifo_ocy);
                repeat(rx_fifo_ocy.fields.occupacy_value) begin
                    apb.rd(`I2C_RX_FIFO_ADDR, rx);
                        gold = rxq.pop_front();
                        $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, rx);
                        assert(rx == gold)
                        else 
                        $display("[TEST_MST][RX][ERROR] data compare: gold[%02h], dut[%02h]", gold, rx);
                end
                apb.rd(`I2C_ISR_ADDR, isr);
                apb.wr(`I2C_IER_ADDR, 'ha);
                apb.wr(`I2C_ISR_ADDR, 255);
            end
        end
        $display("[TEST_SLV] --- DUT end -----");
    endtask

endclass
