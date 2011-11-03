----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- This module implements a full adder.
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity full_adder is
port (
    input1      :  in std_logic;
    input2      :  in std_logic;
    carry_in    :  in std_logic;

    sum         : out std_logic; 
    carry_out   : out std_logic
);
end full_adder;
     
architecture structure of full_adder is
begin
    sum <= input1 xor input2 xor carry_in;
    carry_out <= (input1 and input2) or (input1 and carry_in) or (input2 and carry_in);
end structure;
