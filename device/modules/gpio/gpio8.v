
module gpio8
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
    input      [7:0]            BUS_DATA_IN;
    input                       BUS_RD;
    input                       BUS_WR;
    output     reg [7:0]        BUS_DATA_OUT;


    inout [7:0] IO;

    /////
    wire SOFT_RST; //0
    wire [7:0] INPUT_DATA; //1
    reg [7:0] OUTPUT_DATA; //2
    reg [7:0] DIRECTION; //3

    always@(*) begin
        if(BUS_ADD == 1)
            BUS_DATA_OUT = INPUT_DATA;
        else if(BUS_ADD == 2)
            BUS_DATA_OUT = OUTPUT_DATA;
        else if(BUS_ADD == 3)
            BUS_DATA_OUT = DIRECTION;
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
        end
        else if(BUS_WR) begin
            if(BUS_ADD == 2)
                OUTPUT_DATA <= BUS_DATA_IN; 
            else if(BUS_ADD == 3)
                DIRECTION <= BUS_DATA_IN; 
        end
    end

    genvar i;
    generate
        for(i=0; i<8; i=i+1) begin:sreggen
          assign IO[i] = DIRECTION[i] ? OUTPUT_DATA[i] : 1'bz;
        end
    endgenerate

    assign INPUT_DATA = IO;

endmodule
