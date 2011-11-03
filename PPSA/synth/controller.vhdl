----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- This module generates the control signals and can completely be configured via the
-- generics. The integrate signals triggers shifting-out of the synapse values and the 
-- integrate phase in the membrane and synapse_models. The decay signal starts the decay
-- phase in the membrane and synapse_models. State_end is one at the last clock cycle of
-- each state. The tap signals select one of the various tap values for decay (same 
-- number in membrane and synapse_model) and extend becomes high when sign extend needs
-- to be enabled (depends on exact tap value).
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.numeric_std.all;  
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
library work;
use work.utility_package.all;
--use work.settings_package.all;

entity controller is
generic (
    NR_TAPS_BITS        : integer;
    NR_SYN_MODELS       : integer;
    PIPELINE_DEPTH      : integer; -- PIPELINE_DEPTH(NR_SYN_MODELS, PROJECTION(SYNAPSE_MAP,0), NR_SYN_TAPS);
    COUNTER_SIZE        : integer; -- MAXIMUM(WORD_LENGTH_BITS, LOG2CEIL(PIPELINE_DEPTH - NR_TAPS * WORD_LENGTH)) + 1;
    WORD_LENGTH         : integer;
    NR_SYN_TAPS         : integer_array;
    NR_TAPS             : integer;
    SYN_TAP_ARRAY       : integer_matrix;
    TAP_ARRAY           : integer_array
);
port (
    clk         :  in std_logic;
    reset       :  in std_logic;
    reset_out   : out std_logic;

    integrate   : out std_logic := '0';
    decay       : out std_logic := '0';
    state_end   : out std_logic := '0';
    tap         : out std_logic_vector(NR_TAPS_BITS-1 downto 0);
    extend      : out std_logic_vector(NR_SYN_MODELS downto 0) := (others => '0');

    cycle_end   : out std_logic := '0'
);
end controller;

architecture structure of controller is 
--    constant PIPELINE_DEPTH : integer := PIPELINE_DEPTH(NR_SYN_MODELS, PROJECTION(SYNAPSE_MAP,0), NR_SYN_TAPS);
--    constant COUNTER_SIZE : integer := MAXIMUM(WORD_LENGTH_BITS, LOG2CEIL(PIPELINE_DEPTH - NR_TAPS * WORD_LENGTH)) + 1;    -- +1 for sign
    
    signal counter      : std_logic_vector(COUNTER_SIZE-1 downto 0) := conv_std_logic_vector(WORD_LENGTH-2, COUNTER_SIZE);
    signal tap_counter  : std_logic_vector(NR_TAPS_BITS-1 downto 0) := conv_std_logic_vector(NR_TAPS-1, NR_TAPS_BITS);

    signal s_integrate  : std_logic := '1';
    signal s_decay      : std_logic := '0';
    signal s_state_end  : std_logic := '0';
begin
    process(clk, reset)
        variable state : std_logic_vector(1 downto 0);
    begin
--        if reset = '1' then
--            -- start in integrate state because one idle state is added by delay block below
--            s_integrate <= '1';
--            s_decay <= '0';
--            s_state_end <= '0';
--            extend <= (others => '0');
--            cycle_end <= '0';
--
--            counter <= conv_std_logic_vector(WORD_LENGTH-2, COUNTER_SIZE);
--            tap_counter <= conv_std_logic_vector(NR_TAPS-1, NR_TAPS_BITS);
--        els
        if rising_edge(clk) then
            -- delay all but tap and extend because these need to be one cycle in advance
            -- also introduces idle state after reset
            integrate <= s_integrate;
            decay <= s_decay;
            state_end <= s_state_end;
            
            -- defaults
            cycle_end <= '0';
            reset_out <= '0';
            
            -- state_end counter
            counter <= counter - 1;
            if counter = conv_std_logic_vector(0, COUNTER_SIZE) then
                s_state_end <= '1';
            else
                s_state_end <= '0';
            end if;
            
            state := s_integrate & s_decay;
            case state is
                when "00" =>    -- IDLE
                    if reset = '1' then
                        -- start in integrate state because one idle state is added by delay block below
                        s_integrate <= '1';
                        s_decay <= '0';
                        s_state_end <= '0';
                        extend <= (others => '0');
                        cycle_end <= '0';
                        integrate <= '0';
                        decay <= '0';
                        state_end <= '0';

                        counter <= conv_std_logic_vector(WORD_LENGTH-2, COUNTER_SIZE);
                        tap_counter <= conv_std_logic_vector(NR_TAPS-1, NR_TAPS_BITS);

                        reset_out <= '1';
                    else
                        if counter < 0 then
                            s_integrate <= '1';
                            s_decay <= '0';
                            counter <= conv_std_logic_vector(WORD_LENGTH-2, COUNTER_SIZE);
                        end if;
                        extend <= (others => '0');
                    end if;

                when "10" =>    -- INTEGRATE
                    if counter < 0 then
                        s_integrate <= '0';
                        s_decay <= '1';
                        counter <= conv_std_logic_vector(WORD_LENGTH-2, COUNTER_SIZE);
                        tap_counter <= conv_std_logic_vector(NR_TAPS-1, NR_TAPS_BITS);
                    end if;
                    extend <= (others => '0');
                    
                --when "01" =>    -- DECAY
                when others =>
                    if counter < 0 then
                        tap_counter <= tap_counter - 1;
                        if tap_counter = 0 then
                            if PIPELINE_DEPTH > NR_TAPS * WORD_LENGTH then
                                -- long pipeline, short decay => introduce IDLE states
                                s_decay <= '0';
                                s_integrate <= '0';
                                extend <= (others => '0');
                                cycle_end <= '1';
                                counter <= conv_std_logic_vector(PIPELINE_DEPTH - NR_TAPS * WORD_LENGTH-1, COUNTER_SIZE);
                                tap_counter <= conv_std_logic_vector(NR_TAPS-1, NR_TAPS_BITS);
                            else
                                -- short pipeline, long decay => go staight to INTEGRATE
                                -- introduce at least one IDLE state to set carry to zero !
                                s_decay <= '0';
                                s_integrate <= '0';
                                cycle_end <= '1';
                                extend <= (others => '0');
                                counter <= conv_std_logic_vector(0, COUNTER_SIZE);
                                tap_counter <= conv_std_logic_vector(NR_TAPS-1, NR_TAPS_BITS);
                            end if;
                        else
                            -- go back to DECAY
                            counter <= conv_std_logic_vector(WORD_LENGTH-2, COUNTER_SIZE);
                            extend <= (others => '0');
                        end if;
                    end if;

                    -- extend for membrane taps
                    if counter = conv_std_logic_vector(TAP_ARRAY(NR_TAPS-1-conv_integer('0' & tap_counter)), COUNTER_SIZE) then
                        extend(0) <= '1';
                    end if;
                    -- extend for synapse_model taps
                    for i in NR_SYN_MODELS downto 1 loop
                        if NR_SYN_TAPS(i-1) /= 0 then
                            if counter = conv_std_logic_vector(SYN_TAP_ARRAY(i-1, NR_SYN_TAPS(i-1)-1-conv_integer('0' & tap_counter)), COUNTER_SIZE) then
                                extend(i) <= '1';
                            end if;
                        else
                            extend(i) <= '0';
                        end if;
                    end loop;
            end case;
        end if;
    end process;

    tap <= tap_counter;
end structure;
