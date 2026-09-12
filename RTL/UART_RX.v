`timescale 1ns / 1ps

module UART_RX (
    RX,
    RX_TICK,
    CLK,
    RST,
    Data_Out,
    Done,
    Parity_Error,
    Frame_Error
);

    input  RX, RX_TICK, CLK, RST;
    output reg [7:0] Data_Out;
    output reg Done, Parity_Error, Frame_Error;

    reg [4:0] Bit_Count, Tick_Count;
    reg [7:0] SIPO_REG;

    parameter S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4;
    reg [2:0] STATE;

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            Bit_Count    <= 0;
            Tick_Count   <= 0;
            STATE        <= S0;
            SIPO_REG     <= 0;
            Data_Out     <= 0;
            Parity_Error <= 0;
            Frame_Error  <= 0;
            Done         <= 0;
        end
        else begin
            case (STATE)

                // ---------------------------------------------------------
                // S0: IDLE - watch the line for a start-bit edge
                // ---------------------------------------------------------
                S0: begin
                    Bit_Count    <= 0;
                    Tick_Count   <= 0;
                    SIPO_REG     <= 0;
                    Parity_Error <= 0;
                    Frame_Error  <= 0;
                    Done         <= 0;

                    if (RX == 1'b0) begin
                        STATE <= S1;
                    end
                end

                // ---------------------------------------------------------
                // S1: CONFIRM START - recheck at the midpoint to reject noise
                // ---------------------------------------------------------
                S1: begin
                    if (RX_TICK == 1'b1) begin
                        if (Tick_Count == 7) begin
                            Tick_Count <= 0;
                            if (RX == 1'b0) begin
                                STATE <= S2;  // real start bit confirmed
                            end
                            else begin
                                STATE <= S0;  // glitch, not a real start bit
                            end
                        end
                        else begin
                            Tick_Count <= Tick_Count + 1;
                        end
                    end
                end

                // ---------------------------------------------------------
                // S2: DATA BITS - sample at the midpoint of each bit, 8x
                // ---------------------------------------------------------
                S2: begin
                    if (RX_TICK == 1'b1) begin
                        if (Tick_Count == 15) begin
                            Tick_Count <= 0;
                            if (Bit_Count == 8) begin
                                STATE     <= S3;
                                Bit_Count <= 0;
                            end
                            else begin
                                SIPO_REG  <= {RX, SIPO_REG[7:1]};
                                Bit_Count <= Bit_Count + 1;
                            end
                        end
                        else begin
                            Tick_Count <= Tick_Count + 1;
                        end
                    end
                end

                // ---------------------------------------------------------
                // S3: PARITY - compare received bit against XOR of SIPO_REG
                // ---------------------------------------------------------
                S3: begin
                    if (RX_TICK == 1'b1) begin
                        if (Tick_Count == 15) begin
                            Tick_Count <= 0;
                            STATE      <= S4;
                            if (RX == (^SIPO_REG))
                                Parity_Error <= 1'b0;
                            else
                                Parity_Error <= 1'b1;
                        end
                        else begin
                            Tick_Count <= Tick_Count + 1;
                        end
                    end
                end

                // ---------------------------------------------------------
                // S4: STOP BIT - validate framing, latch output on success
                // ---------------------------------------------------------
                S4: begin
                    if (RX_TICK == 1'b1) begin
                        if (Tick_Count == 15) begin
                            Tick_Count <= 0;
                            STATE      <= S0;
                            if (RX == 1'b1) begin
                                Data_Out    <= SIPO_REG;
                                Done        <= 1'b1;
                                Frame_Error <= 1'b0;
                            end
                            else begin
                                Frame_Error <= 1'b1;
                            end
                        end
                        else begin
                            Tick_Count <= Tick_Count + 1;
                        end
                    end
                end

            endcase
        end
    end

endmodule
