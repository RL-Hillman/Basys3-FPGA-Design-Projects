# FPGA Basys3 VHDL Projects 🚀

<p align="center">
  <img src="docs/images/fpga_basys3_banner.png" alt="FPGA Basys3 Projects Banner" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/HDL-VHDL-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/Tool-Xilinx%20Vivado-red?style=for-the-badge">
  <img src="https://img.shields.io/badge/Board-Basys3-green?style=for-the-badge">
  <img src="https://img.shields.io/badge/FPGA-Artix--7-orange?style=for-the-badge">
  <img src="https://img.shields.io/badge/Processor-MicroBlaze-purple?style=for-the-badge">
  <img src="https://img.shields.io/badge/Processor-KCPSM6%20PicoBlaze-yellow?style=for-the-badge">
  <img src="https://img.shields.io/badge/Interface-AXI4--Lite-6f42c1?style=for-the-badge">
  <img src="https://img.shields.io/badge/Firmware-C%20%7C%20Assembly-lightgrey?style=for-the-badge">
</p>

## Overview

This repository contains a collection of FPGA projects developed on the **Digilent Basys3 / Xilinx Artix-7** development board using **VHDL**, **Xilinx Vivado**, and Xilinx soft processors.

The projects range from standalone RTL designs to embedded FPGA systems based on **MicroBlaze**, **KCPSM6 PicoBlaze**, and custom **AXI4-Lite** peripherals.

Each project is self-contained and includes source files, constraints, simulation material, implementation details, and project-specific documentation.

## Projects

| # | Project | Description | Main Topics |
|---:|---|---|---|
| 1 | **[MicroBlaze AXI Custom IP Traffic Light Controller](./MicroBlaze_AXI_Custom_IP_Traffic_Light_Controller)** | FPGA-based traffic light controller combining a custom VHDL FSM, hardware timers, AXI4-Lite register interface, and MicroBlaze software for monitoring and display control. | `MicroBlaze` `AXI4-Lite` `Custom IP` `VHDL` `Embedded C` |
| 2 | **[MicroBlaze Calculator System](./MicroBlaze_Calculator_System)** | Bare-metal calculator system using MicroBlaze, AXI GPIO, UART-Lite, push buttons, switches, LEDs, and seven-segment display control. | `MicroBlaze` `Embedded C` `AXI GPIO` `UART-Lite` |
| 3 | **[KCPSM6 PicoBlaze Switch Debounce System](./PicoBlaze_KCPSM6_Debounce)** | Switch debounce system implemented with PicoBlaze assembly firmware integrated into a VHDL top-level design with custom I/O port decoding. | `PicoBlaze` `Assembly` `VHDL` `I/O Ports` |
| 4 | **[3-Digit Multiplexed 7-Segment Counter](./3_Digit_Decimal_Counter)** | Modular VHDL decimal counter with clock division, cascaded digit counters, multiplexed seven-segment display control, and simulation testbenches. | `VHDL` `RTL` `Counters` `7-Segment` |

## Development Environment

| Category | Tools / Technologies |
|---|---|
| FPGA Board | Digilent Basys3 |
| FPGA Device | Xilinx Artix-7 |
| HDL | VHDL |
| Toolchain | Xilinx Vivado |
| Soft Processors | MicroBlaze, KCPSM6 PicoBlaze |
| Firmware | Embedded C, PicoBlaze Assembly |
| Interfaces | AXI4-Lite, AXI GPIO, UART-Lite |
| Verification | Vivado Behavioral Simulation, VHDL Testbenches |
| Board I/O | Switches, Push Buttons, LEDs, Seven-Segment Display, UART |

## Repository Structure

```text
FPGA_Basys3_VHDL_Projects/
│
├── MicroBlaze_AXI_Custom_IP_Traffic_Light_Controller/
│   ├── DOCS/
│   ├── SDK_code/
│   ├── traffic_fsm_IP/
│   └── README.md
│
├── MicroBlaze_Calculator_System/
│   ├── docs/
│   ├── SDK_code/
│   └── README.md
│
├── PicoBlaze_KCPSM6_Debounce/
│   ├── vivado_sources/
│   ├── firmware/
│   ├── sim/
│   ├── constraints/
│   └── README.md
│
├── 3_Digit_Decimal_Counter/
│   ├── src/
│   ├── sim/
│   ├── constraints/
│   └── README.md
│
└── README.md
```

## Project Focus

The repository emphasizes practical FPGA development with a focus on:

- Modular VHDL design
- Finite state machines
- Custom AXI4-Lite peripheral integration
- Embedded soft-processor systems
- Bare-metal firmware
- Board-level I/O control
- Behavioral simulation and verification
- Hardware/software co-design

## Author

**Harel Hillman**  
Electrical Engineering student focused on FPGA design, embedded systems, RTL development, and low-level firmware.

- LinkedIn: `[Insert LinkedIn URL]`
- Email: `[Insert Email]`

<p align="center">
  <b>Designed, implemented, simulated, and verified on Digilent Basys3 using Xilinx Vivado.</b>
</p>
