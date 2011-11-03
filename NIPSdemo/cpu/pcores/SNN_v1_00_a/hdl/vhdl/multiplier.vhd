library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;


entity multiplier is
  generic
  (
    DWIDTH_A         : integer := 34;
    MULTIPLIER_WIDTH : integer := 17;
    DWIDTH_Y         : integer := 34
  );
  port
  (
    clk : in std_logic;
    A   : in std_logic_vector(DWIDTH_A-1 downto 0);
    B   : in std_logic_vector(MULTIPLIER_WIDTH-1 downto 0);
    Y   : out std_logic_vector(DWIDTH_Y-1 downto 0)
  );
end entity multiplier;

----------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of multiplier is
  constant ZERO                : std_logic_vector(DWIDTH_A+MULTIPLIER_WIDTH-1 downto 0) := (others => '0');

  signal s_mult1               : std_logic_vector(2*MULTIPLIER_WIDTH-1 downto 0); -- 18x18 multipliers, but for std_logic_vector only 17x17
  signal s_mult1_d             : std_logic_vector(2*MULTIPLIER_WIDTH-1 downto 0); -- 18x18 multipliers, but for std_logic_vector only 17x17
  signal s_mult2               : std_logic_vector(DWIDTH_A-1 downto 0); -- 18x18 multipliers, but for std_logic_vector only 17x17
  signal s_mult2_d             : std_logic_vector(DWIDTH_A-1 downto 0); -- 18x18 multipliers, but for std_logic_vector only 17x17
  signal s_filtered_new        : std_logic_vector(DWIDTH_Y-1 downto 0); -- 18x18 multipliers, but for std_logic_vector only 17x17

begin
    process(clk)
    begin
        if rising_edge(clk) then
            s_mult1        <= A(MULTIPLIER_WIDTH-1 downto 0) * B;
            s_mult2        <= A(DWIDTH_A-1 downto MULTIPLIER_WIDTH) * B;

            s_mult1_d      <= s_mult1;
            s_mult2_d      <= s_mult2;

            Y <= ZERO(DWIDTH_A+MULTIPLIER_WIDTH-1 downto 2*MULTIPLIER_WIDTH) & s_mult1_d(2*MULTIPLIER_WIDTH-1 downto DWIDTH_A+MULTIPLIER_WIDTH-DWIDTH_Y)
               + s_mult2_d & ZERO(MULTIPLIER_WIDTH-1 downto DWIDTH_A+MULTIPLIER_WIDTH-DWIDTH_Y);
        end if;
    end process;
end IMP;
