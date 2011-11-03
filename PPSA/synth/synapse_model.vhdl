----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- A synapse_model is like a membrane, but without the threshold and reset logic. Look
-- at membrane for comment. Serially outputs the sum of the synapse potential with the
-- integrated input from the dendritic tree.
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;
library work;
use work.utility_package.all;

entity synapse_model is 
generic (
    TAP_BITS    : integer; --NR_SYN_TAPS_BITS(SYN_NR)
    TAP_ARRAY   : integer_array; --PROJECTION(SYN_TAP_ARRAY,SYN_NR)
    NR_TAPS     : integer; --NR_SYN_TAPS(SYN_NR)
    WORD_LENGTH : integer
);
port ( 
    clk         :  in std_logic;
    reset       :  in std_logic;
    
    integrate   :  in std_logic;
    decay       :  in std_logic;
    state_end   :  in std_logic;
    tap         :  in std_logic_vector (TAP_BITS-1 downto 0);
    extend      :  in std_logic;
    
    input       :  in std_logic;
    
    output      : out std_logic
);
end synapse_model;

architecture structure of synapse_model is
    signal r_potential : std_logic_vector(WORD_LENGTH-1 downto 0) := (others => '0');
    signal r_carry     : std_logic := '0';
    signal r_neg_shift : std_logic := '1';
    signal r_sat       : std_logic := '0';

    signal s_add     : std_logic;
    signal s_sum     : std_logic;
    signal s_r_carry   : std_logic;
    signal s_tapped  : std_logic;
begin
    s1: if NR_TAPS = 1 generate
        s_tapped <= r_potential(TAP_ARRAY(0)+1);
    end generate;
    s2: if NR_TAPS > 1 generate
        s_tapped <= r_potential(TAP_ARRAY(CONV_INTEGER(tap))+1);
    end generate;
    
    s_add <= input when integrate = '1' else r_neg_shift;
    serial_adder: entity work.full_adder port map (r_potential(0), s_add, r_carry, s_sum, s_r_carry);
    
    process(clk, reset)
    begin
        if reset = '1' then 
            r_potential <= conv_std_logic_vector(0, WORD_LENGTH);
            r_neg_shift <= '1';
        elsif rising_edge(clk) then
            -- this is only crappy implementation of satutation, but it will do
            if ((integrate = '1' and not r_sat = '1' ) or decay = '1') then
                r_potential(WORD_LENGTH-1 downto 0) <= s_sum & r_potential(WORD_LENGTH-1 downto 1);
            end if;
           
            if extend = '0' then
                r_neg_shift <= not s_tapped;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if integrate = '0' and decay = '0'  then        
                r_carry <= '0';
                -- this signals saturation (saturate at sum of taps to prevent decay problems)
                if NR_TAPS = 1 or sum(TAP_ARRAY) >= WORD_LENGTH-2 then
                    r_sat <= r_potential(WORD_LENGTH-2) xor r_potential(WORD_LENGTH-1);
                else
                    r_sat <= r_potential(sum(TAP_ARRAY)) xor r_potential(WORD_LENGTH-1);
                end if;
            else
                if state_end = '0' then
                    r_carry <= s_r_carry;
                else
                    r_carry <= s_sum or JOIN_AND(not r_potential(MINIMUM(TAP_ARRAY) downto 1));
                end if;
            end if;
        end if;
    end process;
    
    -- output sum (only valid during integration)
    output <= r_potential(WORD_LENGTH-1);
end structure;
