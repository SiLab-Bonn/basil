/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */


`ifndef RAMB_8_TO_N
`define RAMB_8_TO_N

module ramb_8_to_n (
    clkA,
    clkB,
    weA,
    weB,
    addrA,
    addrB,
    diA,
    doA,
    diB,
    doB
);

    parameter SIZE = 1024;
    parameter WIDTH = 8;

    localparam WIDTHA = 8;
    localparam SIZEA = SIZE;
    localparam ADDRWIDTHA = $clog2(SIZEA);

    localparam WIDTHB = WIDTH;
    localparam SIZEB = SIZEA * 8 / WIDTHB;
    localparam ADDRWIDTHB = $clog2(SIZEB);

    input wire clkA;
    input wire clkB;
    input wire weA, weB;
    input wire [ADDRWIDTHA-1:0] addrA;
    input wire [ADDRWIDTHB-1:0] addrB;
    input wire [WIDTHA-1:0] diA;
    input wire [WIDTHB-1:0] diB;
    output reg [WIDTHA-1:0] doA;
    output reg [WIDTHB-1:0] doB;

    `define MAX(a, b) {(a) > (b) ? (a) : (b)}
    `define MIN(a, b) {(a) < (b) ? (a) : (b)}

    localparam MAXSIZE = `MAX(SIZEA, SIZEB);
    localparam MAXWIDTH = `MAX(WIDTHA, WIDTHB);
    localparam MINWIDTH = `MIN(WIDTHA, WIDTHB);
    localparam RATIO = MAXWIDTH / MINWIDTH;
    localparam LOG2RATIO = $clog2(RATIO);

    reg [MINWIDTH-1:0] RAM[0:MAXSIZE-1];

    // For simualtion init with 0
    initial begin : INIT_MEM
        integer w;
        for (w = 0; w < MAXSIZE; w = w + 1) begin
            RAM[w] = 0;
        end
    end

    generate
        // Keep the existing generate hierarchy.
        // verilog_lint: waive generate-label
        if (WIDTH == 8) begin
            always @(posedge clkB) begin
                if (weB) RAM[addrB] <= diB;

                doB <= RAM[addrB];
            end

            always @(posedge clkA) begin : portA
                if (weA) RAM[addrA] <= diA;

                doA <= RAM[addrA];
            end
        end
    endgenerate

    generate
        // Keep the existing generate hierarchy.
        // verilog_lint: waive generate-label
        if (WIDTH < 8) begin
            always @(posedge clkB) begin
                if (weB) RAM[addrB] <= diB;

                doB <= RAM[addrB];
            end

            always @(posedge clkA) begin : portA
                integer i;
                reg [LOG2RATIO-1:0] lsbaddr;

                for (i = 0; i < RATIO; i = i + 1) begin
                    lsbaddr = i;
                    if (weA) RAM[{addrA, lsbaddr}] <= diA[(i+1)*MINWIDTH-1-:MINWIDTH];

                    doA[(i+1)*MINWIDTH-1-:MINWIDTH] <= RAM[{addrA, lsbaddr}];
                end
            end
        end
    endgenerate


    generate
        // Keep the existing generate hierarchy.
        // verilog_lint: waive generate-label
        if (WIDTH > 8) begin
            always @(posedge clkA) begin
                if (weA) RAM[addrA] <= diA;

                doA <= RAM[addrA];
            end

            always @(posedge clkB) begin : portA
                integer i;
                reg [LOG2RATIO-1:0] lsbaddr;
                for (i = 0; i < RATIO; i = i + 1) begin
                    lsbaddr = i;
                    if (weB) RAM[{addrB, lsbaddr}] <= diB[(i+1)*MINWIDTH-1-:MINWIDTH];

                    doB[(i+1)*MINWIDTH-1-:MINWIDTH] <= RAM[{addrB, lsbaddr}];
                end
            end
        end
    endgenerate


endmodule

`endif
