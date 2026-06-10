-- Description:
--   Divides the 100 MHz input clock into two slower clock signals:
--   5 Hz   - used for the decimal counter update rate
--   500 Hz - used for multiplexing the 7-segment display digits
--
-- Notes:
--   The generic values represent HALF-period cycle counts.
--   Because the output clock toggles every N input clock cycles,
--   the final output frequency is:
--
--   Fout = Fin / (2 * N)
--
--   For Fin = 100 MHz:
--      N = 10,000,000  -> 5 Hz
--      N = 100,000     -> 500 Hz
--   Reset behavior:
--      When reset is held high, rdy_rst becomes '0' after the first
--      clock cycle. This prevents the divider from being reset
--      continuously while reset remains high.



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity divider is
generic(
clk500Hz: integer:=100000;  -- Half-period cycles for 500 Hz output
clk5Hz: integer:=10000000); -- Half-period cycles for 5 Hz output

Port (
clk,reset: in std_logic;
clk5,clk500: out std_logic );
end divider;

architecture Behavioral of divider is


signal rdy_rst: std_logic;

begin


process(clk)
variable to_clk5: std_logic:='0';
variable cnt5: integer:=0;

begin

if rising_edge(clk) then
    if reset='1' and rdy_rst='1' then 
        to_clk5:='0';
        cnt5:=0;
    else
        cnt5:=cnt5+1;
    end if;

    if cnt5=clk5Hz then
        to_clk5:=not(to_clk5);
        cnt5:=0;
    end if;
clk5<=to_clk5;
end if;
end process;



process(clk)
variable to_clk500: std_logic:='0';
variable cnt500: integer:=0;

begin

if rising_edge(clk) then
    if reset='1' and rdy_rst='1' then 
        to_clk500:='0';
        cnt500:=0;
    else
        cnt500:=cnt500+1;
    end if;

    if cnt500=clk500Hz then
     to_clk500:=not(to_clk500);
     cnt500:=0;
    end if;
clk500<=to_clk500;
end if;
end process;


process(clk)

begin

if rising_edge(clk) then
    if reset='1'  then 
        rdy_rst<='0';
    else 
        rdy_rst<='1';
    end if;
end if;
end process;


end Behavioral;

