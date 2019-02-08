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
    input wire BUS_RD,
    input wire BUS_WR,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    inout wire [DBUSWIDTH-1:0] BUS_DATA,
    
    output wire IP_RD,
    output wire IP_WR,
    output wire [ABUSWIDTH-1:0] IP_ADD,    
    output wire [DBUSWIDTH-1:0] IP_DATA_IN,
    input wire [DBUSWIDTH-1:0] IP_DATA_OUT
);

wire CS;
assign CS = (BUS_ADD >= BASEADDR && BUS_ADD <= HIGHADDR);

assign IP_ADD = CS ? BUS_ADD - BASEADDR : {ABUSWIDTH{1'b0}};
assign IP_RD = CS ? BUS_RD : 1'b0;
assign IP_WR = CS ? BUS_WR: 1'b0;

assign IP_DATA_IN =  BUS_DATA;

//assign BUS_DATA = (CS && BUS_WR) ? {DBUSWIDTH{1'bz}} : (CS ? IP_DATA_OUT : {DBUSWIDTH{1'bz}});
// This is same as above but for Icarus + cocotb this change is needed, and yes, in one line, bug?
reg [DBUSWIDTH-1:0] TMP; always@(*) TMP = (CS & BUS_WR) ? {DBUSWIDTH{1'bz}} : (CS ? IP_DATA_OUT : {DBUSWIDTH{1'bz}}); assign BUS_DATA = TMP;

endmodule
