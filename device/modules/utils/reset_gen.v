
module reset_gen
(
  CLK,                     
  RST                 
); 

input CLK;
output RST;

reg [8:0] rst_cnt;
 
initial rst_cnt = 9'b1_0000_0000;

always@(posedge CLK)
     if(rst_cnt[8] == 1)
        rst_cnt <= rst_cnt +1;

assign RST = rst_cnt[8];

endmodule
