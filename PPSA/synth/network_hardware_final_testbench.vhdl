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
use work.settings_minimal_package.NR_INPUT_NODES;
use work.settings_minimal_package.NR_OUTPUT_NODES;
use work.settings_minimal_package.NR_TAPS;
use work.settings_minimal_package.WORD_LENGTH;

entity network_tb is
end network_tb;

architecture TB_ARCHITECTURE of network_tb is
    signal s_clk, s_reset      : std_logic; 
    signal s_inputs     : std_logic_vector(NR_INPUT_NODES-1 downto 0);
    signal s_output     : std_logic_vector(NR_OUTPUT_NODES-1 downto 0);
begin
    netw: entity work.network_hardware
        port map (s_clk, s_reset, s_inputs, s_output);

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
            else        
                if rest = 0 then
                    rest := (1+NR_TAPS)*WORD_LENGTH+1;          -- number of clocks in total neuron cycle (TODO: network should give this signal)
                    for i in NR_INPUT_NODES-1 downto 0 loop
                        if pos mod 2999 = 0 then                  -- 1/100 spike generation
                            s_inputs(i) <= '1';
                        else
                            s_inputs(i) <= '0';
                        end if;
                        pos := 1103515245*pos + 12345;          -- rand()
                    end loop;
                else 
                    rest := rest - 1;
                end if;
            end if;
        end if;
    end process;
    
end TB_ARCHITECTURE;

