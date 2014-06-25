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
 *
 * Initial version: M. Lemarenko
 */

module uart_master(
    input                UART_CLK_X4,
    input                UART_RST,
    input                UART_RX,
    output               UART_TX,
    inout        [7:0]   BUS_DATA,
    output reg   [31:0]  BUS_ADD,
    output reg           BUS_WR,
    output reg           BUS_RD
);

wire clk;
assign clk = UART_CLK_X4;

wire  [7:0]   data_i;
reg   [7:0]   data_o;

assign data_i = BUS_DATA;
assign BUS_DATA = BUS_WR ? data_o : 8'bzzzz_zzzz;

reg     [7:0] tx_byte;
wire    [7:0] rx_byte;

wire is_receiving, is_transmitting, recv_error,received;
reg  transmit;

uart u_uart(
  // Inputs
  .clk_uart_x4(clk),
  .rst(UART_RST),
  .rx(UART_RX),
  .transmit(transmit),
  .tx_byte(tx_byte),
  // Outputs
  .tx(UART_TX),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);






integer     i;
reg    [4:0]     STATE, NEXTSTATE;
reg    [31:0]     cnt;
wire   [31:0]    block_len;
reg    [7:0]    block_len_0[3:0];

reg            op_done;

wire  [31:0]    address_0;
reg    [7:0]    address_0_0[3:0];        

//reg    [7:0]    test_mem [255:0];
wire[7:0]    roger_word [2:0];


assign block_len     =     {block_len_0[3], block_len_0[2], block_len_0[1],block_len_0[0]};
assign address_0    =    {address_0_0[3], address_0_0[2], address_0_0[1],address_0_0[0]};

assign roger_word[0] = {8'h4f}; // "OK\n"
assign roger_word[1] = {8'h4B}; // "OK\n"
assign roger_word[2] = {8'h0D}; // "OK\n"


localparam      IDLE         =     0,        //idle :)
                SET_LEN        =    1,        //sets the length of the block to be read
                SET_ADD        =    2,        //sets the start address
                READ        =    3,        //reads a block of mem
                WRITE        =    4,        //writes a block of mem
                ROGER        =    5;        //confirms the reception

////////////////////////////// TAKTBLOCK /////////////////////////////////////
always @(posedge clk or posedge UART_RST) 
    if (UART_RST)    begin
        STATE            <=    IDLE;
        end
    else begin
        STATE            <=    NEXTSTATE;
        end 
        // END ALWAYS
    

////////////////////////////// Kombinatorischer Block /////////////////////////////////////    
assign uart_busy = is_receiving || is_transmitting;

//reset counter:
//reg rst_counter[31:0];
//
//always @(posedge clk) begin
//    rst_counter <= rst_counter + 1;
//    if(UART_RST or recv_error)    begin 
//        rst_counter <= 0;
//    end
//end

always @* begin
    NEXTSTATE    =    IDLE;                        
    //if (!uart_busy) 
    
    case (STATE)
        IDLE:    begin
            if (received) begin
                if (rx_byte ==8'h6c) begin            //    ascii "l"
                    $write(".........set length\n");
                    NEXTSTATE    =    SET_LEN;
                end else if (rx_byte ==8'h61) begin        //    ascii "a"     
                    NEXTSTATE    =    SET_ADD;
                    $write(".........set address\n");
                end else if (rx_byte==8'h72) begin         //    ascii "r"
                    NEXTSTATE    =    READ;
                    $write(".........read\n");
                end else if (rx_byte==8'h77) begin         //    ascii "w"
                    NEXTSTATE    =    WRITE;
                    $write(".........write\n");
                end else
                    NEXTSTATE    =    IDLE;
            end
        end    
        SET_LEN:begin
            if ((!uart_busy)&&op_done)
                NEXTSTATE    =    ROGER;
            else
                NEXTSTATE    =    SET_LEN;
        end                    
        SET_ADD:begin
            if ((!uart_busy)&&op_done)
                NEXTSTATE    =    ROGER;
            else
                NEXTSTATE    =    SET_ADD;
        end                    
        READ:    begin
            if ((!uart_busy)&&op_done)
                NEXTSTATE    =    ROGER;
            else
                NEXTSTATE    =    READ;
        end                    
        WRITE: begin
            if ((!uart_busy)&&op_done)
                NEXTSTATE    =    ROGER;
            else
                NEXTSTATE    =    WRITE;
        end
        ROGER: begin
            if ((!uart_busy)&&op_done) begin
                NEXTSTATE    =    IDLE;
                $write("ROGER\n");            
            end else
                NEXTSTATE    =    ROGER;
        end            
        default: begin
            NEXTSTATE    =    IDLE;
        end            
    endcase
end // END ALWAYS

////////////////////////////// Anweisungsblock /////////////////////////////////////    

wire new_state_strobe;
assign new_state_strobe = (STATE != NEXTSTATE);
//assign add            =    address_0+cnt;

always @(posedge clk or posedge UART_RST)
    if (UART_RST)    begin
        cnt               <=    0;
        op_done           <=    0;
        transmit          <=    0;
        BUS_WR             <=    0;
        BUS_RD            <=     0;
        address_0_0[3]    <=    0;
        address_0_0[2]    <=    0;
        address_0_0[1]    <=    0;
        address_0_0[0]    <=    0;
        
        block_len_0[3]    <=    0;
        block_len_0[2]    <=    0;
        block_len_0[1]    <=    0;
        block_len_0[0]    <=    1;
    end else if (new_state_strobe) begin
        op_done      <= 0;
        cnt          <= 0;
        BUS_WR        <= 0;
        transmit     <= 0;
        BUS_RD       <= 0;
    end else begin
        case (STATE)
            IDLE:    begin
            end    
            SET_LEN:begin
                if (cnt > 3)
                    op_done    <=1;
                else if (received) begin
                    $write("setting the length byte %d to value %d\n",cnt,rx_byte);
                    block_len_0[cnt]        <=    rx_byte;
                    cnt                        <=    cnt+1;
                end
            end                    
            SET_ADD:begin
                if (cnt > 3)
                    op_done    <=1;
                else if (received) begin
                    $write("setting the address byte %d to value %d\n",cnt,rx_byte);
                    address_0_0[cnt]        <=    rx_byte;
                    cnt                        <=    cnt+1;
                end
            end                    
            READ:    begin
                //slow down the clk by 4 to get enogh time to update the value
                //hence cnt/4 and cnt[1:0]==3
                if(is_transmitting)
                    transmit <= 0;
                else if (cnt/4 >= block_len)
                    op_done  <= 1; 
                else if ((!is_transmitting)&&(!transmit)) begin
                    if (cnt[1:0]==3) begin
                    //    $write("transmitting the byte %d of value %d\n",cnt/4,tx_byte);
                        transmit     <=  1;
                    end
                    tx_byte        <=    data_i;
                    BUS_ADD        <=    address_0+cnt/4;
                    cnt            <=    cnt + 1;
                    BUS_RD         <=    1;
                end
            end                    
            WRITE: begin
                if (cnt >= block_len)
                    op_done    <=1;
                else if (received) begin
                    $write("setting the byte %d to value %d\n",cnt,rx_byte);
                    //test_mem[address_0+cnt]    <=    rx_byte;
                    BUS_ADD       <=    address_0+cnt;
                    BUS_WR        <=    1;        
                    cnt           <=    cnt + 1;
                    data_o        <=    rx_byte;
                end
            end
            ROGER: begin
                if(is_transmitting)
                    transmit <= 0;
                else if (cnt > 2) begin
                    op_done    <=1;
                end else if ((!is_transmitting)&&(!transmit)) begin                
                    tx_byte                    <=    roger_word[cnt];
                    cnt                        <=    cnt + 1;
                    transmit <= 1;
                end
            end            
            default: begin
            end            
        endcase // STATE
    end


endmodule
