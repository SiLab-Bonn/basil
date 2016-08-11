//////////////////////////////////////////////////////////////////////////////////
// Company: SiLab, Institute of Physics, University of Bonn
// Engineer: Marco Vogt
// 
// Create Date:    13:10:58 07/19/2016 
// Module Name:    spi_emulator 
// Tool versions: 2015.4.1
// Description: Emulation of a 24LC46 128 byte SPI EEPROM.
//              From the SPI side, the module behaves just like a real chip, except the missing erase commands
//              Data is stored in a dual port block memory, which is freely accessible through its second port.
// Revision: 1
//////////////////////////////////////////////////////////////////////////////////
module spi_emu_simple(
    input wire sys_clk,
    input wire [6:0] bram_addr,
    input wire [7:0] bram_din,
    output reg[7:0] bram_dout,
    output reg bram_busy,
    input wire bram_en,
    input wire bram_wr,
    input wire spi_clk,
    input wire spi_mosi,
    inout wire spi_miso,
    input wire spi_cs,
    input wire reset
    );

    reg [7:0] miso_reg, miso_reg_temp;  /* Data transmission is always just 8 bits per read/write operation */
    reg [7:0] mosi_reg;
    reg spi_miso_out;
    reg spi_oe = 1'b1;
    
    /* Tri-state output buffer. Use non-sync'ed CS. */
    assign spi_miso = !spi_oe ? 1'bZ : spi_miso_out;    //spi_miso_out;     //spi_cs ? 1'bZ : spi_miso_out;

    /* Instruction set */
    parameter I_WRITE = 3'b101; // Write memory
    parameter I_READ  = 3'b110; // Read memory
    parameter I_WRCMD = 3'b100; // Write permission
    parameter I_WRDI  = 2'b00;  // Write disable
    parameter I_WREN  = 2'b11;  // Write enable
    parameter I_NONE  = 3'b000; // dummy
    reg [2:0] instruction = I_NONE;
    parameter WE_OFFSET =   1;              // CCC WW|xxxxxxxxxxxxx
    parameter ADDR_OFFSET = 6;              // CCC AAAAAAA|DDDDDDDD
    parameter DATA_OFFSET = ADDR_OFFSET+ 8; // CCC AAAAAAA DDDDDDDD|
    parameter WRITE_DONE = DATA_OFFSET + 1; // the Atmel memory chip needs a few hundred ns to complete its write process. at the end, a ready pulse is generated at miso
    
    /* Input sync */
    wire spi_clk_sync_pos, spi_clk_sync_neg, spi_mosi_sync, spi_cs_sync, spi_cs_rising;
    pos_edge spi_dff_clk_p(sys_clk, spi_clk, spi_clk_sync_pos);
    double_ff spi_dff_mosi(sys_clk, spi_mosi, spi_mosi_sync);
    pos_edge spi_cs_pos(sys_clk, spi_cs, spi_cs_rising);
    
    /* Block memory */
    reg [6:0] mem_addr = 7'd0;
    reg [7:0] mem_data_wr = 8'd0;
    reg [7:0] mem_data_rd = 8'd0;
    reg MEM_EN = 1'b0;
    reg MEM_EN_strobe = 1'b0;
    reg MEM_WE = 1'b0;
    reg MEM_WE_strobe = 1'b0;
    reg CONF_MEM_WE = 1'b0;
    
    /* Dual port BRAM */
    (* RAM_STYLE="block_power2" *)
    reg [7:0] mem [2**7-1:0];
    always @(posedge sys_clk) begin
        if (MEM_EN) begin
            if (MEM_WE)
                mem[mem_addr] <= mem_data_wr;
            mem_data_rd <= mem[mem_addr];
        end
        if (bram_en) begin
            if (bram_wr)
                mem[bram_addr] <= bram_din;
            bram_dout <= mem[bram_addr];
        end
    end

    reg [4:0] bit_count;
    reg strobe = 1'b0;
    reg error = 1'b0;

    /* FSM */
    reg START_FSM;
    localparam  STATE_IDLE  = 0,
                STATE_RECEIVE = 1;
    reg state, next_state = STATE_IDLE;
    
    always @ (posedge sys_clk) begin
        if (reset)
            state <= STATE_IDLE;
        else
            state <= next_state;
    end    
    always @ (*) begin
        next_state <= state;
        case(state)
            STATE_IDLE:
                if(spi_cs_rising == 1)
                    next_state <= STATE_RECEIVE;
            STATE_RECEIVE:
                if(strobe)
                    next_state <= STATE_IDLE;
            default: next_state <= STATE_IDLE;
        endcase
    end

    always @(posedge sys_clk) begin
        /* bit counter */
        if (spi_clk_sync_pos)
            if(state == STATE_RECEIVE && instruction != I_NONE) begin
                if(bit_count < 31)
                    bit_count <= bit_count + 1;
            end
            else begin
                bit_count <= 0;
            end

        /* Shift register */
        spi_miso_out <= miso_reg[7];
        if (spi_clk_sync_pos) begin
            mosi_reg <= {mosi_reg[6:0], spi_mosi_sync};
            //miso_reg = {miso_reg[6:0], 1'b0};
//        end
//        else if (spi_clk_sync_neg) begin
            miso_reg <= {miso_reg[6:0], 1'b0};
            //spi_miso_out <= miso_reg[7];
        end
        
        /* reset flags */
        strobe <= 0;

        /* Prevent write collisions */
        if (state==STATE_RECEIVE && instruction==I_WRITE)
            bram_busy <= 1'b1;
        else
            bram_busy <= 1'b0;

        /* IDLE state */
        if (state==STATE_IDLE) begin
            instruction <= I_NONE;
            if(bit_count == 0)
                spi_oe <= 0;
        end
        
        /* Process received data */
        if (state==STATE_RECEIVE) begin
            if (1) begin
                MEM_EN <= 0;
                MEM_WE <= 0;
                if(instruction == I_NONE && spi_clk_sync_pos) begin //bit_count == CMD_OFFSET &&
                    case(mosi_reg[2:0])
                        I_READ: instruction <= I_READ;
                        I_WRITE: instruction <= I_WRITE;
                        I_WRCMD: instruction <= I_WRCMD;
                    endcase
                end
                else begin
                    if(spi_cs == 0 && spi_clk_sync_pos) begin       //if cs goes low, go back to idle
                        instruction <= I_NONE;
                        strobe <= 1;
                    end
                    case(instruction)
                        I_READ: begin
                            if(bit_count == ADDR_OFFSET) begin
                                mem_addr <= mosi_reg[6:0];
                                MEM_EN <= 1;
                                spi_oe <= 1;
                            end
                            if(bit_count == ADDR_OFFSET && spi_clk_sync_pos)
                                miso_reg <= mem_data_rd;
                            if(bit_count == DATA_OFFSET && spi_clk_sync_pos)
                                spi_oe <= 0;                     
                            if(bit_count == DATA_OFFSET+1 && spi_clk_sync_pos)  //if cs stays high, decode next instruction
                                instruction <= I_NONE;
                        end
                        I_WRITE: begin
                            if(bit_count == ADDR_OFFSET && spi_clk_sync_pos) begin
                                mem_addr <= mosi_reg[6:0];
                            end
                            if(bit_count == DATA_OFFSET && spi_clk_sync_pos) begin
                                mem_data_wr <= mosi_reg[7:0];//{1'b0,mem_addr};
                                MEM_EN <= 1;
                                MEM_WE <= 1;//CONF_MEM_WE;
//                                miso_reg <= 8'h80;  //create a "ready" pulse at miso
//                                spi_oe <= 1;
                            end
                            if(bit_count == WRITE_DONE+1 && spi_clk_sync_pos)   //if cs stays high, decode next instruction
                                    instruction <= I_NONE;
                        end
                        I_WRCMD: begin
                            if(bit_count == WE_OFFSET && spi_clk_sync_pos) begin
                                case(mosi_reg[1:0])
                                    I_WREN: CONF_MEM_WE <= 1;
                                    I_WRDI: CONF_MEM_WE <= 0;
                                endcase
                            end
                            if(bit_count == WE_OFFSET+2 && spi_clk_sync_pos)   //if cs stays high, decode next instruction
                                    instruction <= I_NONE;
                        end
                    endcase
                end
            end
        end
    end
endmodule
