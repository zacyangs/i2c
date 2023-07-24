class test_base;
    virtual apb apb;
    virtual axi_lite axi;

    function new (virtual apb apb, virtual axi_lite axi);
        this.apb = apb;
        this.axi = axi;
    endfunction

    virtual task run(); endtask
endclass
