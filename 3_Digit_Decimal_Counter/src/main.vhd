-- Description:
--   Top-level module for the 3-digit decimal counter system.
--
--   The system counts from 000 up to NNN, where N is selected by
--   the 4-bit top_count input. The three decimal digits are displayed
--   on a multiplexed 7-segment display.
--
--   Main functions:
--      - divider generates 5 Hz and 500 Hz clocks from the 100 MHz clock
--      - three counter instances implement the ones, tens, and hundreds digits
--      - Shift_REG generates the active-low anode rotation pattern
--      - anode_encoder converts the active anode into a MUX selector
--      - mux4x1 selects the digit currently sent to the 7-segment decoder
--      - Seg_decoder converts the selected digit into segment signals
--
--   Clock usage:
--      clk5   - updates the decimal counter once every 0.2 seconds
--      clk500 - refreshes the multiplexed 7-segment display
--
--   LED behavior:
--      led is high only when the counter reaches NNN.
--   a3:
--      Disable the unused fourth 7-segment digit.
--      The anodes are active-low, so '1' keeps this digit off.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity main is
generic (
CLK500_HALF_PERIOD_CYCLES : integer := 100000;
CLK5_HALF_PERIOD_CYCLES   : integer := 10000000
);
Port (
reset,clk_100M: in std_logic;
top_count: in std_logic_vector(3 downto 0);
seven_seg: out std_logic_vector(6 downto 0);
anode: out std_logic_vector(2 downto 0);
a3: out std_logic;
led: out std_logic );
end main;

architecture Behavioral of main is
component divider is
generic(
clk500Hz : integer := 100000;
clk5Hz   : integer := 10000000
);
Port (
clk,reset: in std_logic;
clk5,clk500: out std_logic );
end component;

component counter is
Port (
en,clr,rst,clk: in std_logic;
top_count: in std_logic_vector(3 downto 0);
top_cnt_reach,reach_9: out std_logic;
q: out integer range 0 to 9
 );
end component;

component Shift_REG is
Port (
rst,clk: in std_logic;
toanode: out std_logic_vector(2 downto 0) );
end component;

component anode_encoder is
Port (
active_anode: in std_logic_vector(2 downto 0);
to_mux_sel: out std_logic_vector(1 downto 0) );
end component;

component mux4x1 is
Port (
q1,q2,q3: in integer range 0 to 9;
sel: in std_logic_vector(1 downto 0);
todec: out integer range 0 to 9);
end component;


component Seg_decoder is
Port (
outmux: in integer range 0 to 9;
to7seg: out std_logic_vector(6 downto 0));
end component;




signal clk5,clk500: std_logic;
signal toanode: std_logic_vector(2 downto 0);
signal sel: std_logic_vector(1 downto 0);
signal todec,q1,q2,q3: integer range 0 to 9;
signal clr1,clr2,clr3,en2,en3,high,toprch1,toprch2,toprch3,allrchtop,rch91,rch92: std_logic;

begin

a3<='1';

div: divider
generic map (
clk500Hz => CLK500_HALF_PERIOD_CYCLES,
clk5Hz   => CLK5_HALF_PERIOD_CYCLES
)
port map (clk=>clk_100M, reset=>reset, clk5=>clk5,clk500=>clk500);


shift: Shift_REG
port map(rst=>reset,clk=>clk500,toanode=>toanode);
anode<=toanode;


anodencoder: anode_encoder
port map(active_anode=>toanode,to_mux_sel=>sel);


mux: mux4x1
port map(q1=>q1,q2=>q2,q3=>q3,sel=>sel,todec=>todec);

segdecoder: Seg_decoder
port map(outmux=>todec,to7seg=>seven_seg);


high<='1';
cnt1: counter
port map(en=>high,clr=>clr1,rst=>reset,clk=>clk5,top_count=>top_count,top_cnt_reach=>toprch1,reach_9=>rch91,q=>q1);

cnt2: counter
port map(en=>en2,clr=>clr2,rst=>reset,clk=>clk5,top_count=>top_count,top_cnt_reach=>toprch2,reach_9=>rch92,q=>q2);

cnt3: counter
port map(en=>en3,clr=>clr3,rst=>reset,clk=>clk5,top_count=>top_count,top_cnt_reach=>toprch3,reach_9=>open,q=>q3);

-- Detect when all three digits reached the selected top value NNN.
allrchtop<=toprch3 and toprch2 and toprch1;

led<='1' when allrchtop='1' else '0';

-- Ones digit clears after reaching 9, or when the full number reaches NNN
clr1<='1' when rch91='1' or allrchtop='1' else '0';

-- Tens digit increments when ones reaches 9.
en2<='1' when rch91='1' else '0';
-- Tens digit clears when the counter reaches 99, or when the full number reaches NNN
clr2<='1' when (rch92='1' and rch91='1') or allrchtop='1' else '0';

-- Hundreds digit increments when ones and tens both reach 9.
en3<='1' when rch92='1' and rch91='1' else '0';
-- Hundreds digit clears when the full number reaches NNN.
clr3<='1' when allrchtop='1' else '0';


end Behavioral;
