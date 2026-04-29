`timescale 1ns / 1ps

//Basil module
`include "utils/cdc_syncfifo.v"

//eine adresse hat 8 bit --> ich bruache noch fünf für data in (eine davon spare)
//wenn ich das ganze im rx_core einbaue --> bei inst in rx für die Übergabe den output aus bus to ip nutzen
//nochmal fragen ob als neues out_sx der Alte Wert der gezählt wurde genommen werden soll 
//(müsste man dann als input übergeben)
module signal_counter #(
    parameter integer ABUSWIDTH = 25
    )(
    input wire                  BUS_CLK, //ist das die einzige clock oder brauche ich noch eine mit anderer Frequenz (die mit der sich z.b. is_ready ändert)
    input wire [ABUSWIDTH-1:0]  BUS_ADD,
    input wire                  BUS_RST, //muss vllt noch eingebaut werden
    input wire                  BUS_RD,
    input wire                  BUS_WR,
    input wire [7:0]            BUS_DATA_IN, //ich brauche vier Mal die Größe hiervon wie mache ich das --> BUS breiter machen und daduch Platz für data in haben 
    output reg [7:0]            BUS_DATA_OUT,

    input wire signal1,
    input wire signal2,
    input wire signal3,
    input wire signal4,
    input wire signal5,

    input wire clk,
    input wire reset
);
    
    reg [31:0] max_clk_cyc = 32'b0;
    reg [31:0] counter_clock_cyc = 32'b0;

    reg [31:0] s1 = 32'b0;
    reg [31:0] s2 = 32'b0;
    reg [31:0] s3 = 32'b0;
    reg [31:0] s4 = 32'b0;
    reg [31:0] s5 = 32'b0;

    reg [31:0] out_s1 = 32'b0;

    reg [31:0] out_s2 = 32'b0;
    reg [31:0] out_s3 = 32'b0;
    reg [31:0] out_s4 = 32'b0;
    reg [31:0] out_s5 = 32'b0;

    reg [31:0] count_s_buf;

    reg winc;

    reg rst_bus = 1'b0; 
    wire rst;

    always @ (posedge clk) begin
        if(reset || rst) begin
            counter_clock_cyc <= 32'b0;
            s1 <= 32'b0;
            s2 <= 32'b0;
            s3 <= 32'b0;
            s4 <= 32'b0;
            s5 <= 32'b0;

            out_s1 <= 32'b0;
            out_s2 <= 32'b0;
            out_s3 <= 32'b0;
            out_s4 <= 32'b0;
            out_s5 <= 32'b0;    
            
            winc = 1'b0;    
        end
        else begin
            if(counter_clock_cyc == max_clk_cyc) begin
                out_s1 <= s1;
                out_s2 <= s2;
                out_s3 <= s3;
                out_s4 <= s4;
                out_s5 <= s5;
                winc <= 1'b1;
            end
            else begin
                if(signal1) begin
                    s1 <= s1 + 1;
                end
                if(signal2) begin
                    s2 <= s2 + 1;
                end
                if(signal3) begin
                    s3 <= s3 + 1;
                end
                if(signal4) begin
                    s4 <= s4 + 1;
                end
                if(signal5) begin
                    s5 <= s5 + 1;
                end
                counter_clock_cyc <= counter_clock_cyc + 1;
            end
        end
    end

    
    wire [31:0] out_sync_s1;
    wire [31:0] out_sync_s2;
    wire [31:0] out_sync_s3;
    wire [31:0] out_sync_s4;
    wire [31:0] out_sync_s5;
    
    cdc_syncfifo #(
        .DSIZE(32),
        .ASIZE(2)
    )cdc_syncfifo_inst1(
        .rdata(out_sync_s1), //32 Bit Daten Input
        .wfull(),
        .rempty(),
        .wdata(out_s1), //32 Bit Daten Output
        .winc(1'b1),
        .wclk(clk),
        .wrst(reset),
        .rinc(1'b1), //.rinc(BUS_ADD == 0 && BUS_RD),
        .rclk(BUS_CLK),
        .rrst(BUS_RST)
    );
    
    cdc_syncfifo #(
        .DSIZE(32),
        .ASIZE(2)
    )cdc_syncfifo_inst2(
        .rdata(out_sync_s2), //32 Bit Daten Input
        .wfull(),
        .rempty(),
        .wdata(out_s2), //32 Bit Daten Output
        .winc(1'b1),
        .wclk(clk),
        .wrst(reset),
        .rinc(1'b1), //.rinc(BUS_ADD == 4 && BUS_RD),
        .rclk(BUS_CLK),
        .rrst(BUS_RST)
    );
    
    cdc_syncfifo #(
        .DSIZE(32),
        .ASIZE(2)
    )cdc_syncfifo_inst3(
        .rdata(out_sync_s3), //32 Bit Daten Input
        .wfull(),
        .rempty(),
        .wdata(out_s3), //32 Bit Daten Output
        .winc(1'b1),
        .wclk(clk),
        .wrst(reset),
        .rinc(1'b1), //.rinc(BUS_ADD == 8 && BUS_RD),
        .rclk(BUS_CLK),
        .rrst(BUS_RST)
    );
    
    cdc_syncfifo #(
        .DSIZE(32),
        .ASIZE(2)
    )cdc_syncfifo_inst4(
        .rdata(out_sync_s4), //32 Bit Daten Input
        .wfull(),
        .rempty(),
        .wdata(out_s4), //32 Bit Daten Output
        .winc(1'b1),
        .wclk(clk),
        .wrst(reset),
        .rinc(1'b1), //.rinc(BUS_ADD == 12 && BUS_RD),
        .rclk(BUS_CLK),
        .rrst(BUS_RST)
    );
    
    cdc_syncfifo #(
        .DSIZE(32),
        .ASIZE(2)
    )cdc_syncfifo_inst5(
        .rdata(out_sync_s5), //32 Bit Daten Input
        .wfull(),
        .rempty(),
        .wdata(out_s5), //32 Bit Daten Output
        .winc(winc),
        .wclk(clk),
        .wrst(reset),
        .rinc(1'b1), //.rinc(BUS_ADD == 16 && BUS_RD),
        .rclk(BUS_CLK),
        .rrst(BUS_RST)
    );
    
    always @ (posedge BUS_CLK) begin
        if(BUS_ADD == 24 && BUS_WR) begin
            if(BUS_DATA_IN[0] == 0) begin
                rst_bus <= 1'b0;
            end
            if(BUS_DATA_IN[0] == 1) begin
                rst_bus <= 1'b1;
            end
        end
    end

    cdc_reset_sync cdc_reset_sync_inst(
        .clk_in(BUS_CLK),
        .pulse_in(rst_bus),
        .clk_out(clk),
        .pulse_out(rst)
    );

    always @ (posedge BUS_CLK) begin
        if(BUS_WR) begin
            case(BUS_ADD)
            20: begin
                max_clk_cyc[7:0] <= BUS_DATA_IN;
            end
            21: begin
                max_clk_cyc[15:8] <= BUS_DATA_IN;
            end
            22: begin
                max_clk_cyc[23:16] <= BUS_DATA_IN;
            end
            23: begin
                max_clk_cyc[31:24] <= BUS_DATA_IN;
            end
            endcase
        end
    end

    always @ (posedge BUS_CLK) begin
        if(BUS_RD) begin
            case(BUS_ADD) 
                0: begin
                    BUS_DATA_OUT <= out_sync_s1[7:0];
                end
                1: begin
                    BUS_DATA_OUT <= count_s_buf[15:8];
                end
                2: begin
                    BUS_DATA_OUT <= count_s_buf[23:16];
                end
                3: begin
                    BUS_DATA_OUT <= count_s_buf[31:24];
                end
                4: begin
                    BUS_DATA_OUT <= out_sync_s2[7:0];
                end
                5: begin
                    BUS_DATA_OUT <= count_s_buf[15:8];
                end
                6: begin
                    BUS_DATA_OUT <= count_s_buf[23:16];
                end
                7: begin
                    BUS_DATA_OUT <= count_s_buf[31:24];
                end
                8: begin
                    BUS_DATA_OUT <= out_sync_s3[7:0];
                end
                9: begin
                    BUS_DATA_OUT <= count_s_buf[15:8];
                end
                10: begin
                    BUS_DATA_OUT <= count_s_buf[23:16];
                end
                11: begin
                    BUS_DATA_OUT <= count_s_buf[31:24];
                end
                12: begin
                    BUS_DATA_OUT <= out_sync_s4[7:0];
                end
                13: begin
                    BUS_DATA_OUT <= count_s_buf[15:8];
                end
                14: begin
                    BUS_DATA_OUT <= count_s_buf[23:16];
                end
                15: begin
                    BUS_DATA_OUT <= count_s_buf[31:24];
                end
                16: begin
                    BUS_DATA_OUT <= out_sync_s5[7:0];
                end
                17: begin
                    BUS_DATA_OUT <= count_s_buf[15:8];
                end
                18: begin
                    BUS_DATA_OUT <= count_s_buf[23:16];
                end
                19: begin
                    BUS_DATA_OUT <= count_s_buf[31:24];
                end
            endcase
        end
    end

    //retain upper part of count_sx for next read
    always @ (posedge BUS_CLK) begin
        if(BUS_ADD == 0 && BUS_RD) begin
            count_s_buf <= out_sync_s1;
        end
        if(BUS_ADD == 4 && BUS_RD) begin
            count_s_buf <= out_sync_s2;
        end
        if(BUS_ADD == 8 && BUS_RD) begin
            count_s_buf <= out_sync_s3;
        end
        if(BUS_ADD == 12 && BUS_RD) begin
            count_s_buf <= out_sync_s4;
        end
        if(BUS_ADD == 16 && BUS_RD) begin
            count_s_buf <= out_sync_s5;
        end
    end

endmodule

