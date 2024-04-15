//**
//* ------------------------------------------------------------
//* Copyright (c) All rights reserved
//* SiLab, Physics Institute, University of Bonn
//* ------------------------------------------------------------
//*/
       module priority_encoder_only(
	       input wire CLK,
	       input wire [96-1:0] sample,
	       output reg [6:0] position_out);

	// converts thermometercode to onehot
       function [96/6 -2 : 0] therm2onehot;
	       input [96/6 - 1 : 0] thermo;
	       integer i;
	       begin
		       for(i = 0; i <96/6 -1; i = i+1) begin
			       therm2onehot[i] = (thermo[i] == 1 && thermo[i+1] == 0) ? 1 : 0;
		       end
	       end
       endfunction

       // converts a onehot vector to binary
       function [3:0] onehot2bin; 
	       input [96/6 - 2 : 0] onehot;
	       integer i;
	       begin
		       onehot2bin = 0;
		       for(i=0; i < 96/6 -1; i = i + 1) begin
			       if(onehot[i]) onehot2bin = i + 1;
		       end
       end
       endfunction

       // sums all the 1s in a vector
       function [3:0] find_msb;
	       input [12 -1 :0 ]transition_code;
	       integer i;
	       begin
		       find_msb = 0;
		       for(i=0; i< 12; i = i + 1) begin
			       if(transition_code[i]) find_msb = find_msb +1;
		       end
       end
       endfunction


       reg [96/6 -1 : 0] corse_code;
       reg [3 : 0] corse_position, corse_position_dly1;
       reg [96+8-1 : 0 ] bins_extended, bins_extended_dly;
       reg [11 : 0] transition_code;
       //reg [96-1 : 0] position, position_dly;
       integer j;
       always @(posedge CLK) begin
	       
	       for(j =0; j<96/6; j = j + 1) begin //corse position is calculated in thermo
		       corse_code[j] <= (sample[j*6 +: 6] == 6'b111111) ? 1 : 0;
	       end 
	       bins_extended <= {8'h00, sample};
	       // cycle
	       corse_position <= onehot2bin(therm2onehot(corse_code)); //conversion to binary
	       bins_extended_dly <= bins_extended;
	       // cycle
	       corse_position_dly1 <= corse_position;
	       transition_code <= bins_extended_dly[corse_position*6 +:12]; // the region wiht the transition
	       // cycle
	       position_out <= corse_position_dly1*6 + find_msb(transition_code); // final answer in binary
	       //cycle

       end
       
       endmodule

