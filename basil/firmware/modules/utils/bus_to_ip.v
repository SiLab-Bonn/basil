/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module bus_to_ip
#(
    parameter BASEADDR = 0,
    parameter HIGHADDR = 0,
    parameter ABUSWIDTH = 16,
    parameter DBUSWIDTH = 8
)
(
    input wire BUS_CLK,
    input wire BUS_RD,
    input wire BUS_WR,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    inout wire [DBUSWIDTH-1:0] BUS_DATA,

    output wire IP_RD,
    output reg IP_WR,
    output wire [ABUSWIDTH-1:0] IP_ADD,
    output reg [DBUSWIDTH-1:0] IP_DATA_IN,
    input wire [DBUSWIDTH-1:0] IP_DATA_OUT
);

wire CS;
assign CS = (BUS_ADD >= BASEADDR && BUS_ADD <= HIGHADDR);
reg [ABUSWIDTH-1:0] IP_ADD_BUF;
assign IP_ADD = IP_WR ? IP_ADD_BUF : (BUS_ADD - BASEADDR);
assign IP_RD = CS ? BUS_RD : 1'b0;

always @(posedge BUS_CLK) begin
    IP_ADD_BUF <= BUS_ADD - BASEADDR;
end

always @(posedge BUS_CLK) begin
    if (CS) begin
        IP_WR <= BUS_WR;
    end else begin
        IP_WR <= 1'b0;
    end
end

always @(posedge BUS_CLK) begin
    IP_DATA_IN <= BUS_DATA;
end

assign BUS_DATA = (CS && BUS_WR) ? {DBUSWIDTH{1'bz}} : (CS ? IP_DATA_OUT : {DBUSWIDTH{1'bz}});

endmodule
