

module ODDR ( input wire D1, D2, 
              input wire C, CE, R, S,
              output wire Q );

assign Q = C ? D1 & CE : D2 & CE;

endmodule
