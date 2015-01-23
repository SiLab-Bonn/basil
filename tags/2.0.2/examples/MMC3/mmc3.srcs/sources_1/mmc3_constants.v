// -------  MODULE ADREESSES  ------- //
 
 parameter CMD_BASEADDR = 32'h0000;
 parameter CMD_HIGHADDR = 32'h0800-1;
 
 parameter LED_GPIO_BASE = 32'h1000;
 
 parameter FIFO_BASEADDR = 32'h8100;
 parameter FIFO_HIGHADDR = 32'h8200-1;

 parameter RX4_BASEADDR = 32'h8300;
 parameter RX4_HIGHADDR = 32'h8400-1;
 
 parameter RX3_BASEADDR = 32'h8400;
 parameter RX3_HIGHADDR = 32'h8500-1;
 
 parameter RX2_BASEADDR = 32'h8500;
 parameter RX2_HIGHADDR = 32'h8600-1;
 
 parameter RX1_BASEADDR = 32'h8600;
 parameter RX1_HIGHADDR = 32'h8700-1;
 
 parameter FIFO_BASEADDR_DATA = 32'h8000_0000;
 parameter FIFO_HIGHADDR_DATA = 32'h9000_0000;