----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- General implementation of a two port memory, with two clock domains.
-- Two such memories are used, this is the first two port memory.
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
--use work.settings_package.reg_mem_type;

entity twoportclk_mem is
generic(
    DATA_WIDTH    : integer;
    ADDRESS_WIDTH : integer;
    MEMORY_AMOUNT : integer
);
port(
    clk_1       :  in std_logic;
    clk_2       :  in std_logic;

    address_1   :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    ce_1        :  in std_logic;
    we_1        :  in std_logic;
    d_1         : out std_logic_vector (DATA_WIDTH-1 downto 0);
    q_1         :  in std_logic_vector (DATA_WIDTH-1 downto 0);

    address_2   :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    ce_2        :  in std_logic;
--    we_2        :  in std_logic;
    d_2         : out std_logic_vector (DATA_WIDTH-1 downto 0)
--    q_2         :  in std_logic_vector (DATA_WIDTH-1 downto 0)
);
end twoportclk_mem;

architecture structure of twoportclk_mem is
    constant zeros : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    type memory_type is array(natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal r_memory  : memory_type(MEMORY_AMOUNT-1 downto 0) := (others => zeros);
    attribute ram_style : string;
    attribute ram_style of r_memory: signal is "block";
begin
    process(clk_1)
    begin
        if clk_1'event and clk_1 = '1' then
            if ce_1 = '1' then
                if we_1 = '1' then
                  r_memory(conv_integer(address_1)) <= q_1;
                end if;
                d_1 <= r_memory(conv_integer(address_1));
            end if;
        end if;
    end process;

    process(clk_2)
    begin
        if clk_2'event and clk_2 = '1' then
            if ce_2 = '1' then
--                if we_2 = '1' then
--                    r_memory(conv_integer(address_2)) <= q_2;
--                end if;
                d_2 <= r_memory(conv_integer(address_2));
            end if;
        end if;
    end process;
end structure;
