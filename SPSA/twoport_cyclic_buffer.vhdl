----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- Specialized memory block, using a two-port memory.
-- One of the ports uses a cyclic buffer to address the content.
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity twoport_cyclic_buffer is
generic(
    ADDRESS_WIDTH : integer;
    DATA_WIDTH    : integer;
    MEMORY_AMOUNT : integer
);
port(
    reset       :  in std_logic;

    clk_1       :  in std_logic;
    ce_1        :  in std_logic;
    we_1        :  in std_logic;
    addr_1_dec  :  in std_logic;
    d_1         : out std_logic_vector(DATA_WIDTH-1 downto 0);
    q_1         :  in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    clk_2       :  in std_logic;
    ce_2        :  in std_logic;
    we_2        :  in std_logic;
    address_2   :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    d_2         : out std_logic_vector(DATA_WIDTH-1 downto 0);
    q_2         :  in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')
);
end twoport_cyclic_buffer;

architecture structure of twoport_cyclic_buffer is
    constant zeros : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal r_address, s_address_1, s_address_2 : std_logic_vector(ADDRESS_WIDTH-1 downto 0);

    type memory_type is array(natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal r_memory  : memory_type(MEMORY_AMOUNT-1 downto 0) := (others => zeros);
begin
    process(reset, clk_1)
    begin
        if reset = '1' then
            r_address <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
        elsif clk_1'event and clk_1 = '1' then
            if ce_1 = '1' then
                if we_1 = '1' then
                    r_memory(conv_integer(r_address)) <= q_1;
                end if;
                s_address_1 <= r_address;
            end if;
            if addr_1_dec = '1' then
                if conv_integer(r_address) = 0 then
                    r_address <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
                else
                    r_address <= r_address - 1;
                end if;
            end if;
        end if;
    end process;

    process(clk_2)
    begin
        if clk_2'event and clk_2 = '1' then
            if ce_2 = '1' then
                if we_2 = '1' then
                    r_memory(conv_integer(address_2)) <= q_2;
                end if;
                s_address_2 <= address_2;
            end if;
        end if;
    end process;

    d_1 <= r_memory(conv_integer(s_address_1));
    d_2 <= r_memory(conv_integer(s_address_2));
end structure;
