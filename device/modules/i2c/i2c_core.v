/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module i2c_core #(
    parameter ABUSWIDTH = 16
)(
    input wire BUS_CLK,
    input wire BUS_RST,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    input [7:0] BUS_DATA_IN,
    input BUS_RD,
    input BUS_WR,
    output reg [7:0] BUS_DATA_OUT,
    
    inout wire i2c_sda,
    inout wire i2c_scl,
    output wire busy,
    output wire error 
);

localparam VERSION = 0;

reg [7:0] status_regs [2:0];

wire RST;
wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign RST = BUS_RST || SOFT_RST;

//Long signal generated for starting
wire start_flag;
reg [7:0] start_cnt = 0;
assign start_flag = (start_cnt > 0) ? 1: 0;
always @(posedge BUS_CLK) begin
    if((BUS_ADD == 3) && BUS_WR) begin
        start_cnt <= 255;
    end
    else if(start_cnt > 0)
        start_cnt <= start_cnt - 1;
end        
        
//Long signal generated for reseting the i2c clock
wire i2c_rst_flag;
reg [7:0] i2c_rst_cnt = 0;
assign i2c_rst_flag = (i2c_rst_cnt > 0) ? 1: 0;
always @(posedge BUS_CLK) begin
    if((BUS_ADD == 4) && BUS_WR) begin
        i2c_rst_cnt <= 255;
    end
    else if(i2c_rst_cnt > 0)
        i2c_rst_cnt <= i2c_rst_cnt - 1;
end        
        
always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 0;
        status_regs[3] <= 0;
        status_regs[4] <= 0;
        status_regs[5] <= 0;
        status_regs[6] <= 0;
        status_regs[7] <= 0;
    end
    else if(BUS_WR && BUS_ADD < 8)
        status_regs[BUS_ADD[2:0]] <= BUS_DATA_IN; 
end

wire [7:0] I2C_ADD;
assign I2C_ADD = status_regs[1];

wire [7:0] I2C_DATA;
assign I2C_DATA = status_regs[2];

wire [7:0] I2C_START;
assign I2C_START = start_flag;//status_regs[3];

wire [7:0] I2C_CLK_RST;
assign I2C_CLK_RST = i2c_rst_flag;//status_regs[4];


always @ (posedge BUS_CLK) begin
    if(BUS_ADD == 0)
        BUS_DATA_OUT <= VERSION;
    else if(BUS_ADD == 1)
        BUS_DATA_OUT <= I2C_ADD;
    else if(BUS_ADD == 2)
        BUS_DATA_OUT <= I2C_DATA;
    else if(BUS_ADD == 3)
        BUS_DATA_OUT <= {7'b0, I2C_START};
    else if(BUS_ADD == 4)
        BUS_DATA_OUT <= {7'b0, I2C_CLK_RST};
    else
        BUS_DATA_OUT <= 8'b0;
end

reg [8:0] slow_clock;
reg [2:0] dly_cnt;
wire clock_intern;
wire clock_div4_dly;
wire dly_flag;

localparam div = 5; // 1 to 8
assign clock_intern = slow_clock[div]; // 312.5kHz

//slow down 80MHz input
always @ (posedge BUS_CLK) begin
    if(RST == 1) slow_clock <= 0;
    else slow_clock <= slow_clock + 1; 
end

assign clock_div4_dly = (RST == 0) ? slow_clock[div-2] : 0;
assign dly_flag = ((dly_cnt < 4) && (dly_cnt > 1)) ? 1 : 0;
always @ (negedge clock_div4_dly) begin
    if((RST == 1) || !(i2c_scl_enable == 1)) dly_cnt <= 3'b111;
    else if(dly_cnt == 3) dly_cnt <= 3'd0; 
    else dly_cnt <= dly_cnt + 1;
end

localparam STATE_IDLE  = 0;
localparam STATE_START = 1;
localparam STATE_ADDR  = 2;
localparam STATE_RW    = 3;
localparam STATE_WACK  = 4;
localparam STATE_DATA  = 5;
localparam STATE_WACK2 = 6;
localparam STATE_STOP  = 7;

localparam STATE_ERR   = 8;

reg [7:0] state;
reg [7:0] stored_addr;
reg [7:0] stored_data;
reg [7:0] count;
reg sda_data;
reg sda_data_in;
reg i2c_scl_enable;


assign busy = ((RST == 0) && (state == STATE_IDLE)) ? 0 : 1;
assign error = dly_flag;//state_err_flag;

assign i2c_scl = (((i2c_scl_enable == 1) && (dly_flag == 1)) || (i2c_scl_enable == 0))? 1'bz: 0;
assign i2c_sda = (sda_data == 0) ? 0 : 1'bz;

always @ (posedge clock_intern) begin
    if(RST == 1) i2c_scl_enable <= 0;
    else begin
        if((state == STATE_IDLE) || (state == STATE_START)) i2c_scl_enable <= 0; //  || (state == STATE_STOP)i2c_scl_enable <= 0;
        //if((state == STATE_STOP)) i2c_scl_enable <= 0;
        else i2c_scl_enable <= 1;
    end
end


//Error handling
//reg state_err_flag;
//always @ (negedge i2c_scl) begin
//	if(((state == STATE_WACK) || (state == STATE_WACK2)) && (i2c_sda == 1)) state_err_flag <= 1;
//end

//State Machine
always @ (negedge clock_intern) begin

    if(I2C_CLK_RST == 1) begin
        state   <= STATE_IDLE;
        sda_data <= 1;
        count   <= 8'd0;
        //status_regs[4] <= 0; // set clk rst to 0
    end
    
    else begin
        case(state)
        
            STATE_ERR: begin
                state <= STATE_STOP;
            //	state_err_flag <= 0;
            end
        
            STATE_IDLE: begin
                sda_data <= 1;
                //state_err_flag <= 0;
                if(I2C_START == 1) begin
                    state <= STATE_START;
                    stored_data <= I2C_DATA;
                    stored_addr <= I2C_ADD;
                    //status_regs[3] <= 0; //set start to 0
                end //else if() 
                    else state <= STATE_IDLE;
            end
            
            STATE_START: begin
                sda_data <= 0;
                state <= STATE_ADDR;
                count <= 6;
            end
            
            STATE_ADDR: begin
                sda_data <= stored_addr[count+1];
                if(count == 0) state <= STATE_RW;
                else count <= count - 1;
            end
            
            STATE_RW: begin
                sda_data <= stored_addr[count];
                state <= STATE_WACK;
            end
            
            STATE_WACK: begin  
                /*if(state_err_flag) state <= STATE_ERR;
                else*/ state <= STATE_DATA;
                count <= 7;
            end
            
            STATE_DATA: begin
                //if(state_err_flag == 1) begin
                //	state <= STATE_ERR;
                //end
                //else begin
                    sda_data <= stored_data[count];
                //	state_err_flag <= 0;
                    if(count == 0) state <= STATE_WACK2;
                    else count <= count - 1;
                //end
            end
            
            STATE_WACK2: begin
                /*if(state_err_flag)*/ //state <= STATE_ERR;
                /*else*/ state <= STATE_STOP;
            end
            
            STATE_STOP: begin
                sda_data <= 0;
                state <= STATE_IDLE;
            end
        endcase //end case	
    end //end else
end

endmodule
