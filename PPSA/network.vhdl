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

entity network is
generic (
-------------------------------- neuron parameters
    WORD_LENGTH         : integer;
    ACTIVE_LENGTH       : integer;
    REFR_LENGTH         : integer;
    RESET_VAL           : integer;
    NR_TAPS             : integer;
    TAP_ARRAY           : integer_array;
    NR_SYN_MODELS       : integer;
    NR_SYN_TAPS         : integer_array;
    SYN_TAP_ARRAY       : integer_matrix;
-------------------------------- interconnection parameters
    NR_NEURONS          : integer;
    NR_INPUT_NODES      : integer;
    CONN_FROM           : integer_matrix;
    NR_OUTPUT_NODES     : integer;
    OUTPUT_NODES        : integer_array;
    WEIGHTS             : integer_matrix;
    SYNAPSE_MAP         : integer_matrix
);
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
    signal s_neuron_inputs      : std_logic_matrix(NR_NEURONS-1 downto 0, MAXIMUM(SUM(SYNAPSE_MAP))-1 downto 0);

    signal s_integrate          : std_logic;
    signal s_decay              : std_logic;
    signal s_state_end          : std_logic;
    signal s_tap                : std_logic_vector(LOG2CEIL(NR_TAPS)-1 downto 0);
    signal s_extend             : std_logic_vector(NR_SYN_MODELS downto 0);
begin
    neuron_gen : for i in NR_NEURONS-1 downto 0 generate
        signal temp : std_logic_vector(SUM(SYNAPSE_MAP)(i)-1 downto 0); 
    begin
        temp <= PROJECTION(s_neuron_inputs, i)(SUM(SYNAPSE_MAP)(i)-1 downto 0);
        neur: entity work.neuron
            generic map(WORD_LENGTH, ACTIVE_LENGTH, REFR_LENGTH, RESET_VAL, NR_TAPS, TAP_ARRAY, NR_SYN_MODELS, NR_SYN_TAPS, SYN_TAP_ARRAY, PROJECTION(SYNAPSE_MAP,i), PROJECTION(WEIGHTS,i)(0 to SUM(SYNAPSE_MAP)(i)-1))
            port map(clk, reset, temp, s_integrate, s_decay, s_state_end, s_tap, s_extend, s_neuron_outputs(i));
    end generate;

    control: entity work.controller
        generic map(PIPELINE_DEPTH(NR_SYN_MODELS, PROJECTION(SYNAPSE_MAP,0), NR_SYN_TAPS), NR_TAPS, TAP_ARRAY, WORD_LENGTH, NR_SYN_MODELS, NR_SYN_TAPS, SYN_TAP_ARRAY)
        port map(clk, reset, s_integrate, s_decay, s_state_end, s_tap, s_extend, cycle_end);

    interconnection: entity work.interconnect
        generic map(NR_NEURONS, NR_INPUT_NODES, SUM(SYNAPSE_MAP), CONN_FROM, NR_OUTPUT_NODES, OUTPUT_NODES)
        port map(s_neuron_outputs, s_neuron_inputs, inputs, outputs);
end structure;

