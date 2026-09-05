`timescale 1ns / 1ps


module Baud_Gen(CLK,RST,TX_TICK,RX_TICK);

input CLK,RST;
output reg TX_TICK,RX_TICK;

parameter CLK_FREQ = 100000000;
parameter BAUD_RATE = 9600;

parameter TX_DIVISOR = CLK_FREQ/BAUD_RATE;
parameter RX_DIVISOR = CLK_FREQ/(BAUD_RATE*16); // 16 FOR OVERSAMPLING

reg[31:0] TX_COUNTER;
reg[31:0] RX_COUNTER;

always @(posedge CLK or posedge RST)
begin

if(RST) begin
TX_COUNTER <= 0;
TX_TICK <= 0;
end

else if(TX_COUNTER == TX_DIVISOR - 1) begin // -1 BCZ WE ARE STARTING FROM 0
TX_COUNTER <= 0;
TX_TICK <= 1;
end

else begin 
TX_COUNTER <= TX_COUNTER + 1;
TX_TICK <= 0;
end

end

always @(posedge CLK or posedge RST)
begin

if(RST) begin
RX_COUNTER <= 0;
RX_TICK <= 0;
end

else if(RX_COUNTER == RX_DIVISOR - 1) begin
RX_COUNTER <= 0;
RX_TICK <= 1;
end

else begin 
RX_COUNTER <= RX_COUNTER + 1;
RX_TICK <= 0;
end

end
endmodule
