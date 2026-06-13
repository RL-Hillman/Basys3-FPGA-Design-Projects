-- ============================================================
-- File Name   : top.vhd
-- Project     : PicoBlaze KCPSM6 Debounce System
-- Description : Top-level hardware wrapper for the PicoBlaze
--               switch debounce.
--
-- ------------------------------------------------------------
-- Development Flow
-- ------------------------------------------------------------
--
-- 1. The firmware was written in PicoBlaze assembly language
--    in the PSM file.
--
-- 2. The KCPSM6 assembler converted the PSM file into a VHDL
--    program memory file.
--
-- 3. For simulation/testing use:
--
--        PicoBlaze_Debounce_tst.vhd
--
--    This version contains a small theDelay value so
--    simulation can run faster.
--
-- ------------------------------------------------------------
-- Assembly Port Mapping
-- ------------------------------------------------------------
--
-- The assembly program uses:
--
--        port_in    00
--        port_out   01
--
-- Therefore, this top-level maps:
--
--        port_id = 0x00  -> read switch register
--        port_id = 0x01  -> write LED register
--
-- ------------------------------------------------------------
-- System Components
-- ------------------------------------------------------------
--
-- 1. KCPSM6 PicoBlaze processor
-- 2. Generated program memory
-- 3. Generic switch register, width = 4
-- 4. Generic LED register, width = 4
--
-- Target Board : Basys3
-- Clock        : 100 MHz
-- Author       : Harel Hillman
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity top is
    port (
        clk : in std_logic;

        rst : in std_logic;

        -- Four physical switches used as the 4-bit input number.
        -- sw(3 downto 0) represents X3 X2 X1 X0.
        sw  : in  std_logic_vector(3 downto 0);

        -- Four physical LEDs used as the 4-bit output number.
        -- led(3 downto 0) represents Y3 Y2 Y1 Y0.
        led : out std_logic_vector(3 downto 0)
    );
end entity top;


architecture rtl of top is

    -- ========================================================
    -- Program Memory Interface Signals
    -- ========================================================
    
    -- KCPSM6 outputs an address to the program memory.
    -- KCPSM6 also drives bram_enable, which is the read-enable
    -- signal for the program memory.
    --
    -- The program memory uses the address when bram_enable is
    -- active and returns the 18-bit instruction stored at that
    -- address back to KCPSM6.

    signal address      : std_logic_vector(11 downto 0);
    signal instruction  : std_logic_vector(17 downto 0);
    signal bram_enable  : std_logic;


    -- ========================================================
    -- KCPSM6 I/O Port Signals
    -- ========================================================
    --
    -- in_port:
    --   Data entering the PicoBlaze processor.
    --
    -- out_port:
    --   Data produced by the PicoBlaze processor during OUTPUT.
    --
    -- port_id:
    --   The port address used by INPUT and OUTPUT instructions.
    --
    -- write_strobe:
    --   One-clock pulse generated when PicoBlaze executes OUTPUT.

    signal in_port      : std_logic_vector(7 downto 0);
    signal out_port     : std_logic_vector(7 downto 0);
    signal port_id      : std_logic_vector(7 downto 0);
    signal write_strobe : std_logic;


    -- ========================================================
    -- External Register Signals
    -- ========================================================
    --
    -- switch_reg_value:
    --   Output of the generic switch register.
    --
    -- led_write_enable:
    --   Enables the LED register only when PicoBlaze writes
    --   to output port 0x01.

    signal switch_reg_value : std_logic_vector(3 downto 0);
    signal led_write_enable : std_logic;

begin

    -- ========================================================
    -- KCPSM6 Processor Instance
    -- ========================================================
    --
    -- The PicoBlaze processor executes the instructions returned
    -- by the generated program memory.
    --
    -- Unused output ports are connected to open.

    processor_inst : entity work.kcpsm6
        generic map (
            hwbuild                 => X"00",
            interrupt_vector        => X"3FF",
            scratch_pad_memory_size => 64
        )
        port map (
            address        => address,
            instruction    => instruction,
            bram_enable    => bram_enable,

            in_port        => in_port,
            out_port       => out_port,
            port_id        => port_id,

            write_strobe   => write_strobe,
            k_write_strobe => open,
            read_strobe    => open,

            interrupt      => '0',
            interrupt_ack  => open,
            sleep          => '0',
            reset          => rst,
            clk            => clk
        );


    -- ========================================================
    -- Program Memory Instance
    -- ========================================================
    -- For simulation use:
    
    -- program_memory_inst : entity work.PicoBlaze_Debounce_tst


    -- This version has:
    --
    --   theDelay = 02
    --
    -- Approximate delay:
    --
    --   2^3 * 40 ns = 320 ns per delay
    --   20 samples * 320 ns = about 6.4 us minimum debounce window
    --
    -- For real hardware, replace it with PicoBlaze_Debounce.
    -- This version has:
    --
    --   theDelay = 64 hex = 100 decimal
    --
    -- Approximate delay:
    --
    --   100^3 * 40 ns = about 40 ms per delay
    --   20 samples * 40 ms = about 800 ms minimum debounce window
    -- Hardware version:
    --
    -- program_memory_inst : entity work.PicoBlaze_Debounce
    
    program_memory_inst : entity work.PicoBlaze_Debounce
        port map (
            address     => address,
            instruction => instruction,
            enable      => bram_enable,
            clk         => clk
        );


    -- ========================================================
    -- Switch Register
    -- ========================================================
    --
    -- This register samples the physical switches on every clock.
    -- The software debounce algorithm inside PicoBlaze then reads
    -- this registered value through input port 0x00.

    switch_register_inst : entity work.REG
        generic map (
            n => 4
        )
        port map (
            clk => clk,
            en  => '1',
            d   => sw,
            q   => switch_reg_value
        );


    -- ========================================================
    -- PicoBlaze Input Port Logic
    -- ========================================================
    --
    -- Assembly:
    --
    --   CONSTANT port_in, 00
    --
    -- When PicoBlaze reads from port 0x00, it receives the
    -- switch register value.
    --
    -- PicoBlaze ports are 8-bit wide, but this project uses
    -- only the lower 4 bits.

    process(port_id, switch_reg_value)
    begin
        case port_id is

            when X"00" =>
                in_port <= "0000" & switch_reg_value;

            when others =>
                in_port <= (others => '0');

        end case;
    end process;


    -- ========================================================
    -- Output Port Decode
    -- ========================================================
    --
    -- Assembly:
    --
    --   CONSTANT port_out, 01
    --
    -- The LED register should update only when PicoBlaze writes
    -- to output port 0x01.
    --
    -- Both conditions are required:
    --
    --   port_id      = X"01"
    --   write_strobe = '1'

    led_write_enable <= '1' when (port_id = X"01" and write_strobe = '1') else '0';


    -- ========================================================
    -- LED Register
    -- ========================================================
    --
    -- The register stores the lower 4 bits written by PicoBlaze.
    -- The LEDs keep showing the last valid value written to
    -- output port 0x01.

    led_register_inst : entity work.REG
        generic map (
            n => 4
        )
        port map (
            clk => clk,
            en  => led_write_enable,
            d   => out_port(3 downto 0),
            q   => led
        );

end architecture rtl;