`timescale 1ns / 1ps

module UART_TOP(CLK, RST, TX_START, DATA, RX, TX, Data_Out, Done, Parity_Error, Frame_Error);

input CLK, RST, TX_START, RX;
input[7:0] DATA;
output TX, Done, Parity_Error, Frame_Error;
output[7:0] Data_Out;

wire TX_TICK,RX_TICK;

UART_TX U1(.DATA(DATA),.RST(RST),.CLK(CLK),.TX_TICK(TX_TICK),.TX_START(TX_START),.TX(TX));
Baud_Gen U2(.CLK(CLK),.RST(RST),.TX_TICK(TX_TICK),.RX_TICK(RX_TICK));
UART_RX U3(.RX(RX),.RX_TICK(RX_TICK),.CLK(CLK),.RST(RST),.Data_Out(Data_Out),.Done(Done),.Parity_Error(Parity_Error),.Frame_Error(Frame_Error));
endmodule
