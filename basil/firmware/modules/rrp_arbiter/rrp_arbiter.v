/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none
 
//TODO: check with more then 1 hold/priority at a time

module rrp_arbiter 
#(
    parameter WIDTH = 4
)
(
    input wire RST,
    input wire CLK,
    
    input wire [WIDTH-1:0] WRITE_REQ, // round robin
    input wire [WIDTH-1:0] HOLD_REQ, // lower channels have higher priority, has to be high until read was granted
    input wire [WIDTH*32-1:0] DATA_IN,
    output wire[WIDTH-1:0] READ_GRANT,

    input wire READY_OUT,
    output wire WRITE_OUT,
    output wire [31:0] DATA_OUT
    
);

//`include "../includes/log2func.v"
//localparam SEL_SIZE = log2(WIDTH);

integer m;
reg [WIDTH-1:0] prev_select; // one hot
reg [WIDTH-1:0] select; // one hot

reg hold;

wire WRITE_REQ_OR, HOLD_REQ_OR;
assign WRITE_REQ_OR = |WRITE_REQ;
assign HOLD_REQ_OR = |HOLD_REQ;

assign WRITE_OUT = |(WRITE_REQ & select & READ_GRANT);
//assign WRITE_OUT = HOLD_REQ_OR ? WRITE_REQ[0] : WRITE_REQ_OR;

always@(*) begin
    select = prev_select;
    if(HOLD_REQ_OR && !hold) begin       
        m = 0;
        select = 1; // always start from lowest channel
        while(!(HOLD_REQ & select) && (m < WIDTH)) begin
            m = m + 1;
            select = 1 << m;
        end
    end
    else if(WRITE_REQ_OR && !hold) begin
        m = 0;
        select = prev_select << 1; // start from last channel + 1
        if(select == 0) // 0 is not valid
            select = 1;
        while(!(WRITE_REQ & select) && (m < WIDTH)) begin
            m = m + 1;
            select = select << 1;
            if(select == 0) // 0 is not valid
                select = 1;
        end
    end
end

always@(posedge CLK) begin
    if(RST)
        prev_select <= (1 << (WIDTH - 1));
    else if (WRITE_REQ_OR & !hold)
        prev_select <= select;
end

always@(posedge CLK) begin
    if(RST)
        hold <= 0;
    else if(READY_OUT)
        hold <= 0;
    else if (WRITE_OUT)
        hold <= 1;
end

//wire [31:0] DATA_A [WIDTH-1:0];

wire [WIDTH-1:0] DATA_A [31:0]; // this will simplify the loop below

// generation of DATA_A
genvar i, j;
generate
    for (i = 0; i < 32; i = i + 1) begin: gen
        for (j = 0; j < WIDTH; j = j + 1) begin: gen2
            assign DATA_A[i][j] = DATA_IN[j*32+i];
        end
    end
endgenerate

// selecting bits for DATA_OUT
generate
    for (i = 0; i < 32; i = i + 1) begin: gen3
        assign DATA_OUT[i] = |(DATA_A[i] & select);
    end
endgenerate

//assign DATA_OUT = DATA_A[select];
assign READ_GRANT = select & {WIDTH{READY_OUT}} & WRITE_REQ;

endmodule
