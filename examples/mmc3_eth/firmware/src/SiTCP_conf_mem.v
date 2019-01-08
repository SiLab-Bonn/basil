/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps

module SiTCP_conf_mem
#(
    parameter   CONF_MAC = 48'h001122334455,
    parameter   CONF_IP  = 32'hc0a80a10
) (
    input wire FAKEROM_CS,
    input wire FAKEROM_SK,
    input wire FAKEROM_DI,
    output reg FAKEROM_DO
);

    localparam OP_READ  =  8'b10000000;
    localparam OP_EWEN  =  8'b0011XXXX;
    localparam OP_ERASE =  8'b11000000;
    localparam OP_WRITE =  8'b01000000;
    localparam OP_ERAL  =  8'b0010XXXX;
    localparam OP_WRAL  =  8'b0001XXXX;
    localparam OP_EWDS  =  8'b0000XXXX;


    //localparam OFFSET_OPCODE = 2:
    //localparam OFFSET_ADDRESS = 6;

    reg [1:0] opcode;
    reg [5:0] address, address_to_read;

    reg [16:0] shiftreg;
    reg [7:0]  step_cnt;

    reg [47:0] shiftreg_out;
    reg [3:0]  shiftreg_out_cnt;
    reg [1:0]  reg_size;

    reg error;
    wire CMD_PHASE;

    localparam STATE_IDLE = 3'h0, STATE_READ = 3'h1;
    reg [2:0] state = STATE_IDLE, next_state = STATE_IDLE;



    always @(negedge FAKEROM_SK) begin
        if(FAKEROM_CS) begin
            if (step_cnt < 16) begin
                shiftreg[16:1] <= shiftreg[15:0];
                shiftreg[0]    <= FAKEROM_DI;
                step_cnt <= step_cnt + 1;
            end


            if (step_cnt == 8) begin
                if (shiftreg[8] == 0)
                    error <= 1'b1;
                else begin
                    opcode  <= shiftreg[7:6];
                    address <= shiftreg[5:0];
                end
            end

            if (step_cnt == 16) begin
                if (shiftreg[16] == 0)
                    error <= 1'b1;
                else begin
                    opcode  <= shiftreg[7:6];
                    address <= shiftreg[5:0];
                end
            end

        end
        else begin
            opcode  <= 2'h0;
            address <= 6'h00;
        end

    end



    always @ (posedge FAKEROM_SK) begin
        state <= next_state;

        case(state)
            STATE_READ: begin
                shiftreg_out[15:1] <= shiftreg_out[14:0];
                FAKEROM_DO <= shiftreg_out[15];

                if (!shiftreg_out_cnt) begin
                    if (address_to_read == 6'h00) begin   //MAC
                        shiftreg_out <= CONF_MAC;
                        reg_size <= 2'h3;
                    end
                end

                shiftreg_out_cnt <= shiftreg_out_cnt + 1;
            end
            
        endcase
    end


    always @ (*) begin
        next_state = state;
        case(state)
            STATE_IDLE:
                if (opcode == OP_READ[7:6]) begin
                    address_to_read <= address;
                    reg_size <=
                    next_state <= STATE_READ;
                end

            STATE_READ:
                if (FAKEROM_CS == 0)
                    next_state <= STATE_IDLE;

        endcase
    end


endmodule
