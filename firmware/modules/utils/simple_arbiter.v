/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

// 'base' is a one hot signal indicating the first request
// that should be considered for a grant.  Followed by higher
// indexed requests, then wrapping around.
// NOTE: Ff there is more than one request at time, 
//       this arbiter will finish all requests by the first request,
//       and then go on with higher indexed request request.

module arbiter (
    req, grant, base
);

parameter WIDTH = 16;

input wire [WIDTH-1:0] req;
output wire [WIDTH-1:0] grant;
input wire [WIDTH-1:0] base;

wire [2*WIDTH-1:0] double_req = {req,req};
wire [2*WIDTH-1:0] double_grant = double_req & ~(double_req-base);
assign grant = double_grant[WIDTH-1:0] | double_grant[2*WIDTH-1:WIDTH];

endmodule
