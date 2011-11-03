----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- The network module builds a network of neurons by generating the neurons and passing
-- all the input and output signals to a interconnection block. The neuron parameters
-- and network topology can be passed using generics.
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.utility_package.all;
use work.settings_minimal_package.all;

entity network is
port(
    clk                 :  in std_logic;
    reset               :  in std_logic;

    inputs              :  in std_logic_vector(NR_INPUT_NODES-1 downto 0);
    outputs             : out std_logic_vector(NR_OUTPUT_NODES-1 downto 0);

    cycle_end           : out std_logic
);
end network;

-- NOTE: TOTAL_NR_NEURON_INPUTS = SUM(SYNAPSE_MAP), NR_NEURON_INPUTS(i) = SUM(PROJECTION(SYNAPSE_MAP, i))

-- TODO: support neurons with different number of inputs !! -> controller (ok, as long as output after expexted input for all neurons, else introduce input delays)
-- TODO: make neuron parameters neuron dependent
-- TODO: make weights changeable
-- TODO: provide input and output change signals, so user doesn't have to count
architecture structure of network is
    signal s_neuron_outputs     : std_logic_vector(NR_NEURONS-1 downto 0);

    signal s_integrate          : std_logic;
    signal s_decay              : std_logic;
    signal s_state_end          : std_logic;
    signal s_tap                : std_logic_vector(NR_TAPS_BITS-1 downto 0);
    signal s_extend             : std_logic_vector(NR_SYN_MODELS downto 0);
    signal s_reset_out          : std_logic;

$DECL_TEMPL$

begin
    

$TEMPL$

    control: entity work.controller
        generic map (NR_TAPS_BITS, NR_SYN_MODELS, PIPELINE_DEPTH(NR_SYN_MODELS, PROJECTION(SYNAPSE_MAP,0), NR_SYN_TAPS), MAXIMUM(WORD_LENGTH_BITS, LOG2CEIL(PIPELINE_DEPTH(NR_SYN_MODELS, PROJECTION(SYNAPSE_MAP,0), NR_SYN_TAPS) - NR_TAPS * WORD_LENGTH)) + 1, WORD_LENGTH, NR_SYN_TAPS, NR_TAPS, SYN_TAP_ARRAY, TAP_ARRAY)
        port map(clk, reset, s_reset_out, s_integrate, s_decay, s_state_end, s_tap, s_extend, cycle_end);

    output_gen : for i in NR_OUTPUT_NODES-1 downto 0 generate
        input_connection: if OUTPUT_NODES(i) < 0 generate
            outputs(i) <= inputs(-OUTPUT_NODES(i) - 1);
        end generate;

        internal_connection: if OUTPUT_NODES(i) > 0 generate
            outputs(i) <= s_neuron_outputs(OUTPUT_NODES(i) - 1);
        end generate;
    end generate;
end structure;

