----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- This module enables easy hardware implementation of SNN. Interconnection settings are
-- loaded from settings.vhdl .
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.settings_minimal_package.NR_INPUT_NODES;
use work.settings_minimal_package.NR_NEURONS;

entity network_hardware is
port(
    s_clk        : in std_logic;
    s_reset      : in std_logic; 
    s_inputs     : in std_logic_vector(NR_INPUT_NODES-1 downto 0);
    s_outputs    : out std_logic_vector(NR_NEURONS-1 downto 0)
    );
end network_hardware;

architecture TB_ARCHITECTURE of network_hardware is
    signal ff1, ff2     : std_logic_vector(NR_INPUT_NODES-1 downto 0);
    signal s_cycle_end  : std_logic;
    signal ff1_r, ff2_r : std_logic;
begin
    netw: entity work.network
        port map (s_clk, ff2_r, ff2, s_outputs, s_cycle_end);

    process(s_clk)
    begin
        if rising_edge(s_clk) then
            ff1 <= s_inputs;
            ff1_r <= s_reset;     -- reset is synchronous, so first sample
            ff2_r <= ff1_r;
            if s_cycle_end = '1' then
                ff2 <= ff1;       -- keep input stable during computation
            end if;
        end if;
    end process;
end TB_ARCHITECTURE;

