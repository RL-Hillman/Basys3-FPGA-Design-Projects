-- Description:
--   Single decimal digit counter used as one digit of the 3-digit counter.
--
--   The counter stores one decimal digit in the range 0 to 9.
--   It is instantiated three times in the top-level module:
--      q1 - ones digit
--      q2 - tens digit
--      q3 - hundreds digit
--
--   Inputs:
--      en        - enables counting when high
--      clr       - clears the digit to 0
--      rst       - global synchronous reset
--      top_count - selected top digit N from the switches
--
--   Outputs:
--      q             - current digit value
--      reach_9       - high when the digit equals 9
--      top_cnt_reach - high when the digit equals top_count



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity counter is
Port (
en,clr,rst,clk: in std_logic;
top_count: in std_logic_vector(3 downto 0);
top_cnt_reach,reach_9: out std_logic;
q: out integer range 0 to 9
 );
end counter;

architecture Behavioral of counter is
signal cnt: integer range 0 to 9;
begin

process(clk)

begin
if rising_edge(clk) then 
    if rst='1' or clr='1' then
      cnt<=0;
    elsif en='1' then
      if cnt = 9 then
        cnt <= 0;
      else        
        cnt<=cnt+1;
      end if;
    end if;               
end if;
end process;

q<=cnt;

reach_9<= '1' when cnt=9 else '0';


top_cnt_reach<='1' when cnt=to_integer(unsigned(top_count)) else '0';

end Behavioral;


