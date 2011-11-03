-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- network block
--
-- auteurs    : Michiel D'Haene, Benjamin Schrauwen
-- aangemaakt : 2005/03/04
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.utility_package.all;
use work.neuron_config_package.all;
use work.settings_package.all;

entity network is
port(
    clk                 :  in std_logic;
    reset               :  in std_logic;
    enable              :  in std_logic;

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

    signal start_s, decay_s, write_membr_s, membr_select_s, stop_cycle_s : std_logic;
    -- FIXME, TODO: more neurons ??
    signal pre_ctr_s    : std_logic_vector(STATE_WIDTH(0)-1 downto 0);
    signal ctr_s        : std_logic_vector(STATE_WIDTH(0)-1 downto 0);
    signal reg_select_s : std_logic_vector(REG_WIDTH-1 downto 0);
    signal weight_in_s  : std_logic_vector(WEIGHT_WIDTH*NR_NEURONS-1 downto 0);

    component spiking_neuron is
    generic (
             NEURON_NR          : integer
             );
    port(
             clk            :  in std_logic;
             reset          :  in std_logic;
             
             -- control signals
             ctr            :  in std_logic_vector(STATE_WIDTH(NEURON_NR)-1 downto 0);
             reg_select     :  in std_logic_vector(REG_WIDTH-1 downto 0);
             decay          :  in std_logic;
             start          :  in std_logic;
             write_membr    :  in std_logic;
             membr_select   :  in std_logic;
             stop_cycle     :  in std_logic;
             
             weight_in      :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);
    
             -- neuron inputs and output
             neuron_outputs :  in std_logic_vector(NR_NEURONS-1 downto 0);
             inputs         :  in std_logic_vector(NR_INPUT_NODES-1 downto 0);
             output         : out std_logic
             );
    end component;

    -- $NEURON_DECL$
begin
    -- $NEURON_INST$
--    neuron_gen : for i in NR_NEURONS-1 downto 0 generate
--    begin
--        spiking_neuron_instance: spiking_neuron
--        generic map(i)
--        port map(clk, reset, ctr_s, reg_select_s, decay_s, start_s, write_membr_s, membr_select_s, stop_cycle_s, weight_in_s(WEIGHT_WIDTH*(i+1)-1 downto WEIGHT_WIDTH*i), s_neuron_outputs, inputs, s_neuron_outputs(i));
--    end generate;

    -- weight memory
    weight_memory_instance: entity work.memory
    port map(clk => clk, address => pre_ctr_s, data_out => weight_in_s, we => not enable);


    -- controller
    controller_instance : entity work.controller
    port map (clk, reset, enable, pre_ctr_s, ctr_s, reg_select_s, decay_s, start_s, write_membr_s, membr_select_s, stop_cycle_s);

    cycle_end <= stop_cycle_s;

    output_gen : for i in NR_OUTPUT_NODES-1 downto 0 generate
        input_connection: if OUTPUT_NODES(i) < 0 generate
            outputs(i) <= inputs(-OUTPUT_NODES(i) - 1);
        end generate;

        internal_connection: if OUTPUT_NODES(i) > 0 generate
            outputs(i) <= s_neuron_outputs(OUTPUT_NODES(i) - 1);
        end generate;
    end generate;
end structure;
