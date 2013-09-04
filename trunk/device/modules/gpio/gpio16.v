
module gpio16
(
  BUS_CLK, 
  BUS_RST,
  
  BUS_ADD,                    
  BUS_DATA_IN,                    
  BUS_RD,                    
  BUS_WR,                    
  BUS_DATA_OUT,  
  
  IO
  
); 


    input                       BUS_CLK;
    input                       BUS_RST;
    input      [15:0]           BUS_ADD;
    input      [7:0]           	BUS_DATA_IN;
    input      					BUS_RD;
    input      					BUS_WR;
    output     reg [7:0]        BUS_DATA_OUT;


    inout reg [15:0] IO;

    /////
    wire SOFT_RST; //0
    reg [15:0] DIRECTION; //1 - 2 -3
    reg [15:0] OUTPUT_DATA;
    reg [15:0] INPUT_DATA;

    always@(*) begin

        if(BUS_ADD == 18
            BUS_DATA_OUT = INPUT_DATA[15:7];
        else if(BUS_ADD == 2)
            BUS_DATA_OUT = INPUT_DATA[7:0];
            
        else if(BUS_ADD == 3)
            BUS_DATA_OUT = OUTPUT_DATA[15:8];
        else if(BUS_ADD == 4)
            BUS_DATA_OUT = OUTPUT_DATA[7:0];
        
        else if(BUS_ADD == 5)
            BUS_DATA_OUT = DIRECTION[15:8];
        else if(BUS_ADD == 6)
            BUS_DATA_OUT = DIRECTION[7:0];
            
        else
            BUS_DATA_OUT = 0;
    end

    assign SOFT_RST = (BUS_ADD==0 && BUS_WR);  

    wire RST;
    assign RST = BUS_RST | SOFT_RST;

    always @(posedge BUS_CLK) begin
        if(RST) begin
            DIRECTION <= 0;
            OUTPUT_DATA <= 0;
            INPUT_DATA <= 0;
        end
        else if(BUS_WR) begin
            if(BUS_ADD == 3)
                OUTPUT_DATA[15:8] <= BUS_DATA_IN; 
            else if(BUS_ADD == 4)
                OUTPUT_DATA[7:0] <= BUS_DATA_IN; 
            else if(BUS_ADD == 5)
                DIRECTION[15:8] <= BUS_DATA_IN; 
            else if(BUS_ADD == 6)
                DIRECTION[7:0] <= BUS_DATA_IN;
        end
    end

    always @(*) begin
        for(i=0;i<16;i=i+1)
            IO[i] = DIRECTION[i] ? OUTPUT_DATA[i] : 1'bz;
    end

    assign INPUT_DATA = IO;

endmodule
