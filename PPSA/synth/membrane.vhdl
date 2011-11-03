----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- The membrane module serially receives the integrated value from the complete 
-- dendritic tree. This is serially added to the membrane r_potential. During the decay
-- phase several taps are subtracted from the membrane r_potential to approximate 
-- exponential decay.
--
-- The generic parameters define the neuron properties: WORD_LENGTH defines the 
-- internally used word size for storing the membrane r_potential; ACTIVE_LENGTH defines 
-- the actively used number of bits, this implements the threshold, and the positive and
-- negative saturation (negative saturation = -threshold = -(2**ACTIVE_LENGTH)); 
-- RESET_VAL is the value to which the neuron resets after firing (RESET_VAL <= 
-- -(2**ACTIVE_LENGTH)); REFR_LENGTH is used to implement r_refractory, as long as the 
-- membrane r_potential < -(2**REFR_LENGTH), the dendritic signal is not added to the
-- membrane r_potential during integration; rest r_potential is 0.
--
-- The NR_TAPS and TAP_ARRAY define the time constant of the exponential decay:
--
--
-- NOTE: When using multiple taps, the sum of the taps must be larger or
-- equal to ACTIVE_LENGTH to ensure good decay-saturation (this is due to
-- specific decay implementation)
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;
library work;
use work.utility_package.all;
use work.settings_package.all;

entity membrane is 
port ( 
    clk         :  in std_logic;
    reset       :  in std_logic;
    
    integrate   :  in std_logic;
    decay       :  in std_logic;
    state_end   :  in std_logic;
    tap         :  in std_logic_vector (NR_TAPS_BITS-1 downto 0);        -- position in TAP_ARRAY
    extend      :  in std_logic;
    
    input       :  in std_logic;                        -- bitserial input (LSB first,  2's-complement)
    
    output      : out std_logic                         -- is high during a complete calculation cycl
);
end membrane;

architecture multi_add_mux of membrane is 
    signal r_potential : std_logic_vector(WORD_LENGTH-1 downto 0) := (others => '0');                -- internal representation of r_potential
    signal r_potential_stored : std_logic_vector(WORD_LENGTH-1 downto 0);         -- just for simulation purposes, is the r_potential sampled at correct time
    signal r_carry     : std_logic := '0';                                               -- r_carry bit of serial adder
    signal r_neg_shift : std_logic := '1';
    signal r_fire      : std_logic := '0';
    signal r_refract   : std_logic := '0';

    signal s_add     : std_logic;
    signal s_sum     : std_logic;
    signal s_r_carry   : std_logic;
    signal s_tapped  : std_logic;
    signal s_refr_input : std_logic;
begin
    assert NR_TAPS=1 or ACTIVE_LENGTH <= sum(TAP_ARRAY)
    report "When using multiple taps, the sum of the taps must be larger or equal to ACTIVE_LENGTH to ensure good decay-saturation";

    -- neem 1 tap verder omdat extra delay door r_neg_shift register
    s1: if NR_TAPS = 1 generate
        s_tapped <= r_potential(TAP_ARRAY(0)+1);
    end generate;
    s2: if NR_TAPS > 1 generate
        s_tapped <= r_potential(TAP_ARRAY(CONV_INTEGER(tap))+1);
    end generate;
    
    -- implement refractory
    s_refr_input <= input when REFR_LENGTH = WORD_LENGTH or (r_refract = '0' and r_fire = '0') else '0';
   
    -- bereken nieuwe bit in MSB-positie: als extend=1, dan zijn we met 
    -- sign extend bezig, anders met een echte bit uit de potentiaal
    s_add <= s_refr_input when integrate = '1' else r_neg_shift;
    serial_adder: entity work.full_adder port map (r_potential(0), s_add, r_carry, s_sum, s_r_carry);
    
    process(clk, reset)
        variable temp_pot : std_logic_vector(WORD_LENGTH downto 0);
        variable new_pot  : std_logic_vector(WORD_LENGTH-ACTIVE_LENGTH-1 downto 0);
        variable cross    : std_logic;
    begin
        if reset = '1' then 
            r_potential <= conv_std_logic_vector(0, WORD_LENGTH);
            r_fire <= '0';
            r_neg_shift <= '1';
            r_refract <= '0';
        elsif rising_edge(clk) then
            temp_pot := s_sum & r_potential;
            new_pot := temp_pot(WORD_LENGTH downto ACTIVE_LENGTH+1);
            cross := JOIN_OR(new_pot) and not JOIN_AND(new_pot);

            if (integrate = '1' or decay = '1') then
                if state_end = '0' or cross = '0' then
                    -- deze implementatie is zeer compact, maar gaat ook resetten tijdens decay, maar kan normaal geen kwaad !!
                    r_potential(WORD_LENGTH-1 downto 0) <= s_sum & r_potential(WORD_LENGTH-1 downto 1);
                else
                    r_potential <= conv_std_logic_vector(RESET_VAL, WORD_LENGTH);
                end if;
            end if;
           
            if integrate = '1' and state_end = '1' then
                r_fire <= not(s_sum) and JOIN_OR(r_potential(WORD_LENGTH-1 downto ACTIVE_LENGTH+1));
                if REFR_LENGTH /= WORD_LENGTH then
                    r_refract <= not(not s_sum or (s_sum and JOIN_AND(r_potential(WORD_LENGTH-1 downto REFR_LENGTH+1))));
                else
                    r_refract <= '0';
                end if;
            end if;

            -- dit enkel na integrate normaal, maar tijdens decay kan geen kwaad
            -- blijf geselecteerde tap saven tot dat extend één wordt, dan onthouden
            if extend = '0' then
                r_neg_shift <= not s_tapped;
            end if;
        end if;
    end process;

    -- r_carry met synchrone reset ! sneller
    process(clk)
    begin
        if rising_edge(clk) then
            if integrate = '0' and decay = '0'  then        
                r_carry <= '0';
            else
                if state_end = '0' then
                    r_carry <= s_r_carry;
                else
                    --r_carry <= '1'; 
                    r_carry <= s_sum or JOIN_AND(not r_potential(MINIMUM(TAP_ARRAY) downto 1));         -- correctie van DOS zodat decay naar 0 als positief
                end if;
            end if;
        end if;
    end process;
    
    -- enkel voor observatie
    process(decay)
    begin
        if rising_edge(decay) then
            r_potential_stored <= r_potential;
        end if;
    end process;
    
    output <= r_fire;
end multi_add_mux;
