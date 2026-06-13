# KCPSM6 PicoBlaze Switch Debounce System

![HDL](https://img.shields.io/badge/HDL-VHDL-blue.svg) ![Soft CPU](https://img.shields.io/badge/Soft_CPU-KCPSM6%20PicoBlaze-orange.svg) ![Hardware](https://img.shields.io/badge/Hardware-Vivado%20RTL-purple.svg) ![Platform](https://img.shields.io/badge/Platform-Basys3-green.svg) ![Toolchain](https://img.shields.io/badge/Toolchain-Vivado%20%2B%20KCPSM6-red.svg) ![Interface](https://img.shields.io/badge/Interface-PicoBlaze%20I%2FO%20Ports-lightgrey.svg)

## Overview

This project implements a switch debounce system on the Basys3 FPGA board using the **KCPSM6 PicoBlaze soft microcontroller**.

The system reads a 4-bit input from the physical board switches, performs a software debounce algorithm in PicoBlaze assembly, reverses the bit order, and outputs the result to four physical LEDs.

The project demonstrates a complete FPGA soft-processor workflow: writing assembly firmware, generating VHDL program memory, integrating the KCPSM6 core into a VHDL top-level design, decoding PicoBlaze I/O ports, verifying the behavior in simulation, and preparing the design for Basys3 hardware implementation.

## Project Goal

The goal of this project is to demonstrate how a small soft-core processor can be used inside an FPGA to implement a practical embedded control task.

Instead of designing the debounce algorithm entirely as custom VHDL logic, the debounce process is implemented as firmware running on PicoBlaze. The surrounding VHDL logic handles the hardware interface: switch sampling, LED output storage, PicoBlaze I/O port decoding, and Basys3 pin mapping through the XDC constraints file.

This project demonstrates:

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

## Hardware Architecture

The hardware system is built around the KCPSM6 PicoBlaze processor and a generated VHDL program memory ROM.

The surrounding VHDL logic connects the processor to the Basys3 switch and LED interface through clocked registers and PicoBlaze I/O port decoding.

<p align="center">
  <img src="docs/images/vivado_rtl_schematic.png" width="950" alt="Vivado RTL Schematic of the PicoBlaze Debounce System">
</p>

The main hardware blocks are:

| Component | Purpose |
|---|---|
| `processor_inst` | KCPSM6 PicoBlaze soft microcontroller executing the debounce firmware |
| `program_memory_inst` | Generated VHDL ROM containing the assembled PicoBlaze instructions |
| `switch_register_inst` | Samples the physical switch input into a clocked register |
| `in_port` mux | Provides the registered switch value to PicoBlaze when port `0x00` is selected |
| `port_id` decode logic | Detects when PicoBlaze accesses output port `0x01` |
| `write_strobe` gating logic | Enables the LED register only during a valid PicoBlaze `OUTPUT` instruction |
| `led_register_inst` | Stores the lower 4 bits written by PicoBlaze and drives `led[3:0]` |

## KCPSM6 Processor Interface

In this design, the KCPSM6 processor is connected to two main interfaces:

1. The program memory interface, used to fetch 18-bit instructions from the generated ROM.
2. The 8-bit I/O port interface, used to communicate with the surrounding VHDL logic.

Key KCPSM6 signals used by the custom VHDL wrapper:

| Signal | Role in This Project |
|---|---|
| `address`, `instruction`, `bram_enable` | Program memory fetch interface |
| `port_id` | Selects the logical PicoBlaze I/O port |
| `in_port` | Provides registered switch data to the processor |
| `out_port` | Carries data written by the processor |
| `write_strobe` | Qualifies valid output writes to the LED register |
| `clk`, `reset` | Synchronous clock and processor reset |

## Development Flow

The project was developed using the following flow:

```mermaid
flowchart TD
    A[Write PicoBlaze Assembly .psm] --> B[Test and Inspect in pBlazIDE]
    B --> C[Assemble with kcpsm6.exe]
    C --> D[Generate VHDL Program Memory]
    D --> E[Add KCPSM6 Core and ROM to Vivado]
    E --> F[Connect Switches and LEDs in top.vhd]
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

Before integrating the firmware into Vivado, the PicoBlaze assembly code was tested and inspected using pBlazIDE.

The pBlazIDE test version uses simulated input and output definitions:

```asm
switches    DSIN  0
leds        DSOUT 1
```

These definitions connect simulated devices to the same port numbers used by the firmware.

| Definition | Meaning |
|---|---|
| `switches DSIN 0` | Simulated switches are connected to input port `0` |
| `leds DSOUT 1` | Simulated LEDs are connected to output port `1` |

These definitions are used only for pBlazIDE verification.  
The actual FPGA hardware mapping is implemented in `top.vhd`.

<p align="center">
  <img src="docs/images/pblazide_test.png" width="850" alt="pBlazIDE PicoBlaze Firmware Test">
</p>

## Program Memory Generation

The `.psm` assembly file is not directly executed by Vivado.

The KCPSM6 assembler converts the PicoBlaze assembly program into a VHDL program memory file. The assembler uses `ROM_form.vhd` as a template.

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

The generated `PicoBlaze_Debounce.vhd` file is a VHDL ROM that contains the machine instructions executed by the KCPSM6 processor.

## VHDL Integration

The top-level VHDL file connects the KCPSM6 processor, generated program memory, switch register, LED register, and port decoding logic.

Top-level entity:

```vhdl
entity top is
    port (
        clk : in std_logic;
        rst : in std_logic;
        sw  : in  std_logic_vector(3 downto 0);
        led : out std_logic_vector(3 downto 0)
    );
end entity top;
```

The active hardware implementation uses:

```vhdl
program_memory_inst : entity work.PicoBlaze_Debounce
```

For faster simulation, the test program memory version can be used:

```vhdl
program_memory_inst : entity work.PicoBlaze_Debounce_tst
```

## Register Design

The project uses a generic register module, `REG.vhd`, in two places.

| Instance | Purpose |
|---|---|
| `switch_register_inst` | Samples the physical switch input |
| `led_register_inst` | Stores the PicoBlaze output value |

The switch register provides a clocked interface between the external switches and the internal FPGA logic.

The LED register stores the last valid value written by PicoBlaze, allowing the LEDs to hold their output state until a new valid write occurs.

## PicoBlaze I/O Port Mapping

The PicoBlaze processor communicates with external VHDL logic through 8-bit I/O ports.

| Port ID | Direction | Connected Hardware |
|---|---|---|
| `0x00` | Input | Registered switch value |
| `0x01` | Output | LED output register |

### Input Port Logic

When PicoBlaze executes an `INPUT` instruction from port `0x00`, the VHDL logic places the registered switch value on `in_port`.

```vhdl
process(port_id, switch_reg_value)
begin
    case port_id is

        when X"00" =>
            in_port <= "0000" & switch_reg_value;

        when others =>
            in_port <= (others => '0');

    end case;
end process;
```

PicoBlaze ports are 8-bit wide. Since this project uses only four switches, the upper four bits are filled with zeros.

### Output Port Logic

When PicoBlaze executes an `OUTPUT` instruction to port `0x01`, the VHDL logic enables the LED register.

```vhdl
led_write_enable <= '1' when (port_id = X"01" and write_strobe = '1') else '0';
```

Both conditions are required:

| Condition | Meaning |
|---|---|
| `port_id = X"01"` | PicoBlaze is writing to the LED port |
| `write_strobe = '1'` | The value on `out_port` is valid |

The LED register captures the lower four bits of the PicoBlaze output port:

```vhdl
out_port(3 downto 0)
```

## Output Write Timing

The following timing diagram shows a KCPSM6 `OUTPUT` instruction.

When the firmware executes an output instruction, PicoBlaze places the target port on `port_id`, places the data on `out_port`, and asserts `write_strobe`.

The LED register captures the value from `out_port` only when `write_strobe` is active.

<p align="center">
  <img src="docs/images/kcpsm6_write_timing.png" width="850" alt="KCPSM6 Output Write Timing">
</p>

This is why the LEDs are not connected directly to `out_port`. The `out_port` bus is shared by all possible output ports, while `write_strobe` confirms when the current value is a valid write operation.

## Vivado Simulation

A VHDL testbench was created to verify the top-level system behavior.

The testbench applies all possible 4-bit switch combinations from `0000` to `1111`. For each input value, the expected LED output is the bit-reversed version of the switch input.

<p align="center">
  <img src="docs/images/vivado_simulation_waveform.png" width="850" alt="Vivado Simulation Waveform">
</p>

The waveform verifies:

- Correct PicoBlaze program execution
- Correct switch input sampling
- Correct output port write behavior
- Correct LED register update
- Correct bit-reversal result for all input combinations

## Basys3 Constraints

The physical Basys3 board connections are defined in `Basys3.xdc`.

| Top-Level Signal | Basys3 Resource |
|---|---|
| `clk` | 100 MHz onboard clock |
| `rst` | Push button reset |
| `sw[3:0]` | First four physical switches |
| `led[3:0]` | First four physical LEDs |

The 100 MHz clock is constrained using:

```tcl
create_clock -period 10.000 -name clk100 [get_ports clk]
```

This allows Vivado to perform timing analysis using the correct clock period.

## Simulation Version vs Hardware Version

Two generated program memory files are included:

| File | Purpose |
|---|---|
| `PicoBlaze_Debounce.vhd` | Hardware version with a longer debounce delay |
| `PicoBlaze_Debounce_tst.vhd` | Simulation version with a shorter delay |

The simulation version exists because a real debounce delay would make behavioral simulation unnecessarily long.

For hardware implementation, use:

```vhdl
program_memory_inst : entity work.PicoBlaze_Debounce
```

For fast simulation, use:

```vhdl
program_memory_inst : entity work.PicoBlaze_Debounce_tst
```

## PicoBlaze Microcontroller vs Pure FPGA Logic

This debounce task could be implemented entirely in VHDL, but PicoBlaze provides a useful hardware/software design tradeoff.

| Category | KCPSM6 PicoBlaze | Pure FPGA Logic |
|---|---|---|
| Control Flow | Easy to describe sequential algorithms | Requires explicit FSM design |
| Flexibility | Firmware can be modified more easily | HDL logic must be redesigned |
| Resource Behavior | Logic usage remains mostly fixed as firmware grows | Logic usage grows with implementation complexity |
| Performance | Sequential instruction execution | Fully parallel hardware execution |
| Best Use Case | Control, sequencing, debounce, simple embedded tasks | High-speed datapaths and parallel processing |
| Design Tradeoff | Lower performance, simpler control design | Higher performance, more manual hardware design |

In this project, debounce is a good fit for PicoBlaze because it is a sequential process based on repeated sampling, delays, comparisons, and controlled output updates.

## Repository Structure

```text
KCPSM6-Switch-Debounce-Basys3/
│
├── README.md
├── .gitignore
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
        ├── kcpsm6_block_diagram.png
        ├── kcpsm6_write_timing.png
        ├── vivado_simulation_waveform.png
        └── pblazide_test.png
```

## File Description

| File | Description |
|---|---|
| `top.vhd` | Top-level VHDL wrapper connecting PicoBlaze, program memory, switches, and LEDs |
| `REG.vhd` | Generic register used for switch sampling and LED output storage |
| `kcpsm6.vhd` | KCPSM6 PicoBlaze processor core |
| `PicoBlaze_Debounce.vhd` | Generated VHDL program memory for hardware implementation |
| `PicoBlaze_Debounce_tst.vhd` | Generated VHDL program memory for fast simulation |
| `PicoBlaze_Debounce.psm` | PicoBlaze assembly firmware |
| `TB_PicoBlaze_Debounce.psm` | pBlazIDE-oriented test firmware with simulated I/O definitions |
| `tb_top.vhd` | Vivado behavioral simulation testbench |
| `Basys3.xdc` | Basys3 FPGA pin constraints |
| `ROM_form.vhd` | ROM template used by the KCPSM6 assembler |
| `kcpsm6.exe` | KCPSM6 assembler used to generate VHDL program memory |
| `pBlazIDE.exe` | PicoBlaze development and simulation environment |
| `PicoBlaze.xml` | Notepad++ syntax highlighting file for PicoBlaze assembly |

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

## How to Regenerate the Program Memory

To regenerate the VHDL program memory from the PicoBlaze assembly file:

1. Edit the `.psm` firmware file.
2. Run the KCPSM6 assembler.
3. Use `ROM_form.vhd` as the ROM template.
4. Add the generated `.vhd` file to Vivado.

General flow:

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

For fast simulation, the debounce delay can be reduced before assembling, and the generated file can be used as `PicoBlaze_Debounce_tst.vhd`.

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

Before redistributing third-party tools publicly, their original licensing terms should be reviewed.

## Skills Demonstrated

This project demonstrates practical experience with:

- FPGA design using VHDL
- Soft-core microcontroller integration
- PicoBlaze assembly programming
- Program memory generation
- Register-based hardware interfacing
- PicoBlaze I/O port decoding
- Vivado simulation and waveform analysis
- XDC constraint mapping for Basys3
- Hardware/software co-design inside an FPGA

## Author

**Harel Hillman**

Electrical Engineering Student  
Focus areas: FPGA Design, VHDL, Embedded Systems, and Computer Engineering

## Summary

This project implements a complete PicoBlaze-based switch debounce system on the Basys3 FPGA board.

The debounce algorithm is implemented in PicoBlaze assembly, while the physical switch and LED interfaces are implemented in VHDL. The project shows the full development flow from firmware writing, to program memory generation, to VHDL integration, simulation, and hardware mapping.

It demonstrates how a soft microcontroller can be used inside FPGA logic to implement practical embedded control behavior.
