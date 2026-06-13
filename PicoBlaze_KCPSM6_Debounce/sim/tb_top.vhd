library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top is
end entity tb_top;

architecture sim of tb_top is

  
    -- The Basys3 board clock is 100 MHz.
    constant CLK_PERIOD : time := 10 ns;



    -- ========================================================
    -- Bounce timing
    -- ========================================================
    -- In PicoBlaze_Debounce_tst.psm:
    --
    --     CONSTANT theDelay, 02
    --
    -- Simplified delay model from the assembly comments:
    --
    --     T_delay = theDelay^3 * 40 ns
    --     T_delay = 2^3 * 40 ns
    --     T_delay = 320 ns
    --
    -- The complete bounce phase is shorter than the full debounce
    -- sampling window, so the software should not immediately trust
    -- the input until it remains stable.
    constant BOUNCE_STEP : time := 300 ns;


    -- ========================================================
    -- Stable time after bouncing
    -- ========================================================
    -- The debounce algorithm does not accept the input after one
    -- delay only.
    --
    -- It reads 20 samples:
    --
    --     sample_count_20 = 14 hex = 20 decimal
    --
    -- Minimum simplified sampling window:
    --
    --     20 * 320 ns = 6.4 us
    --
    -- But the real program also executes additional instructions:
    -- CALL, INPUT, AND, STORE, FETCH, COMPARE, JUMP, RETURN,
    -- reverse_bits, and OUTPUT.
    --
    -- Therefore, 100 us is chosen as a safe simulation value.
    -- It is long enough for debounce to finish, but still short
    -- enough that the full simulation runs quickly.
    constant STABLE_TIME : time := 100 us;


    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal sw  : std_logic_vector(3 downto 0) := "0000";
    signal led : std_logic_vector(3 downto 0);

    begin

    process
     begin
        clk <= '1';
        wait for CLK_PERIOD / 2;

        clk <= '0';
        wait for CLK_PERIOD / 2;
      end process;


    uut : entity work.top
        port map (
            clk => clk,
            rst => rst,
            sw  => sw,
            led => led
        );

    process
        variable target_sw   : std_logic_vector(3 downto 0);
        variable previous_sw : std_logic_vector(3 downto 0) := "0000";
    begin

        -- ====================================================
        -- Initial reset
        -- ====================================================
        rst <= '1';
        sw  <= "0000";
        
        wait for 500 ns;
        
        rst <= '0';

        -- Give PicoBlaze time to start running and write the
        -- initial LED value.
        wait for STABLE_TIME;


        -- ====================================================
        -- Test all possible 4-bit switch values: 0000 to 1111
        -- ====================================================
        for i in 0 to 15 loop

            target_sw := std_logic_vector(to_unsigned(i, 4));


            -- =================================================
            -- Bounce phase
            -- =================================================
            -- The switch input jumps between the previous value
            -- and the new target value.
            --
            -- This simulates mechanical switch bouncing.
            -- During this phase, the output should not be trusted

            for j in 0 to 6 loop
            
                sw <= target_sw;
                wait for BOUNCE_STEP;
           
                sw <= previous_sw;
                wait for BOUNCE_STEP;

            end loop;

            -- =================================================
            -- Stable phase
            -- =================================================
            -- Now the switch value is stable.
            -- The debounce algorithm should eventually accept it.
            sw <= target_sw;



            wait for STABLE_TIME;

            
            -- Save this value as the previous switch value for
            -- the next test case.
            previous_sw := target_sw;

        end loop;


        wait;

    end process;

end architecture sim;