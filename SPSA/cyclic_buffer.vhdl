----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- General implementation of a cyclic buffer, two such memories are used. 
-- This is the first cyclic memory.
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------



library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.settings_package.all;

entity cyclic_buffer is
generic(
    ADDRESS_WIDTH : integer;
    DATA_WIDTH    : integer;
    MEMORY_AMOUNT : integer;
    CONTENT       : weight_mem_type := (others => (others => '-'))
);
port(
    clk         :  in std_logic;
    reset       :  in std_logic;
    ce          :  in std_logic;
--    we          :  in std_logic;
    addr_dec    :  in std_logic;
    d           : out std_logic_vector(DATA_WIDTH-1 downto 0)
--    q           :  in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')
);
end cyclic_buffer;

architecture structure of cyclic_buffer is
    signal r_address : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal r_memory  : weight_mem_type := CONTENT;
    attribute ram_style : string;
    attribute ram_style of r_memory: signal is "block";
begin
    process(clk)
    begin
        if clk'event and clk = '1' then
            if ce = '1' then
--                if we = '1' then
--                    r_memory(conv_integer(r_address)) <= q;
--                end if;
                d <= r_memory(conv_integer(r_address));
            end if;
        end if;
    end process;

    process(reset, clk)
    begin
        if reset = '1' then
            r_address <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
        elsif clk'event and clk = '1' then
            if addr_dec = '1' then
                if conv_integer(r_address) = 0 then
                    r_address <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
                else
                    r_address <= r_address - 1;
                end if;
            end if;
        end if;
    end process;
end structure;
