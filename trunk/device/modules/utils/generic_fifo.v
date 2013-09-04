module gerneric_fifo ( clk, reset, write, read, data_in, 
                       full, empty, data_out, size);

parameter DATA_SIZE = 32;
parameter DEPTH = 8;
input clk, reset, write, read;
input [DATA_SIZE-1:0] data_in;

output full, empty;
reg empty;

output reg [DATA_SIZE-1:0] data_out;

  function integer log2;
    input integer value;
    reg [31:0] shifted;
    integer res;
  begin
    if (value < 2)
      log2 = value;
    else
    begin
      shifted = value-1;
      for (res=0; shifted>0; res=res+1)
        shifted = shifted>>1;
      log2 = res;
    end
  end
  endfunction
  
reg [DATA_SIZE:0] mem [DEPTH-1:0];   

localparam POINTER_SIZE = log2(DEPTH) ;//16;

reg [POINTER_SIZE-1:0] rd_ponter, wr_pointer;
output reg [POINTER_SIZE-1:0] size;

wire empty_loc;

always@(posedge clk) begin
    if(reset)
        rd_ponter <= 0;
    else if(read && !empty_loc) begin
        if(rd_ponter == DEPTH-1)
            rd_ponter <= 0;
        else
            rd_ponter <= rd_ponter + 1;
    end
end

always@(posedge clk) begin
    if(reset)
        wr_pointer <= 0;
    else if(write && !full) begin
        if(wr_pointer == DEPTH-1)
            wr_pointer <= 0;
        else
            wr_pointer <= wr_pointer + 1;
    end
end

always@(posedge clk)
    if(read && !empty_loc)
        if(rd_ponter == DEPTH-1)
            empty <= (wr_pointer == 0);
        else
            empty <= (wr_pointer == rd_ponter+1);
    else
        empty <= empty_loc;

    
assign empty_loc = (wr_pointer == rd_ponter);
assign full = ((wr_pointer==(DEPTH-1) && rd_ponter==0) ||  (wr_pointer!=(DEPTH-1) && wr_pointer+1 == rd_ponter) );

always@(posedge clk)
    if(write && !full)
        mem[wr_pointer] <= data_in;
    
always@(posedge clk)
    //if(read && !empty)
        data_out <= mem[rd_ponter];
        
always @ (*) begin
    if(wr_pointer >= rd_ponter)
        size = wr_pointer - rd_ponter;
    else
        size = wr_pointer + (DEPTH-rd_ponter); 
end		

        
endmodule