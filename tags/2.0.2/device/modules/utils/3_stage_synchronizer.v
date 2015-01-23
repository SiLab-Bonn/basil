`timescale 1ns / 1ps

// synchronizing asynchronous signals/flags, prevents metastable events

module three_stage_synchronizer #(
    parameter WIDTH = 1
) (
    input wire                  CLK,
    input wire  [WIDTH-1:0]     IN,
    output reg  [WIDTH-1:0]     OUT
);

reg [WIDTH-1:0] out_d_ff_1, out_d_ff_2;


always @(posedge CLK) // first stage
begin
    out_d_ff_1 <= IN;
    out_d_ff_2 <= out_d_ff_1;
    OUT <= out_d_ff_2;
end

endmodule


