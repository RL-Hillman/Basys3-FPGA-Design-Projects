# FPGA Basys3 VHDL Projects 🚀

[![Hardware](https://img.shields.io/badge/Hardware-Basys3_Artix--7-blue.svg)](#)
[![Language](https://img.shields.io/badge/HDL-VHDL-orange.svg)](#)
[![Firmware](https://img.shields.io/badge/Firmware-C_|_Assembly-lightgrey.svg)](#)
[![Tools](https://img.shields.io/badge/Tools-Xilinx_Vivado-red.svg)](#)

## 📌 Overview
This repository contains a comprehensive collection of practical FPGA projects developed on the **Basys3 (Xilinx Artix-7)** development board[cite: 1, 2, 3, 4]. The projects showcase a clear progression from foundational digital logic design in VHDL to advanced hardware-software co-design utilizing soft-core processors[cite: 1, 2, 3, 4].

The primary focus is on **Embedded Real-Time Engineering**, demonstrating proficiency in:
* RTL Design and modular VHDL architecture[cite: 1, 2, 4].
* Soft-core Processor Integration (MicroBlaze, PicoBlaze / KCPSM6)[cite: 1, 2, 3].
* Custom AXI4-Lite IP creation and memory-mapped interfaces[cite: 2].
* Low-level Bare-Metal Firmware Development (C and Assembly)[cite: 1, 2, 3].
* Standard communication protocols and peripheral control (UART-Lite, AXI GPIO, 7-Segment Multiplexing)[cite: 2, 3, 4].

---

## 📂 Projects Directory

### 1. [MicroBlaze AXI Custom IP Traffic Light Controller](./MicroBlaze_AXI_Custom_IP_Traffic_Light_Controller)
An FPGA-based traffic light controller combining a custom VHDL finite state machine (FSM) with a MicroBlaze soft processor[cite: 2]. 
* **Key Features:** The traffic decision logic runs fully in hardware, while the MicroBlaze handles system monitoring and user interface tasks via a custom AXI4-Lite IP core[cite: 2]. 
* **Tech Stack:** MicroBlaze, Custom AXI4-Lite IP, VHDL, Embedded C[cite: 2].

### 2. [MicroBlaze Calculator System](./MicroBlaze_Calculator_System)
A compact, resource-aware embedded calculator system controlled via physical board components and UART serial communication[cite: 3].
* **Key Features:** Features bare-metal modular C firmware with non-blocking UART input handling, manual floating-point parsing, and state-machine-based calculator logic utilizing only ~28.3 KiB of static memory[cite: 3].
* **Tech Stack:** MicroBlaze, AXI GPIO, AXI UART-Lite, Embedded C[cite: 3].

### 3. [KCPSM6 PicoBlaze Switch Debounce System](./PicoBlaze_KCPSM6_Debounce)
A hardware/software co-design implementing a switch debounce algorithm using the ultra-compact KCPSM6 PicoBlaze soft processor[cite: 1].
* **Key Features:** Offloads sequential debounce logic to a soft-core processor using PicoBlaze assembly firmware, integrating the processor core into a VHDL top-level design with custom I/O port decoding[cite: 1].
* **Tech Stack:** KCPSM6 PicoBlaze, VHDL, PicoBlaze Assembly[cite: 1].

### 4. [3-Digit Multiplexed 7-Segment Counter](./3_Digit_Decimal_Counter)
A modular 3-digit decimal counter system built entirely in VHDL, counting up to a user-selected terminal value[cite: 4].
* **Key Features:** Implements parameterized clock division, dynamic 7-segment display multiplexing, and synchronous control logic for terminal-count detection[cite: 4].
* **Tech Stack:** VHDL, RTL Simulation[cite: 4].

---

## 🛠️ Skills & Technologies Demonstrated

* **Hardware Description:** VHDL (FSMs, Modular Architecture, Testbenches)[cite: 1, 2, 4].
* **Embedded Software:** C (Bare-metal, Memory Optimization), KCPSM6 Assembly[cite: 1, 2, 3].
* **System Design:** Hardware/Software Co-design, AXI4-Lite Interconnects, Address Mapping[cite: 1, 2, 3].
* **Development Tools:** Xilinx Vivado Design Suite, Xilinx SDK, pBlazIDE[cite: 1, 3].
* **Interfaces & Peripherals:** UART, GPIO, Hardware Timers, 7-Segment Displays, Switches/LEDs[cite: 1, 2, 3, 4].

---

## 👨‍💻 About the Author
**Harel Hillman**
Electrical Engineering student specializing in Embedded Systems, RTL Design, and Low-Level Firmware. Passionate about bringing hardware and software together to build optimized, real-time architectures.

* **LinkedIn:** [Insert Link]
* **Email:** [Insert Email]
