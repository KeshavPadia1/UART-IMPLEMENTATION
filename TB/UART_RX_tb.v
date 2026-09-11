`timescale 1ns / 1ps

module UART_RX_tb;

reg RX,RX_TICK,CLK,RST;
wire[7:0] Data_Out;
wire Done,Parity_Error,Frame_Error;

reg Parity;
reg[7:0] test_data;

UART_RX T1(RX,RX_TICK,CLK,RST,Data_Out,Done,Parity_Error,Frame_Error);

initial
begin 
CLK=1'b0;
forever #5 CLK=~CLK;
end

initial 
begin 
RST=1'b0;
#4 RST=1'b1;
#10 RST=1'b0;
end 

initial begin
  RX_TICK = 1'b0;
  forever begin
    #20 RX_TICK = 1'b1;
    #10 RX_TICK = 1'b0;
  end
end

task send_bit(input b);
begin 
RX=b;
repeat(16) @(posedge RX_TICK);
end
endtask 

task send_frame(input[7:0] data);
integer i;
begin
Parity = ^data;
send_bit(1'b0); // Start bit
for(i=0;i<8;i=i+1) begin
send_bit(data[i]);
end 
send_bit(Parity);
send_bit(1'b1);
end 
endtask

initial 
begin 
RX=1'b1;
test_data = 8'b10101011;

#20 send_frame(test_data);

wait(Done==1'b1);
if(Data_Out === test_data && Parity_Error == 1'b0) begin 
$display($time," PASSED - Pass_Data=%b, Received_Data=%b",test_data,Data_Out);
end 
else begin 
$display($time," FAILED - Pass_Data=%b, Received_Data=%b",test_data,Data_Out);
end 

#200 $finish;
end 

endmodule
