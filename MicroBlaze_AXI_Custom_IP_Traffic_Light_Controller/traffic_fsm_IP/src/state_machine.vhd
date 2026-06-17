--------------------------------------------------------------------
-- File        : state_machine.vhd
-- Component   : traffic_fsm
-- Description :
--   This component implements the traffic-light finite state machine.
--
--   The FSM receives the car sensor inputs through switches_in and
--   decides which traffic light should be green.
--
--   The design uses two timer done signals:
--      done_1s - used in the DEFAULT states
--      done_2s - used in the traffic states
--
--   The FSM also generates the timer enable signals:
--      en_1s - enables the 1-second timer
--      en_2s - enables the 2-second timer
--
--   current_state stores the real current state of the FSM.
--   next_state is the combinational decision for the next clock edge.
--
-- Important note about next_state:
--
-- next_state is only the combinational decision for the next clock.
-- It is not the real stored state.
--
-- If next_state is not given a default value, it may keep an old
-- transition value.
--
-- Example:
-- The FSM may move from DEFAULT_A to DEFAULT_B when done_1s = '1'.
-- Right after the clock edge, current_state may already be DEFAULT_B
-- while done_1s is still high for a short delta-cycle.
-- In that moment, next_state can be calculated as DEFAULT_C.
--
-- When done_1s later goes low, if next_state is not assigned again,
-- it may stay stuck on DEFAULT_C and the FSM can jump there too early.
--
-- Therefore, the next-state process starts with:
--
--      next_state <= current_state;
--
-- Outputs:
--   state_out - encoded state value for AXI register 0
--   leds_out  - traffic light LED output for AXI register 1
--
-- LED mapping:
--   Traffic light A -> LED15
--   Traffic light B -> LED0
--   Traffic light C -> LED8
--------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic_fsm is
    port(
        clk,rst: in  std_logic;

        -- Switch input from the MicroBlaze / AXI register 2.
        -- Only SW15, SW9, SW8, SW7, SW6, SW0 are used as sensors.
        switches_in : in  std_logic_vector(15 downto 0);

        -- Timer done pulses.
 
        done_1s     : in  std_logic;
        done_2s     : in  std_logic;

        -- Timer enable outputs.
        en_1s       : out std_logic;
        en_2s       : out std_logic;

        -- this value is connected to AXI register 0.
        state_out   : out std_logic_vector(2 downto 0);

        -- LED output for the traffic lights.
        -- this value is connected to AXI register 1
        -- and also to external LED ports.
        leds_out    : out std_logic_vector(15 downto 0)
    );
end traffic_fsm;

architecture Behavioral of traffic_fsm is

    type state_type is (
        DEFAULT_A,
        DEFAULT_B,
        DEFAULT_C,
        A_ON,
        AB_ON,
        B_ON,
        C_ON
    );

    signal current_state : state_type;
    signal next_state    : state_type;
    
    --car at a traffic light
    signal req_A : std_logic;
    signal req_B : std_logic;
    signal req_C : std_logic;

begin

    --------------------------------------------------------------------
    -- Sensor decoding
    --------------------------------------------------------------------
    -- SW8  = South -> West
    -- SW9  = West  -> South
    -- These directions use traffic light A.
    --
    -- SW6  = East  -> South
    -- SW7  = South -> East
    -- These directions use traffic light B.
    --
    -- SW15 = West  -> East
    -- SW0  = East  -> West
    -- These directions use traffic light C.
    --------------------------------------------------------------------
    req_A <= switches_in(8)  or switches_in(9);
    req_B <= switches_in(6)  or switches_in(7);
    req_C <= switches_in(15) or switches_in(0);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst='0' then
            current_state <= DEFAULT_A;
            else
            current_state <= next_state;
            end if;
        end if;
        
    end process;


    process(current_state, req_A, req_B, req_C, done_1s, done_2s)
    begin

        next_state <= current_state;
        
        case current_state is

            when DEFAULT_A =>
                if done_1s = '1' then
                    if req_A = '1' then
                        next_state <= A_ON;
                    elsif req_B = '1' then
                        next_state <= B_ON;
                    elsif req_C = '1' then
                        next_state <= C_ON;
                    else
                        next_state <= DEFAULT_B;
                    end if;
                end if;

            when DEFAULT_B =>
                if done_1s = '1' then
                    if req_A = '1' then
                        next_state <= A_ON;
                    elsif req_B = '1' then
                        next_state <= B_ON;
                    elsif req_C = '1' then
                        next_state <= C_ON;
                    else
                        next_state <= DEFAULT_C;
                    end if;
                end if;

            when DEFAULT_C =>
                if done_1s = '1' then
                    if req_A = '1' then
                        next_state <= A_ON;
                    elsif req_B = '1' then
                        next_state <= B_ON;
                    elsif req_C = '1' then
                        next_state <= C_ON;
                    else
                        next_state <= DEFAULT_A;
                    end if;
                end if;
                
            when A_ON =>
                if done_2s = '1' then
                    if req_A = '1' and req_B = '1' then
                        next_state <= AB_ON;
                    elsif req_A = '1' then
                        next_state <= A_ON;
                    else
                        next_state <= DEFAULT_A;
                    end if;
                end if;

            when AB_ON =>
                if done_2s = '1' then
                    if req_A = '1' and req_B = '1' then
                        next_state <= AB_ON;
                    elsif req_A = '1' and req_B = '0' then
                        next_state <= A_ON;
                    elsif req_A = '0' and req_B = '1' then
                        next_state <= B_ON;
                    else
                        next_state <= DEFAULT_A;
                    end if;
                end if;

            when B_ON =>
                if done_2s = '1' then
                    if req_A = '1' and req_B = '1' then
                        next_state <= AB_ON;
                    elsif req_A = '0' and req_B = '1' then
                        next_state <= B_ON;
                    else
                        next_state <= DEFAULT_A;
                    end if;
                end if;

            when C_ON =>
                if done_2s = '1' then
                    if req_C = '1' and req_A = '0' and req_B = '0' then
                        next_state <= C_ON;
                    else
                        next_state <= DEFAULT_A;
                    end if;
                end if;
                
             when others=>
             next_state<=DEFAULT_A;
        end case;
    end process;

    --------------------------------------------------------------------
    -- Output logic
    --------------------------------------------------------------------
    -- Moore FSM:
    -- outputs depend only on current_state.
    --------------------------------------------------------------------
    process(current_state)
    begin

        -- Default output values.
        leds_out  <= (others => '0');
        state_out <= "000";
        en_1s     <= '0';
        en_2s     <= '0';

        case current_state is

      
            when DEFAULT_A =>
                leds_out(15) <= '1';     -- Traffic light A
                state_out    <= "000";
                en_1s        <= '1';

          
            when DEFAULT_B =>
                leds_out(0) <= '1';      -- Traffic light B
                state_out   <= "001";
                en_1s       <= '1';

            when DEFAULT_C =>
                leds_out(8) <= '1';      -- Traffic light C
                state_out   <= "010";
                en_1s       <= '1';
                
            when A_ON =>
                leds_out(15) <= '1';     -- Traffic light A
                state_out    <= "011";
                en_2s        <= '1';

            when AB_ON =>
                leds_out(15) <= '1';     -- Traffic light A
                leds_out(0)  <= '1';     -- Traffic light B
                state_out    <= "100";
                en_2s        <= '1';

            when B_ON =>
                leds_out(0) <= '1';      -- Traffic light B
                state_out   <= "101";
                en_2s       <= '1';

            when C_ON =>
                leds_out(8) <= '1';      -- Traffic light C
                state_out   <= "110";
                en_2s       <= '1';

        end case;
    end process;

end Behavioral;