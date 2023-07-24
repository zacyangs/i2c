typedef class test_reg;
typedef class test_slv;
typedef class test_base;

class factory;

    static function test_base new_case(string c, virtual apb apb, virtual axi_lite axi);
        test_reg tr;
        test_slv ts;
        case(c)
            "test_reg" : begin
                tr = new(apb, axi);
                return tr;
            end

            "test_slv" : begin
                ts = new(apb, axi);
                return ts;
            end

            default : begin
                tr = new(apb, axi);
                return tr;
            end
        endcase
    endfunction

endclass