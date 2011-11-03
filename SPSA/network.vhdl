----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- This block implements the network structure of the neural network
-- It takes care for distributing the spikes from source neurons to destination neurons
-- between two time steps.
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
library work;
use work.utility_package.all;

-- networkmem:
-- from-neuron, to-neuron,
-- in special order

entity network is
generic(
    NR_PARALLEL_NEURONS    : integer := 10;
    NR_SERIAL_NEURONS      : integer := 20;
    NR_WEIGHTS             : integer_matrix := ((12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0));       -- S1, S2, M -> number of inputs
    WEIGHT_WIDTH           : integer := 4;

    FROM_MEM_ADDRESS_WIDTH : integer := 5;

    CON_MEM_DATA_WIDTH     : integer := 10
);
port(
    clk               :  in std_logic;
    reset             :  in std_logic;
    start             :  in std_logic;
    neuron_number     :  in std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)-1 downto 0);
    ready             : out std_logic;

    from_mem_addr     : out std_logic_vector(FROM_MEM_ADDRESS_WIDTH-1 downto 0);
    from_mem_data     :  in std_logic_vector(NR_PARALLEL_NEURONS-1 downto 0);

    to_mem_we         : out std_logic;
    to_mem_addr_dec   : out std_logic;
    to_mem_data_sel   : out std_logic_vector(LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);
    to_mem_data       : out std_logic;

    con_mem_dec       : out std_logic;
    con_mem_data      :  in std_logic_vector(CON_MEM_DATA_WIDTH-1 downto 0);

    ext_input_addr    : out std_logic_vector(CON_MEM_DATA_WIDTH-2 downto 0);
    ext_input_data    :  in std_logic
);
end network;

architecture structure of network is
    type copy_state_space is (ready_state, copy);
    signal r_copy_state        : copy_state_space := ready_state;
    signal s_input_select, s_input_select_d, s_input_select_dd : std_logic;
    signal s_to_mem_data_sel, s_to_mem_data_sel_d, s_to_mem_data_sel_dd : std_logic_vector(LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);
    signal s_weight_counter    : std_logic_vector(WEIGHT_WIDTH-1 downto 0);
    signal s_from_data_buff, s_ext_data_buff : std_logic;
    signal s_to_dec, s_to_dec_d : std_logic;
    signal s_to_we, s_to_we_d   : std_logic;
    signal s_from_mem_data_sel, s_from_mem_data_sel_d : std_logic_vector(LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);

begin

    from_mem_addr       <= con_mem_data(CON_MEM_DATA_WIDTH-2 downto LOG2CEIL(NR_PARALLEL_NEURONS));
    s_from_mem_data_sel <= con_mem_data(LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);

    ext_input_addr      <= con_mem_data(CON_MEM_DATA_WIDTH-2 downto 0);

    s_input_select      <= con_mem_data(CON_MEM_DATA_WIDTH-1);

    to_mem_data    <= s_from_data_buff when s_input_select_dd = '0' else s_ext_data_buff;

    -- extra buffers for pipelining the async output memory in order to improve the clockspeed
--     process(clk)
--     begin
--         if rising_edge(clk) then
--             s_from_data_buff <= from_mem_data(conv_integer(s_input_select));
--             s_ext_data_buff  <= ext_input_data;
--             s_input_sel_buff <= s_input_select;
--
--             to_mem_data_sel  <= s_to_mem_data_sel;
--             to_mem_addr_dec  <= s_to_dec_buff;
--             to_mem_we        <= s_to_we_buff;
--         end if;
--     end process;

    -- state machine
    process(reset, clk)
    begin
        if reset = '1' then
            r_copy_state         <= ready_state;
            ready                <= '0';
            s_to_we              <= '0';
            s_to_we_d            <= '0';
            s_to_dec             <= '0';
            s_to_dec_d           <= '0';
            s_weight_counter     <= conv_std_logic_vector(CURRENT_NR_WEIGHTS(NR_WEIGHTS,conv_integer(neuron_number))-1, WEIGHT_WIDTH);
            s_to_mem_data_sel    <= (others => '0');
            s_to_mem_data_sel_d  <= (others => '0');
            s_to_mem_data_sel_dd <= (others => '0');
            con_mem_dec          <= '0';

        elsif rising_edge(clk) then

            -- data available one clock tick later, therefore buffer the input_select signal
            s_input_select_d      <= s_input_select;
            s_input_select_dd     <= s_input_select_d;

            s_from_mem_data_sel_d <= s_from_mem_data_sel;

            s_from_data_buff      <= from_mem_data(conv_integer(s_from_mem_data_sel_d));
            s_ext_data_buff       <= ext_input_data;

            s_to_mem_data_sel_d   <= s_to_mem_data_sel;
            s_to_mem_data_sel_dd  <= s_to_mem_data_sel_d;
            to_mem_data_sel       <= s_to_mem_data_sel_dd;

            s_to_dec_d            <= s_to_dec;
            to_mem_addr_dec       <= s_to_dec_d;

            s_to_we_d             <= s_to_we;
            to_mem_we             <= s_to_we_d;

            case r_copy_state is
                when ready_state =>
                    s_to_we       <= '0';
                    s_to_dec      <= '0';
                    s_to_mem_data_sel <= (others => '0');
                    if start = '1' then
                        r_copy_state <= copy;
                        ready <= '0';
                        con_mem_dec <= '1';
                    else
                        ready <= '1';
                        con_mem_dec <= '0';
                    end if;

                when copy =>
                    con_mem_dec  <= '1';
                    s_to_we      <= '1';

                    if s_to_mem_data_sel = conv_std_logic_vector(NR_PARALLEL_NEURONS-1,LOG2CEIL(NR_PARALLEL_NEURONS)) then
                        s_to_mem_data_sel  <= (others => '0');
                        s_to_dec           <= '1';
                        if s_weight_counter = conv_std_logic_vector(0,WEIGHT_WIDTH) then
                            s_weight_counter <= conv_std_logic_vector(CURRENT_NR_WEIGHTS(NR_WEIGHTS,conv_integer(neuron_number))-1, WEIGHT_WIDTH);
                            r_copy_state     <= ready_state;
                            con_mem_dec      <= '0';
                            ready            <= '1';
                        else
                            s_weight_counter <= s_weight_counter - 1;
                        end if;
                    else
                        s_to_mem_data_sel <= s_to_mem_data_sel + 1;
                        s_to_dec          <= '0';
                    end if;

                --------------------------------------------------------------------------------    
                when others =>
                    assert false report "Unknown state!" severity error;
            end case;
        end if;
    end process;

end structure;
