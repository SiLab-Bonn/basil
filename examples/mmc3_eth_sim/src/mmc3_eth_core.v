

module mmc3_eth_throughput_test(
    input wire RESET_N,

    // pll
    input wire BUS_CLK_PLL,
    input wire CLK250PLL,
    input wire CLK125PLLTX,
    input wire CLK125PLLTX90,
    input wire CLK125PLLRX,
    input wire PLL_LOCKED,

    // SiTCP
    wire RBCP_ACT, RBCP_WE, RBCP_RE;
    wire RBCP_ACK;
    wire [7:0] RBCP_WD, RBCP_RD;
    wire [31:0] RBCP_ADDR;

    wire TCP_CLOSE_REQ;
    wire TCP_OPEN_ACK;
    wire TCP_RX_WR;
    wire TCP_TX_WR;
    wire [7:0] TCP_RX_DATA;
    wire [7:0] TCP_TX_DATA;
    wire TCP_TX_FULL;
    reg [10:0] TCP_RX_WC_11B;

    wire SiTCP_RST;

    // status LEDs
    output wire [7:0] LED
);

wire RST;

wire BUS_CLK;
BUFG BUFG_inst_BUS_CKL (.O(BUS_CLK), .I(BUS_CLK_PLL) );

wire CLK125TX, CLK125TX90, CLK125RX;
BUFG BUFG_inst_CLK125TX (  .O(CLK125TX),  .I(CLK125PLLTX) );
BUFG BUFG_inst_CLK125TX90 (  .O(CLK125TX90),  .I(CLK125PLLTX90) );
BUFG BUFG_inst_CLK125RX (  .O(CLK125RX),  .I(rgmii_rxc) );

assign RST = !RESET_N | !PLL_LOCKED;


// -------  BUS SIGNALING  ------- //
wire BUS_WR, BUS_RD, BUS_RST;
wire [31:0] BUS_ADD;
wire [7:0] BUS_DATA;
assign BUS_RST = SiTCP_RST;

rbcp_to_bus irbcp_to_bus(
    .BUS_RST(BUS_RST),
    .BUS_CLK(BUS_CLK),

    .RBCP_ACT(RBCP_ACT),
    .RBCP_ADDR(RBCP_ADDR),
    .RBCP_WD(RBCP_WD),
    .RBCP_WE(RBCP_WE),
    .RBCP_RE(RBCP_RE),
    .RBCP_ACK(RBCP_ACK),
    .RBCP_RD(RBCP_RD),

    .BUS_WR(BUS_WR),
    .BUS_RD(BUS_RD),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA)
);

// -------  MODULE ADREESSES  ------- //
localparam GPIO_BASEADDR = 32'h1000;
localparam GPIO_HIGHADDR = 32'h101f;

// -------  USER MODULES  ------- //
wire [7:0] GPIO_IO;
gpio #(
    .BASEADDR(GPIO_BASEADDR),
    .HIGHADDR(GPIO_HIGHADDR),
    .ABUSWIDTH(32),
    .IO_WIDTH(8),
    .IO_DIRECTION(8'hff)
) i_gpio_rx (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(GPIO_IO)
);

wire FIFO_EMPTY, FIFO_FULL;
reg fifo_write;
reg [31:0] fifo_data_in;
fifo_32_to_8 #(.DEPTH(256*1024)) i_data_fifo (
    .RST(BUS_RST),
    .CLK(BUS_CLK),

    .WRITE(fifo_write),
    .READ(TCP_TX_WR),
    .DATA_IN(fifo_data_in),
    .FULL(FIFO_FULL),
    .EMPTY(FIFO_EMPTY),
    .DATA_OUT(TCP_TX_DATA)
);
assign TCP_TX_WR = !TCP_TX_FULL && !FIFO_EMPTY;


reg ETH_START_SENDING, ETH_START_SENDING_temp, ETH_START_SENDING_LOCK;
reg [31:0] datasource;
assign LED = ~{TCP_OPEN_ACK, TCP_CLOSE_REQ, TCP_RX_WR, TCP_TX_WR, FIFO_FULL, FIFO_EMPTY, fifo_write, TCP_TX_WR};    //GPIO_IO[3:0]};


always@ (posedge BUS_CLK)
    begin

    // wait for start condition
    ETH_START_SENDING <= GPIO_IO[0];    //TCP_OPEN_ACK;

    if(ETH_START_SENDING && !ETH_START_SENDING_temp)
        ETH_START_SENDING_LOCK <= 1;
    ETH_START_SENDING_temp <= ETH_START_SENDING;

    // RX FIFO word counter
    if(TCP_RX_WR) begin
        TCP_RX_WC_11B <= TCP_RX_WC_11B + 1;
    end
    else begin
        TCP_RX_WC_11B <= 11'd0;
    end

    // FIFO handshake
    if(ETH_START_SENDING_LOCK) begin
        if(!FIFO_FULL) begin
            fifo_data_in <= datasource;
            datasource <= datasource + 1;
            fifo_write <= 1'b1;
            end
        else
            fifo_write <= 1'b0;
    end

    // stop, if connection is closed by host
    if(TCP_CLOSE_REQ || !GPIO_IO[0]) begin
        ETH_START_SENDING_LOCK <= 0;
        fifo_write <= 1'b0;
        datasource <= 32'd0;
    end

end

endmodule
