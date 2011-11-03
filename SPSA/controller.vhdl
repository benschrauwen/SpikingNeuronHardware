----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- This module implements the controller, which is a large state machine, 
-- generating the signals necessary to control the neuron arithmetic
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
library work;
use work.utility_package.all;

entity controller is
generic(
    NR_BITS          : integer := 10;
    NR_NEURONS       : integer := 20;
    NR_SYNAPSES      : integer_array := (2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2);        -- = NR_SYN_CONSTS + 1 (membr) for each neuron
    NR_WEIGHTS       : integer_matrix := ((12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0),(12,0));       -- S1, S2, M -> number of inputs
    REFRACTORINESS   : boolean := TRUE;              -- true if all neurons have refractory
    REFRACTORY_WIDTH : integer := 10;              -- number of refractory bits
    DECAY_SHIFT      : integer_matrix := ((0,1),(0,2),(1,2),(0,1),(0,2),(1,2),(0,1),(0,2),(1,2),(0,1),(0,1),(0,2),(1,2),(0,1),(0,2),(1,2),(0,1),(0,2),(1,2),(0,1))        -- 0 = lin decay
);
port(
    clk              :  in std_logic;
    reset            :  in std_logic;
    start            :  in std_logic;
    neuron_number    :  in std_logic_vector(LOG2CEIL(NR_NEURONS)-1 downto 0);
    ready            : out std_logic;

    address_read_1   : out std_logic_vector(LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH))-1 downto 0);
    address_read_2   : out std_logic_vector(LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH))-1 downto 0);
    address_write    : out std_logic_vector(LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH))-1 downto 0);
    smm_we           : out std_logic;

    wm_ai            : out std_logic; -- both ce and shift signal
    sim_ai           : out std_logic; -- both ce and shift signal
    som_we           : out std_logic; -- both ce and shift signal
    force_one        : out std_logic;
    sel              : out std_logic;

    fz_ce            : out std_logic;
    reset_fz         : out std_logic;

    neg_ce           : out std_logic;
    set_neg          : out std_logic;
    reset_neg        : out std_logic;

    carry_ce         : out std_logic;
    reset_carry      : out std_logic;
    sum_out          : out std_logic;
    bypass           : out std_logic
);
end controller;

architecture structure of controller is
    type neuron_state_space is (ready_state, weight_add, test_neg_refr, decrease_refr, cond_weight_add, cond_synapse_add, test_fire, cond_reset, cond_load_refr, lin_decay_1, exp_decay_1, lin_decay_2, exp_decay_2);
    signal r_neuron_state     : neuron_state_space := ready_state;
    signal r_synapse_counter  : std_logic_vector(LOG2CEIL(MAXIMUM(NR_SYNAPSES))-1 downto 0);
    signal r_weight_counter   : std_logic_vector(LOG2CEIL(MAXIMUM(NR_WEIGHTS))-1 downto 0);
    signal r_bit_counter      : std_logic_vector(LOG2CEIL(NR_BITS)-1 downto 0);
    signal neuron_base        : std_logic_vector(LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH))-1 downto 0);
    signal neuron_base_offset : std_logic_vector(LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH))-1 downto 0);
    signal base_address_1     : std_logic_vector(LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH))-1 downto 0);
    signal base_address_2     : std_logic_vector(LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH))-1 downto 0);
    signal s_address_read_1   : std_logic_vector(LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH))-1 downto 0);    
    signal s_smm_we           : std_logic;
    signal s_wm_ai            : std_logic;
    signal s_force_one        : std_logic;
    signal s_bypass           : std_logic;
    signal first_bit          : std_logic;
    signal s_extra_fz, extra_fz : std_logic;

begin
    -- state machine
    process(reset, clk)
    begin
        if reset = '1' then
            r_neuron_state   <= ready_state;
            ready            <= '0';
            s_extra_fz       <= '0';
        elsif rising_edge(clk) then
            s_extra_fz       <= '0';
            case r_neuron_state is
                when ready_state =>
                    if start = '1' then
                        if neuron_number /= conv_std_logic_vector(0, LOG2CEIL(NR_NEURONS)) then
                            neuron_base <= neuron_base + neuron_base_offset;
                        else
                            neuron_base <= (others => '0');
                        end if;
                        neuron_base_offset <= conv_std_logic_vector(SYN_OFFSET(REFRACTORINESS,REFRACTORY_WIDTH),LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH)));


                        if NR_SYNAPSES(conv_integer(neuron_number)) = 1 then -- only membrane adds
                            base_address_1 <= (others => '0');
                            if refractoriness = TRUE then
                                r_neuron_state <= test_neg_refr;
                            else
                                r_neuron_state <= cond_weight_add;
                            end if;
                        else
                            base_address_1 <= conv_std_logic_vector(SYN_OFFSET(REFRACTORINESS,REFRACTORY_WIDTH),LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH)));
                            r_neuron_state <= weight_add;
                        end if;

                        ready <= '0';
                    else
                        ready <= '1';
                    end if;

                    r_synapse_counter <= (others => '0');
                    r_weight_counter  <= (others => '0');
                    r_bit_counter     <= (others => '0');
                    base_address_2    <= conv_std_logic_vector(SYN_OFFSET(REFRACTORINESS,REFRACTORY_WIDTH),LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH)));

                --------------------------------------------------------------------------------
                when weight_add =>
                    neuron_base_offset <= base_address_1;

                    if r_bit_counter /= conv_std_logic_vector(NR_BITS-1, LOG2CEIL(NR_BITS)) then
                        r_bit_counter <= r_bit_counter + 1;
                    else
                        r_bit_counter <= (others => '0');

                        if r_weight_counter /= conv_std_logic_vector(NR_WEIGHTS(conv_integer(neuron_number), conv_integer(r_synapse_counter))-1, LOG2CEIL(MAXIMUM(NR_WEIGHTS))) then
                            r_weight_counter <= r_weight_counter + 1;
                        else
                            r_weight_counter <= (others => '0');

                            if r_synapse_counter /= conv_std_logic_vector(NR_SYNAPSES(conv_integer(neuron_number))-2, LOG2CEIL(MAXIMUM(NR_SYNAPSES))) then
                                r_synapse_counter <= r_synapse_counter + 1;
                                base_address_1    <= base_address_1 + NR_BITS;
                            else
                                r_synapse_counter <= (others => '0');

                                if refractoriness = TRUE then
                                    base_address_1 <= conv_std_logic_vector(REFRACTORY_WIDTH-1,LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH)));
                                    r_neuron_state <= test_neg_refr;
                                else
                                    base_address_1    <= base_address_1 + NR_BITS;
                                    if NR_WEIGHTS(conv_integer(neuron_number), NR_SYNAPSES(conv_integer(neuron_number))-1) = 0 then
                                        r_neuron_state <= cond_synapse_add;
                                    else
                                        r_neuron_state <= cond_weight_add;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;

                --------------------------------------------------------------------------------
                when test_neg_refr =>
                    r_neuron_state <= decrease_refr;
                    base_address_1 <= (others => '0');

                when decrease_refr =>
                    if r_bit_counter /= conv_std_logic_vector(REFRACTORY_WIDTH-1, LOG2CEIL(NR_BITS)) then
                        r_bit_counter  <= r_bit_counter + 1;
                    else
                        r_bit_counter  <= (others => '0');
                        base_address_1 <= neuron_base_offset + REFRACTORY_WIDTH;

                        if NR_WEIGHTS(conv_integer(neuron_number), NR_SYNAPSES(conv_integer(neuron_number))-1) = 0 then
                            r_neuron_state <= cond_synapse_add;
                        else
                            r_neuron_state <= cond_weight_add;
                        end if;
                        s_extra_fz <= '1';
                    end if;

                --------------------------------------------------------------------------------
                when cond_weight_add => -- membrane weights
                    if r_bit_counter /= conv_std_logic_vector(NR_BITS-1, LOG2CEIL(NR_BITS)) then
                        r_bit_counter <= r_bit_counter + 1;
                    else
                        r_bit_counter <= (others => '0');

                        if r_weight_counter /= conv_std_logic_vector(NR_WEIGHTS(conv_integer(neuron_number), NR_SYNAPSES(conv_integer(neuron_number))-1)-1, LOG2CEIL(MAXIMUM(NR_WEIGHTS))) then
                            r_weight_counter  <= r_weight_counter + 1;
                        else 
                            r_weight_counter  <= (others => '0');

                            if NR_SYNAPSES(conv_integer(neuron_number)) = 1 then -- only membrane
                                base_address_1 <= base_address_1 + NR_BITS;
                                base_address_2 <= base_address_1;
                                r_neuron_state <= test_fire;
                            else
                                r_neuron_state <= cond_synapse_add;
                            end if;

                        end if;

                    end if;

                --------------------------------------------------------------------------------    
                when cond_synapse_add =>
                    if r_bit_counter /= conv_std_logic_vector(NR_BITS-1, LOG2CEIL(NR_BITS)) then
                        r_bit_counter <= r_bit_counter + 1;
                    else
                        r_bit_counter  <= (others => '0');
                        base_address_2 <= base_address_2 + NR_BITS;

                        if r_synapse_counter /= conv_std_logic_vector(NR_SYNAPSES(conv_integer(neuron_number))-2, LOG2CEIL(MAXIMUM(NR_SYNAPSES))) then
                            r_synapse_counter <= r_synapse_counter + 1;
                        else
                            r_synapse_counter <= (others => '0');
                            base_address_1    <= base_address_1 + NR_BITS;
                            base_address_2    <= base_address_1;
                            r_neuron_state    <= test_fire;
                        end if;
                    end if;

                --------------------------------------------------------------------------------    
                when test_fire =>
                    if r_bit_counter /= conv_std_logic_vector(NR_BITS-1, LOG2CEIL(NR_BITS)) then
                        r_bit_counter <= r_bit_counter + 1;
                    else
                        r_bit_counter  <= (others => '0');
                        base_address_1 <= base_address_2; -- base_address_2 contains the membrane address
                        base_address_2 <= base_address_2 + 2*conv_integer(NR_BITS);
                        r_neuron_state <= cond_reset;
                    end if;

                --------------------------------------------------------------------------------    
                when cond_reset =>
                    if r_bit_counter /= conv_std_logic_vector(NR_BITS-1, LOG2CEIL(NR_BITS)) then
                        r_bit_counter <= r_bit_counter + 1;
                    else
                        r_synapse_counter  <= (others => '0');
                        base_address_1     <= (others => '0');
                        base_address_2     <= base_address_2 + NR_BITS;
                        neuron_base_offset <= base_address_2 + NR_BITS;

                        if refractoriness = TRUE then
                            r_bit_counter  <= (others => '0');
                            r_neuron_state <= cond_load_refr;
                        else
                            if DECAY_SHIFT(conv_integer(neuron_number),0) /= 0 then
                                r_bit_counter  <= (others => '0');
                                r_neuron_state <= exp_decay_1;
                            else
                                -- loading carry, thus r_bit_counter remains the same
                                r_neuron_state <= lin_decay_1;
                            end if;
                        end if;
                    end if;

                --------------------------------------------------------------------------------    
                when cond_load_refr =>
                    if r_bit_counter /= conv_std_logic_vector(REFRACTORY_WIDTH-1, LOG2CEIL(NR_BITS)) then
                        r_bit_counter <= r_bit_counter + 1;
                    else
                        r_synapse_counter  <= (others => '0');

                        base_address_1     <= base_address_1 + REFRACTORY_WIDTH;
                        neuron_base_offset <= base_address_2 + REFRACTORY_WIDTH;

                        if DECAY_SHIFT(conv_integer(neuron_number),0) /= 0 then
                            r_bit_counter  <= (others => '0');
                            r_neuron_state <= exp_decay_1;
                        else
                            r_bit_counter  <= conv_std_logic_vector(NR_BITS-1, LOG2CEIL(NR_BITS));
                            r_neuron_state <= lin_decay_1;
                        end if;
                    end if;

                --------------------------------------------------------------------------------    
                when lin_decay_1 =>
                    r_bit_counter      <= (others => '0');
                    r_neuron_state     <= lin_decay_2;
                    base_address_2     <= neuron_base_offset;		    

                when lin_decay_2 =>
                    if r_bit_counter /= conv_std_logic_vector(NR_BITS-1, LOG2CEIL(NR_BITS)) then
                        r_bit_counter <= r_bit_counter + 1;
                    else
                        r_bit_counter <= (others => '0');

                        if r_synapse_counter /= conv_std_logic_vector(NR_SYNAPSES(conv_integer(neuron_number))-1, LOG2CEIL(MAXIMUM(NR_SYNAPSES))) then
                            r_synapse_counter  <= r_synapse_counter + 1;
                            base_address_1     <= base_address_1 + NR_BITS;
                            base_address_2     <= base_address_2 + NR_BITS;
--                            neuron_base_offset <= base_address_2 + NR_BITS;

                            if DECAY_SHIFT(conv_integer(neuron_number),conv_integer(r_synapse_counter)+1) /= 0 then
                                r_bit_counter  <= (others => '0');
                                r_neuron_state <= exp_decay_1;
                            else
                                -- loading carry, thus r_bit_counter remains the same
                                -- r_bit_counter  <= conv_std_logic_vector(NR_BITS-1, LOG2CEIL(NR_BITS));
                                r_neuron_state <= lin_decay_1;
                            end if;
                        else
                            r_neuron_state     <= ready_state;
                            ready <= '1';
                        end if;
			neuron_base_offset <= base_address_2 + NR_BITS;
                    end if;

                --------------------------------------------------------------------------------    
                when exp_decay_1 =>
                    if r_bit_counter /= conv_std_logic_vector(NR_BITS-1, LOG2CEIL(NR_BITS)) then
                        r_bit_counter  <= r_bit_counter + 1;
                    else
                        r_bit_counter  <= (others => '0');
                        base_address_2 <= base_address_1 + DECAY_SHIFT(conv_integer("0"&neuron_number),conv_integer("0"&r_synapse_counter));
                        r_neuron_state <= exp_decay_2;
                    end if;

                when exp_decay_2 =>
                    if r_bit_counter /= conv_std_logic_vector(NR_BITS-1, LOG2CEIL(NR_BITS)) then
                        r_bit_counter  <= r_bit_counter + 1;
                        if r_bit_counter >= NR_BITS-DECAY_SHIFT(conv_integer(neuron_number),conv_integer(r_synapse_counter))-1 then
                            -- this implements a saturating counter
                            base_address_2 <= base_address_2 - 1;
                        end if;
                    else
                        if r_synapse_counter /= conv_std_logic_vector(NR_SYNAPSES(conv_integer(neuron_number))-1, LOG2CEIL(MAXIMUM(NR_SYNAPSES))) then
                            r_synapse_counter  <= r_synapse_counter + 1;
                            base_address_1     <= base_address_1 + NR_BITS;

                            if DECAY_SHIFT(conv_integer(neuron_number),conv_integer(r_synapse_counter)+1) /= 0 then
                                r_neuron_state <= exp_decay_1;
                                r_bit_counter  <= (others => '0');				
                            else
                                -- loading carry, thus r_bit_counter remains the same
                                r_neuron_state <= lin_decay_1;
                            end if;
                        else
                            r_neuron_state     <= ready_state;
                            r_bit_counter      <= (others => '0');			    
                            ready <= '1';
                        end if;
                    end if;

                --------------------------------------------------------------------------------    
                when others =>
                    assert false report "Unknown state!" severity error;
            end case;
        end if;
    end process;

    -- helper signal
    first_bit        <= '1' when r_bit_counter = conv_std_logic_vector(0, LOG2CEIL(NR_BITS)) else '0';

    -- control signals
    s_address_read_1 <= neuron_base + base_address_1 + r_bit_counter;
    address_read_1   <= s_address_read_1;
    address_read_2   <= neuron_base + base_address_2 + r_bit_counter;

    s_wm_ai          <= '1' when r_neuron_state = weight_add or r_neuron_state = cond_weight_add else '0';
    wm_ai            <= s_wm_ai;
    sim_ai           <= s_wm_ai and first_bit;
    som_we           <= '1' when r_neuron_state = cond_reset and first_bit = '1' else '0';
    s_force_one      <= '1' when r_neuron_state = test_neg_refr or r_neuron_state = decrease_refr or r_neuron_state = lin_decay_1 or r_neuron_state = exp_decay_1 else '0';
    s_smm_we         <= '0' when r_neuron_state = ready_state or r_neuron_state = test_neg_refr or r_neuron_state = test_fire or r_neuron_state = lin_decay_1 or r_neuron_state = exp_decay_1 else '1';

    fz_ce            <= '1' when (first_bit = '1' and r_neuron_state = decrease_refr) or extra_fz = '1' else '0';
    reset_fz         <= '1' when r_neuron_state = ready_state or r_neuron_state = test_fire else '0';

    neg_ce           <= '1' when first_bit = '1' and r_neuron_state = lin_decay_2 else '0';    
    set_neg          <= '1' when r_neuron_state = test_fire or r_neuron_state = exp_decay_2 else '0';    
    reset_neg        <= '1' when r_neuron_state = ready_state or r_neuron_state = cond_reset or r_neuron_state = lin_decay_1 or r_neuron_state = exp_decay_1 else '0';

    reset_carry      <= '1' when r_neuron_state = ready_state or r_neuron_state = test_neg_refr or r_neuron_state = lin_decay_1 or (first_bit = '1' and not (r_neuron_state = cond_reset or r_neuron_state = cond_load_refr or r_neuron_state = lin_decay_2 or r_neuron_state = exp_decay_2)) else '0';

    sum_out          <= '1' when first_bit = '1' and (r_neuron_state = exp_decay_2 or r_neuron_state = cond_reset) else '0';
    s_bypass         <= '1' when r_neuron_state = cond_reset or r_neuron_state = cond_load_refr else '0';

    extra_fz         <= s_extra_fz;

    -- because all memory is synchronous, data is available one clock period after the address-generation
    -- therefore, some signals must be delayed with one clock period
    process(clk)
    begin
        if (clk'event and clk = '1') then
            address_write <= s_address_read_1;
            smm_we        <= s_smm_we;
            force_one     <= s_force_one;
            sel           <= not s_wm_ai;
            bypass        <= s_bypass;
            carry_ce      <= not s_bypass;
--	    extra_fz      <= s_extra_fz;
        end if;
    end process;

end structure;
