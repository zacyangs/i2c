module i2c_phy_tb;

logic clk = 0;
logic rstn = 0;


initial begin
    #100 rstn = 1;
end

always #5 clk = ~clk;


logic [3:0] cmd = 0;
logic       din = 0;
wire scl;
wire sda;
wire cmd_ack;





i2c_mst_ctrl_bit u_i2c_phy_bit_ctrl(/*autoinst*/
        .clk                    (clk                            ), //I
        .rstn                   (rstn                           ), //I
        .ena                    (1'b1                           ), //I
        .cmd                    (cmd[3:0]                       ), //I
        .cmd_ack                (cmd_ack                        ), //O
        .al                     (                               ), //O
        .din                    (din                            ), //I
        .dout                   (                               ), //O
        .tsusta                 (32'h10                  ), //I
        .thdsta                 (32'h10                  ), //I
        .thdsto                 (32'h10                  ), //I
        .tsudat                 (32'h10                  ), //I
        .thddat                 (32'h10                  ), //I
        .tlow                   (32'h10                  ), //I
        .thigh                  (32'h10                  ), //I
        .tbuf                   (32'h10                  ), //I
        .sto_det                (1'b0                        ), //I
        .sta_det                (1'b0                        ), //I
        .scl_rising             (1'b0                     ), //I
        .scl_i                  (scl                          ), //I
        .sda_i                  (sda                          ), //I
        .scl_o                  (scl                          ), //O
        .sda_o                  (sda                          )  //O
    );


initial begin
    wait(rstn);
    send_cmd(4'b0001);
    send_cmd(4'b0100, 0);
    send_cmd(4'b0100, 1);
    send_cmd(4'b0100, 0);
    send_cmd(4'b0100, 1);
    send_cmd(4'b0100, 0);
    send_cmd(4'b0100, 0);
    send_cmd(4'b0100, 0);
    send_cmd(4'b0100, 1);
    send_cmd(4'b1000);
    send_cmd(4'b0010);
    $finish();
end

task send_cmd(logic [3:0] cmd_i, logic dat = 0);
begin
    @(posedge clk)
    cmd = cmd_i;
    din = dat;

    forever@(posedge clk)
        if(cmd_ack) break;
end
endtask




endmodule
