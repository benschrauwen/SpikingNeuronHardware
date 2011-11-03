----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- Synapse block serially shifts out the internally stored weight when shift and 
-- input_spike are high. When shift and write are high, the input_data is shifted in.
-- This block does not introduce delay (the next value is pre-loaded).
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;
use work.utility_package.all;

library UNISIM;
use UNISIM.VComponents.all;

entity synapse is
generic (
    WORD_LENGTH : integer;
    WEIGHT_VALUE: integer
);
port (
    clk         :  in std_logic;
    reset       :  in std_logic;

    shift       :  in std_logic;
    write       :  in std_logic;
    
    input_spike :  in std_logic;
    input_data  :  in std_logic;
    
    output      : out std_logic
);
end synapse;

--architecture inferred of synapse is	 
--    -- TODO: why does this gives problems with the Xilinx synthesizer? (solved in ISE 8.1 ??)
--    -- TODO: how will we implement this on Altera? LUT-RAM? M512 shiftreg for multiple synapses
--    signal weight       : std_logic_vector(WORD_LENGTH-1 downto 0) := conv_std_logic_vector(WEIGHT_VALUE, WORD_LENGTH);
--    signal shift_in     : std_logic;
--begin
--    shift_register: process(clk)
--    begin
--        if rising_edge(clk) then
--            if shift = '1' and reset = '0' then
--                weight <= shift_in & weight(WORD_LENGTH-1 downto 1);
--            end if;
--        end if;
--    end process;
--
--    shift_in <= input_data when write = '1' else weight(0);
--    
--    output <= weight(0) and input_spike;
--end inferred;

architecture xilinx of synapse is	 
    signal shift_in, shift_out, shift_enable : std_logic;
    constant shifter_size : std_logic_vector(3 downto 0) := conv_std_logic_vector(WORD_LENGTH-1, 4);

    component SRL16E
    generic ( 
        INIT: bit_vector); 
    port (Q : out STD_ULOGIC; 
        A0 : in STD_ULOGIC; 
        A1 : in STD_ULOGIC; 
        A2 : in STD_ULOGIC; 
        A3 : in STD_ULOGIC; 
        CE : in STD_ULOGIC;
        CLK : in STD_ULOGIC; 
        D : in STD_ULOGIC); 
    end component; 
    
    constant val : bit_vector(WORD_LENGTH-1 downto 0) := bit_vector(to_signed(WEIGHT_VALUE, WORD_LENGTH));
    constant rev_val : bit_vector(WORD_LENGTH-1 downto 0) := REVERSE(val);
    constant zeros : bit_vector(15 downto WORD_LENGTH) := (others => '0');
    constant full_rev_val : bit_vector(15 downto 0) := zeros & rev_val;
begin
    shift_enable <= shift and not reset;
    
    shift_reg : SRL16E 
        generic map(INIT => full_rev_val) 
        port map (Q => shift_out, A0 => shifter_size(0), A1 => shifter_size(1), A2 => shifter_size(2), A3 => shifter_size(3), CLK => clk, D => shift_in, CE => shift_enable); 

    shift_in <= input_data when write = '1' else shift_out;
    
    output <= shift_out and input_spike;
end xilinx;
