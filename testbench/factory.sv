typedef class test_reg;
typedef class test_slv;
typedef class test_xilinx;
typedef class test_base;

class factory;

    static function test_base new_case(string c, virtual apb apb, virtual axi_lite  axi[], virtual interrupt irq);
        test_reg tr;
        test_slv ts;
        test_xilinx tx;
        test_mst tm;
        case(c)
            "test_reg" : begin
                tr = new(apb, axi, irq);
                return tr;
            end

            "test_slv" : begin
                ts = new(apb, axi, irq);
                return ts;
            end

            "test_xilinx" : begin
                tx = new(apb, axi, irq);
                return tx;
            end

            "test_mst" : begin
                tm = new(apb, axi, irq);
                return tm;
            end

            default : begin
                tr = new(apb, axi, irq);
                return tr;
            end
        endcase
    endfunction

endclass
