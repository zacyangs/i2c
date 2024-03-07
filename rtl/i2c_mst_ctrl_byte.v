/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant I2C Master byte-controller       ////
////                                                             ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/projects/i2c/    ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001 Richard Herveille                        ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
`include "i2c_master_defines.v"

module i2c_mst_ctrl_byte (
    input       clk,     // master clock
    input       rst,     // synchronous active high reset
    input       nReset,  // asynchronous active low reset
    input       ena,     // core enable signal

    input [15:0] clk_cnt, // 4x SCL

    // control inputs
    input       cr_msms, // 0 - slave, 1 - master
    input       read,
    input       write,
    input       ack_in,
    input [7:0] din,

    // status outputs
    output reg   cmd_ack,
    output reg   ack_out,
    output       i2c_busy,
    output       i2c_al,
    output [7:0] dout,

    input  scl_i,
    output scl_o,
    output scl_oen,
    input  sda_i,
    output sda_o,
    output sda_oen
    );

    // statemachine
    parameter [4:0] ST_IDLE  = 5'b0_0000;
    parameter [4:0] ST_START = 5'b0_0001;
    parameter [4:0] ST_READ  = 5'b0_0010;
    parameter [4:0] ST_WRITE = 5'b0_0100;
    parameter [4:0] ST_ACK   = 5'b0_1000;
    parameter [4:0] ST_STOP  = 5'b1_0000;

    // signals for bit_controller
    reg  [3:0] core_cmd;
    reg        core_txd;
    wire       core_ack, core_rxd;

    // signals for shift register
    reg [7:0] sr; //8bit shift register
    reg       shift, ld;

    // signals for state machine
    wire       go;
    reg  [2:0] dcnt;
    wire       cnt_done;
    wire       start;
    wire       stop;

    //
    // Module body
    //


    assign start =   cr_msms  && (!cr_msms_d);
    assign stop  = (!cr_msms) &&   cr_msms_d ;


    // generate go-signal
    assign go = (read | write | stop) & ~cmd_ack;

    // assign dout output to shift-register
    assign dout = sr;

    // generate shift register
    always @(posedge clk or negedge nReset)
      if (!nReset)
        sr <= #10 #1 8'h0;
      else if (rst)
        sr <= #10 #1 8'h0;
      else if (ld)
        sr <= #10 #1 din;
      else if (shift)
        sr <= #10 #1 {sr[6:0], core_rxd};

    // generate counter
    always @(posedge clk or negedge nReset)
      if (!nReset)
        dcnt <= #10 #1 3'h0;
      else if (rst)
        dcnt <= #10 #1 3'h0;
      else if (ld)
        dcnt <= #10 #1 3'h7;
      else if (shift)
        dcnt <= #10 #1 dcnt - 3'h1;

    assign cnt_done = ~(|dcnt);

    //
    // state machine
    //
    reg [4:0] c_state; // synopsys enum_state

    always @(posedge clk or negedge nReset)
      if (!nReset) begin
            core_cmd <= #10 #1 `I2C_CMD_NOP;
            core_txd <= #10 #1 1'b0;
            shift    <= #10 #1 1'b0;
            ld       <= #10 #1 1'b0;
            cmd_ack  <= #10 #1 1'b0;
            c_state  <= #10 #1 ST_IDLE;
            ack_out  <= #10 #1 1'b0;
      end
      else if (rst | i2c_al) begin
           core_cmd <= #10 #1 `I2C_CMD_NOP;
           core_txd <= #10 #1 1'b0;
           shift    <= #10 #1 1'b0;
           ld       <= #10 #1 1'b0;
           cmd_ack  <= #10 #1 1'b0;
           c_state  <= #10 #1 ST_IDLE;
           ack_out  <= #10 #1 1'b0;
       end
    else begin
          // initially reset all signals
          core_txd <= #10 #1 sr[7];
          shift    <= #10 #1 1'b0;
          ld       <= #10 #1 1'b0;
          cmd_ack  <= #10 #1 1'b0;

          case (c_state) // synopsys full_case parallel_case
            ST_IDLE:
              if (go) begin
                if (start) begin
                    c_state  <= #10 #1 ST_START;
                    core_cmd <= #10 #1 `I2C_CMD_START;
                end
                else if (read) begin
                    c_state  <= #10 #1 ST_READ;
                    core_cmd <= #10 #1 `I2C_CMD_READ;
                end
                else if (write) begin
                    c_state  <= #10 #1 ST_WRITE;
                    core_cmd <= #10 #1 `I2C_CMD_WRITE;
                end
                else begin
                    c_state  <= #10 #1 ST_STOP;
                    core_cmd <= #10 #1 `I2C_CMD_STOP;
                end

                ld <= #10 #1 1'b1;
              end

            ST_START:
              if (core_ack) begin
                if (read) begin
                    c_state  <= #10 #1 ST_READ;
                    core_cmd <= #10 #1 `I2C_CMD_READ;
                end 
                else begin
                    c_state  <= #10 #1 ST_WRITE;
                    core_cmd <= #10 #1 `I2C_CMD_WRITE;
                end

                ld <= #10 #1 1'b1;
              end

            ST_WRITE:
              if (core_ack)
                if (cnt_done) begin
                      c_state  <= #10 #1 ST_ACK;
                      core_cmd <= #10 #1 `I2C_CMD_READ;
                end
                else begin
                      c_state  <= #10 #1 ST_WRITE;       // stay in same state
                      core_cmd <= #10 #1 `I2C_CMD_WRITE; // write next bit
                      shift    <= #10 #1 1'b1;
                end

            ST_READ:
              if (core_ack) begin
                if (cnt_done) begin
                      c_state  <= #10 #1 ST_ACK;
                      core_cmd <= #10 #1 `I2C_CMD_WRITE;
                end
                else begin
                      c_state  <= #10 #1 ST_READ;       // stay in same state
                      core_cmd <= #10 #1 `I2C_CMD_READ; // read next bit
                end

                shift    <= #10 #1 1'b1;
                core_txd <= #10 #1 ack_in;
              end

            ST_ACK:
              if (core_ack) begin
                   if (stop) begin
                         c_state  <= #10 #1 ST_STOP;
                         core_cmd <= #10 #1 `I2C_CMD_STOP;
                   end
                   else begin
                         c_state  <= #10 #1 ST_IDLE;
                         core_cmd <= #10 #1 `I2C_CMD_NOP;

                         // generate command acknowledge signal
                         cmd_ack  <= #10 #1 1'b1;
                   end

                   // assign ack_out output to bit_controller_rxd (contains last received bit)
                   ack_out <= #10 #1 core_rxd;

                   core_txd <= #10 #1 1'b1;
              end else
                 core_txd <= #10 #1 ack_in;

            ST_STOP:
              if (core_ack) begin
                    c_state  <= #10 #1 ST_IDLE;
                    core_cmd <= #10 #1 `I2C_CMD_NOP;

                    // generate command acknowledge signal
                    cmd_ack  <= #10 #1 1'b1;
              end

          endcase
      end





    // hookup bit_controller
    i2c_mst_ctrl_bit bit_controller (
        .clk     ( clk      ),
        .rst     ( rst      ),
        .nReset  ( nReset   ),
        .ena     ( ena      ),
        .clk_cnt ( clk_cnt  ),
        .cmd     ( core_cmd ),
        .cmd_ack ( core_ack ),
        .busy    ( i2c_busy ),
        .al      ( i2c_al   ),
        .din     ( core_txd ),
        .dout    ( core_rxd ),
        .scl_i   ( scl_i    ),
        .scl_o   ( scl_o    ),
        .scl_oen ( scl_oen  ),
        .sda_i   ( sda_i    ),
        .sda_o   ( sda_o    ),
        .sda_oen ( sda_oen  )
    );







endmodule
