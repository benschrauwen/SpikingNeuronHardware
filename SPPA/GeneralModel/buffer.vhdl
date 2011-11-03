-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Optional membrane potential buffer for memory-decaying SOS-MEM
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
-- created : 2005/03/03
-- version 3
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use work.neuron_config_package.MEMBRANE_WIDTH;

entity buff is
port(
    clk             :  in std_logic;
    reset           :  in std_logic;
    enable          :  in std_logic;

    buff_in         :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    buff_out        : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
);
end buff;

--------------------------------------------------------------------------------

architecture no of buff is
begin
    buff_out <= buff_in;
end no;

--------------------------------------------------------------------------------

architecture yes of buff is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            buff_out(MEMBRANE_WIDTH-2 downto 0) <= (others => '0');
        elsif rising_edge(clk) and enable = '1' then
            buff_out(MEMBRANE_WIDTH-2 downto 0) <= buff_in(MEMBRANE_WIDTH-2 downto 0);
        end if;
    end process;

    buff_out(MEMBRANE_WIDTH-1) <= buff_in(MEMBRANE_WIDTH-1);  -- is needed the first clockcycle, so buffering it would be to slow
end yes;

