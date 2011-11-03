----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- Specialized memory block, using a two-port memory.
-- One of the ports uses a cyclic buffer to address the content.
-- The address of one of the ports is internally offset by half the memory amount.
-- Applying a switch-signal, switches the offset from one port to the other, as such
-- implementing a switching memory.
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

use work.utility_package.pow2ceil;

entity twoport_switching_cyclic_buffer is
generic(
    ADDRESS_WIDTH : integer;
    DATA_WIDTH    : integer;
    MEMORY_AMOUNT : integer
);
port(
    reset       :  in std_logic;
    switch      :  in std_logic;

    clk_1       :  in std_logic;
    ce_1        :  in std_logic;
    we_1        :  in std_logic;
    addr_1_dec  :  in std_logic;
    d_1         : out std_logic_vector(DATA_WIDTH-1 downto 0);
    q_1         :  in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    clk_2       :  in std_logic;
    ce_2        :  in std_logic;
--    we_2        :  in std_logic;
    address_2   :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    d_2         : out std_logic_vector(DATA_WIDTH-1 downto 0)
--    q_2         :  in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')
);
end twoport_switching_cyclic_buffer;

architecture structure of twoport_switching_cyclic_buffer is
    signal r_address   : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal s_offset_1, s_offset_2 : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal s_address_1, s_address_2 : std_logic_vector(ADDRESS_WIDTH downto 0);
    signal address_switch : std_logic;

begin
    process(reset, clk_1)
    begin
        if reset = '1' then
            r_address <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
            address_switch <= '0';
        elsif clk_1'event and clk_1 = '1' then
            if switch = '1' then
                address_switch <= not address_switch;
                r_address      <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
            elsif addr_1_dec = '1' then
                if conv_integer(r_address) = 0 then
                    r_address <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
                else
                    r_address <= r_address - 1;
                end if;
            end if;
        end if;
    end process;

    s_offset_1  <= (others => '0') when address_switch = '0' else conv_std_logic_vector(MEMORY_AMOUNT, ADDRESS_WIDTH);
    s_offset_2  <= (others => '0') when address_switch = '1' else conv_std_logic_vector(MEMORY_AMOUNT, ADDRESS_WIDTH);
    s_address_1 <= conv_std_logic_vector(conv_integer(r_address) + conv_integer(s_offset_1),ADDRESS_WIDTH+1);
    s_address_2 <= conv_std_logic_vector(conv_integer(address_2) + conv_integer(s_offset_2),ADDRESS_WIDTH+1);

    blockram: entity work.twoportclk_mem
        generic map(
            DATA_WIDTH    => DATA_WIDTH,
            ADDRESS_WIDTH => ADDRESS_WIDTH+1,
            MEMORY_AMOUNT => 2*MEMORY_AMOUNT
        )
        port map(
            clk_1      => clk_1,
            address_1  => s_address_1,
            ce_1       => ce_1,
            we_1       => we_1,
            d_1        => d_1,
            q_1        => q_1,
            clk_2      => clk_2,
            address_2  => s_address_2,
            ce_2       => ce_2,
            d_2        => d_2
        );

end structure;
