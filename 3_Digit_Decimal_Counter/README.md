# FPGA 3-Digit Decimal Counter System

A modular VHDL implementation of a 3-digit decimal counter system for the Digilent Basys3 FPGA board.

The design counts from `000` up to a user-selected maximum value `NNN`, where `N` is selected using a 4-bit switch input. The current count is shown on a multiplexed 7-segment display, and an LED is asserted when the counter reaches the selected terminal value.

---

## Project Goals

This project demonstrates a complete synchronous FPGA system built from reusable VHDL components.

The main goals are:

- Design a modular 3-digit decimal counter.
- Generate slower internal clocks from the Basys3 100 MHz clock.
- Drive a multiplexed 7-segment display using active-low anodes.
- Detect the terminal count value `NNN`.
- Assert an LED when the selected maximum count is reached.
- Verify the system using simulation testbenches.
- Implement the design on real FPGA hardware using Vivado.

---

## Hardware Platform

| Item | Description |
|---|---|
| FPGA Board | Digilent Basys3 |
| FPGA Family | Xilinx Artix-7 |
| HDL | VHDL |
| Toolchain | Xilinx Vivado |
| Input Clock | 100 MHz |
| User Input | 4 switches for `top_count`, 1 push button for reset |
| Output | 3 active 7-segment digits and 1 LED |

---

## System Behavior

The input `top_count[3:0]` selects a decimal digit `N` from 0 to 9.

The system then counts from:

```text
000 -> 001 -> 002 -> ... -> NNN -> 000
```

Examples:

| `top_count` | Decimal N | Counter Range |
|---|---:|---|
| `0001` | 1 | `000 -> ... -> 111 -> 000` |
| `0010` | 2 | `000 -> ... -> 222 -> 000` |
| `0101` | 5 | `000 -> ... -> 555 -> 000` |
| `1001` | 9 | `000 -> ... -> 999 -> 000` |

Only values from `0000` to `1001` are valid because each counter digit is decimal and supports values from 0 to 9.

---

## Top-Level Interface

The top-level entity is `main`.

| Signal | Direction | Description |
|---|---|---|
| `clk_100M` | Input | 100 MHz Basys3 system clock |
| `reset` | Input | Synchronous active-high reset |
| `top_count[3:0]` | Input | Selects the terminal digit `N` |
| `seven_seg[6:0]` | Output | 7-segment cathode control signals |
| `anode[2:0]` | Output | Active-low anode control for the three used digits |
| `a3` | Output | Disables the unused fourth 7-segment digit |
| `led` | Output | High when the counter reaches `NNN` |

---

## System Architecture

The design is built from several independent VHDL components connected in the top-level module.

![System Block Diagram](images/block_diagram.png)

```text
100 MHz Clock
     |
     v
+-------------+
|  divider    |
+-------------+
 |           |
 | clk5      | clk500
 v           v
Counters     Shift Register
 |           |
 v           v
MUX <--- Anode Encoder
 |
 v
7-Segment Decoder
 |
 v
7-Segment Display
```

The architecture separates the system into two main paths:

1. **Counter path** - updates the decimal value at a slow rate.
2. **Display path** - rapidly multiplexes the active 7-segment digits.

---

## Component Overview

### 1. `divider.vhd` - Clock Divider

The `divider` receives the 100 MHz input clock and generates two slower clock signals:

| Output Clock | Purpose |
|---|---|
| `clk5` | Updates the decimal counter |
| `clk500` | Refreshes the multiplexed 7-segment display |

The divider uses generic parameters that represent half-period cycle counts:

```vhdl
CLK500_HALF_PERIOD_CYCLES : integer := 100000;
CLK5_HALF_PERIOD_CYCLES   : integer := 10000000;
```

Because each output clock toggles every `N` input-clock cycles, the output frequency is:

```text
Fout = Fin / (2 * N)
```

For a 100 MHz input clock:

| Output | Half-Period Count | Frequency |
|---|---:|---:|
| `clk500` | 100,000 | 500 Hz |
| `clk5` | 10,000,000 | 5 Hz |

#### `rdy_rst` behavior

The divider includes an internal `rdy_rst` signal. Its purpose is to make the divider reset a one-time initialization event for each reset assertion.

When `reset` is sampled high, the divider counters are cleared and the generated clocks are restarted from a known state. After this first reset cycle, `rdy_rst` prevents the divider from being continuously cleared every clock cycle while the reset input remains high.

This keeps the divider behavior controlled and avoids repeatedly forcing the internal divider counters back to zero for the entire duration of a long reset press.

---

### 2. `counter.vhd` - Decimal Digit Counter

The `counter` module implements one decimal digit with a range of 0 to 9.

Each counter has:

| Signal | Purpose |
|---|---|
| `en` | Enables counting |
| `clr` | Clears the digit to 0 |
| `rst` | Synchronous reset |
| `clk` | Counter clock |
| `top_count` | Selected terminal digit `N` |
| `top_cnt_reach` | High when the digit equals `N` |
| `reach_9` | High when the digit equals 9 |
| `q` | Current decimal digit |

The top-level design instantiates three counters:

| Instance | Digit |
|---|---|
| `cnt1` | Ones digit |
| `cnt2` | Tens digit |
| `cnt3` | Hundreds digit |

The counters are cascaded:

- The ones digit counts every `clk5` cycle.
- The tens digit increments when the ones digit reaches 9.
- The hundreds digit increments when both the ones and tens digits reach 9.
- When all three digits reach `N`, the system clears back to `000`.

---

### 3. Terminal Count Detection

The terminal count condition is detected by checking whether all three digits reached the selected value `N`:

```vhdl
allrchtop <= toprch3 and toprch2 and toprch1;
```

When `allrchtop = '1'`:

- The LED turns on.
- All three counters are cleared back to 0 on the next counter update.

This creates the sequence:

```text
... -> NNN -> 000
```

---

### 4. `Shift_REG.vhd` - Anode Rotation Register

The Basys3 7-segment display uses active-low anodes, meaning:

```text
0 = digit enabled
1 = digit disabled
```

The system uses only three of the four display digits. The shift register generates a rotating 3-bit anode pattern:

```text
110 -> 101 -> 011 -> 110 -> ...
```

This pattern activates one digit at a time and allows the system to multiplex the display.

The shift register is clocked by `clk500`, so the active display digit changes fast enough to appear stable to the human eye.

---

### 5. `anode_encoder.vhd` - Anode-to-MUX Selector

The `anode_encoder` converts the active anode pattern into a 2-bit selector used by the digit MUX.

| Active Anode Pattern | Selected Digit |
|---|---|
| `110` | Ones digit |
| `101` | Tens digit |
| `011` | Hundreds digit |

This connects the display scanning logic to the digit-selection logic.

---

### 6. `mux4x1.vhd` - Digit Multiplexer

The `mux4x1` selects which decimal digit is currently sent to the 7-segment decoder.

Inputs:

- `q1` - ones digit
- `q2` - tens digit
- `q3` - hundreds digit

The selector comes from the `anode_encoder`, so the displayed digit always matches the currently active anode.

This is the core mechanism that allows three different digits to share one 7-segment decoder.

---

### 7. `Seg_decoder.vhd` - 7-Segment Decoder

The `Seg_decoder` converts the selected decimal digit into the correct 7-segment cathode pattern.

The Basys3 7-segment cathodes are active-low:

```text
0 = segment ON
1 = segment OFF
```

Therefore, each decimal digit is mapped to a 7-bit active-low segment pattern.

---

### 8. `a3` - Unused Fourth Digit Disable

The Basys3 board has four 7-segment digits, but this design uses only three.

The unused fourth digit is disabled by driving its anode high:

```vhdl
a3 <= '1';
```

Since the anodes are active-low, this keeps the fourth digit off.

---

## LED Behavior

The LED is used as a terminal-count indicator.

It is asserted only when the counter reaches the selected maximum value `NNN`.

Example:

```text
top_count = 0001
```

The LED turns on when the counter reaches:

```text
111
```

On the next counter update, the counter clears back to `000` and the LED turns off.

---

## Simulation

The project includes testbenches for both the full system and individual components.

| Testbench | Purpose |
|---|---|
| `tb_main.vhd` | Full-system simulation |
| `tb_div.vhd` | Clock divider verification |
| `tb_counter.vhd` | Single digit counter verification |
| `tb_Shift_REG.vhd` | Anode rotation verification |

For simulation, the divider generics are reduced so the behavior can be observed quickly:

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

This makes it easy to verify the counter and multiplexing behavior in a short simulation window.

---

## Simulation Result

The waveform below shows the full system operating with `top_count = 1`.

![Simulation Waveform](images/waveform.png)

The simulation demonstrates:

- The clock divider generates separate counter and display clocks.
- The counter reaches `111` when `top_count = 1`.
- The LED is asserted at the terminal count.
- The counter clears back to `000` after reaching the terminal value.
- The anode pattern continues rotating for 7-segment multiplexing.
- The selected digit is decoded and sent to the 7-segment output.

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

## How to Run

### 1. Create a Vivado Project

Create a new RTL project in Xilinx Vivado and select the Basys3 board or the matching Artix-7 device.

### 2. Add Design Sources

Add all VHDL source files from:

```text
src/
```

Set `main.vhd` as the top-level module.

### 3. Add Constraints

Add the Basys3 constraints file:

```text
constraints/Basys3.xdc
```

### 4. Run Simulation

Add the testbench files from:

```text
sim/
```

Run behavioral simulation using:

```text
tb_main.vhd
```

### 5. Generate Bitstream

Run synthesis, implementation, and bitstream generation.

### 6. Program the FPGA

Connect the Basys3 board and program it using Vivado Hardware Manager.

---

## Design Notes

- The design uses a synchronous active-high reset.
- The display anodes are active-low.
- The segment outputs are active-low.
- Only three of the four 7-segment digits are used.
- `top_count` should be set between 0 and 9.
- The design is modular and each major function is separated into its own VHDL component.
- Simulation uses reduced divider values, while hardware uses the real divider values for 5 Hz and 500 Hz operation.

---

## Skills Demonstrated

This project demonstrates:

- Modular VHDL design
- FPGA system integration
- Synchronous digital design
- Clock division
- Cascaded decimal counters
- Terminal-count detection
- 7-segment display decoding
- Display multiplexing
- Testbench-based verification
- Vivado simulation and implementation flow
- Basys3 hardware constraint mapping

---

## License

This project is intended for educational and portfolio purposes.
