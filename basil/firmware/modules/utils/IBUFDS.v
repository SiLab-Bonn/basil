/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef IBUFDS_SIM
`define IBUFDS_SIM

`timescale 1ps / 1ps

module IBUFDS #(
    parameter CAPACITANCE      = "DONT_CARE",
    parameter DIFF_TERM        = "FALSE",
    parameter DQS_BIAS         = "FALSE",
    parameter IBUF_DELAY_VALUE = "0",
    parameter IBUF_LOW_PWR     = "TRUE",
    parameter IFD_DELAY_VALUE  = "AUTO",
    parameter IOSTANDARD       = "DEFAULT"
) (
    output reg  O,
    input  wire I,
    input  wire IB
);

    // Exact four-state cases preserve the UNISIM floating-input bias rule.
    // Equal driven levels and reversed floating pairs retain the prior value.
    always @(I or IB) begin
        case ({
            I, IB
        })
            2'b10: O <= 1'b1;
            2'b01: O <= 1'b0;
            2'bzz, 2'b0z, 2'bz1: O <= ({40'b0, DQS_BIAS} == "TRUE") ? 1'b0 : 1'bx;
            2'b00, 2'b11, 2'b1z, 2'bz0: ;
            default: O <= 1'bx;
        endcase
    end

    initial begin
        if (({40'b0, DQS_BIAS} != "TRUE") && ({40'b0, DQS_BIAS} != "FALSE")) begin
            $display("ERROR: IBUFDS invalid DQS_BIAS (%m)");
            $finish;
        end
    end

endmodule

`endif
