/**
 * ------------------------------------------------------------
 * Copyright (c) SILAB , Physics Institute of Bonn University 
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev::                       $:
 *  $Author::                    $: 
 *  $Date::                      $:
 */
 
module rrp_arbiter 
#(
    parameter WIDTH = 4,
    parameter PRIORITY = 0
)
(
    input RST,
    input CLK,
    
    input [WIDTH-1:0] WRITE_REQ,
    input [WIDTH-1:0] HOLD_REQ,
    input [WIDTH*32-1:0] DATA_IN,
    output [WIDTH-1:0] READ_GRANT,

    input READY_OUT,
    output WRITE_OUT,
    output [31:0] DATA_OUT
    
);

`include "../includes/log2func.v"

assign WRITE_OUT = |WRITE_REQ && !(|HOLD_REQ);

localparam SEL_SIZE = log2(WIDTH);

integer m;
reg [SEL_SIZE-1:0] prev_select;
reg [SEL_SIZE-1:0] select;

wire [WIDTH-1:0] PRIORITY_WRITE_REQ;
assign PRIORITY_WRITE_REQ = PRIORITY & WRITE_REQ;

reg normal_mode;
reg hold;

always@(*) begin
    normal_mode = 0;
    select = 0;
    if( |HOLD_REQ && !hold) begin       
        m = 0;
        select = m;
        while(!HOLD_REQ[select] && (m < WIDTH)) begin
            m = m + 1;
            select = m;
        end 
    end
    else if( |PRIORITY_WRITE_REQ && !hold ) begin
        m = 0;
        select = m;
        while(!PRIORITY_WRITE_REQ[select] && (m < WIDTH)) begin
            m = m+1;
            select = m;
        end 
    end
    else if( |WRITE_REQ ) begin
        normal_mode = 1;
        
        if(hold == 0) begin
                m = 0;
                select = prev_select + 1;
                while(WRITE_REQ[select] != 1 && (m < WIDTH)) begin
                    m = m + 1;
                    select = select + 1;
                end
        end
        else
             select = prev_select;
    end
end

always@(posedge CLK) begin
    if(RST)
        prev_select <= -1;
    else if ( normal_mode & !hold)
        prev_select <= select;
end

always@(posedge CLK) begin
    if(RST)
        hold <= 0;
    else if( READY_OUT )
        hold <= 0;
    else if ( normal_mode || |PRIORITY_WRITE_REQ || |(HOLD_REQ & WRITE_REQ) )
        hold <= 1;
end


wire [31:0] DATA_A [WIDTH-1:0];

genvar i;
generate
  for (i = 0; i < WIDTH; i = i + 1) begin: gen
    assign DATA_A[i] = DATA_IN[(i+1)*32-1:i*32];
  end
endgenerate

assign DATA_OUT = DATA_A[select];
assign READ_GRANT = 1<<select & {WIDTH{READY_OUT}};
 
endmodule
