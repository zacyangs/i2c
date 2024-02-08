class test_base;
    virtual apb apb;
    virtual axi_lite  axi[];

    I2C_GIE          gie         ;
    I2C_ISR          sr          ;
    I2C_IER          er          ;
    I2C_SOFTR        softr       ;
    I2C_CR           cr          ;
    I2C_SR           sr          ;
    I2C_TX_FIFO      tx_fifo     ;
    I2C_RX_FIFO      rx_fifo     ;
    I2C_ADR          adr         ;
    I2C_TX_FIFO_OCY  tx_fifo_ocy ;
    I2C_RX_FIFO_OCY  rx_fifo_ocy ;
    I2C_TEN_ADR      ten_adr     ;
    I2C_RX_FIFO_PIRQ rx_fifo_pirq;
    I2C_TSUSTA       tsusta      ;
    I2C_TSUSTO       tsusto      ;
    I2C_THDSTA       thdsta      ;
    I2C_TSUDAT       tsudat      ;
    I2C_TBUF         tbuf        ;
    I2C_THIGH        thigh       ;
    I2C_TLOW         tlow        ;

    function new (virtual apb apb, virtual axi_lite  axi[]);
        this.apb = apb;
        this.axi = axi;
    endfunction

    virtual task run(); endtask

    task enb(intf);
        `I2C_REG_RD(intf, `I2C_CR_ADDR, cr.word)
        cr.fields.EN = 1;
        `I2C_REG_WR(intf, `I2C_CR_ADDR, cr)
    endtask


    task globa_interrupt_en(intf);
        `I2C_REG_RD(intf, `I2C_GIE_ADDR, gie.word)
        gie.fields.GIE = 1;
        `I2C_REG_WR(intf, `I2C_GIE_ADDR, gie)
    endtask

    task reset(intf);
        softr.fields.RKEY = 'ha;
        softr.fields.rsv0 = 'h0;
        `I2C_REG_WR(intf, `I2C_GIE_ADDR, softr)
    endtask

endclass
