/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef BUFG_SIM
`define BUFG_SIM

`timescale 1ps / 1ps


module BUFG (
    output wire O,
    input  wire I
);

    buf output_buffer (O, I);

endmodule

`endif
