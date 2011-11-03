----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- Simulation testbench for network. Interconnection settings are loaded from 
-- settings.vhdl .
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library std;
use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.utility_package.all;
use work.settings_package.all;

entity network_tb_sp is
end network_tb_sp;

architecture TB_ARCHITECTURE of network_tb_sp is
    constant WORD_LENGTH        : integer := 12;
    constant ACTIVE_LENGTH      : integer := 8;
    constant REFR_LENGTH        : integer := 7;
    constant RESET_VAL          : integer := -200;

    constant NR_TAPS            : integer := 2;
    constant TAP_ARRAY          : integer_array := (5, 6);

    constant NR_SYN_MODELS      : integer := 1;
    constant NR_SYN_TAPS        : integer_array := (0=>2);
    constant SYN_TAP_ARRAY      : integer_matrix := (0=>(4,5));
    
    signal s_cycle_end  : std_logic;
    signal s_clk        : std_logic;
    signal s_reset      : std_logic := '1'; 
    signal s_inputs     : std_logic_vector(NR_INPUT_NODES-1 downto 0) := (others => '0');
    signal s_output     : std_logic_vector(NR_OUTPUT_NODES-1 downto 0);

begin
    netw: entity work.network
        generic map (WORD_LENGTH, ACTIVE_LENGTH, REFR_LENGTH, RESET_VAL, NR_TAPS, TAP_ARRAY, NR_SYN_MODELS, NR_SYN_TAPS, SYN_TAP_ARRAY, NR_NEURONS, NR_INPUT_NODES, CONN_FROM, NR_OUTPUT_NODES, OUTPUT_NODES, WEIGHTS, SYNAPSE_MAP)
        port map (s_clk, s_reset, s_inputs, s_output, s_cycle_end);

    process
    begin
        s_clk<='0';
        wait for 10 ns;
        s_clk<='1';
        wait for 10 ns;
    end process; 
    
    process(s_clk)
        file in_data  : text open read_mode is "../SpeechTest/speech.dat";
        file out_data : text open write_mode is "results.dat";
        variable data : line;
        variable bit_data : bit_vector(NR_INPUT_NODES-1 downto 0);
        variable good : boolean;
    begin
        if rising_edge(s_clk) then
            s_reset <= '0';
            if s_cycle_end = '1' then
                readline(in_data, data);
                read(data, bit_data, good);
                if good then
                    s_inputs <= to_stdlogicvector(bit_data);
                    write(data, to_bitvector(s_output));
                else
                    write(data, string'("-------------------------------"));
                    s_reset <= '1';
                end if;

                writeline(out_data, data);
            end if;
        end if;
    end process;
    
end TB_ARCHITECTURE;

