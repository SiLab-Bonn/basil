/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev::                       $:
 *  $Author::                    $:
 *  $Date::                      $:
 */

`default_nettype none

module gpio
#(
    parameter BASEADDR = 0,
    parameter HIGHADDR = 0,
    parameter ABUSWIDTH = 16,
    parameter IO_WIDTH = 8,
    parameter IO_DIRECTION = 0,
    parameter IO_TRI = 0
)(
    BUS_CLK, 
    BUS_RST,
    BUS_ADD,
    BUS_DATA,
    BUS_RD,
    BUS_WR,

    IO
);

// ORDER:
// 0 - RESET
// 1 - INPUT
// 2 - OUTPUT
// 3 - DIRECTION

input wire                  BUS_CLK;
input wire                  BUS_RST;
input wire [ABUSWIDTH-1:0]  BUS_ADD;
inout wire [7:0]            BUS_DATA;
input wire                  BUS_RD;
input wire                  BUS_WR;
inout wire [IO_WIDTH-1:0]   IO;

wire IP_RD, IP_WR;
wire [ABUSWIDTH-1:0] IP_ADD;
wire [7:0] IP_DATA_IN;
reg [7:0] IP_DATA_OUT;

bus_to_ip #( .BASEADDR(BASEADDR), .HIGHADDR(HIGHADDR), .ABUSWIDTH(ABUSWIDTH) ) i_bus_to_ip
(
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),

    .IP_RD(IP_RD),
    .IP_WR(IP_WR),
    .IP_ADD(IP_ADD),
    .IP_DATA_IN(IP_DATA_IN),
    .IP_DATA_OUT(IP_DATA_OUT) 
);

// CORE //
wire SOFT_RST; //0

localparam IO_BYTES = ((IO_WIDTH-1)/8)+1;

reg [7:0] INPUT_DATA [IO_BYTES-1:0];
reg [7:0] OUTPUT_DATA [IO_BYTES-1:0]; //2
reg [7:0] DIRECTION_DATA [IO_BYTES-1:0]; //3

localparam VERSION = 0;

always @ (posedge BUS_CLK) begin
    if(IP_ADD == 0)
        IP_DATA_OUT <= VERSION;
    else if(IP_ADD - 1 < IO_BYTES)
        IP_DATA_OUT <= INPUT_DATA[IP_ADD - 1];
    else if(IP_ADD - (IO_BYTES+1) < IO_BYTES)
        IP_DATA_OUT <= OUTPUT_DATA[IP_ADD - (IO_BYTES+1)];
    else if(IP_ADD - (IO_BYTES*2+1) < IO_BYTES)
        IP_DATA_OUT <= DIRECTION_DATA[IP_ADD - (IO_BYTES*2+1)];
    else
        IP_DATA_OUT <= 8'b0;
end

assign SOFT_RST = (IP_ADD==0 && IP_WR);  

wire RST;
assign RST = BUS_RST | SOFT_RST;

integer bi;
always @(posedge BUS_CLK) begin
    if(RST) begin
        for(bi = 0; bi < IO_BYTES; bi = bi + 1) begin
            DIRECTION_DATA[bi] <= 0;
            OUTPUT_DATA[bi] <= 0;
        end
    end
    else if(IP_WR) begin
        if(IP_ADD - 1 < IO_BYTES)
            ;
        else if(IP_ADD - (IO_BYTES+1) < IO_BYTES)
            OUTPUT_DATA[IP_ADD - (IO_BYTES+1)] <= IP_DATA_IN;
        else if(IP_ADD - (IO_BYTES*2+1) < IO_BYTES)
            DIRECTION_DATA[IP_ADD - (IO_BYTES*2+1)] <= IP_DATA_IN;
    end
end


genvar i;
generate
    for(i=0; i<IO_WIDTH; i=i+1) begin: sreggen
    if(IO_TRI[i])
        assign IO[i] = DIRECTION_DATA[i/8][i%8] ? OUTPUT_DATA[i/8][i%8] : 1'bz;
    else if(IO_DIRECTION[i])
        assign IO[i] = OUTPUT_DATA[i/8][i%8];
    end
endgenerate

always @ (*)
    for(bi = 0; bi < IO_WIDTH; bi = bi + 1)
        INPUT_DATA[bi/8][bi%8] = IO[bi];


endmodule
