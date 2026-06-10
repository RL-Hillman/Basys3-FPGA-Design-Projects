-- Description:
--   Converts a decimal digit into the corresponding 7-segment pattern.
--
--   Input:
--      outmux - decimal digit in the range 0 to 9
--
--   Output:
--      to7seg - 7-bit active-low segment pattern for the Basys3 display
--
--   Segment convention:
--      '0' = segment ON
--      '1' = segment OFF
--
--   The output pattern is ordered according to the connected segment pins
--   CA, CB, CC, CD, CE, CF, CG.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Seg_decoder is
Port (
outmux: in integer range 0 to 9;
to7seg: out std_logic_vector(6 downto 0));
end Seg_decoder;

architecture Behavioral of Seg_decoder is

begin
    with outmux select
    to7seg <= "0000001" when 0,
    "1001111" when 1,
    "0010010" when 2,
    "0000110" when 3,
    "1001100" when 4,
    "0100100" when 5,
    "0100000" when 6,
    "0001111" when 7,
    "0000000" when 8,
    "0000100" when 9,
    "1111111" when others;

end Behavioral;
