`timescale 1ns / 1ps

module UART_Loopback_tb;

reg CLK, RST, TX_START;
reg[7:0] DATA;
wire  TX, RX, Done, Parity_Error, Frame_Error;
wire[7:0] Data_Out;

UART_TOP Q1(CLK, RST, TX_START, DATA, RX, TX, Data_Out, Done, Parity_Error, Frame_Error);

assign RX = TX;

initial
begin 
CLK=1'b0;
forever #5 CLK=~CLK;
end 

initial 
begin 
RST =1'b1;
TX_START=1'b0; 
DATA = 8'b00000000;

repeat(3) @(posedge CLK);

RST=1'b0;

repeat(2) @(posedge CLK);

DATA = 8'b10101011;
TX_START = 1'b1;

#10 TX_START = 1'b0;

wait(Done == 1'b1);
if (Data_Out === DATA && Parity_Error == 1'b0 && Frame_Error == 1'b0)
    $display($time," LOOPBACK PASSED - Sent=%b, Received=%b", DATA, Data_Out);
else
    $display($time," LOOPBACK FAILED - Sent=%b, Received=%b", DATA, Data_Out);

 
#10 DATA=8'b10111010;
    TX_START=1'b1;
    
#10 TX_START=1'b0;
    
wait(Done == 1'b1);
if (Data_Out === DATA && Parity_Error == 1'b0 && Frame_Error == 1'b0)
    $display($time," LOOPBACK PASSED - Sent=%b, Received=%b", DATA, Data_Out);
else
    $display($time," LOOPBACK FAILED - Sent=%b, Received=%b", DATA, Data_Out);

#50000 // to display ba in waveform

$finish;
end
endmodule
