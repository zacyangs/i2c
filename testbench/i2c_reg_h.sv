`define I2C_GIE_ADDR 32'h1c
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:31] GIE;
        logic [30:0] rsv0;
    } fields;
} I2C_GIE;
`define I2C_ISR_ADDR 32'h20
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:8] rsv0;
        logic [7:7] int7;
        logic [6:6] int6;
        logic [5:5] int5;
        logic [4:4] int4;
        logic [3:3] int3;
        logic [2:2] int2;
        logic [1:1] int1;
        logic [0:0] int0;
    } fields;
} I2C_ISR;
`define I2C_IER_ADDR 32'h28
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:8] rsv0;
        logic [7:7] int7;
        logic [6:6] int6;
        logic [5:5] int5;
        logic [4:4] int4;
        logic [3:3] int3;
        logic [2:2] int2;
        logic [1:1] int1;
        logic [0:0] int0;
    } fields;
} I2C_IER;
`define I2C_SOFTR_ADDR 32'h40
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:4] rsv0;
        logic [3:0] RKEY;
    } fields;
} I2C_SOFTR;
`define I2C_CR_ADDR 32'h100
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:7] rsv0;
        logic [6:6] GC_EN;
        logic [5:5] RSTA;
        logic [4:4] TXAK;
        logic [3:3] TX;
        logic [2:2] MSMS;
        logic [1:1] tx_fifo_rst;
        logic [0:0] EN;
    } fields;
} I2C_CR;
`define I2C_SR_ADDR 32'h104
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:8] rsv0;
        logic [7:7] TX_FIFO_EMPTY;
        logic [6:6] RX_FIFO_EMPTY;
        logic [5:5] RX_FIFO_FULL;
        logic [4:4] TX_FIFO_FULL;
        logic [3:3] SRW;
        logic [2:2] BB;
        logic [1:1] AAS;
        logic [0:0] ABGC;
    } fields;
} I2C_SR;
`define I2C_TX_FIFO_ADDR 32'h108
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:10] rsv0;
        logic [9:9] stop;
        logic [8:8] start;
        logic [7:0] data;
    } fields;
} I2C_TX_FIFO;
`define I2C_RX_FIFO_ADDR 32'h10c
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:8] rsv0;
        logic [7:0] data;
    } fields;
} I2C_RX_FIFO;
`define I2C_ADR_ADDR 32'h110
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:8] rsv0;
        logic [7:0] address;
    } fields;
} I2C_ADR;
`define I2C_TX_FIFO_OCY_ADDR 32'h114
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:4] rsv0;
        logic [3:0] occupacy_value;
    } fields;
} I2C_TX_FIFO_OCY;
`define I2C_RX_FIFO_OCY_ADDR 32'h118
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:4] rsv0;
        logic [3:0] occupacy_value;
    } fields;
} I2C_RX_FIFO_OCY;
`define I2C_TEN_ADR_ADDR 32'h11c
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:3] rsv0;
        logic [2:0] address;
    } fields;
} I2C_TEN_ADR;
`define I2C_RX_FIFO_PIRQ_ADDR 32'h120
typedef union packed{
    logic [31:0] word;
    struct packed {
        logic [31:4] rsv0;
        logic [3:0] compare_value;
    } fields;
} I2C_RX_FIFO_PIRQ;

`define I2C_TSUSTA_ADDR 32'h128
typedef logic [31:0] I2C_TSUSTA;

`define I2C_TSUSTO_ADDR 32'h12c
typedef logic [31:0] I2C_TSUSTO;

`define I2C_THDSTA_ADDR 32'h130
typedef logic [31:0] I2C_THDSTA;

`define I2C_TSUDAT_ADDR 32'h134
typedef logic [31:0] I2C_TSUDAT;

`define I2C_TBUF_ADDR 32'h138
typedef logic [31:0] I2C_TBUF;

`define I2C_THIGH_ADDR 32'h13c
typedef logic [31:0] I2C_THIGH;

`define I2C_TLOW_ADDR 32'h140
typedef logic [31:0] I2C_TLOW;
