`timescale 1ns / 1ps

module UART_TX(DATA,RST,CLK,TX_TICK,TX_START,TX);

input TX_START,TX_TICK,RST,CLK;
input[7:0] DATA;
output reg TX;
reg PARITY;
reg[2:0] STATE;
parameter S0=0,S1=1,S2=2,S3=3,S4=4;
reg[7:0] SHIFT_REG;
reg[3:0] COUNT;

always @(posedge CLK or posedge RST)
begin

if(RST) begin
TX <= 1'b1;
STATE <= S0;
COUNT <= 0;
SHIFT_REG <= DATA;
end 

else 
begin
case(STATE)

S0: begin 

    if(TX_START == 1'b1) begin
    STATE     <= S1;
    COUNT     <= 0; // for consideration of next byte
    SHIFT_REG <= DATA;
    PARITY    <= ^DATA; 
    TX <= 1'b0;
    end
    
    else TX <= 1'b1;
    end

S1: begin

    if(TX_TICK == 1'b1) begin
    STATE     <= S2;
    TX        <= SHIFT_REG[0];
    SHIFT_REG <= SHIFT_REG >> 1;
    COUNT     <= 1;
    end
    
    else TX <= 1'b0;
    end 
    
S2: begin
    if(TX_TICK == 1) begin
    
    if(COUNT == 8) begin 
    STATE <= S3;
    TX <= PARITY;
    end 
    
    else begin 
    TX <= SHIFT_REG[0];
    SHIFT_REG <= SHIFT_REG >> 1;
    COUNT <= COUNT + 1;
    end
    
    end
    end
    
S3: begin 
    if(TX_TICK == 1) begin 
    STATE <= S4;
    TX <= 1; // STOP-BIT
    end
    else TX <= PARITY;
    end
    
 S4: begin 
     if(TX_TICK == 1) begin
     STATE <= S0;
     TX <= 1; // IDLE STATE
     end
     else TX <= 1; // STOP-BIT
     end
 
endcase
end
end
endmodule
