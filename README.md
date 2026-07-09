# FPGA Basys3 VHDL Projects

<p align="center">
  <img src="docs/images/fpga_basys3_banner.png" alt="FPGA Basys3 VHDL Projects" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/HDL-VHDL-1f6feb?style=for-the-badge" alt="VHDL">
  <img src="https://img.shields.io/badge/FPGA-Basys3%20%7C%20Artix--7-238636?style=for-the-badge" alt="Basys3 Artix-7">
  <img src="https://img.shields.io/badge/Tool-Xilinx%20Vivado-da3633?style=for-the-badge" alt="Xilinx Vivado">
  <img src="https://img.shields.io/badge/Soft%20Processors-MicroBlaze%20%7C%20KCPSM6%20PicoBlaze-f7811d?style=for-the-badge" alt="MicroBlaze and KCPSM6 PicoBlaze">
  <img src="https://img.shields.io/badge/Interface-AXI4--Lite-8957e5?style=for-the-badge" alt="AXI4-Lite">
</p>

<p align="center">
<b>RTL Design · Soft Processor Systems · Custom AXI IP · Hardware/Software Co-Design · Simulation & Verification</b>
</p>

---

## Overview

This repository contains a collection of FPGA projects developed for the **Digilent Basys3** development board, based on the **Xilinx Artix-7** FPGA.

The projects move from standalone RTL designs to complete embedded FPGA systems using **MicroBlaze**, **KCPSM6 PicoBlaze**, custom **AXI4-Lite** peripherals, board-level I/O, firmware, and simulation testbenches.

Each project is self-contained and includes its own source files, constraints, simulation material, implementation notes, diagrams, and README documentation.

---

## Featured Projects

<table>
<tr>
<td width="38%">
  <img src="MicroBlaze_AXI_Custom_IP_Traffic_Light_Controller/DOCS/block_design.png" alt="Traffic Light Controller Block Design" width="100%">
</td>
<td width="62%">

### [MicroBlaze AXI Custom IP Traffic Light Controller](./MicroBlaze_AXI_Custom_IP_Traffic_Light_Controller)

Hardware/software co-design built around a custom **AXI4-Lite traffic-light controller IP**.  
The traffic decision logic runs in VHDL hardware as an FSM with hardware timers, while the MicroBlaze processor handles monitoring, switch input forwarding, UART status output, and seven-segment display control.

**Main areas:** `MicroBlaze` · `AXI4-Lite` · `Custom IP` · `VHDL FSM` · `Embedded C` · `Hardware Timers`

</td>
</tr>
</table>

<table>
<tr>
<td width="38%">
  <img src="MicroBlaze_Calculator_System/docs/images/block_design.png" alt="MicroBlaze Calculator Block Design" width="100%">
</td>
<td width="62%">

### [MicroBlaze Calculator System](./MicroBlaze_Calculator_System)

Bare metal calculator system running on a **MicroBlaze soft processor**.  
The system combines UART-Lite input, AXI GPIO peripherals, push-button operation selection, switch-based mode control, LEDs, and seven-segment display output.

**Main areas:** `MicroBlaze` · `Bare-Metal C` · `AXI GPIO` · `UART-Lite` · `7-Segment Display` · `State Machines`

</td>
</tr>
</table>

<table>
<tr>
<td width="38%">
  <img src="PicoBlaze_KCPSM6_Debounce/docs/images/vivado_rtl_schematic.png" alt="PicoBlaze Debounce RTL Schematic" width="100%">
</td>
<td width="62%">

### [KCPSM6 PicoBlaze Switch Debounce System](./PicoBlaze_KCPSM6_Debounce)

Switch debounce system implemented using the **KCPSM6 PicoBlaze** soft processor.  
The debounce algorithm runs as PicoBlaze assembly firmware, while the surrounding VHDL system handles program memory integration, I/O port decoding, switch sampling, and LED output storage.

**Main areas:** `PicoBlaze` · `Assembly` · `VHDL` · `I/O Port Decoding` · `Program Memory ROM` · `Simulation`

</td>
</tr>
</table>

<table>
<tr>
<td width="38%">
  <img src="3_Digit_Decimal_Counter/images/System_Block_Diagram.png" alt="3-Digit Counter System Block Diagram" width="100%">
</td>
<td width="62%">

### [3-Digit Multiplexed 7-Segment Counter](./3_Digit_Decimal_Counter)

Modular VHDL counter system for the Basys3 seven segment display.  
The design includes clock division, cascaded decimal counters, display refresh logic, digit selection, segment decoding, terminal count detection, and testbenches for both full system and component level verification.

**Main areas:** `VHDL` · `RTL Design` · `Counters` · `Clock Division` · `Display Multiplexing` · `Testbenches`

</td>
</tr>
</table>

---

## Engineering Scope

<table>
<tr>
<td align="center" width="20%"><b>RTL Design</b><br>VHDL modules, counters, FSMs, timers, display logic</td>
<td align="center" width="20%"><b>Embedded Systems</b><br>MicroBlaze and PicoBlaze based FPGA systems</td>
<td align="center" width="20%"><b>Custom IP</b><br>AXI4-Lite peripheral design and register mapping</td>
<td align="center" width="20%"><b>Firmware</b><br>Bare metal C and PicoBlaze assembly</td>
<td align="center" width="20%"><b>Verification</b><br>Vivado behavioral simulation and VHDL testbenches</td>
</tr>
</table>

---

## Development Flow

```mermaid
flowchart TD
    A[Project Source Files] --> B{Project Type}

    B --> C[Standalone RTL Design]
    B --> D[Embedded FPGA System]

    C --> C1[VHDL Modules]
    C1 --> C2[Testbench Simulation]
    C2 --> C3[XDC Constraints]
    C3 --> C4[Synthesis & Implementation]
    C4 --> C5[Bitstream]
    C5 --> C6[Basys3 Hardware Test]

    D --> D1[Soft Processor System]
    D1 --> D2{Processor Type}

    D2 --> E[MicroBlaze System]
    D2 --> F[KCPSM6 PicoBlaze System]

    E --> E1[AXI GPIO / UART-Lite / Custom AXI IP]
    E1 --> E2[Vivado Block Design]
    E2 --> E3[Hardware Export]
    E3 --> E4[Embedded C Firmware]
    E4 --> E5[Program FPGA and Run on Basys3]

    F --> F1[PicoBlaze Assembly Firmware]
    F1 --> F2[Program ROM Generation]
    F2 --> F3[VHDL Top-Level Integration]
    F3 --> F4[Simulation]
    F4 --> F5[Synthesis & Bitstream]
    F5 --> F6[Basys3 Hardware Test]
```

---

## Development Environment

| Category | Tools / Technologies |
|---|---|
| FPGA Board | Digilent Basys3 |
| FPGA Device | Xilinx Artix-7 |
| HDL | VHDL |
| FPGA Toolchain | Xilinx Vivado |
| Embedded Toolchain | Xilinx SDK, KCPSM6 tools, pBlazIDE |
| Soft Processors | MicroBlaze, KCPSM6 PicoBlaze |
| Firmware | Embedded C, PicoBlaze Assembly |
| Interfaces | AXI4-Lite, AXI GPIO, UART-Lite, PicoBlaze I/O Ports |
| Board I/O | Switches, Push Buttons, LEDs, Seven-Segment Display, UART |
| Verification | Vivado Behavioral Simulation, VHDL Testbenches |

---
## Repository Structure

```text
FPGA_Basys3_VHDL_Projects/
│
├── README.md
│
├── docs/
│
├── MicroBlaze_AXI_Custom_IP_Traffic_Light_Controller/
│   ├── DOCS/
│   ├── SDK_code/
│   ├── constrs/
│   ├── traffic_fsm_IP/
│   └── README.md
│
├── MicroBlaze_Calculator_System/
│   ├── docs/
│   ├── src/
│   └── README.md
│
├── PicoBlaze_KCPSM6_Debounce/
│   ├── vivado_sources/
│   ├── firmware/
│   ├── constraints/
│   ├── sim/
│   ├── tools/
│   ├── docs/
│   └── README.md
│
└── 3_Digit_Decimal_Counter/
    ├── src/
    ├── sim/
    ├── constraints/
    ├── images/
    └── README.md
```


---

## Author

**Harel Hillman**

FPGA & Embedded Systems Engineer specializing in VHDL, custom AXI IP development, hardware/software co design, and bare metal embedded firmware.

<p align="center">
  <b>Designed, implemented, simulated, and verified on Digilent Basys3 using Xilinx Vivado.</b>
</p>
