`timescale 1ns / 1ps

module UART_TX (
    DATA,
    RST,
    CLK,
    TX_TICK,
    TX_START,
    TX
);

    input TX_START, TX_TICK, RST, CLK;
    input  [7:0] DATA;
    output reg TX;

    reg PARITY;
    reg [7:0] SHIFT_REG;
    reg [3:0] COUNT;

    parameter S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4;
    reg [2:0] STATE;

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            TX        <= 1'b1;
            STATE     <= S0;
            COUNT     <= 0;
            SHIFT_REG <= DATA;
        end
        else begin
            case (STATE)

                // ---------------------------------------------------------
                // S0: IDLE - line held high, wait for a byte to send
                // ---------------------------------------------------------
                S0: begin
                    if (TX_START == 1'b1) begin
                        STATE     <= S1;
                        COUNT     <= 0;       // reset for the new byte
                        SHIFT_REG <= DATA;
                        PARITY    <= ^DATA;
                        TX        <= 1'b0;
                    end
                    else begin
                        TX <= 1'b1;
                    end
                end

                // ---------------------------------------------------------
                // S1: START BIT - hold low for one bit-period
                // ---------------------------------------------------------
                S1: begin
                    if (TX_TICK == 1'b1) begin
                        STATE     <= S2;
                        TX        <= SHIFT_REG[0];  // output bit 0 immediately
                        SHIFT_REG <= SHIFT_REG >> 1;
                        COUNT     <= 1;
                    end
                    else begin
                        TX <= 1'b0;
                    end
                end

                // ---------------------------------------------------------
                // S2: DATA BITS - shift out remaining bits, LSB first
                // ---------------------------------------------------------
                S2: begin
                    if (TX_TICK == 1'b1) begin
                        if (COUNT == 8) begin
                            STATE <= S3;
                            TX    <= PARITY;
                        end
                        else begin
                            TX        <= SHIFT_REG[0];
                            SHIFT_REG <= SHIFT_REG >> 1;
                            COUNT     <= COUNT + 1;
                        end
                    end
                end

                // ---------------------------------------------------------
                // S3: PARITY - hold the computed even-parity bit
                // ---------------------------------------------------------
                S3: begin
                    if (TX_TICK == 1'b1) begin
                        STATE <= S4;
                        TX    <= 1'b1;  // stop bit
                    end
                    else begin
                        TX <= PARITY;
                    end
                end

                // ---------------------------------------------------------
                // S4: STOP BIT - hold high for one bit-period, then idle
                // ---------------------------------------------------------
                S4: begin
                    if (TX_TICK == 1'b1) begin
                        STATE <= S0;
                        TX    <= 1'b1;  // idle
                    end
                    else begin
                        TX <= 1'b1;  // stop bit
                    end
                end

            endcase
        end
    end

endmodule
