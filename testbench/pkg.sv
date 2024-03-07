package pkg;

`define I2C_REG_WR(intf, addr, dat)\
    if(``intf`` == 0) apb.wr(``addr``, ``dat``); \
    else if(``intf`` == 1) axi[0].wr(``addr``, ``dat``); \
    else if(``intf`` == 2) axi[1].wr(``addr``, ``dat``);

`define I2C_REG_RD(intf, addr, dat)\
    if(``intf`` == 0)      apb.rd(``addr``, ``dat``); \
    else if(``intf`` == 1) axi[0].rd(``addr``, ``dat``); \
    else if(``intf`` == 2) axi[1].rd(``addr``, ``dat``);



`include "./i2c_reg_h.sv"
`include "./test_case/test_base.sv"
`include "./test_case/test_reg.sv"
`include "./test_case/test_slv.sv"
`include "./test_case/test_mst.sv"
`include "./test_case/test_xilinx.sv"
`include "factory.sv"
`include "env.sv"


endpackage
