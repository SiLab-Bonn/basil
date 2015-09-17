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
 
module SiLibUSB (input FCLK);

  reg         RD_B;
  reg         WR_B;
  tri         [7:0] DATA;
  reg         [15:0] ADD;
  
  reg FREAD;
  reg FSTROBE;
  reg FMODE;
  tri [7:0] FD;
  
  reg [7:0] DATA_T;
  assign DATA = ~WR_B ? DATA_T : 8'bzzzz_zzzz;
  initial begin
    RD_B = 1;
    WR_B = 1;
    ADD = 0;
    FREAD = 0;
    FSTROBE = 0;
    FMODE = 0;
        
  end  
  
    task ReadExternal;
        input [15:0]  ADDIN;
        output [7:0]  DATAOUT;
        begin
            RD_B = 1;
            ADD = 16'hxxxx;
            repeat (5)
                @(posedge FCLK);

            @(posedge FCLK);
            ADD = ADDIN + 16'h4000;
            @(posedge FCLK);
            RD_B = 0;
            @(posedge FCLK);
            RD_B = 0;
            @(posedge FCLK);
            DATAOUT = DATA;
            RD_B = 1;
            @(posedge FCLK);
            RD_B = 1;
            ADD = 16'hxxxx;
            repeat (5)
                @(posedge FCLK);

        end
    endtask

    task WriteExternal;
        input [15:0]  ADDIN;
        input [7:0]  DATAIN;
        begin
            WR_B = 1;
            ADD = 16'hxxxx;
            DATA_T = 16'hxxxx;
            repeat (5)
                @(posedge FCLK);

            @(posedge FCLK);
            ADD = ADDIN + 16'h4000;
            DATA_T = DATAIN;
            @(posedge FCLK);
            WR_B = 0;
            @(posedge FCLK);
            WR_B = 0;
            @(posedge FCLK);
            WR_B = 1;
            @(posedge FCLK);
            WR_B = 1;
            ADD = 16'hxxxx;
            DATA_T = 16'hxxxx;   
            repeat (5)
                @(posedge FCLK);

        end
    endtask

    task FastBlockRead;
        output [7:0]  DATAOUT;
        begin
            @(posedge FCLK);
            @(posedge FCLK); #1 FREAD <= 1; FSTROBE <= 1;
            @(posedge FCLK)
                DATAOUT <= FD;
             #1 FREAD <= 0; FSTROBE = 0;
             @(posedge FCLK);
        end
    endtask	
    
endmodule
    
 