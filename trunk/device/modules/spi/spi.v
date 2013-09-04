
module spi
(
  BUS_CLK,                     
  BUS_RST,                  
  BUS_ADD,                    
  BUS_DATA_IN,                    
  BUS_RD,                    
  BUS_WR,                    
  BUS_DATA_OUT,  
  
  SPI_CLK,
  
  SCLK,
  SDI,
  SDO,
  
  SEN,
  SLD
 
); 

parameter MEM_BYTES = 2;

input                       BUS_CLK;
input                       BUS_RST;
input      [15:0]           BUS_ADD;
input      [7:0]           	BUS_DATA_IN;
input      					BUS_RD;
input      					BUS_WR;
output     reg [7:0]        BUS_DATA_OUT;

input SPI_CLK;

output SCLK;
input SDO;
output reg SDI;

output reg SEN; 
output reg SLD;

reg [7:0] status_regs [8+MEM_BYTES*2-1:0];  

wire RST;
wire SOFT_RST;

assign RST = BUS_RST || SOFT_RST;

localparam DEF_BIT_OUT = 8*MEM_BYTES;

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 0;
        status_regs[3] <= DEF_BIT_OUT[15:8]; //bits
        status_regs[4] <= DEF_BIT_OUT[7:0]; //bits
        status_regs[5] <= 0; //wait
        status_regs[6] <= 0; //wait
        status_regs[7] <= 1; // 7  repeat
    end
    else if(BUS_WR && BUS_ADD < 8)
        status_regs[BUS_ADD[2:0]] <= BUS_DATA_IN;
end

reg [7:0] BUS_IN_MEM;
reg [7:0] BUS_OUT_MEM;

// 1 - finished

wire START;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign START = (BUS_ADD==1 && BUS_WR);

wire [15:0] CONF_BIT_OUT;
assign CONF_BIT_OUT = {status_regs[3],status_regs[4]};

wire [7:0] CONF_CLK_DIV;
assign CONF_CLK_DIV = status_regs[2];
reg CONF_DONE;

wire [15:0] CONF_WAIT;
assign CONF_WAIT = {status_regs[5],status_regs[6]};

wire [7:0] CONF_REPEAT;
assign CONF_REPEAT = status_regs[7];


wire [7:0] BUS_STATUS_OUT;
assign BUS_STATUS_OUT = status_regs[BUS_ADD];

always @(*) begin
  if(BUS_ADD == 1)
    BUS_DATA_OUT = {7'b0,CONF_DONE};
  else if(BUS_ADD == 3)
      BUS_DATA_OUT = CONF_BIT_OUT[15:8];    
  else if(BUS_ADD == 4)
      BUS_DATA_OUT = CONF_BIT_OUT[7:0];
  else if(BUS_ADD == 5)
      BUS_DATA_OUT = CONF_WAIT[15:8];
  else if(BUS_ADD == 6)
      BUS_DATA_OUT = CONF_WAIT[7:0]; 
  else if(BUS_ADD == 7)
      BUS_DATA_OUT = CONF_REPEAT;     
  else if(BUS_ADD < 8)
    BUS_DATA_OUT = BUS_STATUS_OUT;
  else if(BUS_ADD < 8+MEM_BYTES )
    BUS_DATA_OUT = BUS_IN_MEM;
  else if(BUS_ADD < 8+MEM_BYTES+ MEM_BYTES)
    BUS_DATA_OUT = BUS_OUT_MEM;
end

reg [15:0] out_bit_cnt;

wire [13:0] memout_addrb;
assign memout_addrb = out_bit_cnt;
wire [10:0] memout_addra;
assign memout_addra =  (BUS_ADD-8);

integer i;
reg [7:0] BUS_DATA_IN_IB;
always @(*) begin
    for(i=0;i<8;i=i+1)
        BUS_DATA_IN_IB[i] = BUS_DATA_IN[7-i];
end

wire [7:0] BUS_IN_MEM_IB;
always @(*) begin
    for(i=0;i<8;i=i+1)
        BUS_IN_MEM[i] = BUS_IN_MEM_IB[7-i];
end

wire [7:0] BUS_OUT_MEM_IB;
always @(*) begin
    for(i=0;i<8;i=i+1)
        BUS_OUT_MEM[i] = BUS_OUT_MEM_IB[7-i];
end

wire SDI_MEM;

blk_mem_gen_8_to_1_2k memout(
  .CLKA(BUS_CLK), .CLKB(SPI_CLK), .DOUTA(BUS_IN_MEM_IB), .DOUTB(SDI_MEM), .WEA(BUS_WR && BUS_ADD >=8 && BUS_ADD < 8+MEM_BYTES), .WEB(1'b0),
  .ADDRA(memout_addra), .ADDRB(memout_addrb), .DINA(BUS_DATA_IN_IB), .DINB()
);

wire [10:0] ADDRA_MIN;
assign ADDRA_MIN = (BUS_ADD-8-MEM_BYTES) ;
wire [13:0] ADDRB_MIN;
assign ADDRB_MIN = out_bit_cnt-1;
reg SEN_INT;
blk_mem_gen_8_to_1_2k memin(
  .CLKA(BUS_CLK), .CLKB(SPI_CLK), .DOUTA(BUS_OUT_MEM_IB), .DOUTB(), .WEA(1'b0), .WEB(SEN_INT), 
  .ADDRA( ADDRA_MIN ), .ADDRB( ADDRB_MIN ), .DINA(BUS_DATA_IN_IB), .DINB(SDO)
);

wire RST_SYNC;
wire RST_SOFT_SYNC;
pulse_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(SPI_CLK), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;

wire START_SYNC;
pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(SPI_CLK), .pulse_out(START_SYNC));

wire [15:0] STOP_BIT;
assign STOP_BIT = CONF_BIT_OUT + CONF_WAIT;
reg [7:0] REPEAT_COUNT;

wire REP_START;
assign REP_START = (out_bit_cnt == STOP_BIT && (CONF_REPEAT==0 || REPEAT_COUNT < CONF_REPEAT));

always @ (posedge SPI_CLK)
    if (RST_SYNC)
        SEN_INT <= 0;
    else if(START_SYNC || REP_START)
        SEN_INT <= 1;
    else if(out_bit_cnt == CONF_BIT_OUT)
        SEN_INT <= 0;

always @ (posedge SPI_CLK)
    if (RST_SYNC)
        out_bit_cnt <= 0;
    else if(START_SYNC)
        out_bit_cnt <= 1;
    else if(REP_START)
        out_bit_cnt <= 1;
    else if(out_bit_cnt == STOP_BIT)
        out_bit_cnt <= 0;
    else if(out_bit_cnt != 0)
        out_bit_cnt <= out_bit_cnt + 1;

always @ (posedge SPI_CLK)
    if (RST_SYNC || START_SYNC)
        REPEAT_COUNT <= 1;
    else if(out_bit_cnt == STOP_BIT)
        REPEAT_COUNT <= REPEAT_COUNT + 1;
        

reg [1:0] sync_ld;
always @(posedge SPI_CLK) begin
    sync_ld[0] <= SEN_INT;
    sync_ld[1] <= sync_ld[0];
end

always @(posedge SPI_CLK)
    SLD <= (sync_ld[1]==1 && sync_ld[0]==0);

always @(posedge SPI_CLK)
    if(RST_SYNC | START_SYNC)
        CONF_DONE <= 0;
    else if(SLD && REPEAT_COUNT >= CONF_REPEAT)
        CONF_DONE <= 1;


CG_MOD_pos icg2(.ck_in(SPI_CLK), .enable(SEN), .ck_out(SCLK));

always @(negedge SPI_CLK)
    SDI <= SDI_MEM;

always @(negedge SPI_CLK)
    SEN <= SEN_INT;
    
endmodule
