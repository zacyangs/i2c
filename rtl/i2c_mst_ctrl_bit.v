/////////////////////////////////////
// Bit controller section
/////////////////////////////////////
//
// Translate simple commands into SCL/SDA transitions
// Each command has 5 states, A/B/C/D/idle
//
// start:	SCL	~~~~~~~~\____
//			SDA	~~~~\________
//		      x | A | B | C | i
//
// stop	    SCL	____/~~~~~~~~
//		    SDA	________/~~~~
//		      x | A | B | C | i
//
//         --->|tsu |<- ->|thd|<-
//- write	SCL	____/~~~~~\____
//			SDA	X==============
//		  	  x | A |  B  | C | i
//
//- read	SCL	____/~~~~~\____
//			SDA	XXXXXXXXXXXXXXX
//		 	  x | A |  B  | C | i
//

// Timing:     Normal mode      Fast mode   Fast-mode-plus
//---------------------------------------------------------------------
// Fscl        100KHz           400KHz
// Th_scl      4.0us            0.6us   High period of SCL
// Tl_scl      4.7us            1.3us   Low period of SCL
// Tsu:sta     4.7us            0.6us   setup time for a repeated start condition
// Tsu:sto     4.0us            0.6us   setup time for a stop conditon
// Tbuf        4.7us            1.3us   Bus free time between a stop and start condition
//


`include "i2c_master_defines.v"

module i2c_mst_ctrl_bit (
    input             clk,      // system clock
    input             rstn,     // asynchronous active low reset
    input             ena,      // core enable signal

    input      [ 3:0] cmd,      // command (from byte controller)
    output            cmd_ack,  // command complete acknowledge
    output reg        al,       // i2c bus arbitration lost

    input             din,
    output reg        dout,


    input      [31:0] tsusta,
    input      [31:0] thdsta,
    input      [31:0] tsusto,
    input      [31:0] tsudat,
    input      [31:0] thddat,
    input      [31:0] tlow,
    input      [31:0] thigh,
    input      [31:0] tbuf,

    input             sto_det,
    input             sta_det,
    input             scl_rising,
    input             scl_i,    // i2c clock line input
    input             sda_i,    // i2c data line input
    output reg        scl_o,    // i2c clock line output 
    output reg        sda_o     // i2c data line output
);

    parameter [17:0] idle    = 18'b0_0000_0000_0000_0000;
    parameter [17:0] start_a = 18'b0_0000_0000_0000_0001;
    parameter [17:0] start_b = 18'b0_0000_0000_0000_0010;
    parameter [17:0] start_c = 18'b0_0000_0000_0000_0100;
    parameter [17:0] stop_a  = 18'b0_0000_0000_0010_0000;
    parameter [17:0] stop_b  = 18'b0_0000_0000_0100_0000;
    parameter [17:0] stop_c  = 18'b0_0000_0000_1000_0000;
    parameter [17:0] rd_a    = 18'b0_0000_0010_0000_0000;
    parameter [17:0] rd_b    = 18'b0_0000_0100_0000_0000;
    parameter [17:0] rd_c    = 18'b0_0000_1000_0000_0000;
    parameter [17:0] wr_a    = 18'b0_0010_0000_0000_0000;
    parameter [17:0] wr_b    = 18'b0_0100_0000_0000_0000;
    parameter [17:0] wr_c    = 18'b0_1000_0000_0000_0000;
    parameter [17:0] hang    = 18'b0_1000_0000_0000_0000;


    parameter TSUSTA = 0;
    parameter THDSTA = 1;
    parameter THDSTO = 2;
    parameter TSUDAT = 3;
    parameter THDDAT = 4;
    parameter TLOW   = 5;
    parameter THIGH  = 6;
    parameter TBUF   = 7;
    //
    // variable declarations
    //

    reg        dscl_o  ;        // delayed scl_o  
    wire       sda_chk;         // check SDA output (Multi-master arbitration)
    reg        slv_wait;      // slave inserts wait states
    wire       slv_wait_set;
    wire       slv_wait_clr;
    reg [31:0] cnt;             // clock divider counter (synthesis)
    wire[31:0] cnt_nxt;
    wire       cnt_clr;
    wire       wait_thigh_done;
    wire       wait_tlow_done; // hlow means half low
    wire       wait_tbuf_done; // tbuf means half buf
    wire       wait_tsusta_done;
    wire       wait_thdsta_done;
    wire       wait_tsudat_done;
    wire       wait_thddat_done;
    wire       wait_tsusto_done;

    // state machine variable
    reg [17:0] c_state; // synopsys enum_state

    //
    // module body
    //    
    assign cnt_clr = wait_thigh_done & (c_state == rd_b | c_state == wr_b)|
                     wait_tlow_done & (c_state == start_c | c_state == rd_a | c_state == rd_c)|
                     wait_tbuf_done & (c_state == stop_c)|
                     wait_tsusta_done &(c_state == start_a)|
                     wait_thdsta_done &(c_state == start_b)|
                     wait_tsudat_done &(c_state == stop_a | c_state == wr_a)|
                     wait_thddat_done &(c_state == wr_c)|
                     wait_tsusto_done &(c_state == stop_b);

    assign cnt_nxt = cnt_clr ? 32'b0 : 
                     slv_wait ? cnt : cnt + 1'b1;

    assign wait_thigh_done  = cnt == thigh;
    assign wait_tlow_done  = cnt == (tlow[31:1] + tlow[0]);
    assign wait_tbuf_done  = cnt == (tbuf[31:1] + tlow[0]);
    assign wait_tsusta_done = cnt == tsusta;
    assign wait_thdsta_done = cnt == thdsta;
    assign wait_tsudat_done = cnt == tsudat;
    assign wait_thddat_done = cnt == thddat;
    assign wait_tsusto_done = cnt == tsusto;

    assign cmd_ack = c_state == start_c & wait_tlow_done |
                     c_state == stop_c  & wait_tbuf_done |
                     c_state == rd_c    & wait_tlow_done |
                     c_state == wr_c    & wait_thddat_done;

    // whenever the slave is not ready it can delay the cycle by pulling SCL low
    // delay scl_o  
    always @(posedge clk)
      dscl_o   <= scl_o  ;

    // slv_wait is asserted when master wants to drive SCL high, but the slave pulls it low
    // slv_wait remains asserted until the slave releases SCL
    
    assign slv_wait_set = (!dscl_o & scl_o) & (!scl_i);
    assign slv_wait_clr = slv_wait & scl_i;

    always @(posedge clk or negedge rstn)
      if (!rstn) slv_wait <= 1'b0;
      else       slv_wait <= (slv_wait & ~slv_wait_clr) | slv_wait_set ;

    // master drives SCL high, but another master pulls it low
    // master start counting down its low cycle now (clock synchronization)

    // generate arbitration lost signal
    // aribitration lost when:
    // 1) master drives SDA high, but the i2c bus is low
    // 2) stop detected while not requested
    reg cmd_stop;
    always @(posedge clk or negedge rstn)
      if (~rstn)
          cmd_stop <= 1'b0;
      else if (c_state == idle)
          cmd_stop <= cmd == `I2C_CMD_STOP;

    assign sda_chk = c_state == wr_b && wait_thigh_done;
    always @(posedge clk or negedge rstn)
      if (~rstn)
          al <= 1'b0;
      else
          al <= (sda_chk & ~sda_i & sda_o  ) | (|c_state & sto_det & ~cmd_stop);


    // generate dout signal (store SDA on rising edge of SCL)
    always @(posedge clk)
      if (scl_rising) dout <= sda_i;


    // generate statemachine
    always @(posedge clk or negedge rstn)
      if (!rstn) begin
          c_state <= idle;
          scl_o   <= 1'b1;
          sda_o   <= 1'b1;
          cnt     <= 32'b0;
      end
      else if (al) begin
          c_state <= idle;
          scl_o   <= 1'b1;
          sda_o   <= 1'b1;
          cnt     <= 32'b0;
      end
      else if(ena) begin 
          cnt <= cnt_nxt;
        case (c_state) // synopsys full_case parallel_case
              // idle state
              idle: begin
                  case (cmd) // synopsys full_case parallel_case
                       `I2C_CMD_START: c_state <= start_a;
                       `I2C_CMD_STOP:  c_state <= stop_a; 
                       `I2C_CMD_WRITE: c_state <= wr_a;
                       `I2C_CMD_READ:  c_state <= rd_a;
                       `I2C_CMD_WAIT:  c_state <= hang;
                       default:        c_state <= idle;
                  endcase

                  scl_o   <= scl_o  ; // keep SCL in same state
                  sda_o   <= sda_o  ; // keep SDA in same state
              end

              // start
              start_a: begin
                  scl_o <= 1'b1;
                  sda_o <= 1'b1;

                  if(wait_tsusta_done) c_state <= start_b;
              end

              start_b: begin
                  scl_o <= 1'b1;
                  sda_o <= 1'b0;

                  if(wait_thdsta_done) c_state <= start_c;
              end

              start_c: begin
                  scl_o <= 1'b0; 
                  sda_o <= 1'b0; 
                  if(wait_tlow_done) c_state <= idle;
              end

              // stop
              stop_a: begin
                  scl_o <= 1'b0; // keep SCL low
                  sda_o <= 1'b0; // set SDA low

                  if(wait_tsudat_done) c_state <= stop_b;
              end

              stop_b: begin
                  scl_o <= 1'b1; // set SCL high
                  sda_o <= 1'b0; // keep SDA low
                  if(wait_tsusto_done) c_state <= stop_c;
              end

              stop_c: begin
                  scl_o <= 1'b1; // keep SCL high
                  sda_o <= 1'b1; // keep SDA low
                  if(wait_tbuf_done) c_state <= idle;
              end

              // read
              rd_a: begin
                  scl_o <= 1'b0; // keep SCL low
                  sda_o <= 1'b1; // tri-state SDA
                  if(wait_tlow_done) c_state <= rd_b;
              end

              rd_b: begin
                  scl_o <= 1'b1; // set SCL high
                  sda_o <= 1'b1; // keep SDA tri-stated
                  if(wait_thigh_done) c_state <= rd_c;
              end

              rd_c: begin
                  scl_o <= 1'b0; // keep SCL high
                  sda_o <= 1'b1; // keep SDA tri-stated
                  if(wait_tlow_done) c_state <= idle;
              end

              // write
              wr_a: begin
                  scl_o <= 1'b0; // keep SCL low
                  sda_o <= din;  // set SDA
                  if(wait_tsudat_done) c_state <= wr_b;
              end

              wr_b: begin
                  scl_o <= 1'b1; // set SCL high
                  sda_o <= din;  // keep SDA
                  if(wait_thigh_done) c_state <= wr_c;
              end

              wr_c: begin
                  scl_o <= 1'b0; // keep SCL high
                  sda_o <= din;
                  if(wait_thddat_done) c_state <= idle;
              end

              hang: begin
                  scl_o <= 1'b0; // keep SCL high
                  sda_o <= 1'b0;
                  if(cmd != `I2C_CMD_WAIT) c_state <= idle;
              end
        endcase
      end

endmodule
