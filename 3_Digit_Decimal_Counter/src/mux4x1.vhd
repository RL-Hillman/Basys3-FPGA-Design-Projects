-- Description:
--   Selects which decimal digit is currently sent to the 7-segment decoder.
--
--   The display is multiplexed, so only one digit is driven at a time.
--   The sel input comes from the anode_encoder and indicates which
--   anode/digit is currently active.
--
--   q1, q2, and q3 are the three decimal digits of the counter.
--   The selected digit is sent to 'todec', which is then decoded
--   into the 7-segment pattern.




library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity mux4x1 is
Port (
q1,q2,q3: in integer range 0 to 9;
sel: in std_logic_vector(1 downto 0);
todec: out integer range 0 to 9 );
end mux4x1;

architecture Behavioral of mux4x1 is

begin

with sel select
todec<= 
q1 when "00",
q2 when "01",
q3 when "10",
0 when others;


end Behavioral;


