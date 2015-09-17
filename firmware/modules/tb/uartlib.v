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
            //start bit
            $display("write_byte: 0x%x (0b%b) [%c]", data, data, data); 
            
            repeat(2) @(posedge UART_CLK) UART_TX <= 1;
            
            @(posedge UART_CLK) UART_TX <= 0;
            //data    
            @(posedge UART_CLK) UART_TX <= data[0];
            @(posedge UART_CLK) UART_TX <= data[1];
            @(posedge UART_CLK) UART_TX <= data[2];
            @(posedge UART_CLK) UART_TX <= data[3];

            @(posedge UART_CLK) UART_TX <= data[4];
            @(posedge UART_CLK) UART_TX <= data[5];
            @(posedge UART_CLK) UART_TX <= data[6];
            @(posedge UART_CLK) UART_TX <= data[7];
            //stop bit
            @(posedge UART_CLK) UART_TX <= 1;
            repeat(2) @(posedge UART_CLK);
        end
    endtask
        
    task write;
        input [31:0] addr;
        input [31:0] size;
    begin
        repeat (40) @(posedge UART_CLK);
        
        write_byte(8'h61); // 0x61 = a
        
        write_byte(addr[7:0]);
        write_byte(addr[15:8]);
        write_byte(addr[23:16]);
        write_byte(addr[31:24]);
        
        repeat(40) @(posedge UART_CLK) ;
        
        write_byte(8'h6c);  // 0x6c = l
        
        write_byte(size[7:0]);
        write_byte(size[15:8]);
        write_byte(size[23:16]);
        write_byte(size[31:24]);
        
        repeat(40) @(posedge UART_CLK) ;
        
        write_byte(8'h77);  //0x77 = w
        
        repeat(40) @(posedge UART_CLK) ;

    end
    endtask

    task read;
        input [31:0] addr;
        input [31:0] size;
    begin
        
        repeat (40) @(posedge UART_CLK);
        
        write_byte(8'h61); // 0x61 = a
        
        write_byte(addr[7:0]);
        write_byte(addr[15:8]);
        write_byte(addr[23:16]);
        write_byte(addr[31:24]);
        
        repeat(40) @(posedge UART_CLK) ;
        
        write_byte(8'h6c);  // 0x6c = l
        
        write_byte(size[7:0]);
        write_byte(size[15:8]);
        write_byte(size[23:16]);
        write_byte(size[31:24]);
        
        repeat(40) @(posedge UART_CLK) ;//wait for receiving OK
        
        write_byte(8'h72);  // 0x72 = r
        
        repeat(40) @(posedge UART_CLK) ;
        
    end
    endtask

endmodule
