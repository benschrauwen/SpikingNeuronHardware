----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- Memory structure implemented using LUTs. This is a standard two port memory, 
-- sharing the same clock.
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- 1-bit memory
-- can be inplemented with LUTS
-- one read and one write port

entity distrib_twoport_mem is
generic(
    ADDRESS_WIDTH : integer;
    MEMORY_AMOUNT : integer
);
port(
    clk       :  in std_logic;

    w_address :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    we        :  in std_logic;
    data_in   :  in std_logic;

    r_address :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    data_out  : out std_logic
);
end distrib_twoport_mem;

architecture structure of distrib_twoport_mem is
    type memory_type is array(natural range <>) of std_logic;
    signal r_memory  : memory_type(MEMORY_AMOUNT-1 downto 0) := (others => '0');
    attribute ram_style : string;
    attribute ram_style of r_memory: signal is "distributed";
begin
    process(clk)
    begin
        if clk'event and clk = '1' then
            if we = '1' then
                 r_memory(conv_integer(w_address)) <= data_in;
            end if;
        end if;
    end process;

    data_out <= r_memory(conv_integer(r_address));
end structure;
