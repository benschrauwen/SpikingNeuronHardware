library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity twoport_mem is
generic(
    DATA_WIDTH    : integer;
    ADDRESS_WIDTH : integer;
    MEMORY_AMOUNT : integer
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
    type memory_type is array(natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal r_memory  : memory_type(MEMORY_AMOUNT-1 downto 0);
    attribute ram_style : string;
--    attribute WRITE_MODE_A : string;
--    attribute WRITE_MODE_B : string;
--    attribute DOA_REG      : integer;
--    attribute DOB_REG      : integer;

    attribute ram_style of r_memory: signal is "block"; -- auto|block|distributed
--    attribute WRITE_MODE_A of r_memory: signal is "WRITE_FIRST";
--    attribute WRITE_MODE_B of r_memory: signal is "WRITE_FIRST";
--    attribute DOA_REG of r_memory: signal is 0;
--    attribute DOB_REG of r_memory: signal is 0;

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
		end if;
			if ce_2 = '1' then
--                if we_2 = '1' then
--                    r_memory(conv_integer(address_2)) <= q_2;
--                end if;
				d_2 <= r_memory(conv_integer(address_2));
			end if;
    end process;
end structure;
