# Basys3 3-Digit Decimal Counter

A modular VHDL implementation of a 3-digit decimal counter for the Digilent Basys3 FPGA board.

The system counts from `000` up to a user-selected maximum value `NNN`, where `N` is selected using the board switches. The current value is displayed on the Basys3 7-segment display using digit multiplexing, and an LED turns on when the counter reaches the selected maximum value.

---

## Project Overview

This project demonstrates a complete FPGA-based digital system built from several reusable VHDL components.

Main features:

- 3-digit decimal counter
- User-selectable maximum count using switches
- Clock division from the 100 MHz Basys3 system clock
- 7-segment display decoding
- 7-segment display multiplexing
- Synchronous active-high reset
- LED indication when the counter reaches the selected maximum value
- Modular VHDL structure with dedicated testbenches

The top-level entity is:

```vhdl
main
```

---

## Hardware Platform

| Item | Description |
|---|---|
| FPGA Board | Digilent Basys3 |
| FPGA Family | Xilinx Artix-7 |
| HDL | VHDL |
| Toolchain | Xilinx Vivado |
| Input Clock | 100 MHz |
| Display | On-board 4-digit 7-segment display |
| Used Display Digits | 3 digits |
| Input | 4 switches for `top_count` |
| Reset | Push button, synchronous active-high |
| Output | 7-segment display and LED |

---

## System Behavior

The input `top_count` is a 4-bit value connected to switches `SW0` to `SW3`.

It represents the decimal digit `N` in the range:

```text
0000 to 1001
```

Equivalent decimal range:

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

Values above `1001` are considered invalid inputs because each counter digit is decimal and supports only values from 0 to 9.

---

## System Architecture

The design is divided into independent VHDL modules and connected in the top-level file `main.vhd`.

![System Block Diagram](images/block_diagram.png)

### High-Level Data Flow

```text
100 MHz Clock
     │
     ▼
Clock Divider
 ├── clk5   ─────► Decimal Counter Chain
 └── clk500 ─────► Display Anode Rotation

Decimal Counter Chain ─► MUX ─► 7-Segment Decoder ─► 7-Segment Display

Shift Register ─► Anode Encoder ─► MUX Select
              └──────────────────► Active Anodes
```

---

## Clocking

The Basys3 board provides a 100 MHz input clock. The `divider` module generates two slower internal clocks.

| Clock Signal | Frequency | Purpose |
|---|---:|---|
| `clk5` | 5 Hz | Updates the decimal counter |
| `clk500` | 500 Hz | Refreshes the multiplexed 7-segment display |

The divider uses generic values representing half-period cycle counts:

```vhdl
CLK500_HALF_PERIOD_CYCLES : integer := 100000;
CLK5_HALF_PERIOD_CYCLES   : integer := 10000000;
```

Because the output clock toggles every `N` input clock cycles, the output frequency is:

```text
Fout = Fin / (2 × N)
```

For a 100 MHz input clock:

```text
100 MHz / (2 × 100,000)    = 500 Hz
100 MHz / (2 × 10,000,000) = 5 Hz
```

---

## VHDL Modules

| File | Description |
|---|---|
| `main.vhd` | Top-level module that connects the full system |
| `divider.vhd` | Generates the 5 Hz and 500 Hz internal clocks |
| `counter.vhd` | Single decimal digit counter, range 0 to 9 |
| `Shift_REG.vhd` | Rotating shift register for active-low anode control |
| `anode_encoder.vhd` | Converts the active anode pattern into a MUX select signal |
| `mux4x1.vhd` | Selects which decimal digit is sent to the 7-segment decoder |
| `Seg_decoder.vhd` | Converts a decimal digit into a 7-segment output pattern |
| `Basys3.xdc` | Pin constraints for the Basys3 FPGA board |

---

## Component Description

### 1. Clock Divider

The `divider` module receives the 100 MHz board clock and generates:

- `clk5` for the counter update rate
- `clk500` for display multiplexing

This allows the counter to update slowly enough to be visible while the display refreshes fast enough to appear stable.

---

### 2. Decimal Counter Chain

The `counter` module stores a single decimal digit from 0 to 9.

The system instantiates three counters:

| Counter | Digit |
|---|---|
| `cnt1` | Ones digit |
| `cnt2` | Tens digit |
| `cnt3` | Hundreds digit |

The counters are cascaded:

- The ones digit increments on every `clk5` count event.
- The tens digit increments when the ones digit reaches 9.
- The hundreds digit increments when both the ones and tens digits reach 9.
- When all three digits reach the selected value `NNN`, the system returns to `000`.

---

### 3. Maximum Count Detection

Each counter compares its current digit value with `top_count`.

The top-level module combines the three comparison outputs:

```vhdl
allrchtop <= toprch3 and toprch2 and toprch1;
```

When `allrchtop = '1'`, the counter has reached `NNN`.

At this point:

- The LED turns on.
- The counter is cleared back to `000` on the next counter clock event.

---

### 4. 7-Segment Display Multiplexing

The Basys3 board has a 4-digit 7-segment display. This design uses three digits and disables the fourth digit.

The anodes are active-low, so a `0` enables a digit and a `1` disables it.

The rotating anode sequence is:

```text
110 → 101 → 011 → 110 → ...
```

This means only one digit is active at a time, but the refresh rate is fast enough that the user sees all three digits continuously.

The unused fourth digit is disabled by driving:

```vhdl
a3 <= '1';
```

---

### 5. Anode Encoder and MUX

The `anode_encoder` converts the active anode pattern into a 2-bit selector.

The selector controls the `mux4x1` module, which chooses which digit is currently sent to the 7-segment decoder.

| Active Anode Pattern | Selected Digit |
|---|---|
| `110` | Ones digit |
| `101` | Tens digit |
| `011` | Hundreds digit |

---

### 6. 7-Segment Decoder

The `Seg_decoder` module converts a decimal digit into the correct 7-segment pattern.

The segment outputs are active-low:

```text
0 = segment ON
1 = segment OFF
```

The output vector controls the Basys3 cathode signals for the 7-segment display.

---

## LED Behavior

The LED output is high only when the counter reaches the selected maximum value `NNN`.

Example:

```text
top_count = 0010
```

In this case, the selected maximum value is:

```text
222
```

The LED turns on when the displayed count reaches `222`. On the next counter update, the counter returns to `000` and the LED turns off.

---

## Pin Mapping

The exact pin assignments are defined in:

```text
constraints/Basys3.xdc
```

Main external connections:

| Top-Level Signal | Basys3 Peripheral |
|---|---|
| `clk_100M` | 100 MHz board clock |
| `reset` | Push button |
| `top_count[3:0]` | Switches SW0-SW3 |
| `seven_seg[6:0]` | 7-segment cathode signals |
| `anode[2:0]` | Three active 7-segment anodes |
| `a3` | Disabled fourth 7-segment anode |
| `led` | On-board LED |

---

## Simulation

The project includes testbenches for the complete system and for individual modules.

| Testbench | Purpose |
|---|---|
| `tb_main.vhd` | Full-system simulation |
| `tb_div.vhd` | Clock divider simulation |
| `tb_counter.vhd` | Single decimal counter simulation |
| `tb_Shift_REG.vhd` | Anode rotation simulation |

For simulation, the clock divider generic values are reduced so the behavior can be observed quickly.

Example from `tb_main.vhd`:

```vhdl
generic map (
    CLK500_HALF_PERIOD_CYCLES => 2,
    CLK5_HALF_PERIOD_CYCLES   => 5
)
```

This makes the internal clocks much faster during simulation while keeping the same logical behavior.

---

## Simulation Result

The waveform below shows the top-level system simulation.

It demonstrates:

- Synchronous reset behavior
- Counter progression
- 7-segment output changes
- Anode multiplexing
- LED assertion when the counter reaches `NNN`

![Simulation Waveform](images/waveform.png)

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
│   ├── tb_counter.vhd
│   └── tb_Shift_REG.vhd
├── constraints/
│   └── Basys3.xdc
└── images/
    ├── block_diagram.png
    └── waveform.png
```

---

## How to Run in Vivado

### 1. Create a New Vivado Project

Create a new RTL project and select the Digilent Basys3 board or the matching Artix-7 FPGA device.

### 2. Add Design Sources

Add all VHDL files from:

```text
src/
```

Set `main.vhd` as the top-level design.

### 3. Add Constraints

Add the Basys3 constraints file:

```text
constraints/Basys3.xdc
```

### 4. Run Behavioral Simulation

Add the simulation files from:

```text
sim/
```

Run behavioral simulation using:

```text
tb_main.vhd
```

### 5. Run Synthesis and Implementation

Run the Vivado flow:

```text
Synthesis → Implementation → Generate Bitstream
```

### 6. Program the FPGA

Connect the Basys3 board, open Hardware Manager, and program the FPGA with the generated bitstream.

---

## Design Notes

- The design uses a synchronous active-high reset.
- The 7-segment display signals are active-low.
- The anode signals are active-low.
- Only three of the four Basys3 7-segment digits are used.
- The fourth digit is disabled using `a3 <= '1'`.
- Valid `top_count` values are from `0000` to `1001`, representing decimal values 0 to 9.
- The project is organized as a modular FPGA design, making each component easy to test and reuse.

---

## Skills Demonstrated

This project demonstrates:

- VHDL-based RTL design
- Modular FPGA system architecture
- Synchronous digital design
- Clock division
- Cascaded decimal counters
- 7-segment display decoding
- Display multiplexing
- Testbench-based verification
- Vivado simulation and implementation flow
- Basys3 FPGA hardware integration

---

## License

This project is intended for educational and portfolio purposes.

