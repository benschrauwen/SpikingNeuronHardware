----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- The neuron module generates a dendritic tree consisting of dendrite_adders and
-- synapse_models. The leafs are synapses and the root is a membrane module. A pipeline
-- delay line for the control signals is also created. Note that synapses do not go in 
-- a new delay stage.
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.utility_package.all;

entity neuron is
generic (
    WORD_LENGTH   : integer;
    ACTIVE_LENGTH : integer;
    REFR_LENGTH   : integer;
    RESET_VAL     : integer;
    
    NR_TAPS       : integer;
    TAP_ARRAY     : integer_array;

    NR_SYN_MODELS : integer;
    NR_SYN_TAPS   : integer_array;
    SYN_TAP_ARRAY : integer_matrix;

    NR_SYNAPSES   : integer_array;
    WEIGHTS       : integer_array
);
port (
    clk         :  in std_logic;
    reset       :  in std_logic;

    input_spikes:  in std_logic_vector(SUM(NR_SYNAPSES)-1 downto 0);
    integrate   :  in std_logic;
    decay       :  in std_logic;
    state_end   :  in std_logic;
    tap         :  in std_logic_vector(LOG2CEIL(NR_TAPS)-1 downto 0);
    extend      :  in std_logic_vector(NR_SYN_MODELS downto 0);

    output      : out std_logic
);
end neuron;

-- TODO: instead of zero_generator which is used to trim away empty synapse_models (but synthesizer is not smart enough), 
--       create a smaller dendritic tree
architecture structure of neuron is 
    constant NR_DEN_LAYERS      : integer := PIPELINE_DEPTH(NR_SYN_MODELS, NR_SYNAPSES, NR_SYN_TAPS);
 
    signal s_dendrite           : std_logic_vector(NR_SYN_MODELS*2-1 downto 1);
    signal s_dendrite_syn       : std_logic_matrix(NR_SYN_MODELS-1 downto 0, MAXIMUM(NR_SYNAPSES)*2-1 downto 1);
    
    signal s_integrate_delay    : std_logic_vector(NR_DEN_LAYERS downto 0);
    signal s_decay_delay        : std_logic_vector(NR_DEN_LAYERS downto 0);
    signal s_state_end_delay    : std_logic_vector(NR_DEN_LAYERS downto 0);
    type tap_type is array (natural range <>) of std_logic_vector(LOG2CEIL(NR_TAPS)-1 downto 0);
    signal s_tap_delay          : tap_type(NR_DEN_LAYERS downto 0);
    type extend_type is array (natural range <>) of std_logic_vector(NR_SYN_MODELS downto 0);
    signal s_extend_delay       : extend_type(NR_DEN_LAYERS downto 0);
begin
    -- create synapse_models
    syn_model_generator: for i in NR_SYN_MODELS-1 downto 0 generate
        -- create synapse_model if number of taps > 0
        syn_models_test_1: if NR_SYN_TAPS(i) /= 0 generate
            syn_models: entity work.synapse_model
                generic map (WORD_LENGTH, NR_SYN_TAPS(i), PROJECTION(SYN_TAP_ARRAY,i))
                port map (clk, reset, s_integrate_delay(LOG2FLOOR(NR_SYN_MODELS*2-1-i)+1), s_decay_delay(LOG2FLOOR(NR_SYN_MODELS*2-1-i)+1), s_state_end_delay(LOG2FLOOR(NR_SYN_MODELS*2-1-i)+1), s_tap_delay(LOG2FLOOR(NR_SYN_MODELS*2-1-i)+1), s_extend_delay(LOG2FLOOR(NR_SYN_MODELS*2-1-i)+1)(i+1), s_dendrite_syn(i, 1), s_dendrite(NR_SYN_MODELS*2-1-i));
            
            -- create sub-dendritic tree for this synapse model
            dendrite_generator: for j in NR_SYNAPSES(i)-1 downto 1 generate
                dendrites: entity work.dendrite_adder
                    port map (clk, reset, s_integrate_delay(LOG2FLOOR(j*2+1)+LOG2FLOOR(NR_SYN_MODELS*2-1-i)+1), s_dendrite_syn(i, j*2), s_dendrite_syn(i, j*2+1), s_dendrite_syn(i, j));
            end generate;
        
            -- and connect synapses to them
            synapses_generator: for j in NR_SYNAPSES(i)-1 downto 0 generate
                synapses: entity work.synapse(inferred) 
                    -- synapse does not introduce delay because next value is already pre-loaded
                    generic map (WORD_LENGTH, WEIGHTS(SUM_END(NR_SYNAPSES,i+1) + j))
                    port map (clk, reset, s_integrate_delay(LOG2FLOOR(NR_SYNAPSES(i)*2-1-j)+LOG2FLOOR(NR_SYN_MODELS*2-1-i)+1), '0', input_spikes(SUM_END(NR_SYNAPSES,i+1) + j), '0', s_dendrite_syn(i, NR_SYNAPSES(i)*2-1-j));
            end generate;
            
            -- if this model does not have synapses, connect zero
            zero_generator: if NR_SYNAPSES(i) = 0 generate
                s_dendrite_syn(i, 1) <= '0';
            end generate;
        end generate;

        -- if number of taps = 0, no synapse_model, just create sub-tree
        syn_models_test_2: if NR_SYN_TAPS(i) = 0 generate
            s_dendrite(NR_SYN_MODELS*2-1-i) <= s_dendrite_syn(i, 1);
            
            -- create sub-dendritic tree
            dendrite_generator: for j in NR_SYNAPSES(i)-1 downto 1 generate
                dendrites: entity work.dendrite_adder
                    port map (clk, reset, s_integrate_delay(LOG2FLOOR(j*2+1)+LOG2FLOOR(NR_SYN_MODELS*2-1-i)), s_dendrite_syn(i, j*2), s_dendrite_syn(i, j*2+1), s_dendrite_syn(i, j));
            end generate;
        
            -- connect synapses
            synapses_generator: for j in NR_SYNAPSES(i)-1 downto 0 generate
                synapses: entity work.synapse(inferred)
                    generic map (WORD_LENGTH, WEIGHTS(SUM_END(NR_SYNAPSES,i+1) + j))
                    port map (clk, reset, s_integrate_delay(LOG2FLOOR(NR_SYNAPSES(i)*2-1-j)+LOG2FLOOR(NR_SYN_MODELS*2-1-i)), '0', input_spikes(SUM_END(NR_SYNAPSES,i+1) + j), '0', s_dendrite_syn(i, NR_SYNAPSES(i)*2-1-j));
            end generate;

            -- if no synapses, zero 
            zero_generator: if NR_SYNAPSES(i) = 0 generate
                s_dendrite_syn(i, 1) <= '0';
            end generate;
        end generate;
    end generate;

    -- create primary dendritic tree which connects to the various synapse_models
    base_dendrite_generator: for i in NR_SYN_MODELS-1 downto 1 generate
        base_dendrites: entity work.dendrite_adder
            port map (clk, reset, s_integrate_delay(LOG2FLOOR(i*2+1)), s_dendrite(i*2), s_dendrite(i*2+1), s_dendrite(i));
    end generate;

    -- membrane block
    membr: entity work.membrane
        generic map (WORD_LENGTH, ACTIVE_LENGTH, REFR_LENGTH, RESET_VAL, NR_TAPS, TAP_ARRAY)
        port map (clk, reset, s_integrate_delay(0), s_decay_delay(0), s_state_end_delay(0), s_tap_delay(0), s_extend_delay(0)(0), s_dendrite(1), output);

    -- creates the control pipeline
    s_integrate_delay(NR_DEN_LAYERS) <= integrate;
    s_decay_delay(NR_DEN_LAYERS) <= decay;
    s_state_end_delay(NR_DEN_LAYERS) <= state_end;
    s_tap_delay(NR_DEN_LAYERS) <= tap;
    s_extend_delay(NR_DEN_LAYERS) <= extend;

    control_pipeline_generator: for i in NR_DEN_LAYERS-1 downto 0 generate
        control_pipeline: entity work.commandpipe
            generic map (NR_TAPS, NR_SYN_MODELS)
            port map (clk, reset, s_integrate_delay(i+1), s_decay_delay(i+1), s_state_end_delay(i+1), s_tap_delay(i+1), s_extend_delay(i+1), s_integrate_delay(i), s_decay_delay(i), s_state_end_delay(i), s_tap_delay(i), s_extend_delay(i));
    end generate;
end structure;

