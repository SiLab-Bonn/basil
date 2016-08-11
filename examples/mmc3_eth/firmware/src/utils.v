`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:25:04 07/19/2016 
// Design Name: 
// Module Name:    utils 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


module pos_edge(clk, d_in, d_out);
    input wire clk, d_in;
    output wire d_out;
    reg   temp1, temp2, d_out;

    always @(posedge clk) begin
        temp1 <= d_in;
        temp2 <= temp1;
        if (temp2 == 0 && temp1 == 1)
            d_out <= 1;
        else
            d_out <= 0;
    end
endmodule

module neg_edge(clk, d_in, d_out);
    input  wire clk, d_in;
    output wire d_out;
    reg   temp1, temp2, d_out;

    always @(posedge clk) begin
        temp1 <= d_in;
        temp2 <= temp1;
        if (temp2 == 1 && temp1 == 0)
            d_out <= 1;
        else
            d_out <= 0;
    end
endmodule


module double_ff(clk, d_in, d_out);
    input  wire clk, d_in;
    output wire d_out;
    reg   temp1, temp2, d_out;

    always @(posedge clk) begin
        temp1 <= d_in;
        temp2 <= temp1;
        d_out <= temp2;
    end
endmodule