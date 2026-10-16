/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef SKID_BUFFER
`define SKID_BUFFER

`timescale 1ps/1ps
`default_nettype none


// Two-entry pipeline register with valid/ready handshake.
// Both IN_READY and OUT_VALID/OUT_DATA are driven directly from registers, which breaks
// the combinational path between source and sink. Full throughput (one word per cycle).
// A word is accepted at the input when IN_VALID && IN_READY and leaves at the output
// when OUT_VALID && OUT_READY.
module skid_buffer #(
    parameter integer WIDTH = 32
) (
    input wire CLK,
    input wire RST,

    input  wire             IN_VALID,
    output wire             IN_READY,
    input  wire [WIDTH-1:0] IN_DATA,

    output reg              OUT_VALID,
    input  wire             OUT_READY,
    output reg  [WIDTH-1:0] OUT_DATA
);

    reg             skid_valid;
    reg [WIDTH-1:0] skid_data;

    // Input is only accepted while the skid register is empty
    assign IN_READY = !skid_valid;

    wire in_accept = IN_VALID && IN_READY;
    wire out_load  = OUT_READY || !OUT_VALID;  // output register is free (or drained this cycle)

    always @(posedge CLK) begin
        if (RST) begin
            OUT_VALID  <= 1'b0;
            skid_valid <= 1'b0;
        end else if (out_load) begin
            if (skid_valid) begin
                // Drain the skid register first to keep order
                OUT_VALID  <= 1'b1;
                skid_valid <= 1'b0;
            end else begin
                OUT_VALID <= in_accept;
            end
        end else if (in_accept) begin
            // Output stalled: park the incoming word in the skid register
            skid_valid <= 1'b1;
        end
    end

    always @(posedge CLK) begin
        if (out_load) begin
            if (skid_valid)
                OUT_DATA <= skid_data;
            else if (in_accept)  // no data in skid, forward only
                OUT_DATA <= IN_DATA;
        end
    end

    // Store data for one more cycle if downstream not ready
    always @(posedge CLK) begin
        if (!out_load && in_accept)
            skid_data <= IN_DATA;
    end

endmodule

`endif
