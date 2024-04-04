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

module i2c_phy_fsm (
    input             clk,      // system clock
    input             rstn,     // asynchronous active low reset
    input             ena,      // core enable signal

    input             msms,     // master slave mode select
    input      [ 3:0] cmd,      // command (from byte controller)
    output            cmd_ack,  // command complete acknowledge
    output reg        al,       // i2c bus arbitration lost
    output reg        rsta_det = 0,

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
    input             scl_falling,
    input             scl_i,    // i2c clock line input
    input             sda_i,    // i2c data line input
    output reg        scl_o,    // i2c clock line output 
    output reg        sda_o     // i2c data line output
);

    localparam idle    = 4'd1;
    localparam start_a = 4'd2;
    localparam start_b = 4'd3;
    localparam start_c = 4'd4;
    localparam start_d = 4'd5;
    localparam stop_a  = 4'd6;
    localparam stop_b  = 4'd7;
    localparam stop_c  = 4'd8;
    localparam rd_a    = 4'd9;
    localparam rd_b    = 4'd10;
    localparam rd_c    = 4'd11;
    localparam wr_a    = 4'd12;
    localparam wr_b    = 4'd13;
    localparam wr_c    = 4'd14;
    localparam hang    = 4'd15;


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
    reg       scl_x;
    reg       sda_x;

    // state machine variable
    reg [3:0] cstate, nstate; 


//ila_32 u_ila_32(
//    .clk(clk),
//    .probe0({
//        cnt,
//        cstate,
//        nstate,
//    sda_chk,
//    slv_wait,
//    scl_o,
//    sda_o,
//    al,
//    sda_i,
//    sto_det,
//    msms,
//    cmd_stop
//    })
//);


    //
    // module body
    //    
    assign cnt_clr = cstate != nstate;

    assign cnt_nxt = cnt_clr ? 32'b0 : 
                     slv_wait ? cnt : cnt + 1'b1;

    assign wait_thigh_done  = cnt >= thigh;
    assign wait_tlow_done  = cnt >= (tlow[31:1] + tlow[0]);
    assign wait_tbuf_done  = cnt >= (tbuf[31:1] + tlow[0]);
    assign wait_tsusta_done = cnt == tsusta;
    assign wait_thdsta_done = cnt == thdsta;
    assign wait_tsudat_done = cnt == tsudat;
    assign wait_thddat_done = cnt == thddat;
    assign wait_tsusto_done = cnt == tsusto;

    assign cmd_ack = cstate == start_d & wait_tlow_done |
                     cstate == stop_c  & wait_tbuf_done |
                     cstate == rd_c    & (wait_tlow_done || !msms) |
                     cstate == wr_c    & wait_thddat_done;

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
    wire cmd_stop;
    assign cmd_stop = (cmd == `I2C_CMD_STOP);
    //always @(posedge clk or negedge rstn)
    //  if (~rstn)
    //      cmd_stop <= 1'b0;
    //  else if (cstate == idle)
    //      cmd_stop <= cmd == `I2C_CMD_STOP;

    assign sda_chk = cstate == wr_b && nstate == wr_c;
    always @(posedge clk or negedge rstn)
      if (~rstn)
          al <= 1'b0;
      else
          al <= (sda_chk & ~sda_i & sda_o) | (sto_det & ~cmd_stop & msms);


    // generate dout signal (store SDA on rising edge of SCL)
    always @(posedge clk) begin
      if (scl_rising) dout <= sda_i;
      if (scl_falling && (dout != sda_i) && cstate == rd_b) 
          rsta_det <=1'b1;
      else if(cmd_ack)
          rsta_det <=1'b0;
    end


    // generate statemachine
    always @(posedge clk or negedge rstn)
      if (!rstn) begin
          cstate <= idle;
          scl_o   <= 1'b1;
          sda_o   <= 1'b1;
          cnt     <= 32'b0;
      end
      else if (al) begin
          cstate <= idle;
          scl_o   <= 1'b1;
          sda_o   <= 1'b1;
          cnt     <= 32'b0;
      end
      else if(ena) begin 
        cnt     <= cnt_nxt;
        cstate  <= nstate;
        scl_o   <= scl_x;
        sda_o   <= sda_x;
      end

    always@(*) if(ena) begin
        nstate = cstate;
        case (cstate) // synopsys full_case parallel_case
              // idle state
              idle: begin
                  case (cmd) // synopsys full_case parallel_case
                       `I2C_CMD_START: nstate = start_a;
                       `I2C_CMD_STOP:  nstate = stop_a; 
                       `I2C_CMD_WRITE: nstate = wr_a;
                       `I2C_CMD_READ:  nstate = rd_a;
                       `I2C_CMD_WAIT:  nstate = hang;
                       default:        nstate = idle;
                  endcase

                  scl_x   = scl_o  ; // keep SCL in same state
                  sda_x   = sda_o  ; // keep SDA in same state
              end

              // start

              start_a: begin
                  scl_x = scl_o; 
                  sda_x = 1'b1; 
                  if(wait_tlow_done) nstate = start_b;
              end

              start_b: begin
                  scl_x = 1'b1;
                  sda_x = 1'b1;

                  if(wait_tsusta_done) nstate = start_c;
              end

              start_c: begin
                  scl_x = 1'b1;
                  sda_x = 1'b0;

                  if(wait_thdsta_done) nstate = start_d;
              end

              start_d: begin
                  scl_x = 1'b0; 
                  sda_x = 1'b0; 
                  if(wait_tlow_done) nstate = idle;
              end

              // stop
              stop_a: begin
                  scl_x = 1'b0; // keep SCL low
                  sda_x = 1'b0; // set SDA low

                  if(wait_tsudat_done) nstate = stop_b;
              end

              stop_b: begin
                  scl_x = 1'b1; // set SCL high
                  sda_x = 1'b0; // keep SDA low
                  if(wait_tsusto_done) nstate = stop_c;
              end

              stop_c: begin
                  scl_x = 1'b1; // keep SCL high
                  sda_x = 1'b1; // keep SDA low
                  if(wait_tbuf_done) nstate = idle;
              end

              // read
              rd_a: begin
                  scl_x = !msms; // keep SCL low
                  sda_x = 1'b1; // tri-state SDA
                  if(wait_tlow_done && msms || scl_rising && !msms) nstate = rd_b;
              end

              rd_b: begin
                  scl_x = 1'b1; // set SCL high
                  sda_x = 1'b1; // keep SDA tri-stated
                  if(wait_thigh_done && msms || scl_falling && !msms) nstate = rd_c;
              end

              rd_c: begin
                  scl_x = !msms; // keep SCL high
                  sda_x = 1'b1; // keep SDA tri-stated
                  if(wait_tlow_done || !msms) nstate = idle;
              end

              // write
              wr_a: begin
                  scl_x = 1'b0; // keep SCL low
                  sda_x = din;  // set SDA
                  if(wait_tsudat_done) nstate = wr_b;
              end

              wr_b: begin
                  scl_x = 1'b1; // set SCL high
                  sda_x = din;  // keep SDA
                  if(wait_thigh_done && msms || scl_falling && !msms) nstate = wr_c;
              end

              wr_c: begin
                  scl_x = !msms; // keep SCL high
                  sda_x = din;
                  if(wait_thddat_done) nstate = idle;
              end

              hang: begin
                  scl_x = 1'b0; // keep SCL high
                  sda_x = sda_o;
                  if(cmd != `I2C_CMD_WAIT) nstate = idle;
              end
        endcase
    end

endmodule
