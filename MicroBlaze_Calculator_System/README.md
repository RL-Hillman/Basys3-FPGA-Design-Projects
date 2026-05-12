# MicroBlaze Calculator System



## Overview

This project implements an embedded calculator system on the Basys3 FPGA board using a Xilinx MicroBlaze soft processor.

The system is controlled through board switches, push buttons, LEDs, a 4-digit 7-segment display, and UART terminal communication.

The calculator supports two operating modes:

| Mode | Switch Setting | Supported Operations |
|---|---|---|
| Idle Mode | `SW15 = 0`, `SW0 = 0` | Mode selection screen and LED pattern |
| Simple Calculator | `SW15 = 1`, `SW0 = 0` | ADD, SUB |
| Advanced Calculator | `SW15 = 0`, `SW0 = 1` | ADD, SUB, MUL, DIV |
| Invalid Mode | `SW15 = 1`, `SW0 = 1` | Warning message and blinking side LEDs |

## Project Goal

The goal of this project is to demonstrate a complete FPGA-based embedded system that combines hardware design in Vivado with modular C firmware running on a MicroBlaze soft processor.

This project demonstrates:

- MicroBlaze soft processor system design
- AXI GPIO peripheral usage
- UART-Lite terminal communication
- Switch and push-button input handling
- LED and 7-segment display control
- Modular C firmware
- Simple state-machine based calculator logic
- Manual floating-point input parsing

## Hardware Architecture

The Vivado hardware system includes:

| Peripheral | Purpose |
|---|---|
| MicroBlaze | Soft processor running the C firmware |
| AXI GPIO 0 | DIP switches and LEDs |
| AXI GPIO 1 | 7-segment anodes and segment display |
| AXI GPIO 2 | Push-button inputs |
| AXI UART-Lite | UART terminal communication |
| Clock / Reset | System clock and reset logic |

## Vivado Block Design

<p align="center">
  <img src="docs/images/block_design.png" width="850" alt="Vivado MicroBlaze Block Design">
</p>

## AXI Address Map

<p align="center">
  <img src="docs/images/address_map.png" width="850" alt="AXI Address Map">
</p>

## Firmware Structure

The firmware is written in C and organized into modular functions.

| Function | Description |
|---|---|
| `main()` | Main program loop. Continuously checks the selected mode and calls the matching system function |
| `Initialize()` | Initializes AXI GPIO peripherals and UART-Lite |
| `ReadSwitches()` | Reads the 16 DIP switch values |
| `ReadSwMode()` | Extracts the mode bits from `SW15` and `SW0` |
| `ReadButtons()` | Reads the push-button GPIO input |
| `WriteLeds()` | Writes values to the 16 board LEDs |
| `LedPatt()` | Runs the menu moving LED animation |
| `put7SEG()` | Writes one active anode and one segment pattern to the 7-segment display |
| `Write7SEG()` | Displays a 4-character word using 7-segment multiplexing |
| `Decode7Seg()` | Converts a character into an active-low 7-segment pattern |
| `ClearScreen()` | Clears the UART terminal using ANSI escape sequences |
| `UartTryGetChar()` | Reads one UART character without blocking the program |
| `UartSendChar()` | Sends one character through UART-Lite |
| `UartSendUnsignedInt()` | Sends an unsigned integer through UART without using heavy formatted printing |
| `UartSendFloat3()` | Sends a floating-point number with 3 decimal digits |
| `ProcessInputChar()` | Builds and parses signed decimal input from UART characters |
| `simpleCalc()` | Runs Simple Calculator mode: ADD and SUB |
| `advancedCalc()` | Runs Advanced Calculator mode: ADD, SUB, MUL, and DIV |

## Calculator State Machine

```text
GET_X
  |
  | User enters first operand through UART
  v
GET_Y
  |
  | User enters second operand through UART
  v
WAIT_OPERATION
  |
  | User presses operation button
  v
Print result to UART terminal
```

## Static ELF Memory Footprint

After building the MicroBlaze application, the generated ELF file size was:

| Section | Size (bytes) | Approx. KiB | Meaning |
|---|---:|---:|---|
| `text` | 25,024 | 24.44 KiB | Program code and read-only data |
| `data` | 700 | 0.68 KiB | Initialized global/static variables |
| `bss` | 3,244 | 3.17 KiB | Uninitialized global/static variables |
| `dec` | 28,968 | 28.29 KiB | Total static size |
| `hex` | `0x7128` | — | Total size in hexadecimal |

```text
text    data    bss     dec     hex     filename
25024   700     3244    28968   7128    microblaze_gpio.elf
```

This footprint represents the static ELF size after compilation. It does not include dynamic stack usage during runtime.

The firmware avoids heavy floating-point formatted printing by using a custom `UartSendFloat3()` function instead of `printf("%.3f")`.
