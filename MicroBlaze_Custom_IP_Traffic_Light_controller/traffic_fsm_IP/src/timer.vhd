
-- Component : timer
-- Description:
--   Counts for exactly SECONDS seconds using the input clock,
--   then asserts 'done' HIGH for ONE clock cycle.
--
--   set the delay in seconds directly via the generic.
--   The component computes MAX_COUNT internally at compile time:
--
--    number of clock cycles = seconds * clock cycles per second
--    MAX_COUNT = SECONDS * CLK_FREQ_HZ
--
--
-- Instantiation examples:
--   -- 1-second timer
--   T1 : entity work.timer(Behavioral) 
--       generic map ( SECONDS => 1 )
--       port map    ( clk => clk,
--                     enable => en_1s, done => done_1s,rst=>rst );
--
--   -- 2-second timer  
--   T2 : entity work.timer(Behavioral)
--       generic map ( SECONDS => 2 )
--       port map    ( clk => clk,
--                     enable => en_2s, done => done_2s,rst=>rst );
 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity timer is
    generic(
        -- Number of seconds to count.
        SECONDS     : positive := 1;

        -- Input clock frequency in Hz.
        -- Basys 3 board clock is 100 MHz.
        CLK_FREQ_HZ : positive := 100_000_000
    );
    port(
        clk,rst    : in  std_logic;   -- system clock,reset
        enable : in  std_logic;   -- start / keep timer running
        done   : out std_logic    -- 1-clock-cycle pulse when time is finished
    );
end timer;

architecture Behavioral of timer is

    constant MAX_COUNT : positive := SECONDS * CLK_FREQ_HZ;

    signal count : integer range 0 to MAX_COUNT - 1;


begin

    process(clk)

    begin
        if rising_edge(clk) then
           
            if enable = '1' then
            
              if count = MAX_COUNT - 1 then
                     
                   count<= 0;
              else
                   count<=count+1;
                   
              end if;

            else
                -- Timer is disabled.
                count<= 0;

            end if;

        end if; 
    end process;
    
done <= '1' when (enable = '1' and count = MAX_COUNT - 1) else '0';

end Behavioral;
