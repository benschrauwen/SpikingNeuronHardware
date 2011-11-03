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
    MEMBRANE_RESET     : integer;
    
    -- value selection constants
    WEIGHT_WIDTH       : integer;
    DOS_SHIFT          : integer;
    FIXED_WEIGHT       : integer;
    FIXED_DECAY        : integer;
    
    -- absolute refractory constants
    REFR_COMPARE_VALUE : integer;
    REFR_COUNTER_WIDTH : integer;
    REFR_COUNTER_VALUE : integer
    );
    
port(
    clk            :  in std_logic;
    start          :  in std_logic; -- high 1 clockcycle at start new cycle
    stop           :  in std_logic;    -- high 1 clockcycle at end of a cycle
    reset          :  in std_logic;
    
    ctr            :  in std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);    

    we             :  in std_logic;
    weight         :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);

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
        DOS_SHIFT          : integer;
        FIXED_WEIGHT       : integer;
        FIXED_DECAY        : integer
    );
    port(
        start          :  in std_logic;
        ctr            :  in std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);    

        input          :  in std_logic_vector(N-1 downto 0);
        input_enable   :  in std_logic;
        membr_pot_buff :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        accum          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        weight         :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);

        carry          : out std_logic;
        add_2          : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
        );
    end component;

    -- weight memory (can be just one bit when using fixed weights)
    component memory
    generic(
        ADDRESS_WIDTH : integer;
        DATA_WIDTH    : integer
    );
    port(
        clk      :  in std_logic;
        we       :  in std_logic;
        address  :  in std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);
        data_in  :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);
        data_out : out std_logic_vector(WEIGHT_WIDTH-1 downto 0)
        );
    end component;
   

    -- this block buffers the membrane potential if needed
    component membrane_buffer
    generic(
        MEMBRANE_WIDTH : integer;
        MEMBRANE_RESET : integer
    );
    port(
        reset          :  in std_logic;
        clk            :  in std_logic;
        stop           :  in std_logic;
        accum          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        membr_pot_buff : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
    );
    end component;

    -- in some shift-implementations, the membrane has to be initialized
    component init
    generic(
        MEMBRANE_WIDTH : integer
    );
    port(
        start          :  in std_logic;
        accum          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        add_1          : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
        );
    end component;

    -- absolute refractory selection
    component abs_refractory
    generic(
        MEMBRANE_WIDTH : integer;
        COMPARE_VALUE     : integer;
        COUNTER_WIDTH     : integer;
        COUNTER_VALUE     : integer
    );
    port(
        reset          :  in std_logic;
        clk            :  in std_logic;
        start          :  in std_logic;
        stop           :  in std_logic;
        spike_out      :  in std_logic;
        accum          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        membr_pot_buff :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
        ASP_enable     : out std_logic;
        input_enable   : out std_logic
        );
    end component;

    -- internal signals
    signal input_enable_s   : std_logic;
    signal carry_s          : std_logic;
    signal weight_in        : std_logic_vector(WEIGHT_WIDTH-1 downto 0);
    signal accum_out        : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal membr_pot_buff_s : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal add_1_s          : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal add_2_s          : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal ASP_enable_s     : std_logic;

    signal sum              : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal mux_out          : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal accum_in         : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal thr_exceeded     : std_logic;
    signal output_s         : std_logic;


begin
    -- value selection block
    value_selection_instance: value_selection
    generic map(
        N                  => N,
        NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
        MEMBRANE_WIDTH     => MEMBRANE_WIDTH,
        WEIGHT_WIDTH       => WEIGHT_WIDTH,
        DOS_SHIFT          => DOS_SHIFT,
        FIXED_WEIGHT       => FIXED_WEIGHT,
        FIXED_DECAY        => FIXED_DECAY
    )
    port map(
        start          => start,
        ctr            => ctr,

        input          => input,
        input_enable   => input_enable_s,
        membr_pot_buff => membr_pot_buff_s,
        accum          => accum_out,
        weight         => weight_in,

        carry          => carry_s,
        add_2          => add_2_s
    );

    -- weight memory (can be just one bit when using fixed weights)
    memory_instance: memory
    generic map(
        ADDRESS_WIDTH => NEURON_STATE_WIDTH,
        DATA_WIDTH    => WEIGHT_WIDTH
    )
    port map(
        clk      => clk,
        we       => we,
        address  => ctr,
        data_in  => weight,
        data_out => weight_in
        );

    -- this block buffers the membrane potential if needed
    membrane_buffer_instance: membrane_buffer
    generic map(
        MEMBRANE_WIDTH => MEMBRANE_WIDTH,
        MEMBRANE_RESET => MEMBRANE_RESET
    )
    port map(
        reset          => reset,
        clk            => clk,
        stop           => stop,
        accum          => mux_out,
        membr_pot_buff => membr_pot_buff_s
    );

    -- in some shift-implementations, the membrane has to be initialized
    init_instance: init
    generic map(
        MEMBRANE_WIDTH => MEMBRANE_WIDTH
    )
    port map(
        start          => start,
        accum          => accum_out,
        add_1          => add_1_s
    );

    -- absolute refractory selection
    abs_refractory_instance: abs_refractory
    generic map(
        MEMBRANE_WIDTH => MEMBRANE_WIDTH,
        COMPARE_VALUE  => REFR_COMPARE_VALUE,
        COUNTER_WIDTH  => REFR_COUNTER_WIDTH,
        COUNTER_VALUE  => REFR_COUNTER_VALUE        
    )
    port map(
        reset          => reset,
        clk            => clk,
        start          => start,
        stop           => stop,
        spike_out      => output_s,
        accum          => accum_out,
        membr_pot_buff => membr_pot_buff_s,
        ASP_enable     => ASP_enable_s,
        input_enable   => input_enable_s
        );

    -------------------------------------------------------
    -- internal processes
    sum          <= add_1_s + add_2_s + carry_s;
    mux_out      <= conv_std_logic_vector(ASP, MEMBRANE_WIDTH) when ASP_enable_s = '1' else sum;
    accum_in     <= mux_out;    
    thr_exceeded <= '1' when conv_integer(sum) > THRESHOLD else '0';    
    output       <= output_s;

    process(clk, reset)
    begin
        if reset = '1' then
            accum_out <= conv_std_logic_vector(MEMBRANE_RESET, MEMBRANE_WIDTH);
        elsif (clk'event and clk = '1') then
            accum_out <= accum_in;
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '1' then
            output_s <= '0';
        elsif (clk'event and clk = '1') then
            if stop = '1' then 
                output_s <= thr_exceeded; 
            end if;
        end if;
    end process;

end impl;


--------------------------------------------------------------------------------

configuration upegui of spiking_neuron is
    for impl
        for value_selection_instance: value_selection 
          use entity WORK.value_selection (linear_decay);
        end for;
        for membrane_buffer_instance: membrane_buffer
          use entity WORK.membrane_buffer (no_buffer);
        end for;
        for init_instance: init
          use entity WORK.init            (membrane_init);
        end for;
        for abs_refractory_instance: abs_refractory
          use entity WORK.abs_refractory  (one_clk);
        end for;
    end for;
end upegui;

--------------------------------------------------------------------------------

configuration dos_no_refractory of spiking_neuron is
    for impl
        for value_selection_instance: value_selection 
          use entity WORK.value_selection (dos_hard_decay);
        end for;
        for membrane_buffer_instance: membrane_buffer
          use entity WORK.membrane_buffer (no_buffer);
        end for;
        for init_instance: init
          use entity WORK.init            (membrane_init);
        end for;
        for abs_refractory_instance: abs_refractory
          use entity WORK.abs_refractory  (no);
        end for;
    end for;
end dos_no_refractory;

--------------------------------------------------------------------------------

configuration dos_with_refractory of spiking_neuron is
    for impl
        for value_selection_instance: value_selection 
          use entity WORK.value_selection (dos_hard_decay);
        end for;
        for membrane_buffer_instance: membrane_buffer
          use entity WORK.membrane_buffer (with_buffer);
        end for;
        for init_instance: init
          use entity WORK.init            (membrane_init);
        end for;
        for abs_refractory_instance: abs_refractory
          use entity WORK.abs_refractory  (one_clk_and_acc_neg);
        end for;
    end for;
end dos_with_refractory;

--------------------------------------------------------------------------------

configuration dos_with_refractory_2 of spiking_neuron is
    for impl
        for value_selection_instance: value_selection 
          use entity WORK.value_selection (dos_hard_decay);
        end for;
        for membrane_buffer_instance: membrane_buffer
          use entity WORK.membrane_buffer (no_buffer);
        end for;
        for init_instance: init
          use entity WORK.init            (membrane_init);
        end for;
        for abs_refractory_instance: abs_refractory
          use entity WORK.abs_refractory  (one_clk_and_acc_compared);
        end for;
    end for;
end dos_with_refractory_2;

--------------------------------------------------------------------------------

configuration dos_with_refractory_3 of spiking_neuron is
    for impl
        for value_selection_instance: value_selection 
          use entity WORK.value_selection (dos_hard_decay);
        end for;
        for membrane_buffer_instance: membrane_buffer
          use entity WORK.membrane_buffer (no_buffer);
        end for;
        for init_instance: init
          use entity WORK.init            (membrane_init);
        end for;
        for abs_refractory_instance: abs_refractory
          use entity WORK.abs_refractory  (counted);
        end for;
    end for;
end dos_with_refractory_3;

--------------------------------------------------------------------------------

configuration sos_mem of spiking_neuron is
    for impl
        for value_selection_instance: value_selection 
          use entity WORK.value_selection (sos_mem_decay);
        end for;
        for membrane_buffer_instance: membrane_buffer
          use entity WORK.membrane_buffer (with_buffer);
        end for;
        for init_instance: init
          use entity WORK.init            (zero_init);
        end for;
        for abs_refractory_instance: abs_refractory
          use entity WORK.abs_refractory  (one_clk);
        end for;
    end for;
end sos_mem;

--------------------------------------------------------------------------------
