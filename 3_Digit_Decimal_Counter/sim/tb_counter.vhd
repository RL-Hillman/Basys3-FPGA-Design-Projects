library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_counter is
end tb_counter;

architecture Behavioral of tb_counter is

    component counter is
        Port (
            en, clr, rst, clk : in std_logic;
            top_count         : in std_logic_vector(3 downto 0);
            top_cnt_reach     : out std_logic;
            reach_9           : out std_logic;
            q                 : out integer range 0 to 9
        );
    end component;

    signal en, clr, rst, clk : std_logic := '0';
    signal top_count         : std_logic_vector(3 downto 0) := "0101"; 
    signal top_cnt_reach     : std_logic;
    signal reach_9           : std_logic;
    signal q                 : integer range 0 to 9;

begin

    uut: counter
    port map (
        en            => en,
        clr           => clr,
        rst           => rst,
        clk           => clk,
        top_count     => top_count,
        top_cnt_reach => top_cnt_reach,
        reach_9       => reach_9,
        q             => q
    );

    -- clock: 10 ns period
    process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

    process
    begin
        rst <= '1';
        en  <= '0';
        clr <= '0';
        wait for 20 ns;

        rst <= '0';
        wait for 20 ns;

        en <= '1';
        wait for 120 ns;

        en <= '0';
        wait for 30 ns;

        en <= '1';
        wait for 50 ns;

        clr <= '1';
        wait for 10 ns;
        clr <= '0';
        wait for 30 ns;

         
        top_count <= "1001";
        wait for 100 ns;

        rst <= '1';
        wait for 10 ns;
        rst <= '0';

        wait for 50 ns;

        wait;
    end process;

end Behavioral;
