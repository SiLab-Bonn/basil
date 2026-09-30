/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */

`ifdef _IVERILOG_
`define CLOG2 $clog2
`else
// Verilog-2005 functions use static lifetime by default.
// verilog_lint: waive explicit-function-lifetime
function integer clog2;
    input integer value;
    reg [31:0] shifted;
    integer res;
    begin
        if (value < 2) clog2 = value;
        else begin
            shifted = value - 1;
            for (res = 0; shifted > 0; res = res + 1) shifted = shifted >> 1;
            clog2 = res;
        end
    end
endfunction

`define CLOG2 clog2
`endif
