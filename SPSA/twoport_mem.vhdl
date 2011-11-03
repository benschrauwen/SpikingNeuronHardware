----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- This is a standard two port memory, sharing the same clock.
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.settings_package.reg_mem_type;

entity twoport_mem is
generic(
    DATA_WIDTH    : integer;
    ADDRESS_WIDTH : integer;
    CONTENT       : reg_mem_type
);
port(
    clk         :  in std_logic;

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
end twoport_mem;

architecture structure of twoport_mem is
    signal r_memory  : reg_mem_type := CONTENT;
    --attribute ram_style : string;
    --attribute ram_style of r_memory: signal is "block";
begin
    process(clk)
    begin
        if clk'event and clk = '1' then
            if ce_1 = '1' then
                if we_1 = '1' then
                  r_memory(conv_integer(address_1)) <= q_1;
                end if;
                d_1 <= r_memory(conv_integer(address_1));
            end if;
            if ce_2 = '1' then
--                if we_2 = '1' then
--                    r_memory(conv_integer(address_2)) <= q_2;
--                end if;
                d_2 <= r_memory(conv_integer(address_2));
            end if;
        end if;
    end process;
end structure;
