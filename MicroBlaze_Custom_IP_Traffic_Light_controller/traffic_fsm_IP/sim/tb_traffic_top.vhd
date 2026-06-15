library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_traffic_top is
end tb_traffic_top;

architecture sim of tb_traffic_top is

    --------------------------------------------------------------------
    -- Simulation parameters
    --------------------------------------------------------------------
    -- The simulated clock period is still 10 ns, like a 100 MHz clock.
    --
    -- However, for simulation only, we give the FSM a much lower
    -- frequency value than the real clock frequency:
    -- TB_CLK_FREQ_HZ = 10
    --
    -- Because of this, the FSM timers become shorter:
    -- 1 second = 10 clock cycles
    -- 2 seconds = 20 clock cycles
    --
    -- This saves simulation time and makes the waveform easier to check.
    --------------------------------------------------------------------
    constant CLK_PERIOD     : time     := 10 ns;
    constant TB_CLK_FREQ_HZ : positive := 10;

    --------------------------------------------------------------------
    -- Signals connected to traffic_top
    --------------------------------------------------------------------
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal switches_in : std_logic_vector(15 downto 0) := (others => '0');
    signal state_out   : std_logic_vector(2 downto 0);
    signal leds_out    : std_logic_vector(15 downto 0);

begin

    --------------------------------------------------------------------
    -- Clock generator
    --------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;

        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;


    --------------------------------------------------------------------
    -- Unit Under Test
    --------------------------------------------------------------------
    UUT : entity work.traffic_top(Structural)
        generic map(
            CLK_FREQ_HZ => TB_CLK_FREQ_HZ
        )
        port map(
            clk         => clk,
            rst         => rst,
            switches_in => switches_in,
            state_out   => state_out,
            leds_out    => leds_out
        );


    --------------------------------------------------------------------
    -- Stimulus process
    --------------------------------------------------------------------
    -- We check all relevant switch combinations.
    --
    -- Only these switches are sensors:
    -- SW6, SW7, SW8, SW9, SW15, SW0
    --
    -- Therefore we use a 6-bit vector.
    -- Each bit of test_vec controls one relevant switch.
    --------------------------------------------------------------------
    stim_proc : process
        variable test_vec : std_logic_vector(5 downto 0);
        variable full_sw  : std_logic_vector(15 downto 0);
    begin

        ----------------------------------------------------------------
        -- Reset
        ----------------------------------------------------------------
        switches_in <= (others => '0');

        rst <= '0';
        wait for 50 ns;

        rst <= '1';
        wait for 50 ns;


        ----------------------------------------------------------------
        -- Run over all 64 combinations of the 6 relevant switches.
        ----------------------------------------------------------------
        for i in 0 to 63 loop

            test_vec := std_logic_vector(to_unsigned(i, 6));

            full_sw := (others => '0');

            ----------------------------------------------------------------
            -- Map the 6-bit test vector into the real switch locations
            ----------------------------------------------------------------
            full_sw(6)  := test_vec(0); -- SW6  = East  -> South, B request
            full_sw(7)  := test_vec(1); -- SW7  = South -> East,  B request
            full_sw(8)  := test_vec(2); -- SW8  = South -> West,  A request
            full_sw(9)  := test_vec(3); -- SW9  = West  -> South, A request
            full_sw(15) := test_vec(4); -- SW15 = West  -> East,  C request
            full_sw(0)  := test_vec(5); -- SW0  = East  -> West,  C request


            ----------------------------------------------------------------
            -- Apply current test vector.
            -- Wait long enough for the FSM timers and state transitions.
            ----------------------------------------------------------------
            switches_in <= full_sw;
            wait for 273 ns;

        end loop;


        ----------------------------------------------------------------
        -- Clear all requests at the end
        ----------------------------------------------------------------
        switches_in <= (others => '0');
        wait for 500 ns;


        ----------------------------------------------------------------
        -- Stop simulation here
        ----------------------------------------------------------------
        wait;

    end process;

end sim;