# KCPSM6 PicoBlaze Switch Debounce System

![HDL](https://img.shields.io/badge/HDL-VHDL-blue.svg) ![Soft Core](https://img.shields.io/badge/Soft_Core-KCPSM6%20PicoBlaze-orange.svg) ![Hardware](https://img.shields.io/badge/Hardware-Vivado%20RTL-purple.svg) ![Platform](https://img.shields.io/badge/Platform-Basys3-green.svg) ![Toolchain](https://img.shields.io/badge/Toolchain-Vivado%20%2B%20KCPSM6-red.svg) ![Interface](https://img.shields.io/badge/Interface-PicoBlaze%20I%2FO%20Ports-lightgrey.svg)


## Overview

This project implements a switch debounce system on the Basys3 FPGA board using the **KCPSM6 PicoBlaze soft microcontroller**.

The system reads a 4-bit input from the physical board switches, performs a software debounce algorithm in PicoBlaze assembly, reverses the bit order, and outputs the result to four physical LEDs.

The project demonstrates a complete FPGA soft-processor workflow: writing assembly firmware, generating VHDL program memory, integrating the KCPSM6 core into a VHDL top-level design, decoding PicoBlaze I/O ports, verifying the behavior in simulation, and preparing the design for Basys3 hardware implementation.

## Project Goal

The goal of this project is to demonstrate how a small soft-core processor can be used inside an FPGA to implement a practical embedded control task.

Instead of designing the debounce algorithm entirely as custom VHDL logic, the debounce process is implemented as firmware running on PicoBlaze. The surrounding VHDL logic handles the hardware interface: switch sampling, LED output storage, PicoBlaze I/O port decoding, and Basys3 pin mapping through the XDC constraints file.




This project demonstrates:

- Hardware/software co-design inside an FPGA
- KCPSM6 PicoBlaze soft processor integration
- PicoBlaze assembly programming
- VHDL top-level system design
- Program memory generation from `.psm` firmware
- Register-based FPGA hardware interfacing
- PicoBlaze `INPUT` and `OUTPUT` port decoding
- Vivado behavioral simulation and waveform verification

## System Behavior

The system continuously samples the four physical switches on the Basys3 board.

After the input remains stable for the required debounce period, the firmware reverses the order of the four input bits and writes the result to the LEDs.

```text
Input:   sw[3:0]
Output:  led[3:0]
```

The bit reversal is:

| Switch Input | LED Output |
|---|---|
| `sw[0]` | `led[3]` |
| `sw[1]` | `led[2]` |
| `sw[2]` | `led[1]` |
| `sw[3]` | `led[0]` |

Example:

```text
sw[3:0]  = 0001
led[3:0] = 1000
```

## Target Hardware and Tools

| Category | Details |
|---|---|
| FPGA Board | Digilent Basys3 |
| FPGA Device | Xilinx / AMD Artix-7 |
| Clock | 100 MHz |
| Soft Processor | KCPSM6 PicoBlaze |
| Firmware Language | PicoBlaze Assembly |
| Hardware Description Language | VHDL |
| FPGA Tool | Xilinx Vivado |
| Firmware Tools | pBlazIDE, KCPSM6 Assembler |
| Inputs | 4 physical switches |
| Outputs | 4 physical LEDs |

## Hardware Architecture and HDL Components

The hardware system is built around the **KCPSM6 PicoBlaze** and a generated VHDL program memory ROM.

The debounce algorithm runs in PicoBlaze assembly firmware, while the surrounding VHDL logic connects the processor to the Basys3 switches and LEDs.

<p align="center">
  <img src="docs/images/vivado_rtl_schematic.png"
       width="1200"
       height="800"
       alt="Vivado RTL Schematic of the PicoBlaze Debounce System">
</p>

The schematic above shows the RTL-level connection between the main design components.

### `top.vhd`

`top.vhd` is the top-level wrapper of the FPGA design.

It connects the external Basys3 signals to the internal PicoBlaze-based system:

```vhdl
clk : in std_logic;
rst : in std_logic;
sw  : in  std_logic_vector(3 downto 0);
led : out std_logic_vector(3 downto 0);
```

Inside this file, the design instantiates the PicoBlaze processor, the generated program memory, the switch register, and the LED register.

It also contains the VHDL logic that connects PicoBlaze logical I/O ports to the hardware interface:

| PicoBlaze Port | Direction | Connected Hardware |
|---|---|---|
| `0x00` | Input | Registered switch value |
| `0x01` | Output | LED register |

The PicoBlaze processor does not connect directly to the Basys3 switches and LEDs.  
`top.vhd` defines the complete hardware system around the processor.

---

### `kcpsm6.vhd`

`kcpsm6.vhd` is the KCPSM6 PicoBlaze processor core.

This is the soft soft-core processor that executes the PicoBlaze assembly firmware.  
In this project, the firmware performs the debounce algorithm, checks that the switch input is stable, reverses the lower four bits, and writes the result to the output port.

The processor communicates with the rest of the design through:

| Signal | Purpose |
|---|---|
| `address` | Selects the next instruction address in program memory |
| `instruction` | Carries the instruction from program memory back to PicoBlaze |
| `bram_enable` | Enables the program memory during instruction fetch |
| `in_port` | Carries input data into PicoBlaze |
| `out_port` | Carries output data from PicoBlaze |
| `port_id` | Selects the logical I/O port |
| `write_strobe` | Indicates a valid output write cycle |

The debounce process is implemented as software running on a soft processor, rather than as a fully custom VHDL state machine.

---

### `PicoBlaze_Debounce.vhd`

`PicoBlaze_Debounce.vhd` is the program memory of the PicoBlaze system.

This file contains the actual machine instructions that the KCPSM6 processor runs.  

It was generated from the PicoBlaze assembly source file using the KCPSM6 assembler.

The original firmware is written in a human-readable `.psm` assembly file, but the FPGA design uses the generated VHDL ROM version:

```text
PicoBlaze_Debounce.psm
        +
ROM_form.vhd
        |
        v
kcpsm6.exe
        |
        v
PicoBlaze_Debounce.vhd
```

During operation, the PicoBlaze processor sends an instruction address to this memory through `address`.  
The program memory returns the matching 18-bit instruction through `instruction`.  
The `bram_enable` signal enables the memory access, and `clk` synchronizes the ROM with the rest of the system.

---



### `PicoBlaze_Debounce_tst.vhd`

`PicoBlaze_Debounce_tst.vhd` is a simulation version of the generated program memory.

It contains the same firmware logic but uses a shorter debounce delay, so the design can be simulated faster in Vivado.

For hardware implementation, use:

```vhdl
program_memory_inst : entity work.PicoBlaze_Debounce
```

For fast simulation, use:

```vhdl
program_memory_inst : entity work.PicoBlaze_Debounce_tst
```
---

### `switch_register_inst`

`switch_register_inst` is an instance of the generic `REG.vhd` module that samples and stores the physical switch inputs.

```text
sw[3:0]  ->  switch_register_inst  ->  switch_reg_value
```

Its purpose is to provide the PicoBlaze processor with a stable, clock-synchronized, and modular interface to the external switches. By registering the input values, the design separates the physical board signals from the internal logic and ensures that the processor always reads a synchronized value.

When PicoBlaze performs an `INPUT` operation from port `0x00`, `top.vhd` places the registered switch value on `in_port`:

```vhdl
when X"00" =>
    in_port <= "0000" & switch_reg_value;
```

The upper four bits are filled with zeros because PicoBlaze uses 8-bit I/O ports, while this project uses only four switch inputs.

---

### `led_register_inst`

`led_register_inst` is another instance of the generic `REG.vhd` register module.

It stores the lower four bits written by PicoBlaze and drives the physical LEDs.

```text
out_port[3:0]  ->  led_register_inst  ->  led[3:0]
```

This register is needed because `out_port` is only valid during a PicoBlaze output operation.  
The LEDs must keep displaying the last valid output value after the `OUTPUT` instruction has finished.

The LED register updates only when PicoBlaze writes to output port `0x01` and `write_strobe` is active:

```vhdl
led_write_enable <= '1' when (port_id = X"01" and write_strobe = '1') else '0';
```

This prevents the LEDs from changing when PicoBlaze is not performing a valid write to the LED port.

<p align="center">
  <img src="docs/images/kcpsm6_write_timing.png" width="600" alt="KCPSM6 Output Write Timing">
</p>

The timing diagram illustrates the relationship between `port_id`, `out_port`, and `write_strobe` during a PicoBlaze `OUTPUT` instruction.

While `out_port` carries the data being written, `write_strobe` generates a one-clock pulse indicating that the data is valid and should be captured. In this project, the LED register updates only when `write_strobe` is asserted **and** `port_id` equals `0x01`, ensuring that only valid writes intended for the LED output are stored.

---

### System Operation Summary

The complete operation is:

```text
1. The Basys3 switches enter the FPGA through sw[3:0].
2. switch_register_inst samples the switch value.
3. PicoBlaze reads the registered switch value through input port 0x00.
4. The firmware performs debounce and bit reversal.
5. PicoBlaze writes the result to output port 0x01.
6. led_register_inst stores out_port[3:0] only during a valid write_strobe.
7. The Basys3 LEDs display the stored result.
```

## Development Flow

The project was developed using the following flow:

```mermaid
flowchart TD
    A[Write PicoBlaze Assembly .psm] --> B[Test and Inspect in pBlazIDE]
    B --> C[Assemble with kcpsm6.exe]
    C --> D[Generate VHDL Program Memory]
    D --> E[Add KCPSM6 Core and ROM to Vivado]
    E --> F[Write top.vhd to connect the processor, ROM, registers, and I/O decode logic]
    F --> G[Run Vivado Simulation]
    G --> H[Add Basys3 XDC Constraints]
    H --> I[Generate Bitstream for Hardware]
```

## PicoBlaze Firmware

The debounce algorithm is implemented in PicoBlaze assembly.

The firmware defines two I/O ports:

```asm
CONSTANT port_in,  00
CONSTANT port_out, 01
```

| Port | Direction | Purpose |
|---|---|---|
| `0x00` | Input | Read switch value |
| `0x01` | Output | Write LED value |

The firmware performs the following sequence:

1. Initialize internal PicoBlaze registers.
2. Read the switch value from input port `0x00`.
3. Store multiple switch samples in scratchpad memory.
4. Wait between samples using a delay loop.
5. Compare all collected samples.
6. Accept the value only if all samples are equal.
7. Reverse the lower four bits.
8. Write the result to output port `0x01`.

This approach filters mechanical switch bouncing by requiring the input value to remain stable across multiple consecutive samples.

## pBlazIDE Firmware Verification

Before integrating the firmware into Vivado, the PicoBlaze assembly code was imported into **pBlazIDE** for testing and verification.


To simulate the hardware interface, the following definitions were added:

| Definition | Meaning |
|---|---|
| `switches DSIN 0` | Simulated switches are connected to input port `0` |
| `leds DSOUT 1` | Simulated LEDs are connected to output port `1` |

These definitions create virtual input and output devices inside pBlazIDE, allowing the firmware to be tested using the same logical port numbers that are later used in the FPGA implementation.

<p align="center">
  <img src="docs/images/pblazide_test.png" width="850" alt="pBlazIDE PicoBlaze Firmware Test">
</p>

## Vivado Simulation

A VHDL testbench was created to verify the top-level system behavior in Vivado.

The testbench applies all possible 4-bit switch combinations from `0000` to `1111`.  
Before each stable input value, the testbench also applies fast-changing switch transitions to emulate mechanical switch bouncing.

This verifies that the PicoBlaze firmware does not immediately accept unstable input changes. Instead, it waits until the sampled switch value remains stable before updating the LED output.

<p align="center">
  <img src="docs/images/vivado_simulation_waveform.png"
       width="100%"
       height="900"
       alt="Vivado Simulation Waveform">
</p>

The waveform verifies:

- Fast-changing switch input transitions are applied before stable values
- The debounce firmware waits for a stable input before accepting the value
- The final LED output matches the bit-reversed switch input
- All 16 possible 4-bit input combinations are tested

## PicoBlaze Microcontroller vs Pure FPGA Logic

This debounce task could be implemented entirely in VHDL, but PicoBlaze provides a useful hardware/software design tradeoff.

| Category | KCPSM6 PicoBlaze | Pure FPGA Logic |
|---|---|---|
| Control Flow | Easy to describe sequential algorithms | Requires explicit FSM and control logic |
| Resource Behavior | Resource requirements remain constant with increasing complexity | Logic resources grow with increasing complexity |
| Best Use Case | Control, sequencing, debounce, simple embedded tasks | High-speed datapaths and parallel processing |
| Execution Model | Sequential instruction execution | Fully parallel hardware execution |
| Design Tradeoff | Simpler development with lower performance | Higher performance with increased design complexity |

In this project, debounce is a good fit for PicoBlaze because it is a sequential process based on repeated sampling, delays, comparisons, and controlled output updates.

## Repository Structure

```text
PicoBlaze_KCPSM_Debounce/
│
├── README.md
│ 
│
├── vivado_sources/
│   ├── top.vhd
│   ├── REG.vhd
│   ├── kcpsm6.vhd
│   ├── PicoBlaze_Debounce.vhd
│   └── PicoBlaze_Debounce_tst.vhd
│
├── firmware/
│   ├── PicoBlaze_Debounce.psm
│   └── TB_PicoBlaze_Debounce.psm
│
├── constraints/
│   └── Basys3.xdc
│
├── sim/
│   └── tb_top.vhd
│
├── tools/
│   ├── PicoBlaze.xml
│   ├── pBlazIDE.exe
│   ├── kcpsm6.exe
│   └── ROM_form.vhd
│
└── docs/
    └── images/
        ├── vivado_rtl_schematic.png
        ├── kcpsm6_write_timing.png
        ├── vivado_simulation_waveform.png
        └── pblazide_test.png
```

## How to Run in Vivado

1. Open Vivado.
2. Create a new RTL project.
3. Select the Basys3 board or the matching Artix-7 FPGA device.
4. Add all files from `vivado_sources/` as design sources.
5. Add `constraints/Basys3.xdc` as the constraints file.
6. Add `sim/tb_top.vhd` as a simulation source.
7. Run behavioral simulation.
8. For hardware implementation, make sure `top.vhd` instantiates `PicoBlaze_Debounce`.
9. Run synthesis.
10. Run implementation.
11. Generate the bitstream.
12. Program the Basys3 board.

## Third-Party Tools and Attribution

This repository includes several PicoBlaze-related tools and files that were used during development.

The following files were not written by the project author:

| File | Purpose |
|---|---|
| `kcpsm6.vhd` | KCPSM6 PicoBlaze processor core |
| `kcpsm6.exe` | KCPSM6 assembler |
| `pBlazIDE.exe` | PicoBlaze development and simulation environment |
| `ROM_form.vhd` | ROM template used by the assembler |
| `PicoBlaze.xml` | Notepad++ syntax highlighting file for PicoBlaze assembly |

They are included to document the development process and make the project easier to reproduce.

## Summary

This project implements a complete PicoBlaze-based switch debounce system on the Basys3 FPGA board.

The debounce algorithm is implemented in PicoBlaze assembly, while the physical switch and LED interfaces are implemented in VHDL. The project demonstrates the full development flow from firmware writing, to program memory generation, to VHDL integration, simulation, and hardware mapping.

It demonstrates how a soft-core processor can be used inside FPGA logic to implement practical embedded control behavior.


