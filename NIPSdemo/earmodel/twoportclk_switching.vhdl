library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity twoportclk_switching is
generic(
    ADDRESS_WIDTH : integer;
    DATA_WIDTH    : integer;
    MEMORY_AMOUNT : integer
);
port(
    reset       :  in std_logic;
    switch      :  in std_logic;

    clk_1       :  in std_logic;
    clk_2       :  in std_logic;

    -- read/write port
    address_1   :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    ce_1        :  in std_logic;
    we_1        :  in std_logic;
    d_1         : out std_logic_vector (DATA_WIDTH-1 downto 0);
    q_1         :  in std_logic_vector (DATA_WIDTH-1 downto 0);

    -- read port
    address_2   :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    ce_2        :  in std_logic;
    d_2         : out std_logic_vector (DATA_WIDTH-1 downto 0)

);
end twoportclk_switching;

architecture structure of twoportclk_switching is
    signal s_offset_1, s_offset_2 : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal s_address_1, s_address_2 : std_logic_vector(ADDRESS_WIDTH downto 0);
    signal address_switch : std_logic;

begin
    process(reset, clk_1)
    begin
        if reset = '1' then
            address_switch <= '0';
        elsif clk_1'event and clk_1 = '1' then
            if switch = '1' then
                address_switch <= not address_switch;
            end if;
        end if;
    end process;

    s_offset_1  <= (others => '0') when address_switch = '0' else conv_std_logic_vector(MEMORY_AMOUNT, ADDRESS_WIDTH);
    s_offset_2  <= (others => '0') when address_switch = '1' else conv_std_logic_vector(MEMORY_AMOUNT, ADDRESS_WIDTH);
    s_address_1 <= conv_std_logic_vector(conv_integer(unsigned(address_1)) + conv_integer(unsigned(s_offset_1)),ADDRESS_WIDTH+1);
    s_address_2 <= conv_std_logic_vector(conv_integer(unsigned(address_2)) + conv_integer(unsigned(s_offset_2)),ADDRESS_WIDTH+1);

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
