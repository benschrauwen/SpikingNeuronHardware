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
use work.utility_package.all;
use work.settings_package.all;

entity network_hardware is
port(
    s_clk        : in std_logic;
    s_reset      : in std_logic; 
    s_inputs     : in std_logic_vector(NR_INPUT_NODES-1 downto 0);
    s_output     : out std_logic_vector(NR_NEURONS-1 downto 0)
    );
end network_hardware;

architecture TB_ARCHITECTURE of network_hardware is
    constant WORD_LENGTH        : integer := 12;
    constant ACTIVE_LENGTH      : integer := 8;
    constant REFR_LENGTH        : integer := 6;
    constant RESET_VAL          : integer := -123;

    constant NR_TAPS            : integer := 2;
    constant TAP_ARRAY          : integer_array := (4, 5);

    constant NR_SYN_MODELS      : integer := 1;
    constant NR_SYN_TAPS        : integer_array := (0=>2);
    constant SYN_TAP_ARRAY      : integer_matrix := (0=>(3, 4));
begin
    netw: entity work.network
        generic map (WORD_LENGTH, ACTIVE_LENGTH, REFR_LENGTH, RESET_VAL, NR_TAPS, TAP_ARRAY, NR_SYN_MODELS, NR_SYN_TAPS, SYN_TAP_ARRAY, NR_NEURONS, NR_INPUT_NODES, CONN_FROM, NR_OUTPUT_NODES, OUTPUT_NODES, WEIGHTS, SYNAPSE_MAP)
        port map (s_clk, s_reset, s_inputs, s_output);
end TB_ARCHITECTURE;
