class env;
    virtual apb apb;
    virtual axi_lite  axi[];
    test_base tb;

    function new(virtual apb apb, virtual axi_lite  axi[]);
        this.apb = apb;
        this.axi = axi;
    endfunction

    task run();
        tb = factory::new_case("test_slv", apb, axi);
        tb.run();
    endtask

endclass // env
