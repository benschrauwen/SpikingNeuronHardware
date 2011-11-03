----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- Simulation testbench for network. Interconnection settings are loaded from 
-- settings.vhdl .
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.utility_package.all;
use work.settings_package.all;

entity network_tb is
end network_tb;

architecture TB_ARCHITECTURE of network_tb is
    constant WORD_LENGTH        : integer := 12;
    constant ACTIVE_LENGTH      : integer := 8;
    constant REFR_LENGTH        : integer := 7;
    constant RESET_VAL          : integer := -200;

    constant NR_TAPS            : integer := 2;
    constant TAP_ARRAY          : integer_array := (4, 5);

    constant NR_SYN_MODELS      : integer := 1;
    constant NR_SYN_TAPS        : integer_array := (0=>2);
    constant SYN_TAP_ARRAY      : integer_matrix := (0=>(3,4));
    
    signal s_cycle_end  : std_logic;
    signal s_clk        : std_logic;
    signal s_reset      : std_logic; 
    signal s_inputs     : std_logic_vector(NR_INPUT_NODES-1 downto 0);
    signal s_output     : std_logic_vector(NR_OUTPUT_NODES-1 downto 0);
begin
    netw: entity work.network
        generic map (WORD_LENGTH, ACTIVE_LENGTH, REFR_LENGTH, RESET_VAL, NR_TAPS, TAP_ARRAY, NR_SYN_MODELS, NR_SYN_TAPS, SYN_TAP_ARRAY, NR_NEURONS, NR_INPUT_NODES, CONN_FROM, NR_OUTPUT_NODES, OUTPUT_NODES, WEIGHTS, SYNAPSE_MAP)
        port map (s_clk, s_reset, s_inputs, s_output, s_cycle_end);

    process
    begin
        s_clk<='1';
        wait for 10 ns;
        s_clk<='0';
        wait for 10 ns;
    end process; 
    
    s_reset <= '1','0' after 30 ns;
    
    process(s_clk)
        variable  rest : integer := 0;
        variable  pos  : integer := 2999;                      -- random seed
    begin
        if rising_edge(s_clk) then
            if s_reset = '1' then 
                s_inputs <= (others => '0');
            elsif s_cycle_end = '1' then 
                for i in NR_INPUT_NODES-1 downto 0 loop
                    if pos mod 2999 = 0 then                  -- 1/100 spike generation
                        s_inputs(i) <= '1';
                    else
                        s_inputs(i) <= '0';
                    end if;
                    pos := 1103515245*pos + 12345;          -- rand()
                end loop;
            end if;
        end if;
    end process;
    
end TB_ARCHITECTURE;

