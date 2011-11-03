-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Main-entity with fixed stuff
--
-- authors    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- created    : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity spiking_neuron is
generic (
    N                  : integer;
    NEURON_STATE_WIDTH : integer;
    MEMBRANE_WIDTH     : integer;
    THRESHOLD          : integer;
    ASP                : integer;
    
    -- value selection constants
    WEIGHT_WIDTH       : integer;
    DOS_SHIFT1         : integer;
    DOS_SHIFT2         : integer;

    -- register bank constants    
    REG_WIDTH          : integer;
    
    -- absolute refractory constants
    REFR_COMPARE_VALUE : integer
    );
    
port(
    clk            :  in std_logic;
    reset          :  in std_logic;
    
    ctr            :  in std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);	
    reg_select     :  in std_logic_vector(REG_WIDTH-1 downto 0);	
    start_syn      :  in std_logic;
    start_membr    :  in std_logic;
    stop_syn       :  in std_logic;
    stop_membr     :  in std_logic;
    
    we             :  in std_logic;
    weight_ext     :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);

    input          :  in std_logic_vector(N-1 downto 0);
    output         : out std_logic
    );
end spiking_neuron;

architecture impl of spiking_neuron is
    
    -- value selection block
    component value_selection
    generic(
        N                  : integer;
        NEURON_STATE_WIDTH : integer;
        MEMBRANE_WIDTH     : integer;
        WEIGHT_WIDTH       : integer;
        DOS_SHIFT1         : integer;
        DOS_SHIFT2         : integer
    );
    port(
        ctr            :  in std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);
        start_syn      :  in std_logic;
        start_membr    :  in std_logic;
        stop_membr     :  in std_logic;

        input          :  in std_logic_vector(N-1 downto 0);
        --input_enable   :  in std_logic;
        reg_bank       :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        accum          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        weight         :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);

        carry          : out std_logic;
        add_2          : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
        );
    end component;

    -- weight memory (can be just one bit when using fixed weights)
    component memory
    generic(
        ADDRESS_WIDTH  : integer;
        DATA_WIDTH     : integer
    );
    port(
        clk           :  in std_logic;
        we            :  in std_logic;
        address       :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        data_in       :  in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out      : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;
   

    component register_bank
    generic(
        MEMBRANE_WIDTH : integer;
        REG_WIDTH      : integer
    );
    port(
        clk            :  in std_logic;
        reset          :  in std_logic;

        stop_syn       :  in std_logic;
        stop_membr     :  in std_logic;
        reg_select     :  in std_logic_vector(REG_WIDTH-1 downto 0);

        adder          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

        output         : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
    );
    end component;

    -- in some shift-implementations, the membrane has to be initialized
    component init
    generic(
        MEMBRANE_WIDTH : integer
    );
    port(
        start_syn      :  in std_logic;
        start_membr    :  in std_logic;

        accum          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        reg_bank       :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

        add_1          : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
        );
    end component;

    -- absolute refractory selection
    component abs_refractory
    generic(
        MEMBRANE_WIDTH : integer;
        COMPARE_VALUE    : integer
    );
    port(
        clk          :  in std_logic;
        reset        :  in std_logic;
        stop_membr   :  in std_logic;

        spike_out    :  in std_logic;
        adder        :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

        ASP_enable   : out std_logic;
        membr_enable : out std_logic
        );
    end component;

    component reset_accum is
    port(
        reg_sign        :  in std_logic;
        accum_sign      :  in std_logic;

        start_syn       :  in std_logic;
        start_membr     :  in std_logic;
        stop_syn        :  in std_logic;
        stop_membr      :  in std_logic;
        reset_in        :  in std_logic;
        membr_enable    :  in std_logic;

        reset_out       : out std_logic
        );
    end component;

    -- internal signals
    signal membr_enable_s   : std_logic;
    signal weight_in        : std_logic_vector(WEIGHT_WIDTH-1 downto 0);
    
    signal accum_in         : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal accum_out        : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal accum_reset      : std_logic;
    signal sum              : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);    
    signal thr_exceeded     : std_logic;
    signal output_s         : std_logic;    
    
    signal reg_bank_s       : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal ASP_enable_s     : std_logic;    
    signal prev_sign        : std_logic;
    
    signal carry_s          : std_logic;
    signal add_1_s          : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal add_2_s          : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

begin
    -- value selection block
    value_selection_instance: value_selection
    generic map(
        N                  => N,
        NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
        MEMBRANE_WIDTH     => MEMBRANE_WIDTH,
        WEIGHT_WIDTH       => WEIGHT_WIDTH,
        DOS_SHIFT1         => DOS_SHIFT1,
        DOS_SHIFT2         => DOS_SHIFT2
    )
    port map(
        ctr            => ctr,
        start_syn      => start_syn,
        start_membr    => start_membr,
        stop_membr     => stop_membr,

        input          => input,
        --input_enable   => '1', --input_enable_s,
        reg_bank       => reg_bank_s,
        accum          => accum_out,
        weight         => weight_in,

        carry          => carry_s,
        add_2          => add_2_s
    );

    -- weight memory (can be just one bit when using fixed weights)
    weight_memory_instance: memory
    generic map(
        ADDRESS_WIDTH => NEURON_STATE_WIDTH,
        DATA_WIDTH    => WEIGHT_WIDTH
    )
    port map(
        clk      => clk,
        we       => we,
        address  => ctr,
        data_in  => weight_ext,
        data_out => weight_in
    );

    -- register bank used in this synapse model
    register_bank_instance: register_bank
    generic map(
        MEMBRANE_WIDTH => MEMBRANE_WIDTH,
        REG_WIDTH      => REG_WIDTH
    )
    port map(
        clk            => clk,
        reset          => reset,
        stop_syn       => stop_syn,
        stop_membr     => stop_membr,
        reg_select     => reg_select,
        adder          => accum_in,
        output         => reg_bank_s
    );

    -- in some shift-implementations, the membrane has to be initialized
    init_instance: init
    generic map(
        MEMBRANE_WIDTH => MEMBRANE_WIDTH
    )
    port map(
        start_syn      => start_syn,
        start_membr    => start_membr,
        accum          => accum_out,
        reg_bank       => reg_bank_s,
        add_1          => add_1_s
    );

    -- absolute refractory selection
    abs_refractory_instance: abs_refractory
    generic map(
        MEMBRANE_WIDTH => MEMBRANE_WIDTH,
        COMPARE_VALUE  => REFR_COMPARE_VALUE
    )
    port map(
        clk            => clk,
        reset          => reset,
        stop_membr     => stop_membr,
        spike_out      => output_s,
        adder          => sum,
        ASP_enable     => ASP_enable_s,
        membr_enable   => membr_enable_s
        );

    reset_accum_instance: reset_accum
    port map(
        reg_sign       => reg_bank_s(MEMBRANE_WIDTH-1),
        accum_sign     => sum(MEMBRANE_WIDTH-1),
        start_syn      => start_syn,
        start_membr    => start_membr,
        stop_syn       => stop_syn,
        stop_membr     => stop_membr,
        reset_in       => reset,
        membr_enable   => membr_enable_s,
        reset_out      => accum_reset
    );

    -------------------------------------------------------
    -- internal processes
    sum          <= add_1_s + add_2_s + carry_s;
    accum_in     <= conv_std_logic_vector(ASP, MEMBRANE_WIDTH) when ASP_enable_s = '1' else sum;
    thr_exceeded <= '1' when conv_integer(sum) > THRESHOLD else '0';
    output       <= output_s;

    process(clk)
    begin
        if rising_edge(clk) then
            if accum_reset = '1' then
                accum_out <= (others => '0');
            else
                accum_out <= accum_in;
            end if;
	    
            if reset = '1' then
                output_s  <= '0';
            elsif stop_membr = '1' then 
                output_s <= thr_exceeded;
            else
                output_s <= output_s;
            end if;
        end if;
    end process;
end impl;


--------------------------------------------------------------------------------

configuration linear of spiking_neuron is
    for impl
        for value_selection_instance: value_selection 
          use entity WORK.value_selection (linear_decay);
        end for;
        for init_instance: init
          use entity WORK.init            (regbank_init_syn);
        end for;
        for abs_refractory_instance: abs_refractory
          use entity WORK.abs_refractory  (one_clk_and_add_compared);
        end for;
        for reset_accum_instance: reset_accum
          use entity WORK.reset_accum  (reset_accum_syn);
        end for;
    end for;
end linear;

--------------------------------------------------------------------------------

configuration sos of spiking_neuron is
    for impl
        for value_selection_instance: value_selection 
          use entity WORK.value_selection (sos_mem_decay);
        end for;
        for init_instance: init
          use entity WORK.init            (zero_init_syn);
        end for;
        for abs_refractory_instance: abs_refractory
          use entity WORK.abs_refractory  (one_clk_and_add_neg);
        end for; 
        for reset_accum_instance: reset_accum
          use entity WORK.reset_accum  (no);
        end for;
    end for;
end sos;

--------------------------------------------------------------------------------

configuration sos_optimized of spiking_neuron is
    for impl
        for value_selection_instance: value_selection 
          use entity WORK.value_selection (sos_mem_decay);
        end for;
        for init_instance: init
          use entity WORK.init            (no_init);
        end for;
        for abs_refractory_instance: abs_refractory
          use entity WORK.abs_refractory  (one_clk_and_add_neg);
        end for; 
        for reset_accum_instance: reset_accum
          use entity WORK.reset_accum  (reset_accum_stop_membr);
        end for;
    end for;
end sos_optimized;

--------------------------------------------------------------------------------

configuration dos_reg_bank of spiking_neuron is
    for impl
        for value_selection_instance: value_selection 
          use entity WORK.value_selection (dos_hard_decay);
        end for;
        for init_instance: init
          use entity WORK.init            (regbank_init_syn);
        end for;
        for abs_refractory_instance: abs_refractory
          use entity WORK.abs_refractory  (one_clk_and_add_compared);
        end for;
        for reset_accum_instance: reset_accum
          use entity WORK.reset_accum  (reset_accum_syn_membr);
        end for;
    end for;
end dos_reg_bank;

