# MicroBlaze Calculator System

<p align="center">
  <img src="docs/images/block_design.png" width="800" alt="Vivado Block Design">
</p>

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
| AXI GPIO 1 | 7-segment anodes and segment outputs |
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

The firmware is written in C and divided into small functions for readability and maintainability.

| Function | Description |
|---|---|
| `Initialize()` | Initializes GPIO and UART peripherals |
| `ReadSwitches()` | Reads the DIP switch values |
| `ReadSwMode()` | Extracts the mode bits from `SW15` and `SW0` |
| `WriteLeds()` | Writes values to the board LEDs |
| `LedPatt()` | Runs the idle-mode LED animation |
| `put7SEG()` | Writes one digit to the 7-segment display |
| `Write7SEG()` | Displays a 4-character word using multiplexing |
| `Decode7Seg()` | Converts characters into active-low 7-segment patterns |
| `UartTryGetChar()` | Reads UART input without blocking |
| `ProcessInputChar()` | Parses signed decimal floating-point input |
| `simpleCalc()` | Runs ADD/SUB calculator mode |
| `advancedCalc()` | Runs ADD/SUB/MUL/DIV calculator mode |
| `ClearScreen()` | Clears the UART terminal screen |

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
