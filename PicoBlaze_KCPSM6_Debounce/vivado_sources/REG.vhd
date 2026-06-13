-- ============================================================
-- File Name   : reg.vhd
-- Project     : PicoBlaze KCPSM6 Debounce System
-- Description : Generic synchronous register.
--
-- Author      : Harel Hillman
-- ============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity REG is
    generic (
        n : integer := 2
    );
    port (
        clk : in  std_logic;
        en  : in  std_logic;
        d   : in  std_logic_vector(n-1 downto 0);
        q   : out std_logic_vector(n-1 downto 0)
    );
end entity REG;

architecture rtl of REG is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                q <= d;
            end if;
        end if;
    end process;

end architecture rtl;