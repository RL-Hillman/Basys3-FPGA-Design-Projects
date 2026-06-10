-- Description:
--   Encodes the active-low anode pattern into a 2-bit MUX select.
--
--   The Shift_REG module generates the active anode pattern:
--      "110" -> digit 0 selected
--      "101" -> digit 1 selected
--      "011" -> digit 2 selected
--
--   This encoder converts that pattern into the selector used by
--   the 4-to-1 MUX, which chooses the digit value to send to the
--   7-segment decoder.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity anode_encoder is
Port (
active_anode: in std_logic_vector(2 downto 0);
to_mux_sel: out std_logic_vector(1 downto 0) );
end anode_encoder;

architecture Behavioral of anode_encoder is

begin
with active_anode select
to_mux_sel<=
"00" when "110",
"01" when "101",
"10" when "011",
"11" when others;

end Behavioral;

