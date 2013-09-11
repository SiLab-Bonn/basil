
module gpio8
#(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000
)
(
  BUS_CLK, 
  BUS_RST,
  BUS_ADD,                    
  BUS_DATA,                    
  BUS_RD,                    
  BUS_WR,                    

  IO
); 

    input           BUS_CLK;
    input           BUS_RST;
    input   [15:0]  BUS_ADD;
    output  [7:0]   BUS_DATA;
    input           BUS_RD;
    input           BUS_WR;
    inout   [7:0]   IO;
        
    reg     [7:0]   IP_DATA;

    bus_to_ip #( .BASEADDR(BASEADDR), .HIGHADDR(HIGHADDR) ) ibus_to_ip
    (
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        
        .IP_RD(IP_RD),
        .IP_WR(IP_WR),
        .IP_ADD(IP_ADD),
        .IP_DATA(IP_DATA) 
    );

    /////
    wire SOFT_RST; //0
    wire [7:0] INPUT_DATA; //1
    reg [7:0] OUTPUT_DATA; //2
    reg [7:0] DIRECTION; //3

    always@(posedge BUS_CLK) begin
        if(BUS_WR) begin
            if(IP_ADD == 1)
                IP_DATA <= INPUT_DATA;
            else if(IP_ADD == 2)
                IP_DATA <= OUTPUT_DATA;
            else if(IP_ADD == 3)
                IP_DATA <= DIRECTION;
        end
    end

    assign SOFT_RST = (IP_ADD==0 && IP_WR);  

    wire RST;
    assign RST = BUS_RST | SOFT_RST;

    always @(posedge BUS_CLK) begin
        if(RST) begin
            DIRECTION <= 0;
            OUTPUT_DATA <= 0;
        end
        else if(IP_WR) begin
            if(IP_ADD == 2)
                OUTPUT_DATA <= BUS_DATA; 
            else if(IP_ADD == 3)
                DIRECTION <= BUS_DATA; 
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
