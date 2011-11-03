-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Main-entity with fixed stuff
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
-- created : 2005/03/03
-- version 2
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use work.utility_package.all;
use work.neuron_config_package.all;
use work.settings_package.all;
use work.gen_settings_package.all;

-- TODO: er is precies nog iets mis met refractory

entity spiking_neuron--_$NEURON_NR$
is
generic (
    NEURON_NR          : integer        --:=$NEURON_NR$
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
    
    weight_in      : in std_logic_vector(WEIGHT_WIDTH-1 downto 0);

    -- neuron inputs and output
    neuron_outputs :  in std_logic_vector(NR_NEURONS-1 downto 0);
    inputs         :  in std_logic_vector(NR_INPUT_NODES-1 downto 0);
    output         : out std_logic
    );
end spiking_neuron--_$NEURON_NR$
;

architecture impl of spiking_neuron--_$NEURON_NR$
is
    component value_selection is
    generic(
        NEURON_NR      : integer
        );
    port(
        ctr            :  in std_logic_vector(STATE_WIDTH(NEURON_NR)-1 downto 0);
        start          :  in std_logic;
        decay_s        :  in std_logic;
        reg_select     :  in std_logic_vector(REG_WIDTH-1 downto 0);

        input          :  in std_logic_vector(NR_NEURON_INPUTS(NEURON_NR)-1 downto 0);
        reg_bank       :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        weight         :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);

        carry          : out std_logic;
        weight_out     : out std_logic_vector(WEIGHT_WIDTH-1 downto 0)
        );
    end component;

    component abs_refractory is
    generic(
        COMPARE_VALUE  : integer := 0
        );
    port(
        clk             :  in std_logic;
        reset           :  in std_logic;

        end_membr_decay :  in std_logic;

        spike_out       :  in std_logic;
        adder           :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

        ASP_enable      : out std_logic;            -- enabling this signal will write ASP in registers
        refract         : out std_logic
    );
    end component;

    component reset_accum is
    port(
        reg_sign   :  in std_logic;
        adder_sign :  in std_logic;

        start_decay :  in std_logic;

        reg_select :  in std_logic_vector(REG_WIDTH-1 downto 0);
        reset_in   :  in std_logic;

        reset_out  : out std_logic_vector(NR_SYN downto 0)
        );
    end component;

    component saturation is
    port(
        adder_value     :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

        neg_sat         : out std_logic;
        pos_sat         : out std_logic
    );
    end component;

    component buff is
    port(
        clk             :  in std_logic;
        reset           :  in std_logic;
        enable          :  in std_logic;

        buff_in         :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        buff_out        : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
    );
    end component;

    signal weight_out_s     : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal buf_reg_bank_s   : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal reg_bank_s       : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal ASP_enable_s     : std_logic;    
    signal carry_s          : std_logic;
    signal sum_s            : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);    
    signal thr_exceeded_s   : std_logic;
    signal output_s         : std_logic;    
    signal add_2_s          : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal write_enable_s   : std_logic;    
    signal asp_in_s         : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal reg_in_s         : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal membr_out_s      : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal accum_reset      : std_logic_vector(NR_SYN downto 0);
    signal end_membr_decay_s : std_logic;
    signal refract_s        : std_logic;
    signal neg_sat_s        : std_logic;
    signal pos_sat_s        : std_logic;
    signal capture_s        : std_logic;

    signal input_spikes: std_logic_vector(NR_NEURON_INPUTS(NEURON_NR)-1 downto 0);

    for value_selection_instance: value_selection
      use entity WORK.value_selection (hard_decay);
    for abs_refractory_instance: abs_refractory
      use entity WORK.abs_refractory  (membr_compared);
    for reset_accum_instance: reset_accum
      use entity WORK.reset_accum     (no);
    for saturation_instance: saturation
      use entity WORK.saturation      (posneg); -- no, neg, posneg
    for buffer_instance: buff
      use entity WORK.buff            (no);
begin
    internal_connections: for j in 0 to NR_NEURON_INPUTS(NEURON_NR)-1 generate
        input_connection: if CONN_FROM(NEURON_NR, j) < 0 generate
           input_spikes(j) <= inputs(-CONN_FROM(NEURON_NR, j) - 1);
        end generate;

        internal_connection: if CONN_FROM(NEURON_NR, j) > 0 generate
           input_spikes(j) <= neuron_outputs(CONN_FROM(NEURON_NR, j) - 1);
        end generate;
    end generate;

    buffer_instance: buff 
    port map(clk, reset, start, reg_bank_s, buf_reg_bank_s);

    -- value selection block
    value_selection_instance: value_selection
    generic map(NEURON_NR)
    port map(ctr, start, decay, reg_select, input_spikes, buf_reg_bank_s, weight_in, carry_s, weight_out_s);

    capture_s <= decay and start and write_membr;
    -- register bank used in this synapse model
    register_bank_instance: entity work.register_bank
    port map(clk, reset, accum_reset, write_enable_s, membr_select, capture_s, reg_select, reg_in_s, reg_bank_s, membr_out_s);

    -- absolute refractory selection
    abs_refractory_instance: abs_refractory
    generic map(REFR_COMPARE_VALUE )
    port map(clk, reset, end_membr_decay_s, output_s, sum_s, ASP_enable_s, refract_s);

    -- accumulator reset handling
    reset_accum_instance: reset_accum
    port map(reg_bank_s(MEMBRANE_WIDTH-1), sum_s(MEMBRANE_WIDTH-1), start, reg_select, reset, accum_reset);

    saturation_instance: saturation
    port map(sum_s, neg_sat_s, pos_sat_s);

    -- membrane mux
    add_2_s      <= weight_out_s when membr_select = '0' else membr_out_s;
    -- adder
    sum_s        <= reg_bank_s + add_2_s + carry_s;
    -- saturation
    asp_in_s     <= "11" & (asp_in_s'high-2 downto 0 => '0') when neg_sat_s = '1' else
                    "00" & (asp_in_s'high-2 downto 0 => '1') when pos_sat_s = '1' else
                    sum_s;
    -- ASP mux
    reg_in_s     <= conv_std_logic_vector(ASP, MEMBRANE_WIDTH) when ASP_enable_s = '1' else asp_in_s;
    
    -- threshold function
    thr_exceeded_s <= '1' when conv_integer(sum_s) > THRESHOLD else '0';
    output       <= output_s;

    -- output buffer
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                output_s  <= '0';
            elsif stop_cycle = '1' then 
                output_s <= thr_exceeded_s;
            else
                output_s <= output_s;
            end if;
        end if;
    end process;
    
    -- utility signals
    end_membr_decay_s <= decay and write_membr;
    write_enable_s <= not(refract_s and write_membr and not decay);
    
end impl;

----------------------------------------------------------------------------------
--
--configuration linear_1 of spiking_neuron is
--    for impl
--        for value_selection_instance: value_selection
--          use entity WORK.value_selection (linear_decay_1clk);
--        end for;
--        for abs_refractory_instance: abs_refractory
--          use entity WORK.abs_refractory  (no_refr); --membr_compared);
--        end for;
--        for reset_accum_instance: reset_accum
--          use entity WORK.reset_accum     (reset_stable_zero);
--        end for;
--        for saturation_instance: saturation
--          use entity WORK.saturation      (neg); -- no, neg, posneg
--        end for;
--        for buffer_instance: buff
--          use entity WORK.buff            (no);
--        end for;
--    end for;
--end linear_1;
--
----------------------------------------------------------------------------------
--
--configuration linear_2 of spiking_neuron is
--    for impl
--        for value_selection_instance: value_selection
--          use entity WORK.value_selection (linear_decay_2clk);
--        end for;
--        for abs_refractory_instance: abs_refractory
--          use entity WORK.abs_refractory  (no_refr); --membr_compared);
--        end for;
--        for reset_accum_instance: reset_accum
--          use entity WORK.reset_accum     (reset_stable_zero);
--        end for;
--        for saturation_instance: saturation
--          use entity WORK.saturation      (neg); -- no, neg, posneg
--        end for;
--        for buffer_instance: buff
--          use entity WORK.buff            (no);
--        end for;
--    end for;
--end linear_2;
--
----------------------------------------------------------------------------------
--
--configuration sos of spiking_neuron is
--    for impl
--        for value_selection_instance: value_selection
--          use entity WORK.value_selection (mem_decay);
--        end for;
--        for abs_refractory_instance: abs_refractory
--          use entity WORK.abs_refractory  (no_refr); -- membr_compared
--        end for;
--        for reset_accum_instance: reset_accum
--          use entity WORK.reset_accum     (no);
--        end for;
--        for saturation_instance: saturation
--          use entity WORK.saturation      (no); -- no, neg, posneg
--        end for;
--        for buffer_instance: buff
--          use entity WORK.buff            (yes);
--        end for;
--    end for;
--end sos;
--
----------------------------------------------------------------------------------
--
--configuration dos of spiking_neuron is
--    for impl
--        for value_selection_instance: value_selection
--          use entity WORK.value_selection (hard_decay);
--        end for;
--        for abs_refractory_instance: abs_refractory
--          use entity WORK.abs_refractory  (no_refr); --membr_compared);
--        end for;
--        for reset_accum_instance: reset_accum
--          use entity WORK.reset_accum     (no);
--        end for;
--        for saturation_instance: saturation
--          use entity WORK.saturation      (neg); -- no, neg, posneg
--        end for;
--        for buffer_instance: buff
--          use entity WORK.buff            (no);
--        end for;
--    end for;
--end dos;
--
