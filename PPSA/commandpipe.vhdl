----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- This block introduces one clock cycle of delay for each of the control signals. This
-- is used to implement the control signals for pipelined processing.
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library work;
use work.utility_package.all;

entity commandpipe is
generic (
    NR_TAPS       : integer;
    NR_SYN_MODELS : integer
);
port (
    clk         :  in std_logic;
    reset       :  in std_logic;
    
    integrate   :  in std_logic;
    decay       :  in std_logic;
    state_end   :  in std_logic;
    tap         :  in std_logic_vector(LOG2CEIL(NR_TAPS)-1 downto 0);
    extend      :  in std_logic_vector(NR_SYN_MODELS downto 0);

    integrate_d : out std_logic;
    decay_d     : out std_logic;
    state_end_d : out std_logic;
    tap_d       : out std_logic_vector(LOG2CEIL(NR_TAPS)-1 downto 0);
    extend_d    : out std_logic_vector(NR_SYN_MODELS downto 0)
);
end commandpipe;

architecture structure of commandpipe is
begin    
    process(clk, reset)
    begin
        if reset = '1' then 
            integrate_d <= '0';
            decay_d <= '0';
            state_end_d <= '0';
            tap_d <= (others => '0');
            extend_d <= (others => '0');
        elsif rising_edge(clk) then
            integrate_d <= integrate;
            decay_d <= decay;
            state_end_d <= state_end;
            tap_d <= tap;
            extend_d <= extend;
        end if;  
    end process;
end structure;
