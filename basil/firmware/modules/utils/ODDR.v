/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module ODDR #(
    parameter DDR_CLK_EDGE = "OPPOSITE_EDGE",
    parameter INIT = 1'b0,
    parameter SRTYPE = "SYNC"
)(
    output reg Q,
    input wire C,
    input wire CE,
    input wire D1,
    input wire D2,
    input wire R,
    input wire S
);

always @(posedge C or negedge C) begin
    if (R) begin
        Q <= INIT;
    end else if (CE) begin
        if (DDR_CLK_EDGE == "OPPOSITE_EDGE") begin
            if (C) Q <= D2;
            else Q <= D1;
        end else begin
            if (C) Q <= D1;
            else Q <= D2;
        end
    end
end

endmodule
