#  3-Digit Decimal Counter System

A modular VHDL-based FPGA design implemented on the Digilent Basys3 board.

This project implements a configurable 3-digit decimal counter that counts from `000` up to `NNN`, where `N` is selected using the onboard switches. The current value is displayed on a multiplexed 7-segment display, and an LED is asserted when the counter reaches the selected terminal value.

The design is built as a structured digital system composed of multiple reusable VHDL components, including clock division, cascaded decimal counters, display multiplexing, anode control, digit selection, and 7-segment decoding.

---

## Project Highlights

- Modular VHDL system architecture
- 3-digit cascaded decimal counter
- User-configurable terminal count using FPGA switches
- 7-segment display multiplexing
- Active-low anode and segment control
- Synchronous counter logic
- Clock division from the Basys3 100 MHz system clock
- Component-level and top-level simulation
- Basys3 hardware pin mapping using an XDC constraints file

---

## System Overview

The system is designed around two main functional paths:

| Path | Purpose |
|---|---|
| Counter Path | Generates the current 3-digit decimal value |
| Display Path | Selects and displays the active digit on the 7-segment display |

The counter path updates at a slow visible rate, while the display path refreshes much faster to create a stable multiplexed display.

The top-level entity of the project is:

```vhdl
main
```

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

When the counter reaches `NNN`, the LED is asserted. On the next count cycle, the counter clears back to `000`.

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

The system is implemented as a set of dedicated VHDL components connected together at the top level.

![System Block Diagram](images/System_Block_Diagram.png)

The architecture separates the design into small hardware blocks, where each component has a clear responsibility. This makes the system easier to understand, test, debug, and reuse.

---

## Top-Level Integration

The `main.vhd` file is the top-level integration module.

It connects the following components:

| Component | Purpose |
|---|---|
| `divider` | Generates the internal timing signals |
| `counter` | Implements one decimal digit |
| `Shift_REG` | Rotates the active display anode |
| `anode_encoder` | Converts the active anode pattern into a MUX selector |
| `mux4x1` | Selects the digit currently sent to the display decoder |
| `Seg_decoder` | Converts the selected digit into 7-segment control signals |

The top-level module also implements the system control logic:

- Enables the ones digit continuously
- Enables the tens digit when the ones digit reaches 9
- Enables the hundreds digit when both lower digits reach 9
- Detects when all three digits equal the selected `top_count`
- Clears the counter after reaching `NNN`
- Drives the LED at the terminal count
- Disables the unused fourth 7-segment digit

This structure demonstrates system-level FPGA design using reusable hardware modules rather than a single monolithic process.

---

## VHDL Source Files

| File | Description |
|---|---|
| `main.vhd` | Top-level system integration |
| `divider.vhd` | Clock divider for counter and display timing |
| `counter.vhd` | Reusable single-digit decimal counter |
| `Shift_REG.vhd` | Rotating active-low anode controller |
| `anode_encoder.vhd` | Encodes the active anode into a MUX select signal |
| `mux4x1.vhd` | Selects the currently displayed digit |
| `Seg_decoder.vhd` | Converts decimal values to 7-segment patterns |
| `Basys3.xdc` | Basys3 pin constraints |

---

## Component-Level Design

### `divider.vhd` — Clock Generation

The Basys3 board provides a 100 MHz input clock. The `divider` module generates two slower timing signals from this clock:

| Signal | Frequency | Purpose |
|---|---:|---|
| `clk5` | 5 Hz | Updates the decimal counter |
| `clk500` | 500 Hz | Refreshes the multiplexed display |

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

The divider includes an internal `rdy_rst` signal used as a reset qualifier. Its role is to treat reset as a controlled one-time initialization event for the divider. When reset is sampled high, the internal counters and generated clock states are restarted from a known state. After the reset event has been handled, `rdy_rst` prevents the divider from being continuously cleared on every clock cycle while the reset input remains high.

This allows the divider to restart cleanly without repeatedly forcing its internal state back to zero for the entire duration of a held reset button.

---

### `counter.vhd` — Reusable Decimal Counter

The `counter` module implements a single decimal digit in the range 0 to 9.

It includes:

| Signal | Purpose |
|---|---|
| `en` | Enables the counter to increment |
| `clr` | Clears the digit to zero |
| `rst` | Global reset input |
| `top_count` | Selected terminal digit value |
| `q` | Current digit value |
| `reach_9` | Indicates that the digit reached 9 |
| `top_cnt_reach` | Indicates that the digit equals `top_count` |

The top-level system instantiates this module three times:

| Instance | Digit |
|---|---|
| `cnt1` | Ones digit |
| `cnt2` | Tens digit |
| `cnt3` | Hundreds digit |

This demonstrates component reuse: one verified counter block is reused to construct a larger multi-digit system.

---

### `Shift_REG.vhd` — Active-Low Anode Rotation

The Basys3 7-segment display uses active-low anodes. A `0` activates a digit, while a `1` disables it.

The `Shift_REG` module generates a rotating 3-bit anode pattern:

```text
110 → 101 → 011 → 110 → ...
```

Only one digit is active at a time. The rotation is driven by `clk500`, which is fast enough to make the three digits appear continuously visible to the human eye.

The fourth digit is not used in this design and is disabled separately by the top-level signal `a3`.

---

### `anode_encoder.vhd` — Display Selection Encoding

The `anode_encoder` converts the active-low anode pattern into a 2-bit selector used by the digit multiplexer.

| Active Anode Pattern | Selected Digit |
|---|---|
| `110` | Ones digit |
| `101` | Tens digit |
| `011` | Hundreds digit |

This keeps the selected counter digit synchronized with the active physical display digit.

---

### `mux4x1.vhd` — Digit Multiplexer

The `mux4x1` module selects which counter digit is currently sent to the 7-segment decoder.

Inputs:

- `q1` — ones digit
- `q2` — tens digit
- `q3` — hundreds digit
- `sel` — selected digit control signal

Output:

- `todec` — the digit currently sent to the decoder

The MUX is part of the display pipeline. It ensures that the displayed value matches the currently active anode.

---

### `Seg_decoder.vhd` — 7-Segment Decoder

The `Seg_decoder` module converts a decimal digit from 0 to 9 into the corresponding 7-segment output pattern.

The Basys3 display uses active-low segment control:

```text
0 = segment ON
1 = segment OFF
```

This module isolates the display encoding logic from the counter logic, keeping the design modular and easier to maintain.

---

## Counter Control Logic

The three counter instances are cascaded to create a decimal counting system.

The ones digit is always enabled:

```vhdl
cnt1: counter
port map(
    en => high,
    ...
);
```

The tens digit increments when the ones digit reaches 9:

```vhdl
en2 <= '1' when rch91 = '1' else '0';
```

The hundreds digit increments when both the ones and tens digits reach 9:

```vhdl
en3 <= '1' when rch92 = '1' and rch91 = '1' else '0';
```

The terminal count is detected when all three digits equal the selected `top_count`:

```vhdl
allrchtop <= toprch3 and toprch2 and toprch1;
```

The LED is asserted at the terminal count:

```vhdl
led <= '1' when allrchtop = '1' else '0';
```

After reaching `NNN`, the clear logic resets the counter back to `000`.

---

## Display Multiplexing

The system uses three digits of the Basys3 7-segment display.

The fourth digit is disabled:

```vhdl
a3 <= '1';
```

Since the display anodes are active-low, assigning `1` keeps the unused digit off.

The display multiplexing flow is:

```text
Shift_REG → anode_encoder → mux4x1 → Seg_decoder → seven_seg
```

At each refresh step:

1. `Shift_REG` activates one display digit.
2. `anode_encoder` generates the matching MUX selector.
3. `mux4x1` selects the matching counter digit.
4. `Seg_decoder` generates the correct 7-segment pattern.
5. The selected digit appears on the active display position.

This allows three decimal digits to share a single 7-segment output bus.

---

## Simulation and Verification

The project includes testbenches for both the integrated system and key internal components.

| Testbench | Purpose |
|---|---|
| `tb_main.vhd` | Verifies the complete integrated system |
| `tb_div.vhd` | Verifies the clock divider behavior |
| `tb_counter.vhd` | Verifies the single decimal counter behavior |

For simulation, the divider generic values are reduced:

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

These reduced values allow the system behavior to be verified quickly without simulating millions of 100 MHz clock cycles.

---

## Simulation Result

The waveform below shows the top-level system simulation.

![Simulation Waveform](images/Simulation_Waveform.png)

In this simulation, `top_count` is set to `1`, so the selected terminal value is:

```text
111
```

The waveform verifies that:

- The divided clocks are generated correctly
- The counter reaches `111`
- The LED is asserted at the terminal count
- The counter clears back to `000`
- The anode pattern continues rotating for display multiplexing
- The selected digit and 7-segment output update according to the active digit

This verifies both the counting path and the display path of the system. Vivado’s waveform viewer is commonly used for inspecting HDL signal behavior and debugging simulation results. :contentReference[oaicite:1]{index=1}

---

## FPGA Pin Mapping

The `Basys3.xdc` file maps the top-level ports to the physical Basys3 board pins.

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
- The same decimal counter component is instantiated three times to create a 3-digit counter.
- The counter path and display path are separated for clarity.
- The display is driven using time-multiplexing and active-low anode control.
- The 7-segment segment outputs are active-low.
- The fourth 7-segment digit is disabled using `a3`.
- `top_count` should be set from 0 to 9.
- Simulation uses reduced divider values to verify the system quickly without simulating millions of 100 MHz clock cycles.
- Hardware uses the full divider values for 5 Hz counting and 500 Hz display refresh.

---

## License

This project is intended for educational and portfolio use.
