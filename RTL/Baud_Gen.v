`timescale 1ns / 1ps

module Baud_Gen (
    CLK,
    RST,
    TX_TICK,
    RX_TICK
);

    input CLK, RST;
    output reg TX_TICK, RX_TICK;

    parameter CLK_FREQ  = 100_000_000;
    parameter BAUD_RATE = 9600;

    parameter TX_DIVISOR = CLK_FREQ / BAUD_RATE;          // ~10,416 cycles per bit
    parameter RX_DIVISOR = CLK_FREQ / (BAUD_RATE * 16);   // ~651 cycles per oversample tick (16x)

    reg [13:0] TX_COUNTER;  // counts up to ~10,416 -> 14 bits is the tight fit
    reg [9:0]  RX_COUNTER;  // counts up to ~651   -> 10 bits is the tight fit

    // ---------------------------------------------------------------------
    // TX_TICK: fires once per full bit-period, drives the transmitter
    // ---------------------------------------------------------------------
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            TX_COUNTER <= 0;
            TX_TICK    <= 0;
        end
        else if (TX_COUNTER == TX_DIVISOR - 1) begin  // -1 since counting starts from 0
            TX_COUNTER <= 0;
            TX_TICK    <= 1;
        end
        else begin
            TX_COUNTER <= TX_COUNTER + 1;
            TX_TICK    <= 0;
        end
    end

    // ---------------------------------------------------------------------
    // RX_TICK: fires 16x per bit-period, drives the receiver's oversampling
    // ---------------------------------------------------------------------
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            RX_COUNTER <= 0;
            RX_TICK    <= 0;
        end
        else if (RX_COUNTER == RX_DIVISOR - 1) begin
            RX_COUNTER <= 0;
            RX_TICK    <= 1;
        end
        else begin
            RX_COUNTER <= RX_COUNTER + 1;
            RX_TICK    <= 0;
        end
    end

endmodule
