# UART (Universal Asynchronous Receiver-Transmitter)

UART is a peripheral, point-to-point, asynchronous serial communication protocol used for device-to-device data exchange without a shared clock line. This project implements a complete UART core (Transmitter, Receiver, and Baud Rate Generator) targeting an 8E1 configuration (8 data bits, even parity, 1 stop bit), with the baud rate designed to be configurable rather than hardcoded.

## Design Parameters

| Parameter     | Value             |
|---------------|-------------------|
| System Clock  | 100 MHz           |
| Baud Rate     | 9600 (configurable) |
| Data Bits     | 8                 |
| Stop Bits     | 1                 |
| Parity        | Even (1 bit)      |

## Architecture

The core consists of three modules: a shared Baud Rate Generator, a Transmitter (parallel-to-serial), and a Receiver (serial-to-parallel).

```
   ┌──────────────────┐         ┌──────────────┐     ┌───────────────────┐
   │    Data In        │────────►│   UART TX    │────►│  TX (Serial Out)  │
   │ (8-bit parallel)  │         │ (PISO + FSM) │     └───────────────────┘
   └─────────┬─────────┘         └──────────────┘
             │
   ┌─────────▼─────────┐
   │   Baud Rate        │
   │   Generator        │
   └─────────┬─────────┘
             │
   ┌─────────▼─────────┐  ┌────────────────────┐
   │  RX (Serial In)    │─►│      UART RX       │────► Data Out
   │  (SIPO + FSM)       │  │  (8-bit parallel)   │
   └────────────────────┘  └────────────────────┘
```

**Baud Rate Generator** — Derives precisely-timed tick pulses from the 100 MHz system clock: one tick per bit-period for the transmitter, and a 16x oversampled tick for the receiver, used for mid-bit sampling and noise rejection.

**Transmitter (TX)** — Loads an 8-bit parallel word and shifts it out serially (start bit → 8 data bits → even parity bit → stop bit), timed off the baud generator's tick. The parity bit is computed as the XOR of the 8 data bits.

**Receiver (RX)** — Detects the start-bit edge, then samples the serial line at the midpoint of each bit window (via 16x oversampling) to reconstruct the original 8-bit word. Independently recomputes the expected parity and compares it against the received parity bit to flag a `parity_error`, with stop-bit validation for basic framing-error detection.

## Repository Structure

```
UART/
├── rtl/
│   ├── baud_gen.v
│   ├── uart_tx.v
│   ├── uart_rx.v
│   └── uart_top.v
├── tb/
│   ├── uart_tx_tb.v
│   ├── uart_rx_tb.v
│   └── uart_loopback_tb.v
├── docs/
│   └── waveforms/
└── README.md
```

## Status

- [x] Baud rate generator + verification
- [x] Transmitter (TX): design + simulation
- [x] Receiver (RX): design + simulation
- [x] Top-level integration + simulation
- [x] Verification

## State Transition Diagram

### TX State Transition Diagram

```
                    ┌───────────────────────┐
                    │       S0: IDLE         │
                    │        TX = 1          │
                    └───────────┬───────────┘
                                │  TX_START = 1
                                ▼
                    ┌───────────────────────┐
                    │    S1: START BIT       │
                    │        TX = 0          │
                    └───────────┬───────────┘
                                │  TX_TICK
                                ▼
                    ┌───────────────────────┐
              ┌────►│    S2: DATA BITS       │
              │     │  shift out, LSB first  │
              │     └───────────┬───────────┘
              │                 │
              └─────────────────┤  TX_TICK, COUNT < 8  (loops 8x)
                                │  COUNT == 8
                                ▼
                    ┌───────────────────────┐
                    │      S3: PARITY        │
                    │   TX = parity bit      │
                    └───────────┬───────────┘
                                │  TX_TICK
                                ▼
                    ┌───────────────────────┐
                    │     S4: STOP BIT       │
                    │        TX = 1          │
                    └───────────┬───────────┘
                                │  TX_TICK
                                └──────────────► back to S0
```

### RX State Transition Diagram

```
                    ┌───────────────────────┐
                    │       S0: IDLE         │
                    │   watch for RX == 0    │
                    └───────────┬───────────┘
                                │  RX == 0
                                ▼
                    ┌───────────────────────┐
                    │  S1: CONFIRM START     │
                    │ recheck RX at midpoint │
                    └───────────┬───────────┘
                     RX == 0 (real start) │ RX == 1 (glitch) → back to S0
                                ▼
                    ┌───────────────────────┐
              ┌────►│    S2: DATA BITS       │
              │     │  sample @ midpoint x16 │
              │     └───────────┬───────────┘
              │                 │
              └─────────────────┤  tick x16, COUNT < 8  (loops 8x)
                                │  COUNT == 8
                                ▼
                    ┌───────────────────────┐
                    │      S3: PARITY        │
                    │  compare RX vs ^SIPO   │
                    └───────────┬───────────┘
                                │  tick x16
                                ▼
                    ┌───────────────────────┐
                    │     S4: STOP BIT       │
                    │    check RX == 1       │
                    └───────────┬───────────┘
                RX == 1 → Data_Out, Done   │   RX == 0 → Frame_Error
                                └──────────────► back to S0
```

## LoopBack Verification

UART_TOP is instantiated once, with its own TX output wired directly back into its own RX input inside the testbench (assign RX = TX) - this is a test-only connection, not how the core is meant to be deployed (in real use, TX/RX connect to a separate external device's RX/TX). A byte written to DATA and triggered via TX_START is transmitted, looped back, and independently reconstructed by the receiver.

```
                    ┌───────────────────────────────────┐
                    │              UART_TOP               │
                    │                                     │
  DATA[7:0] ───────►│                                     │
  TX_START ────────►│         TX ●────────────┐           │
                    │                          │           │
                    │         RX ●◄────────────┘           │
                    │                                     │
  Data_Out, Done,  ◄│                                     │
  Parity_Error,     │                                     │
  Frame_Error       └───────────────────────────────────┘
                         (testbench only: assign RX = TX;)
```
