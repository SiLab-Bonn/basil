/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module IDDR (
    output reg Q1, Q2, 
    input wire C, CE, D, R, S
);


always@ (posedge C) begin
    if (R==1'b1)
        Q1 <= 1'b0;
    else if (S==1'b1)
        Q1 <= 1'b1;
    else if (CE)
        if (D==1'b1)
            Q1 <= 1'b1;
        else if (D==1'b0)
            Q1 <= 1'b0;
end


always@ (negedge C)
begin
    if (R==1'b1)
        Q2 <= 1'b0;
    else if (S==1'b1)
        Q2 <= 1'b1;
    else if (CE)
        if (D==1'b1)
            Q2 <= 1'b1;
        else if (D==1'b0)
            Q2 <= 1'b0;
end                      


endmodule
