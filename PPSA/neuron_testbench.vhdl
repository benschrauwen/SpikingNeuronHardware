----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- Simulation testbench for neuron.
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.utility_package.all;

entity tb is
end tb;

architecture TB_ARCHITECTURE of tb is
    constant WORD_LENGTH        : integer := 12;
    constant ACTIVE_LENGTH      : integer := 8;
    constant REFR_LENGTH        : integer := 6;
    constant RESET_VAL          : integer := -123;

    constant NR_TAPS            : integer := 2;
    constant TAP_ARRAY          : integer_array := (4, 5);

    constant NR_SYN_MODELS      : integer := 2;
    constant NR_SYN_TAPS        : integer_array := (2, 0);
    constant SYN_TAP_ARRAY      : integer_matrix := ((3, 4), (0,0));

    constant NR_SYNAPSES        : integer_array := (3, 1);
    constant WEIGHTS            : integer_array := (80, 37, 52, 43);
 
    signal s_clk        : std_logic;
    signal s_reset      : std_logic; 
    signal s_inputs     : std_logic_vector(SUM(NR_SYNAPSES)-1 downto 0);
    signal s_output     : std_logic;
    signal s_integrate  : std_logic;
    signal s_decay      : std_logic;
    signal s_state_end  : std_logic;
    signal s_tap        : std_logic_vector(LOG2CEIL(NR_TAPS)-1 downto 0);
    signal s_extend     : std_logic_vector(NR_SYN_MODELS downto 0);
begin
    control : entity work.controller
        generic map (PIPELINE_DEPTH(NR_SYN_MODELS, NR_SYNAPSES, NR_SYN_TAPS), NR_TAPS, TAP_ARRAY, WORD_LENGTH, NR_SYN_MODELS, NR_SYN_TAPS, SYN_TAP_ARRAY)
        port map (s_clk, s_reset, s_integrate, s_decay, s_state_end, s_tap, s_extend);

    neur : entity work.neuron
        generic map (WORD_LENGTH, ACTIVE_LENGTH, REFR_LENGTH, RESET_VAL, NR_TAPS, TAP_ARRAY, NR_SYN_MODELS, NR_SYN_TAPS, SYN_TAP_ARRAY, NR_SYNAPSES, WEIGHTS)
        port map (s_clk, s_reset, s_inputs, s_integrate, s_decay, s_state_end, s_tap, s_extend, s_output);

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
        variable  pos  : integer := 12345;                      -- random seed
    begin
        if rising_edge(s_clk) then
            if s_reset = '1' then 
                s_inputs <= (others => '0');
            else        
                if rest = 0 then
                    rest := (1+NR_TAPS)*WORD_LENGTH+1;          -- number of clocks in total neuron cycle (TODO: network should give this signal)
                    for i in NR_INPUT_NODES-1 downto 0 loop
                        pos := 1103515245*pos + 12345;          -- rand()
                        if pos mod 99 = 0 then                  -- 1/100 spike generation
                            s_inputs(i) <= '1';
                        else
                            s_inputs(i) <= '0';
                        end if;
                    end loop;
                else 
                    rest := rest - 1;
                end if;
            end if;
        end if;
    end process;
end TB_ARCHITECTURE;

