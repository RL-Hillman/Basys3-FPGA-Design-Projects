# 3-Digit Multiplexed 7-Segment Counter 

A modular FPGA-based digital system written in VHDL for the Digilent Basys3 board.

The project implements a configurable 3-digit decimal counter that counts from `000` up to a user-selected terminal value `NNN`, where `N` is selected using the onboard switches. The current count is displayed on three multiplexed 7-segment digits, and an LED is asserted when the selected terminal count is reached.

The design is built as a complete small-scale FPGA system, combining parameterized clock generation, reusable VHDL components, cascaded counter control, active-low display driving, dynamic digit multiplexing, and simulation-based verification.

---

## Overview

This repository contains the VHDL source files, simulation testbenches, Basys3 constraints file, architecture diagram, and simulation waveform for the counter system.

The implementation is organized as a hierarchical hardware design. Instead of placing the full behavior inside one large process, the system is divided into focused VHDL components that are connected together in the top-level module.

The design separates the main counter logic from the display refresh logic:

| Path | Role |
|---|---|
| Counter Path | Generates the current 3-digit decimal count |
| Display Path | Selects and drives the active 7-segment digit |

This structure keeps the system readable, easier to debug, and closer to how larger FPGA designs are usually organized.

The top-level entity is:

```vhdl
main
```

---

## Key Features

### Modular VHDL Architecture

The system is built from multiple dedicated components, each responsible for a specific hardware function. This keeps the top-level design clean and makes the project easier to understand, verify, and extend.

### Reusable Decimal Counter Component

A single decimal counter component is instantiated three times to create the ones, tens, and hundreds digits. This avoids duplicated logic and keeps the multi-digit counter structure consistent.

### Parameterized Clock Divider

The clock divider generates two internal timing signals from the 100 MHz Basys3 clock:

- `clk5` for the counter update rate
- `clk500` for 7-segment display multiplexing

The divider uses generic parameters, allowing the same source code to support both real hardware timing and shortened simulation timing.

### Dynamic 7-Segment Display Multiplexing

The display system uses a rotating active-low anode pattern, a digit multiplexer, and a 7-segment decoder. Together, these components allow three decimal digits to share one 7-segment output bus while still appearing as a stable multi-digit display.

### Configurable Terminal Count

The `top_count` input allows the user to select the terminal digit `N` using the onboard switches. The system then counts from `000` up to `NNN`.

### Terminal Count LED Indication

The LED output is asserted when all three digits reach the selected terminal value. After that, the counter returns to `000` and begins a new cycle.

### Simulation-Based Verification

The repository includes testbenches for the full system and key internal modules. The top-level waveform verifies clock division, counter progression, terminal-count detection, LED assertion, counter clearing, and display multiplexing.

---

## System Behavior

The system receives a 4-bit input called `top_count`.

This input represents the selected decimal digit `N`.

Valid values:

```text
0000 to 1001
```

Decimal equivalent:

```text
0 to 9
```

The system counts from:

```text
000 → 001 → 002 → ... → NNN → 000
```

Examples:

| `top_count` | Decimal N | Counter Range |
|---|---:|---|
| `0001` | 1 | `000 → 001 → ... → 111 → 000` |
| `0010` | 2 | `000 → 001 → ... → 222 → 000` |
| `0101` | 5 | `000 → 001 → ... → 555 → 000` |
| `1001` | 9 | `000 → 001 → ... → 999 → 000` |

When all three digits match the selected value `N`, the `led` output is asserted. On the next count cycle, the counter clears back to `000`.

Values above `1001` are not intended for use because each digit is implemented as a decimal counter with a valid range of 0 to 9.

---

## Hardware Platform

| Item | Description |
|---|---|
| FPGA Board | Digilent Basys3 |
| FPGA Family | Xilinx Artix-7 |
| HDL | VHDL |
| Toolchain | Xilinx Vivado |
| Input Clock | 100 MHz |
| User Input | 4 onboard switches |
| Reset Input | Onboard push button |
| Display Output | 3 digits of the onboard 7-segment display |
| Status Output | Onboard LED |

---

## System Architecture

The system is organized as a hierarchy of VHDL modules connected at the top level.

![System Block Diagram](images/System_Block_Diagram.png)

The architecture is split into two main parts:

### Counter Path

The counter path is responsible for generating the current 3-digit decimal value.

```text
clk5 → counters → terminal-count detection → LED / clear logic
```

The ones digit is enabled continuously. The tens digit increments when the ones digit reaches 9, and the hundreds digit increments when both lower digits reach 9.

### Display Path

The display path is responsible for selecting and driving the currently active 7-segment digit.

```text
clk500 → Shift_REG → anode_encoder → mux4x1 → Seg_decoder → seven_seg
```

The display refresh logic runs faster than the counter logic, allowing the three digits to appear continuously active through multiplexing.

---

## Source Files

| File | Description |
|---|---|
| `main.vhd` | Top-level system integration |
| `divider.vhd` | Generates internal timing signals from the 100 MHz input clock |
| `counter.vhd` | Reusable single-digit decimal counter |
| `Shift_REG.vhd` | Generates the rotating active-low anode pattern |
| `anode_encoder.vhd` | Converts the active anode pattern into a MUX select value |
| `mux4x1.vhd` | Selects the currently displayed digit |
| `Seg_decoder.vhd` | Converts a decimal digit into a 7-segment pattern |
| `Basys3.xdc` | Basys3 FPGA pin constraints |

---

## Component-Level Architecture

### `main.vhd` — Top-Level Integration

The `main` module connects the complete system.

It instantiates:

- One clock divider
- Three decimal counters
- One anode shift register
- One anode encoder
- One digit multiplexer
- One 7-segment decoder

The module also contains the system-level control logic:

- The ones digit is enabled continuously.
- The tens digit is enabled when the ones digit reaches 9.
- The hundreds digit is enabled when both lower digits reach 9.
- The terminal count is detected when all three digits equal `top_count`.
- The LED is asserted at the terminal count.
- The counter clears back to `000` after reaching `NNN`.
- The unused fourth display digit is disabled using `a3`.

This keeps the project organized around reusable hardware blocks and a clear top-level integration layer.

---

### `divider.vhd` — Parameterized Clock Divider

The Basys3 board provides a 100 MHz input clock. The `divider` module generates two slower internal timing signals:

| Signal | Frequency | Purpose |
|---|---:|---|
| `clk5` | 5 Hz | Updates the decimal counter |
| `clk500` | 500 Hz | Refreshes the multiplexed 7-segment display |

The divider uses generic half-period cycle values:

```vhdl
clk500Hz : integer := 100000;
clk5Hz   : integer := 10000000;
```

The output frequency is calculated as:

```text
Fout = Fin / (2 × N)
```

For a 100 MHz input clock:

```text
100 MHz / (2 × 10,000,000) = 5 Hz
100 MHz / (2 × 100,000)    = 500 Hz
```

The divider includes an internal `rdy_rst` signal used as a reset qualifier.

When reset is sampled high and the divider is ready for reset, the internal counters and generated clock states are restarted from a known value. After this reset event is handled, `rdy_rst` prevents the divider from being continuously cleared on every input clock edge while the reset input remains high.

This keeps the divider from being held in a constant cleared state during a long reset press, while still allowing the timing sequence to restart from a known state.

---

### `counter.vhd` — Reusable Decimal Counter

The `counter` module implements one decimal digit in the range 0 to 9.

| Signal | Purpose |
|---|---|
| `en` | Enables counting |
| `clr` | Clears the digit to zero |
| `rst` | Synchronous reset |
| `top_count` | Selected terminal digit value |
| `q` | Current digit value |
| `reach_9` | Indicates that the digit reached 9 |
| `top_cnt_reach` | Indicates that the digit equals `top_count` |

The top-level system uses three instances of this module:

| Instance | Digit |
|---|---|
| `cnt1` | Ones digit |
| `cnt2` | Tens digit |
| `cnt3` | Hundreds digit |

Using the same counter block for all three digit positions keeps the design consistent and avoids duplicating counter logic.

---

### `Shift_REG.vhd` — Active-Low Anode Rotation

The Basys3 7-segment display uses active-low anodes:

```text
0 = digit ON
1 = digit OFF
```

The `Shift_REG` module generates the rotating 3-bit anode pattern:

```text
110 → 101 → 011 → 110 → ...
```

Only one digit is active at a time. The rotation is driven by `clk500`, which refreshes the display fast enough for the three digits to appear continuously visible.

The shift register also uses an internal `rdy_rst` signal. Its role is to initialize the anode sequence once when reset is asserted, instead of repeatedly forcing the same pattern while reset remains high.

---

### `anode_encoder.vhd` — Active Digit Encoding

The `anode_encoder` converts the active-low anode pattern into a 2-bit selector for the digit multiplexer.

| Active Anode Pattern | Selected Digit |
|---|---|
| `110` | Ones digit |
| `101` | Tens digit |
| `011` | Hundreds digit |

This keeps the active display position synchronized with the digit value being routed to the decoder.

---

### `mux4x1.vhd` — Digit Multiplexer

The `mux4x1` module selects which counter digit is currently sent to the 7-segment decoder.

Inputs:

- `q1` — ones digit
- `q2` — tens digit
- `q3` — hundreds digit
- `sel` — digit select from the anode encoder

Output:

- `todec` — selected decimal digit

The multiplexer is part of the display path. It ensures that the digit value sent to the decoder matches the currently active anode.

---

### `Seg_decoder.vhd` — 7-Segment Decoder

The `Seg_decoder` module converts a decimal digit from 0 to 9 into the matching 7-segment output pattern.

The segment outputs are active-low:

```text
0 = segment ON
1 = segment OFF
```

The output pattern is connected to the segment pins:

```text
CA, CB, CC, CD, CE, CF, CG
```

Keeping the decoder as a separate module isolates the display encoding from the counter and control logic.

---

## Counter Control Logic

The three counter instances are cascaded to create the full 3-digit decimal counter.

The ones digit is always enabled:

```vhdl
high <= '1';
```

The tens digit increments when the ones digit reaches 9:

```vhdl
en2 <= '1' when rch91 = '1' else '0';
```

The hundreds digit increments when both the ones and tens digits reach 9:

```vhdl
en3 <= '1' when rch92 = '1' and rch91 = '1' else '0';
```

The terminal count is detected when all three digits equal the selected `top_count` value:

```vhdl
allrchtop <= toprch3 and toprch2 and toprch1;
```

The LED is asserted at the terminal count:

```vhdl
led <= '1' when allrchtop = '1' else '0';
```

The clear logic then returns the counter to `000` for the next counting cycle.

---

## Display Multiplexing

The design uses three of the four Basys3 7-segment digits.

The fourth digit is disabled by the top-level signal:

```vhdl
a3 <= '1';
```

Since the anodes are active-low, assigning `1` keeps the unused digit off.

The display path works as follows:

```text
Shift_REG → anode_encoder → mux4x1 → Seg_decoder → seven_seg
```

At each refresh step:

1. `Shift_REG` activates one anode.
2. `anode_encoder` generates the matching selector.
3. `mux4x1` selects the corresponding counter digit.
4. `Seg_decoder` converts the digit to a segment pattern.
5. The selected digit appears on the active display position.

This allows three decimal digits to share one 7-segment segment bus.

---

## Simulation and Verification

The repository includes testbenches for the complete system and key internal modules.

| Testbench | Purpose |
|---|---|
| `tb_main.vhd` | Verifies the full integrated system |
| `tb_div.vhd` | Verifies the clock divider |
| `tb_counter.vhd` | Verifies the decimal counter |

For simulation, the divider values are reduced to avoid simulating millions of 100 MHz clock cycles.

Example from `tb_main.vhd`:

```vhdl
generic map (
    CLK500_HALF_PERIOD_CYCLES => 2,
    CLK5_HALF_PERIOD_CYCLES   => 5
)
```

With a 10 ns simulation clock period:

| Signal | Toggle Interval | Full Period |
|---|---:|---:|
| `clk500` | 20 ns | 40 ns |
| `clk5` | 50 ns | 100 ns |

These shortened values make it possible to verify the counter and display behavior quickly while preserving the same divider structure used in the hardware configuration.

---

## Simulation Result

The waveform below shows the top-level simulation.

![Simulation Waveform](images/Simulation_Waveform.png)

In this simulation, `top_count` is set to `1`, so the selected terminal value is:

```text
111
```

The waveform shows:

- Correct generation of the divided timing signals
- Counter progression up to `111`
- LED assertion at the terminal count
- Counter clearing back to `000`
- Continuous anode rotation for display multiplexing
- Digit selection and 7-segment output updates according to the active display position

The waveform confirms the coordination between the counter path and the display path.

---

## FPGA Pin Mapping

The `Basys3.xdc` file maps the top-level VHDL ports to the physical Basys3 board pins.

| Top-Level Signal | Basys3 Peripheral |
|---|---|
| `clk_100M` | 100 MHz onboard clock |
| `reset` | Push button |
| `top_count[3:0]` | Switches SW0–SW3 |
| `seven_seg[6:0]` | 7-segment cathode signals |
| `anode[2:0]` | Three active display anodes |
| `a3` | Disabled fourth anode |
| `led` | Onboard LED |

---

## Repository Structure

```text
.
├── README.md
├── src/
│   ├── main.vhd
│   ├── divider.vhd
│   ├── counter.vhd
│   ├── Shift_REG.vhd
│   ├── anode_encoder.vhd
│   ├── mux4x1.vhd
│   └── Seg_decoder.vhd
├── sim/
│   ├── tb_main.vhd
│   ├── tb_div.vhd
│   └── tb_counter.vhd
├── constraints/
│   └── Basys3.xdc
└── images/
    ├── System_Block_Diagram.png
    └── Simulation_Waveform.png
```

---

## How to Run

### 1. Create a Vivado Project

Create a new RTL project in Xilinx Vivado and select the Digilent Basys3 board or the matching Artix-7 device.

### 2. Add Design Sources

Add all VHDL files from the `src/` directory.

Set the top-level entity to:

```text
main
```

### 3. Add Constraints

Add the constraints file:

```text
constraints/Basys3.xdc
```

### 4. Run Behavioral Simulation

Add the testbench files from the `sim/` directory and run behavioral simulation using:

```text
tb_main.vhd
```

### 5. Generate Bitstream

Run synthesis, implementation, and bitstream generation.

### 6. Program the FPGA

Connect the Basys3 board and program it using Vivado Hardware Manager.

---

## Design Notes

- The design is built from multiple reusable VHDL components.
- The same `counter` component is instantiated three times to create the 3-digit decimal counter.
- The counter path and display path are separated at the architectural level.
- The display is driven using time-multiplexing and active-low anode control.
- The segment outputs are active-low.
- The fourth 7-segment digit is disabled using `a3`.
- `top_count` should be set to a value from 0 to 9.
- Simulation uses reduced divider values to verify the system quickly without simulating millions of 100 MHz clock cycles.
- Hardware uses the full divider values for 5 Hz counting and 500 Hz display refresh.

---

## Summary

This project presents a complete FPGA-based digital system built around modular VHDL components, synchronous control logic, parameterized clock generation, dynamic 7-segment display multiplexing, and Basys3 board-level integration.

The final system combines timing generation, cascaded decimal counting, terminal-count detection, display control, simulation verification, and hardware-ready pin mapping in one organized FPGA project.

---

