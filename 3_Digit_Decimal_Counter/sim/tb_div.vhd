library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity tb_div is
--  Port ( );
end tb_div;

architecture Behavioral of tb_div is

component divider is
generic(clk500Hz : integer := 100000;
clk5Hz : integer := 10000000
);
Port (clk,reset: in std_logic;
clk5,clk500: out std_logic );
end component;

signal clk,reset,clk5,clk500: std_logic:='0';

begin
process
   begin
    clk<='0';
    wait for 5 ns;
    clk<='1';
    wait for 5 ns;
end process;


u1: divider
generic map (clk500Hz => 2, clk5Hz=> 5)
port map(clk=>clk,reset=>reset,clk5=>clk5,clk500=>clk500);

process
begin
wait for 30 ns;
reset<='1';
wait for 20 ns;
reset<='0';

wait;
end process;

end Behavioral;
