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
 
module gpac_adc_iobuf
(   
    input ADC_DCO_P, ADC_DCO_N,
    output ADC_DCO,
    
    input ADC_FCO_P, ADC_FCO_N,
    output ADC_FCO,
    
    input ADC_ENC, 
    output ADC_ENC_P, ADC_ENC_N,
    
    input [3:0] ADC_IN_P, ADC_IN_N,
    output [3:0] ADC_IN
); 

    // I/O BUFFERS
    
    IBUFDS
    #(
       .DIFF_TERM("TRUE"),    // Differential Termination 
       .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
    ) IBUFGDS_ADC_FCO (
       .O(ADC_FCO),  // Clock buffer output
       .I(ADC_FCO_P),  // Diff_p clock buffer input (connect directly to top-level port)
       .IB(ADC_FCO_N) // Diff_n clock buffer input (connect directly to top-level port)
    );
    
    
    IBUFGDS     // Specify the input I/O standard
    #(
        .DIFF_TERM("TRUE"),    // Differential Termination 
        .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
    )
    IBUFDS_ADC_DCO (
      .O(ADC_DCO),  // Buffer output
      .I(ADC_DCO_P),  // Diff_p buffer input (connect directly to top-level port)
      .IB(ADC_DCO_N) // Diff_n buffer input (connect directly to top-level port)
    );
    //BUFG ADC_BUFG_INST (.I(ADC_FCO_PB), .O(ADC_FCO)); 
    
    OBUFDS #(
        .IOSTANDARD("LVDS_25") // Specify the output I/O standard
    ) OBUFDS_ADC_ENC (
        .O(ADC_ENC_P),     // Diff_p output (connect directly to top-level port)
        .OB(ADC_ENC_N),   // Diff_n output (connect directly to top-level port)
        .I(ADC_ENC)      // Buffer input 
   );
   
    IBUFDS
    #(
        .DIFF_TERM("TRUE"),    // Differential Termination 
        .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
    ) IBUFGDS_ADC_OUT_0 (
        .O(ADC_IN[0]),  // Clock buffer output
        .I(ADC_IN_P[0]),  // Diff_p clock buffer input (connect directly to top-level port)
        .IB(ADC_IN_N[0]) // Diff_n clock buffer input (connect directly to top-level port)
    );
    
    IBUFDS
    #(
        .DIFF_TERM("TRUE"),    // Differential Termination 
        .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
    ) IBUFGDS_ADC_OUT_1 (
        .O(ADC_IN[1]),  // Clock buffer output
        .I(ADC_IN_P[1]),  // Diff_p clock buffer input (connect directly to top-level port)
        .IB(ADC_IN_N[1]) // Diff_n clock buffer input (connect directly to top-level port)
    );
    
    IBUFDS
    #(
        .DIFF_TERM("TRUE"),    // Differential Termination 
        .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
    ) IBUFGDS_ADC_OUT_2 (
        .O(ADC_IN[2]),  // Clock buffer output
        .I(ADC_IN_P[2]),  // Diff_p clock buffer input (connect directly to top-level port)
        .IB(ADC_IN_N[2]) // Diff_n clock buffer input (connect directly to top-level port)
    );
    
    IBUFDS
    #(
        .DIFF_TERM("TRUE"),    // Differential Termination 
        .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
    ) IBUFGDS_ADC_OUT_3 (
        .O(ADC_IN[3]),  // Clock buffer output
        .I(ADC_IN_P[3]),  // Diff_p clock buffer input (connect directly to top-level port)
        .IB(ADC_IN_N[3]) // Diff_n clock buffer input (connect directly to top-level port)
    );

endmodule
