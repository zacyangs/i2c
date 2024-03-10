class test_mst extends test_base;

    int tmp;
    bit [7:0] adr;
    bit [7:0] txq [$], rxq [$];

    function new(virtual apb apb, virtual axi_lite axi[], virtual interrupt irq);
        super.new(apb, axi, irq);
        adr = 7'h5a;
    endfunction

    task run();
        bit[7:0] dat [$];
        bit [6:0] len;
        bit [7:0] gold, dut, tmp;
        $display("[TEST_MST] ---Test Init begins to run -----");
        apb.init();
        axi[0].init();
        wait(apb.rstn);
        globa_interrupt_en(0);
        reset(0);

        $display("[TEST_MST][MASTER_TRANSMITTER] test begins -----");
        fork
            run_golden(1);
            begin
                repeat(2000)@(posedge apb.clk);
                `I2C_REG_WR(1, `I2C_IER_ADDR, 32'h08);
                `I2C_REG_WR(1, `I2C_ISR_ADDR, 255);
                for(int i = 0; i < $urandom_range(0,100);i++) begin
                    tmp = $urandom_range(0,255);
                    dat.push_back(tmp);
                    rxq.push_back(tmp);
                end
                run_tx_standard(adr, dat, 0);
                repeat(2000)@(posedge apb.clk);
                for(int i = 0; i < $urandom_range(0,100);i++) begin
                    tmp = $urandom_range(0,255);
                    dat.push_back(tmp);
                    rxq.push_back(tmp);
                end
                run_tx_standard(adr, dat, 1);
                repeat(2000)@(posedge apb.clk);
                for(int i = 0; i < $urandom_range(0,100);i++) begin
                    tmp = $urandom_range(0,255);
                    dat.push_back(tmp);
                    rxq.push_back(tmp);
                end
                run_tx_dynamic(0, adr, dat, 0);
                repeat(2000)@(posedge apb.clk);
                for(int i = 0; i < $urandom_range(0,100);i++) begin
                    tmp = $urandom_range(0,255);
                    dat.push_back(tmp);
                    rxq.push_back(tmp);
                end
                run_tx_dynamic(0, adr, dat, 1);

                `I2C_REG_WR(1, `I2C_ISR_ADDR, 255);
                `I2C_REG_WR(1, `I2C_IER_ADDR, 32'h04);
                repeat(2000)@(posedge apb.clk);
                len = $urandom_range(5, 100);
                run_receiver_standard(adr, len, dat, 0);
                while(dat.size) begin
                    gold = txq.pop_front();
                    dut  = dat.pop_front();
                    $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, dut);
                    assert(gold == dut)
                    else    $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, dut);
                end

                repeat(2000)@(posedge apb.clk);
                len = $urandom_range(5, 100);
                run_receiver_standard(adr, len, dat, 1);
                while(dat.size) begin
                    gold = txq.pop_front();
                    dut  = dat.pop_front();
                    $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, dut);
                    assert(gold == dut)
                    else    $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, dut);
                end
                repeat(2000)@(posedge apb.clk);
                len = $urandom_range(5, 100);
                run_rx_dynamic(adr, len, dat, 0);
                while(dat.size) begin
                    gold = txq.pop_front();
                    dut  = dat.pop_front();
                    $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, dut);
                    assert(gold == dut)
                    else    $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, dut);
                end

                repeat(2000)@(posedge apb.clk);
                len = $urandom_range(5, 100);
                run_rx_dynamic(adr, len, dat, 1);
                while(dat.size) begin
                    gold = txq.pop_front();
                    dut  = dat.pop_front();
                    $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, dut);
                    assert(gold == dut)
                    else    $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, dut);
                end
                repeat(2000)@(posedge apb.clk);
                $finish();
            end
        join
        $display("[TEST_MST][MASTER_TRANSMITTER] test complete -----");

    endtask

    task run_golden(intf);
        bit [7:0] tx, rx, gold;

        $display("[TEST_MST][SLAVE_RECEIVER] golden model Running -----");
        reset(1);
        globa_interrupt_en(1);
        cr.word = 0;
        cr.fields.EN = 1;
        cr.fields.GCEN = 1;
        `I2C_REG_WR(intf, `I2C_CR_ADDR, cr);
        `I2C_REG_WR(intf, `I2C_ADR_ADDR, {adr, 1'b0});
        // enable aas interrupt
        `I2C_REG_WR(intf, `I2C_RX_FIFO_PIRQ_ADDR, 32'hff);
        axi[0].rd(`I2C_RX_FIFO_OCY_ADDR, rx_fifo_ocy);
        repeat(rx_fifo_ocy.fields.occupacy_value) begin
            axi[0].rd(`I2C_RX_FIFO_ADDR, rx);
        end
        `I2C_REG_RD(intf, `I2C_SR_ADDR, sr);
        if(!sr.fields.RX_FIFO_EMPTY) 
            axi[0].rd(`I2C_RX_FIFO_ADDR, rx);
        $display("[TEST_MST] --- GOLDEN model receive enabled -----");

        forever begin
            if(intf == 1)
                wait(irq.irq_gold);
            else
                wait(irq.irq_dut);
            
            `I2C_REG_RD(intf, `I2C_ISR_ADDR, isr.word)
            `I2C_REG_RD(intf, `I2C_IER_ADDR, ier.word)

            if(isr.fields.int2 && ier.fields.int2) begin // tx empty
                repeat(15) begin
                    tx = $urandom_range(0,255);
                    txq.push_back(tx);
                    `I2C_REG_WR(intf, `I2C_TX_FIFO_ADDR, tx)
                end
            end
            if(isr.fields.int3 && ier.fields.int3) begin
                `I2C_REG_RD(intf, `I2C_SR_ADDR, sr);
                while(!sr.fields.RX_FIFO_EMPTY) begin
                    `I2C_REG_RD(intf, `I2C_RX_FIFO_ADDR, rx);
                    `I2C_REG_RD(intf, `I2C_SR_ADDR, sr);
                    gold = rxq.pop_front();
                    $display("[TEST_MST][RX][INFO] data compare: gold[%02h], dut[%02h]", gold, rx);
                    assert(rx == gold)
                    else 
                    $display("[TEST_MST][RX][ERROR] data compare: gold[%02h], dut[%02h]", gold, rx);
                end
            end
            `I2C_REG_WR(intf, `I2C_ISR_ADDR, 255)
        end
    endtask

    task run_tx_standard(input bit[6:0]addr, ref bit [7:0] dat[$], input bit finish=1);
        int tmp;
        $display("[TEST_MST][STANDARD] transmit of %0d bytes begin", dat.size);
        // sent addr
        apb.rd(`I2C_CR_ADDR, cr.word);
        cr.fields.TX = 1;
        if(cr.fields.MSMS) begin
            cr.fields.RSTA = 1;
            apb.wr(`I2C_CR_ADDR, cr);
            apb.wr(`I2C_TX_FIFO_ADDR, {2'b00, addr, 1'b0});
        end else begin
            cr.fields.EN = 1;
            cr.fields.MSMS = 1;
            apb.wr(`I2C_TX_FIFO_ADDR, {2'b00, addr, 1'b0});
            apb.wr(`I2C_CR_ADDR, cr);
        end
        ier.word = 0;
        ier.word = 0;
        ier.fields.int2 = 1;
        apb.wr(`I2C_ISR_ADDR, 255);
        apb.wr(`I2C_IER_ADDR, ier);
        while(dat.size > finish) begin
            apb.rd(`I2C_TX_FIFO_OCY_ADDR, tx_fifo_ocy.word);
            tmp = 16 - tx_fifo_ocy.fields.occupacy_value; 
            if(dat.size-finish <= tmp) begin
                repeat(dat.size-finish) apb.wr(`I2C_TX_FIFO_ADDR, dat.pop_front());
            end
            else begin
                repeat(tmp) apb.wr(`I2C_TX_FIFO_ADDR, dat.pop_front());
            end
            $display("[TEST_MST][STANDARD] tx remain %0d bytes", dat.size);
            // clear all empty interrupt
            wait(irq.irq_dut);
            apb.wr(`I2C_ISR_ADDR, 255);
        end

        if(finish) begin
            wait(irq.irq_dut);
            ier.fields.int4 = 1;
            ier.fields.int2 = 0;
            apb.rd(`I2C_CR_ADDR, cr.word);
            cr.fields.TXAK = 1;
            cr.fields.MSMS = 0;
            apb.wr(`I2C_CR_ADDR, cr);
            apb.wr(`I2C_TX_FIFO_ADDR, dat.pop_front());
            apb.wr(`I2C_ISR_ADDR, 255);
            apb.wr(`I2C_IER_ADDR, ier);
            wait(irq.irq_dut);
            ier.fields.int4 = 0;
            apb.wr(`I2C_IER_ADDR, ier);
            apb.wr(`I2C_ISR_ADDR, 255);
        end
        $display("[TEST_MST][STANDARD] Transmit complete ");
    endtask

    task run_tx_dynamic(input intf, 
                        input bit[6:0]addr, 
                        ref bit [7:0] dat[$],
                        input bit finish=1);
        $display("[TEST_MST][DYNAMIC] Transimit of %0d bytes begin", dat.size);
        `I2C_REG_WR(intf, `I2C_TX_FIFO_ADDR, {2'b01, addr, 1'b0});
        repeat(dat.size-finish)
            `I2C_REG_WR(intf, `I2C_TX_FIFO_ADDR, {2'b00, dat.pop_front()});

        `I2C_REG_WR(intf, `I2C_ISR_ADDR, 255);
        ier.word = 0;
        if(finish) begin
            `I2C_REG_WR(intf, `I2C_TX_FIFO_ADDR, {2'b10, dat.pop_front()});
            // set BNB interrupt
            ier.fields.int4 = 1;
        end else begin
            ier.fields.int2 = 1;
        end
        `I2C_REG_WR(intf, `I2C_IER_ADDR, ier);
        if(intf == 1)
            wait(irq.irq_gold);
        else
            wait(irq.irq_dut);
        `I2C_REG_WR(intf, `I2C_IER_ADDR, 0);
        `I2C_REG_WR(intf, `I2C_ISR_ADDR, 255);
        $display("[TEST_MST][DYNAMIC] Transmit complete ");
    endtask

    task run_receiver_standard(
        input bit[6:0]addr, len,
        ref bit [7:0] dat[$], 
        input bit finish=1);

        bit [7:0] rx;
        bit [4:0] rx_th;
        int rd_len;
        $display("[TEST_MST][STANDERD] rx of %0d bytes begins ...", len);
        apb.rd(`I2C_CR_ADDR, cr.word);
        cr.fields.TX = 0;
        cr.fields.TXAK = 0;
        if(cr.fields.MSMS) begin
            cr.fields.RSTA = 1;
            apb.wr(`I2C_CR_ADDR, cr);
            apb.wr(`I2C_TX_FIFO_ADDR, {2'b00, addr, 1'b1});
        end else begin
            cr.fields.EN = 1;
            cr.fields.MSMS = 1;
            apb.wr(`I2C_TX_FIFO_ADDR, {2'b00, addr, 1'b1});
            apb.wr(`I2C_CR_ADDR, cr);
        end

        ier.word = 0;
        ier.fields.int3 = 1;
        apb.wr(`I2C_IER_ADDR, ier);
        do begin
            if(len > 16)
                rx_th = 16;
            else if(len > 1)
                rx_th = len-1;
            else
                rx_th = 1;
            $display("[TEST_MST] rx fifo program full set to %0d", rx_th);
            apb.wr(`I2C_RX_FIFO_PIRQ_ADDR, rx_th);
            wait(irq.irq_dut);
            if(rx_th == len - 1) begin
                cr.fields.TXAK = 1;
                cr.fields.MSMS = !finish;
                cr.fields.RSTA = 0;
                apb.wr(`I2C_CR_ADDR, cr);
            end

            if(len==1) apb.wr(`I2C_RX_FIFO_PIRQ_ADDR, 0);
            read_fifo(dat, rd_len);
            len -= rd_len;
            apb.wr(`I2C_ISR_ADDR, 255);
        end while(len>0);
        $display("[TEST_MST][RECEIVER][STANDERD] test completes ...");
    endtask

    task run_rx_dynamic(
        input bit[6:0]addr, bit[7:0]len,
        ref bit [7:0] dat[$], 
        input bit finish=1);

        int rd_len, cnt=0;
        $display("[TEST_MST][DYNAMIC][RX] %0d bytes ...", len);
        apb.rd(`I2C_CR_ADDR, cr.word);
        cr.fields.RSTA = 0;
        apb.wr(`I2C_CR_ADDR, cr);
        apb.wr(`I2C_TX_FIFO_ADDR, {2'b01, addr, 1'b1});
        if(finish)
            apb.wr(`I2C_TX_FIFO_ADDR, {2'b10, len});
        else
            apb.wr(`I2C_TX_FIFO_ADDR, {2'b00, len});

        ier.word = 0;
        ier.fields.int3 = 1;
        apb.wr(`I2C_IER_ADDR, ier);
        do begin
            if(len - cnt > 16)
                apb.wr(`I2C_RX_FIFO_PIRQ_ADDR, 16);
            else
                apb.wr(`I2C_RX_FIFO_PIRQ_ADDR, len-cnt);
            apb.wr(`I2C_ISR_ADDR, 255);
            wait(irq.irq_dut);
            if(len - cnt <= 16) 
                apb.wr(`I2C_RX_FIFO_PIRQ_ADDR, 0);
            read_fifo(dat, rd_len);
            cnt += rd_len;
            $display("[TEST_MST][DYNAMIC][RX] fifo read %0d bytes", cnt);
            apb.wr(`I2C_ISR_ADDR, 255);
        end while(cnt < len);
        $display("[TEST_MST][DYNAMIC][RX] completes ...");
    endtask

    task read_fifo(ref bit [7:0] dat[$], output int len);
        bit [7:0] rx;
        apb.rd(`I2C_RX_FIFO_OCY_ADDR, rx_fifo_ocy);
        repeat(rx_fifo_ocy.fields.occupacy_value) begin
            apb.rd(`I2C_RX_FIFO_ADDR, rx);
            dat.push_back(rx);
        end
        len = rx_fifo_ocy.fields.occupacy_value;
    endtask
endclass
