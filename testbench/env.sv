class env;
    virtual apb apb;
    virtual axi_lite  axi[];
    virtual interrupt irq;
    test_base tb;

    function new(virtual apb apb, virtual axi_lite  axi[], virtual interrupt irq);
        this.apb = apb;
        this.axi = axi;
        this.irq = irq;
    endfunction

    task run();
        tb = factory::new_case("test_slv", apb, axi, irq);
        tb.run();
    endtask

endclass // env
