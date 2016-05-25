`timescale 1ps / 1ps

module clock_multiplier
#(
    parameter MULTIPLIER = 4
)
(
    input wire CLK,
    output reg CLOCK
);
   
integer time_prev,time_diff;
initial begin
    time_prev = 0;
    forever begin
        @(posedge CLK)
        time_diff = $time - time_prev;
        time_prev = $time;
    end        
end 

initial begin
    CLOCK = 0;
    forever begin
        @(posedge CLK)
        CLOCK = 1;
        repeat(MULTIPLIER*2-1)
            #(time_diff/(MULTIPLIER*2)) CLOCK = !CLOCK;
    end        
end 

endmodule
