library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_main is
end tb_main;

architecture Behavioral of tb_main is

component main is
generic (
    CLK500_HALF_PERIOD_CYCLES : integer := 100000;
    CLK5_HALF_PERIOD_CYCLES   : integer := 10000000
);
Port (
    reset     : in  std_logic;
    clk_100M  : in  std_logic;
    top_count : in  std_logic_vector(3 downto 0);
    seven_seg : out std_logic_vector(6 downto 0);
    anode     : out std_logic_vector(2 downto 0);
    a3        : out std_logic;
    led       : out std_logic
);
end component;

signal RST       : std_logic := '0';
signal CLK       : std_logic := '0';
signal LED       : std_logic;
signal a3        : std_logic;
signal anode     : std_logic_vector(2 downto 0);
signal TOP_COUNT : std_logic_vector(3 downto 0);
signal seven_seg : std_logic_vector(6 downto 0);

begin

U1: main
generic map (
    CLK500_HALF_PERIOD_CYCLES => 2,
    CLK5_HALF_PERIOD_CYCLES   => 5
)
port map (
    reset     => RST,
    clk_100M  => CLK,
    top_count => TOP_COUNT,
    led       => LED,
    anode     => anode,
    seven_seg => seven_seg,
    a3        => a3
);

process
begin
    CLK <= '0';
    wait for 5 ns;
    CLK <= '1';
    wait for 5 ns;
end process;

process 
begin
    RST <= '0';
    wait for 23 ns;

    RST <= '1';
    wait for 500 ns;

    RST <= '0';

    wait;
end process;

process
begin 
    TOP_COUNT <= "0001"; -- count up to 111
    wait for 1000000 ns;

    TOP_COUNT <= "0010"; -- count up to 222
    wait for 1000000 ns;

    wait;
end process;

end Behavioral;