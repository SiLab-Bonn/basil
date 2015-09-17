
module ODDR ( input wire D1, D2, 
              input wire C, CE, R, S,
              output wire Q );

ODDR2 ODDR2_inst (
  .Q(Q),   
  .C0(C),   
  .C1(~C),  
  .CE(CE), 
  .D0(D1), 
  .D1(D2), 
  .R(R),  
  .S(S)
);

endmodule
