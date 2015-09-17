/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none
 
module gpac_adc_iobuf
(   
    input ADC_CLK,
    
    input ADC_DCO_P, ADC_DCO_N,
    (* IOB="TRUE" *)
    output reg ADC_DCO,
    
    input ADC_FCO_P, ADC_FCO_N,
    (* IOB="TRUE" *)
    output reg ADC_FCO,
    
    (* IOB="TRUE" *)
    input ADC_ENC, 
    output ADC_ENC_P, ADC_ENC_N,
    
    input [3:0] ADC_IN_P, ADC_IN_N,
    
    output [13:0] ADC_IN0, ADC_IN1, ADC_IN2, ADC_IN3
); 

(* IOB="TRUE" *)
wire ADC_DCO_BUF;
(* IOB="TRUE" *)
wire ADC_FCO_BUF;
(* IOB="TRUE" *)
wire [3:0] ADC_IN_BUF;
(* IOB="TRUE" *)
wire ADC_ENC_BUF;
(* IOB="TRUE" *)
reg [3:0] ADC_IN;

// I/O BUFFERS

always@(negedge ADC_CLK)
    ADC_DCO <= ADC_DCO_BUF;

always@(negedge ADC_CLK)
    ADC_FCO <= ADC_FCO_BUF;
    
always@(negedge ADC_CLK)
    ADC_IN <= ADC_IN_BUF;
    
//always@(negedge ADC_CLK)
//    ADC_ENC_BUF <= ADC_ENC;
assign ADC_ENC_BUF = ADC_ENC;

IBUFDS
#(
   .DIFF_TERM("TRUE"),    // Differential Termination 
   .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
) IBUFGDS_ADC_FCO (
   .O(ADC_FCO_BUF),  // Clock buffer output
   .I(ADC_FCO_P),  // Diff_p clock buffer input (connect directly to top-level port)
   .IB(ADC_FCO_N) // Diff_n clock buffer input (connect directly to top-level port)
);


IBUFGDS     // Specify the input I/O standard
#(
    .DIFF_TERM("TRUE"),    // Differential Termination 
    .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
)
IBUFDS_ADC_DCO (
  .O(ADC_DCO_BUF),  // Buffer output
  .I(ADC_DCO_P),  // Diff_p buffer input (connect directly to top-level port)
  .IB(ADC_DCO_N) // Diff_n buffer input (connect directly to top-level port)
);
//BUFG ADC_BUFG_INST (.I(ADC_FCO_PB), .O(ADC_FCO)); 

OBUFDS #(
    .IOSTANDARD("LVDS_25") // Specify the output I/O standard
) OBUFDS_ADC_ENC (
    .O(ADC_ENC_P),     // Diff_p output (connect directly to top-level port)
    .OB(ADC_ENC_N),   // Diff_n output (connect directly to top-level port)
    .I(ADC_ENC_BUF)      // Buffer input 
);

IBUFDS
#(
    .DIFF_TERM("TRUE"),    // Differential Termination 
    .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
) IBUFGDS_ADC_OUT_0 (
    .O(ADC_IN_BUF[0]),  // Clock buffer output
    .I(ADC_IN_P[0]),  // Diff_p clock buffer input (connect directly to top-level port)
    .IB(ADC_IN_N[0]) // Diff_n clock buffer input (connect directly to top-level port)
);

IBUFDS
#(
    .DIFF_TERM("TRUE"),    // Differential Termination 
    .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
) IBUFGDS_ADC_OUT_1 (
    .O(ADC_IN_BUF[1]),  // Clock buffer output
    .I(ADC_IN_P[1]),  // Diff_p clock buffer input (connect directly to top-level port)
    .IB(ADC_IN_N[1]) // Diff_n clock buffer input (connect directly to top-level port)
);

IBUFDS
#(
    .DIFF_TERM("TRUE"),    // Differential Termination 
    .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
) IBUFGDS_ADC_OUT_2 (
    .O(ADC_IN_BUF[2]),  // Clock buffer output
    .I(ADC_IN_P[2]),  // Diff_p clock buffer input (connect directly to top-level port)
    .IB(ADC_IN_N[2]) // Diff_n clock buffer input (connect directly to top-level port)
);

IBUFDS
#(
    .DIFF_TERM("TRUE"),    // Differential Termination 
    .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
) IBUFGDS_ADC_OUT_3 (
    .O(ADC_IN_BUF[3]),  // Clock buffer output
    .I(ADC_IN_P[3]),  // Diff_p clock buffer input (connect directly to top-level port)
    .IB(ADC_IN_N[3]) // Diff_n clock buffer input (connect directly to top-level port)
);


reg [1:0] fco_sync;
always@(negedge ADC_CLK) begin
    fco_sync <= {fco_sync[0],ADC_FCO};
end

wire adc_des_rst;
assign adc_des_rst = fco_sync[0] & !fco_sync[1] ;

reg [15:0] adc_des_cnt;
always@(negedge ADC_CLK) begin
    if(adc_des_rst)
        adc_des_cnt[0] <= 1;
    else
        adc_des_cnt <= {adc_des_cnt[14:0],1'b0};
end

wire adc_load;
assign adc_load = adc_des_cnt[12];

reg [13:0] adc_out_sync [3:0];

genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin: gen
        reg [13:0] adc_des;
        always@(negedge ADC_CLK) begin
            adc_des <= {adc_des[12:0],ADC_IN[i]};
        end
        
        reg [13:0] adc_des_syn;
        always@(negedge ADC_CLK) begin
            if(adc_load)
                adc_des_syn <= adc_des;
        end

        always@(posedge ADC_ENC)
            adc_out_sync[i] <= adc_des_syn;            

    end
endgenerate


assign ADC_IN0 = adc_out_sync[0];
assign ADC_IN1 = adc_out_sync[1];
assign ADC_IN2 = adc_out_sync[2];
assign ADC_IN3 = adc_out_sync[3];

`ifdef SYNTHESIS_
    wire [35:0] control_bus;
    chipscope_icon ichipscope_icon
    (
        .CONTROL0(control_bus)
    ); 

    chipscope_ila ichipscope_ila 
    (
        .CONTROL(control_bus),
        .CLK(ADC_CLK), 
        .TRIG0({ADC_IN0, adc_load, adc_des_rst, fco_sync, ADC_IN[0]})
    ); 
`endif

endmodule
