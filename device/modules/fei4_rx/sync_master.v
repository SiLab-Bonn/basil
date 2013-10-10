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
`timescale 1 ps / 1ps
`default_nettype none

module sync_master(
input wire          clk,                // clock input
input wire          clk90,                // clock 90 input
input wire          datain,                // data inputs
input wire          rst,                // reset input
output wire         useaout,            // useA output for cascade
output wire         usebout,            // useB output for cascade
output wire         usecout,            // useC output for cascade
output wire         usedout,            // useD output for cascade
output wire [1:0]   ctrlout,            // ctrl outputs for cascade
output reg          sdataout );            // data out

wire         aa0 ;
wire         bb0 ;
wire         cc0 ;
wire         dd0 ;
reg         usea ;
reg         useb ;
reg         usec ;
reg         used ;
reg         useaint ;
reg         usebint ;
reg         usecint ;
reg         usedint ;
reg     [1:0]     ctrlint;
wire        sdataa ;
wire        sdatab ;
wire        sdatac ;
wire        sdatad ;
wire     [1:0]     az ;
wire     [1:0]     bz ;
wire     [1:0]     cz ;
wire     [1:0]     dz ;
reg         aap, bbp, ccp, ddp, az2, bz2, cz2, dz2 ;
reg         aan, bbn, ccn, ddn ;
reg         pipe_ce0 ;
wire         notclk ;
wire         notclk90 ;

assign notclk = ~clk ;
assign notclk90 = ~clk90 ;
assign useaout = useaint ;
assign usebout = usebint ;
assign usecout = usecint ;
assign usedout = usedint ;
assign ctrlout = ctrlint ;
assign sdataa = {(aa0 && useaint)} ;
assign sdatab = {(bb0 && usebint)} ;
assign sdatac = {(cc0 && usecint)} ;
assign sdatad = {(dd0 && usedint)} ;

SRL16 saa0(.D(az2), .CLK(clk), .A0(ctrlint[0]), .A1(ctrlint[1]), .A2(1'b0), .A3(1'b0), .Q(aa0));
SRL16 sbb0(.D(bz2), .CLK(clk), .A0(ctrlint[0]), .A1(ctrlint[1]), .A2(1'b0), .A3(1'b0), .Q(bb0));
SRL16 scc0(.D(cz2), .CLK(clk), .A0(ctrlint[0]), .A1(ctrlint[1]), .A2(1'b0), .A3(1'b0), .Q(cc0));
SRL16 sdd0(.D(dz2), .CLK(clk), .A0(ctrlint[0]), .A1(ctrlint[1]), .A2(1'b0), .A3(1'b0), .Q(dd0));

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        ctrlint <= 2'b10 ;
        useaint <= 1'b0 ; usebint <= 1'b0 ; usecint <= 1'b0 ; usedint <= 1'b0 ;
        usea <= 1'b0 ; useb <= 1'b0 ; usec <= 1'b0 ; used <= 1'b0 ;
        pipe_ce0 <= 1'b0 ; sdataout <= 1'b1 ;
        aap <= 1'b0 ; bbp <= 1'b0 ; ccp <= 1'b0 ; ddp <= 1'b0 ;
        aan <= 1'b0 ; bbn <= 1'b0 ; ccn <= 1'b0 ; ddn <= 1'b0 ;
        az2 <= 1'b0 ; bz2 <= 1'b0 ; cz2 <= 1'b0 ; dz2 <= 1'b0 ;
    end
    else begin
        az2 <= az[1] ; bz2 <= bz[1] ; cz2 <= cz[1] ; dz2 <= dz[1] ;
        aap <= (az ^ az[1]) & ~az[1] ;        // find positive edges
        bbp <= (bz ^ bz[1]) & ~bz[1] ;
        ccp <= (cz ^ cz[1]) & ~cz[1] ;
        ddp <= (dz ^ dz[1]) & ~dz[1] ;
        aan <= (az ^ az[1]) & az[1] ;        // find negative edges
        bbn <= (bz ^ bz[1]) & bz[1] ;
        ccn <= (cz ^ cz[1]) & cz[1] ;
        ddn <= (dz ^ dz[1]) & dz[1] ;
        // aap <= (az[1] ^ az2) & ~az2;    // find positive edges
        // bbp <= (bz[1] ^ bz2) & ~bz2;
        // ccp <= (cz[1] ^ cz2) & ~cz2;
        // ddp <= (dz[1] ^ dz2) & ~dz2;
        // aan <= (az[1] ^ az2) & az2;        // find negative edges
        // bbn <= (bz[1] ^ bz2) & bz2;
        // ccn <= (cz[1] ^ cz2) & cz2;
        // ddn <= (dz[1] ^ dz2) & dz2;
        usea <= (bbp & ~ccp & ~ddp & aap) | (bbn & ~ccn & ~ddn & aan) ;
        useb <= (ccp & ~ddp & aap & bbp) | (ccn & ~ddn & aan & bbn) ;
        usec <= (ddp & aap & bbp & ccp) | (ddn & aan & bbn & ccn) ;
        used <= (aap & ~bbp & ~ccp & ~ddp) | (aan & ~bbn & ~ccn & ~ddn) ;
        if (usea | useb | usec | used) begin
            pipe_ce0 <= 1'b1 ;
            useaint <= usea ;
            usebint <= useb ;
            usecint <= usec ;
            usedint <= used ;
        end
        if (pipe_ce0)
            sdataout <= sdataa | sdatab | sdatac | sdatad ;

        if (usedint & usea)              // 'd' going to 'a'
            ctrlint <= ctrlint - 1 ;
        else if (useaint & used)          // 'a' going to 'd'
            ctrlint <= ctrlint + 1 ;

    end
end

// get all the samples into the same time domain

FDC ff_az0(.D(datain), .C(clk), .CLR(rst), .Q(az[0]))/*synthesis rloc = "x0y0" */;
FDC ff_az1(.D(az[0]),     .C(clk), .CLR(rst), .Q(az[1]))/*synthesis rloc = "x2y0" */;

FDC ff_bz0(.D(datain), .C(clk90), .CLR(rst), .Q(bz[0]))/*synthesis rloc = "x1y0" */;
FDC ff_bz1(.D(bz[0]),     .C(clk), .CLR(rst), .Q(bz[1]))/*synthesis rloc = "x4y0" */;

FDC ff_cz0(.D(datain), .C(notclk), .CLR(rst), .Q(cz[0]))/*synthesis rloc = "x1y1" */;
FDC ff_cz1(.D(cz[0]),     .C(clk), .CLR(rst), .Q(cz[1]))/*synthesis rloc = "x2y0" */;

FDC ff_dz0(.D(datain), .C(notclk90), .CLR(rst), .Q(dz[0]))/*synthesis rloc = "x0y1" */;
FDC ff_dz1(.D(dz[0]),     .C(clk90), .CLR(rst), .Q(dz[1]))/*synthesis rloc = "x3y0" */;

endmodule
