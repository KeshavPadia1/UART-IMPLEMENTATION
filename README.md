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
- [ ] Transmitter (TX) — design + simulation
- [ ] Receiver (RX) — design + simulation
- [ ] Parity generation (TX) and checking (RX)
- [ ] TX/RX loopback verification
- [ ] Top-level integration
- [ ] Synthesis + Static Timing Analysis
