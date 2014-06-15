`timescale 1ns / 100ps

module uartlib(
        input UART_CLK, output reg UART_TX    
    );
    
    integer counter;
    initial 
        UART_TX = 1;
        
    task write_byte;
        input [7:0]  data;
        begin    
            counter = 0;
                
            while(counter < 8) begin
                //start bit
                repeat(4) @(posedge UART_CLK) UART_TX = 0;
                //data    
                @(posedge UART_CLK) UART_TX = data[counter%8];
                @(posedge UART_CLK) UART_TX = data[counter%8];
                @(posedge UART_CLK) UART_TX = data[counter%8];
                @(posedge UART_CLK) UART_TX = data[counter%8];

                @(posedge UART_CLK) UART_TX = data[counter%8];
                @(posedge UART_CLK) UART_TX = data[counter%8];
                @(posedge UART_CLK) UART_TX = data[counter%8];
                @(posedge UART_CLK) UART_TX = data[counter%8];
                //stop bit
                @(posedge UART_CLK) UART_TX = 1;
                repeat(4) @(posedge UART_CLK);
                counter = counter + 1;
            end
        end
    endtask
        
    task write;
        input [31:0] addr;
        input [31:0] size;
    begin
        $display("Start task: writing write"); 
        
        write_byte(8'h61); // 0x61 = a
        
        write_byte(addr[7:0]);
        write_byte(addr[15:8]);
        write_byte(addr[23:16]);
        write_byte(addr[31:24]);
        
        write_byte(8'h6c);  // 0x6c = l
        
        write_byte(size[7:0]);
        write_byte(size[15:8]);
        write_byte(size[23:16]);
        write_byte(size[31:24]);
        
        write_byte(8'h77);  //0x77 = w
        
        $display("Stop task: writing data");
    end
    endtask

    task read;
        input [31:0] addr;
        input [31:0] size;
    begin
        $display("Start task: writing read");
        
        write_byte(8'h61); // 0x61 = a
        
        write_byte(addr[7:0]);
        write_byte(addr[15:8]);
        write_byte(addr[23:16]);
        write_byte(addr[31:24]);
        
        write_byte(8'h6c);  // 0x6c = l
        
        write_byte(size[7:0]);
        write_byte(size[15:8]);
        write_byte(size[23:16]);
        write_byte(size[31:24]);
        
        write_byte(8'h72);  // 0x72 = r
     
        $display("Stop task: reading data");
    end
    endtask

endmodule
