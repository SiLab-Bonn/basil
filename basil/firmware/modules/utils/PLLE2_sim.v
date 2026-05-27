`ifdef COCOTB_SIM
module PLLE2_sim (
    input  wire CLKIN1,
    output wire CLKOUT0,
    output wire CLKOUT1,
    output wire CLKOUT2,
    output wire CLKOUT3,
    output wire CLKOUT4,
    output wire CLKOUT5,
    output wire LOCKED
);
    // Simple behavioral model: forward input clock to all outputs and indicate locked
    assign CLKOUT0 = CLKIN1;
    assign CLKOUT1 = CLKIN1;
    assign CLKOUT2 = CLKIN1;
    assign CLKOUT3 = CLKIN1;
    assign CLKOUT4 = CLKIN1;
    assign CLKOUT5 = CLKIN1;
    assign LOCKED = 1'b1;
endmodule
`endif
