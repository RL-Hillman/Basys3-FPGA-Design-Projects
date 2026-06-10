-- Description:
-- Rotating anode shift register
-- Initial/reset value: "110"
-- Rotation sequence:
--   "110" -> "101" -> "011" -> "110" -> ...
-- Since the anodes are active-low, the single '0' selects
-- the currently active 7-segment digit.



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Shift_REG is
Port (
rst,clk: in std_logic;
toanode: out std_logic_vector(2 downto 0) );
end Shift_REG;

architecture Behavioral of Shift_REG is
signal rdy_rst: std_logic;
begin

process(clk)
variable temp: std_logic_vector(2 downto 0):="110";
begin
    if rising_edge(clk) then
        if rst='1' and rdy_rst='1' then
          temp:="110";
        else
            temp:=temp(1 downto 0)&temp(2);
        end if;
    toanode<=temp;
    end if;
end process;


process(clk)
begin
if rising_edge(clk) then
    if rst='1' then 
       rdy_rst<='0';
    else 
       rdy_rst<='1';
    end if;
end if;

end process;

end Behavioral;

