-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Reset block
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
-- created : 2005/03/03
-- version 3
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use work.neuron_config_package.REG_WIDTH;
use work.settings_package.NR_SYN;

entity reset_accum is
port(
    reg_sign   :  in std_logic;
    adder_sign :  in std_logic;

    start_decay :  in std_logic;
    
    reg_select :  in std_logic_vector(REG_WIDTH-1 downto 0);
    reset_in   :  in std_logic;

    reset_out  : out std_logic_vector(NR_SYN downto 0)
    );
end reset_accum;

--------------------------------------------------------------------------------
-- basic reset distribution

architecture no of reset_accum is
begin
   reset_logic: for i in 0 to NR_SYN generate
       reset_out(i) <= reset_in;
   end generate;
end no;

--------------------------------------------------------------------------------
-- prevent oscillation by resetting the currently selected register if sign changes
-- only needed for certain implementations of linear decay

architecture reset_stable_zero of reset_accum is
begin
    reset_logic: for i in 0 to NR_SYN generate
        reset_out(i) <= (reset_in or ((reg_sign xor adder_sign) and start_decay)) when i = conv_integer("0" & reg_select) else reset_in;
    end generate;
end reset_stable_zero;

