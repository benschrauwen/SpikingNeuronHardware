----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- Memory structure implemented using LUTs. The memory is split in two sections,
-- where one section is used to preload data for the next time step, and the other
-- is the working memory.
-- The function of both sections is changed by applying a switch-signal.
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------



library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- two different clocks possible
-- can be inplemented with LUTS
-- one read and one write port
-- 1-bit synchronous writing
-- N-bit synchronous reading
-- switching content when switch input is high, clocked with read-clock
-- warning: w_clk must be at least as fast as r_clk!

entity distrib_preload_buff is
generic(
    ADDRESS_WIDTH : integer;
    MEMORY_AMOUNT : integer;
    SELECT_WIDTH  : integer;
    R_DATA_WIDTH  : integer
);
port(
    reset         :  in std_logic;

    r_clk         :  in std_logic;
    switch        :  in std_logic;
    r_addr_dec    :  in std_logic;
    data_out      : out std_logic_vector(R_DATA_WIDTH-1 downto 0);

    w_clk         :  in std_logic;
    we_array      :  in std_logic_vector(R_DATA_WIDTH-1 downto 0);
--    we            :  in std_logic;
    w_addr_dec    :  in std_logic;
    data_select   :  in std_logic_vector(SELECT_WIDTH-1 downto 0);
    data_in       :  in std_logic
);
end distrib_preload_buff;

architecture structure of distrib_preload_buff is
    signal r_offset, w_offset : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal s_w_addr, s_r_addr : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal w_address, r_address : std_logic_vector(ADDRESS_WIDTH downto 0);
    signal s_data_in, s_data_out : std_logic_vector(R_DATA_WIDTH-1 downto 0);
--    signal s_we : std_logic_vector(R_DATA_WIDTH-1 downto 0);
begin

    -- generate R_DATA_WIDTH times a 1 bit memory of 2 times the memory amount (for preloading)
    spike_in_mem: for i in 0 to R_DATA_WIDTH-1 generate
        spike_in_mem_i: entity work.distrib_twoport_mem
            generic map(
                ADDRESS_WIDTH => ADDRESS_WIDTH+1,
                MEMORY_AMOUNT => 2*MEMORY_AMOUNT
            )
            port map(
                clk        => w_clk,
                w_address  => w_address,
                we         => we_array(i), --s_we(i),
                data_in    => s_data_in(i),
                r_address  => r_address,
                data_out   => s_data_out(i)
            );
    end generate;

    w_address <= conv_std_logic_vector(conv_integer(w_offset) + conv_integer(s_w_addr),ADDRESS_WIDTH+1);
    r_address <= conv_std_logic_vector(conv_integer(r_offset) + conv_integer(s_r_addr),ADDRESS_WIDTH+1);

--     process (we,data_select)
--     begin
--         s_we <= (others => '0');
--         s_we(conv_integer(data_select)) <= we;
--     end process;

    process (data_select, data_in)
    begin
        s_data_in <= (others => '0');
        s_data_in(conv_integer(data_select)) <= data_in;
    end process;

    process(w_clk,reset)
    begin
        if reset = '1' then
            s_w_addr <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
        elsif w_clk'event and w_clk = '1' then
            -- warning: w_clk must be at least as fast as r_clk!
            if switch = '1' then
                s_w_addr     <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
            elsif w_addr_dec = '1' then
                if conv_integer(s_w_addr) = 0 then
                    s_w_addr <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
                else
                    s_w_addr <= s_w_addr - 1;
                end if;
            end if;
        end if;
    end process;

    process(r_clk,reset)
    begin
        if reset = '1' then
            s_r_addr   <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
            r_offset <= (others => '0');
            w_offset <= conv_std_logic_vector(MEMORY_AMOUNT, ADDRESS_WIDTH);
        elsif r_clk'event and r_clk = '1' then
            if switch = '1' then
                if conv_integer(r_offset) = 0 then
                    r_offset <= conv_std_logic_vector(MEMORY_AMOUNT, ADDRESS_WIDTH);
                    w_offset <= (others => '0');
                else
                    r_offset <= (others => '0');
                    w_offset <= conv_std_logic_vector(MEMORY_AMOUNT, ADDRESS_WIDTH);
                end if;
                s_r_addr     <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);

            elsif r_addr_dec = '1' then
                if conv_integer(s_r_addr) = 0 then
                    s_r_addr <= conv_std_logic_vector(MEMORY_AMOUNT-1,ADDRESS_WIDTH);
                else
                    s_r_addr <= s_r_addr - 1;
                end if;
            end if;
        end if;
    end process;

    data_out <= s_data_out;

end structure;
