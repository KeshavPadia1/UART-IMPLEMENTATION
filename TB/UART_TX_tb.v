`timescale 1ns / 1ps

module UART_TX_tb;

    reg [7:0] DATA;
    reg RST, CLK, TX_TICK, TX_START;
    wire TX;

    UART_TX A1 (DATA, RST, CLK, TX_TICK, TX_START, TX);

    // -------------------------------------------------------------------
    // Clock: 100 MHz (10ns period)
    // -------------------------------------------------------------------
    initial begin
        CLK = 1'b0;
        forever #5 CLK = ~CLK;
    end

    // -------------------------------------------------------------------
    // Initialize all inputs at t=0
    // -------------------------------------------------------------------
    initial begin
        RST      = 1'b0;
        TX_START = 1'b0;
        TX_TICK  = 1'b0;
        DATA     = 8'b0;
    end

    // -------------------------------------------------------------------
    // Reset pulse
    // -------------------------------------------------------------------
    initial begin
        #4  RST = 1'b1;
        #10 RST = 1'b0;
    end

    // -------------------------------------------------------------------
    // Artificial TX_TICK: fast bit-period tick, independent of Baud_Gen,
    // for isolated TX unit testing
    // -------------------------------------------------------------------
    initial begin
        forever begin
            #40 TX_TICK = 1'b1;
            #10 TX_TICK = 1'b0;
        end
    end

    // -------------------------------------------------------------------
    // Stimulus: send one byte, then a second byte to confirm the FSM
    // reloads and restarts cleanly
    // -------------------------------------------------------------------
    initial begin
        DATA = 8'b10101010;
        #20 TX_START = 1'b1;  // pulse after RST has deasserted
        #10 TX_START = 1'b0;

        #600 DATA = 8'b11001100;
        #10  TX_START = 1'b1;
        #10  TX_START = 1'b0;
    end

    // -------------------------------------------------------------------
    // Observation + simulation end
    // -------------------------------------------------------------------
    initial begin
        $monitor($time, " RST=%b TX_START=%b TX_TICK=%b DATA=%b STATE=%0d TX=%b",
                 RST, TX_START, TX_TICK, DATA, A1.STATE, TX);
        #3000 $finish;
    end

endmodule
