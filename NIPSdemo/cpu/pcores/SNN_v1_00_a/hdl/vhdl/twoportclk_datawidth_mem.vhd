library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
--use work.utility_package.log2ceil;

-- memory port 1 is the basic data width, port 2 can be NB_PORTS_2 times port 1 in width

entity twoportclk_datawidth_mem is
generic(
    ADDRESS_WIDTH_1 : integer;
    DATA_WIDTH_1    : integer;
    NB_PORTS_2      : integer;
    ADDRESS_WIDTH_2 : integer;
    MEMORY_AMOUNT   : integer
);
port(
    clk_1       :  in std_logic;
    address_1   :  in std_logic_vector(ADDRESS_WIDTH_1-1 downto 0);
    ce_1        :  in std_logic;
    we_1        :  in std_logic;
    d_1         : out std_logic_vector (DATA_WIDTH_1-1 downto 0);
    q_1         :  in std_logic_vector (DATA_WIDTH_1-1 downto 0);

    clk_2       :  in std_logic;
    address_2   :  in std_logic_vector(ADDRESS_WIDTH_2-1 downto 0);
    ce_2        :  in std_logic;
    we_2        :  in std_logic;
    d_2         : out std_logic_vector (NB_PORTS_2*DATA_WIDTH_1-1 downto 0);
    q_2         :  in std_logic_vector (NB_PORTS_2*DATA_WIDTH_1-1 downto 0)
);
end twoportclk_datawidth_mem;

architecture structure of twoportclk_datawidth_mem is
    type memory_type is array(MEMORY_AMOUNT-1 downto 0) of std_logic_vector(DATA_WIDTH_1-1 downto 0);
    signal r_memory : memory_type := (others => (others=>'0'));

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
                if we_2 = '1' then
                    for i in 0 to NB_PORTS_2-1 loop
                        r_memory(conv_integer(address_2)*NB_PORTS_2+i) <= q_2((i+1)*DATA_WIDTH_1-1 downto i*DATA_WIDTH_1);
                    end loop;
                end if;
                for i in 0 to NB_PORTS_2-1 loop
                    d_2((i+1)*DATA_WIDTH_1-1 downto i*DATA_WIDTH_1) <= r_memory(conv_integer(address_2)*NB_PORTS_2+i);
                end loop;
            end if;
        end if;
    end process;
end structure;
