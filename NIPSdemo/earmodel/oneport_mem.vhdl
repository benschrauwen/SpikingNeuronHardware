library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity oneport_mem is
generic(
    DATA_WIDTH    : integer;
    ADDRESS_WIDTH : integer;
    MEMORY_AMOUNT : integer
);
port(
    clk       :  in std_logic;

    address   :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    ce        :  in std_logic;
    we        :  in std_logic;
    d         : out std_logic_vector (DATA_WIDTH-1 downto 0);
    q         :  in std_logic_vector (DATA_WIDTH-1 downto 0)
);
end oneport_mem;

architecture structure of oneport_mem is
    constant zeros : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    type memory_type is array(natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem  : memory_type(MEMORY_AMOUNT-1 downto 0) := (others => zeros);
    attribute ram_style : string;
    attribute ram_style of mem: signal is "block";

begin
    process(clk)
    begin
        if clk'event and clk = '1' then
            if ce = '1' then
                if we = '1' then
                  mem(conv_integer(address)) <= q;
                end if;
                d <= mem(conv_integer(address));
            end if;
         end if;
    end process;
end structure;
