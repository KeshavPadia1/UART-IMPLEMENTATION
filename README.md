# UART (Universal Asynchronous Receiver-Transmitter)
UART is a peripheral, point-to-point, asynchronous serial communication protocol used for device-to-device data exchange without a shared clock line. This project implements a complete UART core (Transmitter, Receiver, and Baud Rate Generator) targeting an 8E1 configuration (8 data bits, even parity, 1 stop bit), with the baud rate designed to be configurable rather than hardcoded.
## Design Parameters
Parameter	       Value
System Clock	100 MHz
---
Baud Rate	9600 (configurable)
---
Data Bits	8
---
Stop Bits	1
---
Parity	Even (1 bit)
---
