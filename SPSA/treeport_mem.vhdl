----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- This module emulates a tree port memory using 1 clock domain
-- Attention, to enable full speed clock for the address-calculation, 
-- input 3 is pipelined and thus delayed with one extra clock tick. 
-- Therefore, input 3 is used for writing only!
-- And also, the data of port 1 is available only at the falling edge of the clock!
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.settings_package.all;

entity treeport_mem is
generic(
    DATA_WIDTH    : integer;
    ADDRESS_WIDTH : integer;
    CONTENT       : reg_mem_type
);
port (
    clk    :  in std_logic; -- the same clock for each input
    clkx2  :  in std_logic; -- clock x2

--    dia    :  in std_logic_vector (DATA_WIDTH-1 downto 0) := (others => '0'); -- A data in
--    dib    :  in std_logic_vector (DATA_WIDTH-1 downto 0) := (others => '0'); -- B data in
    dic    :  in std_logic_vector (DATA_WIDTH-1 downto 0) := (others => '0'); -- C data in

--    wea    :  in std_logic; -- A write enable in
--    web    :  in std_logic; -- B write enable in
    wec    :  in std_logic; -- C write enable in

    addra  :  in std_logic_vector (ADDRESS_WIDTH-1 downto 0); -- A address in
    addrb  :  in std_logic_vector (ADDRESS_WIDTH-1 downto 0); -- B address in
    addrc  :  in std_logic_vector (ADDRESS_WIDTH-1 downto 0); -- C address in

    doa    : out std_logic_vector (DATA_WIDTH-1 downto 0); -- A data out
    dob    : out std_logic_vector (DATA_WIDTH-1 downto 0) -- B data out
--    doc    : out std_logic_vector (DATA_WIDTH-1 downto 0) -- C data out
);
end treeport_mem;

architecture arch_treeport_mem of treeport_mem is

--signal data_muxac : std_logic_vector (DATA_WIDTH-1 downto 0);
signal doa_int    : std_logic_vector (DATA_WIDTH-1 downto 0);
--signal dob_int    : std_logic_vector (DATA_WIDTH-1 downto 0);
signal dic_buff   : std_logic_vector (DATA_WIDTH-1 downto 0);
signal we_muxac   : std_logic;
signal wec_buff   : std_logic;
signal addr_muxac : std_logic_vector (ADDRESS_WIDTH-1 downto 0);
signal addrc_buff : std_logic_vector (ADDRESS_WIDTH-1 downto 0);
--signal test       : std_logic_vector (ADDRESS_WIDTH-1 downto 0);
signal muxac      : std_logic;
signal clk_lac    : std_logic;

begin

block_ram : entity work.twoportclk_mem_2
generic map(
    DATA_WIDTH    => DATA_WIDTH,
    ADDRESS_WIDTH => ADDRESS_WIDTH,
    CONTENT       => CONTENT
)
port map(
    clk_1      => clkx2,
    clk_2      => clk,

    address_1  => addr_muxac,
    ce_1       => '1',
    we_1       => we_muxac,
    d_1        => doa_int,
    q_1        => dic_buff,

    address_2  => addrb,
    ce_2       => '1',
--    we_2       => web,
    d_2        => dob
--    q_2        => dib,
);

--data_muxac <= dic when muxac = '0' else dia;
we_muxac   <= wec_buff when muxac = '1' else '0';
addr_muxac <= addrc_buff when muxac = '1' else addra;
--addr_muxac <= addrc_buff when muxac = '1' else test;
muxac      <= clk_lac;

process (clk)
begin
if clk'event and clk = '1' then
    dic_buff   <= dic;
    addrc_buff <= addrc;
    wec_buff   <= wec;
--    test       <= addra;
end if;
if clk'event and clk = '0' then
    doa        <= doa_int;
end if;
end process;

process (clkx2) -- produce slightly delayed clk signal (clk_lac)
begin
if clkx2'event and clkx2 = '1' then
    clk_lac <= not clk;
end if;
end process;

end arch_treeport_mem;


