/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none
 

module cdc_syncfifo #(
    parameter DSIZE = 34,
    parameter ASIZE = 2
) (
    output wire [DSIZE-1:0] rdata,
    output wire wfull,
    output wire rempty,
    input wire [DSIZE-1:0] wdata,
    input wire winc, wclk, wrst,
    input wire rinc, rclk, rrst
);
    
wire [ASIZE-1:0] waddr, raddr;
wire [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;

cdc_sync_r2w #(.ADDRSIZE(ASIZE)) sync_r2w_inst (.wq2_rptr(wq2_rptr), .rptr(rptr),
    .wclk(wclk), .wrst(wrst));

cdc_sync_w2r #(.ADDRSIZE(ASIZE)) sync_w2r_inst (.rq2_wptr(rq2_wptr), .wptr(wptr),
    .rclk(rclk), .rrst(rrst));

cdc_fifomem #(.DATASIZE(DSIZE), .ADDRSIZE(ASIZE)) cdc_fifomem_inst
(.rdata(rdata), .wdata(wdata),
    .waddr(waddr), .raddr(raddr),
    .wclken(winc), .wfull(wfull),
    .wclk(wclk));

rptr_empty #(.ADDRSIZE(ASIZE)) rptr_empty_inst
(.rempty(rempty),
    .raddr(raddr),
    .rptr(rptr), .rq2_wptr(rq2_wptr),
    .rinc(rinc), .rclk(rclk),
    .rrst(rrst));

wptr_full #(.ADDRSIZE(ASIZE)) wptr_full_inst
(.wfull(wfull), .waddr(waddr),
    .wptr(wptr), .wq2_rptr(wq2_rptr),
    .winc(winc), .wclk(wclk),
    .wrst(wrst));

endmodule

module cdc_fifomem #(
parameter DATASIZE = 34, // Memory data word widt
    parameter ADDRSIZE = 2 // Number of mem address
) (
    output wire [DATASIZE-1:0] rdata,
    input wire [DATASIZE-1:0] wdata,
    input wire [ADDRSIZE-1:0] waddr, raddr,
    input wire wclken, wfull, wclk
);
        
        
//`ifdef VENDORRAM
//
//    // instantiation of a vendor's dual-port RAM
//    vendor_ram mem (.dout(rdata), .din(wdata),
//        .waddr(waddr), .raddr(raddr),
//        .wclken(wclken),
//        .wclken_n(wfull), .clk(wclk));
//`else

// RTL Verilog memory model
localparam DEPTH = 1<<ADDRSIZE;
reg [DATASIZE-1:0] cdc_mem [0:DEPTH-1];


assign rdata = cdc_mem[raddr];
//always @(posedge wclk)
//	rdata <= mem[raddr];
    
always @(posedge wclk)
    if (wclken && !wfull) cdc_mem[waddr] <= wdata;
        
//`endif

endmodule



module rptr_empty #(
    parameter ADDRSIZE = 2
) (
    output reg rempty,
    output wire [ADDRSIZE-1:0] raddr,
    output reg [ADDRSIZE :0] rptr,
    input wire [ADDRSIZE :0] rq2_wptr,
    input wire rinc, rclk, rrst
);
    
reg [ADDRSIZE:0] rbin;
wire [ADDRSIZE:0] rgraynext, rbinnext;
//-------------------
// GRAYSTYLE2 pointer
//-------------------
//synopsys sync_set_reset "rrst"
always @(posedge rclk)
    if (rrst) {rbin, rptr} <= 0;
    else {rbin, rptr} <= {rbinnext, rgraynext};
    
// Memory read-address pointer (okay to use binary to address memory)
assign raddr = rbin[ADDRSIZE-1:0];
assign rbinnext = rbin + (rinc & ~rempty);
assign rgraynext = (rbinnext>>1) ^ rbinnext;
//---------------------------------------------------------------
// FIFO empty when the next rptr == synchronized wptr or on reset
//---------------------------------------------------------------
wire rempty_val;
assign rempty_val = (rgraynext == rq2_wptr);
//synopsys sync_set_reset "rrst"
always @(posedge rclk)
    if (rrst) rempty <= 1'b1;
    else rempty <= rempty_val;
        
endmodule

module wptr_full #(
    parameter ADDRSIZE = 2
) (
    output reg wfull,
    output wire [ADDRSIZE-1:0] waddr,
    output reg [ADDRSIZE :0] wptr,
    input wire [ADDRSIZE :0] wq2_rptr,
    input wire winc, wclk, wrst
);

reg [ADDRSIZE:0] wbin;
wire [ADDRSIZE:0] wgraynext, wbinnext;
// GRAYSTYLE2 pointer
//synopsys sync_set_reset "wrst"
always @(posedge wclk)
    if (wrst) {wbin, wptr} <= 0;
    else {wbin, wptr} <= {wbinnext, wgraynext};
// Memory write-address pointer (okay to use binary to address memory)
assign waddr = wbin[ADDRSIZE-1:0];
assign wbinnext = wbin + (winc & ~wfull);
assign wgraynext = (wbinnext>>1) ^ wbinnext;
//------------------------------------------------------------------
// Simplified version of the three necessary full-tests:
// assign wfull_val=((wgnext[ADDRSIZE]    !=wq2_rptr[ADDRSIZE] ) &&
//                   (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
//                   (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
//------------------------------------------------------------------
wire wfull_val;
assign wfull_val = (wgraynext=={~wq2_rptr[ADDRSIZE:ADDRSIZE-1], wq2_rptr[ADDRSIZE-2:0]});
//synopsys sync_set_reset "wrst"
always @(posedge wclk)
    if (wrst) wfull <= 1'b0;
    else wfull <= wfull_val;
        
endmodule

module cdc_sync_r2w #(
    parameter ADDRSIZE = 2
) (
    output reg [ADDRSIZE:0] wq2_rptr,
    input wire [ADDRSIZE:0] rptr,
    input wire wclk, wrst
);

reg [ADDRSIZE:0] cdc_sync_wq1_rptr;
//synopsys sync_set_reset "wrst"
always @(posedge wclk)
    if (wrst) {wq2_rptr,cdc_sync_wq1_rptr} <= 0;
    else {wq2_rptr,cdc_sync_wq1_rptr} <= {cdc_sync_wq1_rptr,rptr};
        
endmodule

module cdc_sync_w2r #(
    parameter ADDRSIZE = 2
) (
    output reg [ADDRSIZE:0] rq2_wptr,
    input wire [ADDRSIZE:0] wptr,
    input wire rclk, rrst
);

reg [ADDRSIZE:0] cdc_sync_rq1_wptr;
//synopsys sync_set_reset "rrst"
always @(posedge rclk)
    if (rrst) {rq2_wptr,cdc_sync_rq1_wptr} <= 0;
    else {rq2_wptr,cdc_sync_rq1_wptr} <= {cdc_sync_rq1_wptr,wptr};

endmodule
