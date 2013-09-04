
module gen_seq
(
  BUS_CLK,                     
  BUS_RST,                  
  BUS_ADD,                    
  BUS_DATA_IN,                    
  BUS_RD,                    
  BUS_WR,                    
  BUS_DATA_OUT,  
  
  OUT_CLK,
  OUT_SEQ
); 


parameter OUT_LINES = 1;

input                       BUS_CLK;
input                       BUS_RST;
input      [15:0]           BUS_ADD;
input      [7:0]           	BUS_DATA_IN;
input      					BUS_RD;
input      					BUS_WR;
output     reg [7:0]        BUS_DATA_OUT;

output OUT_CLK;
output OUT_SEQ[7:0];


wire SOFT_RST; //0
wire START, CONF_FINISH; //1
wire CONF_EN_EXT_START, CONF_EN_CLOCK_GATE, CONF_EN_NEGEDGE_DATA, CONF_EN_EXT_NEGEDGE; //2
wire [15:0] CONF_CMD_SIZE; //3 - 4
wire [15:0] CONF_REPEAT_COUNT; //5 -6

reg [7:0] status_regs [7:0];  

//wire RST;
assign RST = BUS_RST || SOFT_RST;


always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 8'b0000_0010; //invert clock out
        status_regs[3] <= 0;
        status_regs[4] <= 0;
        status_regs[5] <= 8'd1; //repaet once
        status_regs[6] <= 0;
    end
    else if(BUS_WR && BUS_ADD < 8)
        status_regs[BUS_ADD[2:0]] <= BUS_DATA_IN;
end

assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign START = (BUS_ADD==1 && BUS_WR);

assign CONF_CMD_SIZE = {status_regs[4], status_regs[3]};
assign CONF_REPEAT_COUNT = {status_regs[6], status_regs[5]};
assign CONF_WAIT_COUNT  = {status_regs[8], status_regs[7]};
assign CONF_CLK_DEVIDE  = {status_regs[9]};

assign CONF_EN_CLOCK_GATE = status_regs[2][2];

assign CONF_EN_NEGEDGE_DATA = status_regs[2][1];
assign CONF_EN_EXT_NEGEDGE = status_regs[2][3];
assign CONF_EN_EXT_START = status_regs[2][0];


/////
(* RAM_STYLE="{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
reg [7:0] cmd_mem [2047:0];
always @(posedge BUS_CLK) begin
  if (BUS_WR && BUS_ADD >= 8)
        cmd_mem[BUS_ADD[10:0]-16] <= BUS_DATA_IN;
  
  if(BUS_ADD == 1)
    BUS_DATA_OUT <= {7'b0, CONF_FINISH};
  else if(BUS_ADD < 8)
    BUS_DATA_OUT <= status_regs[BUS_ADD[2:0]];
  else
    BUS_DATA_OUT <= cmd_mem[BUS_ADD[10:0]-16];

end


reg [7:0] OUT_MEM_DATA;
reg [10:0] OUT_MEM_ADD;
always @(posedge BUS_CLK)
     OUT_MEM_DATA <= cmd_mem[OUT_MEM_ADD];

///////

wire [15:0] out_cnt;
wire [15:0] wait_cnt;
wire [7:0] div_cnt;

reg [1:0] state, next_state;

localparam NOP = 1, SEND = 2, WAIT = 3;
 
always @ (posedge BUS_CLK)
    if (RST)
      state <= NOP;
    else
      state <= next_state; 

always @ (*) begin
    next_state = state;
    
    case(state)
        NOP : if(START)
                    next_state = SEND;
                else
                    next_state = WAIT;
                    
        SEND : if(out_cnt == CONF_CMD_SIZE) begin
                     if(CONF_WAIT_COUNT > 0)
                        next_state = WAIT;
                     else if(repeat_cnt==CONF_REPEAT_COUNT)
                        next_state = NOP;
                     else
                        next_state = SEND;
                end
                else
                    next_state = SEND;
                    
        WAIT :
            if(wait_cnt == CONF_WAIT_COUNT && repeat_cnt==CONF_REPEAT_COUNT)
                next_state = NOP;
            else if(wait_cnt == CONF_WAIT_COUNT && repeat_cnt!=CONF_REPEAT_COUNT)
                next_state = SEND;
            else
                next_state = WAIT;	
                
        default : next_state = NOP;
    endcase
end



endmodule	