-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Saturation block
--
-- authors : Benjamin Schrauwen
-- created : 2006/04/14
-- version 1
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use work.neuron_config_package.MEMBRANE_WIDTH;

entity saturation is
port(
    adder_value     :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

    neg_sat         : out std_logic;
    pos_sat         : out std_logic
);
end saturation;

--------------------------------------------------------------------------------

architecture no of saturation is
begin
    neg_sat <= '0';
    pos_sat <= '0';
end no;

--------------------------------------------------------------------------------
-- only negative saturation, good to saturate only membrane

architecture neg of saturation is
begin
    neg_sat <= adder_value(MEMBRANE_WIDTH-1) and not adder_value(MEMBRANE_WIDTH-2);
    pos_sat <= '0';
end neg;

--------------------------------------------------------------------------------
-- pos and neg saturation,  good to saturate synapses and membrane

architecture posneg of saturation is
begin
    neg_sat <= adder_value(MEMBRANE_WIDTH-1) and not adder_value(MEMBRANE_WIDTH-2);
    pos_sat <= not adder_value(MEMBRANE_WIDTH-1) and adder_value(MEMBRANE_WIDTH-2);
end posneg;

