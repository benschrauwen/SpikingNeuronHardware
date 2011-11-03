----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- The dendrite_adder module serially adds the input signals and serially outputs their
-- sum. This is only done while the enable signal is high. Lowering the enable signal
-- resets the internal carry flip-flop, but keeps the output unchanged. This block 
-- introduces one clock cycle delay.
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;   

entity dendrite_adder is 
port (
    clk         :  in std_logic;
    reset       :  in std_logic;
    enable      :  in std_logic;
    
    input1      :  in std_logic;
    input2      :  in std_logic;
    
    output      : out std_logic
);
end dendrite_adder;

architecture structure of dendrite_adder is
    signal carry, output_reg    : std_logic := '0';
    signal sum_temp, carry_temp : std_logic;
begin
    serial_adder: entity work.full_adder port map (input1, input2, carry, sum_temp, carry_temp);
    
    process(clk, reset)
    begin 
        if reset = '1' then 
            carry <= '0';
            output_reg <= '0';
        else
            if rising_edge(clk) then
                if enable = '1' then
                    carry <= carry_temp;
                    output_reg <= sum_temp;
                else
                    carry <= '0';
                    output_reg <= output_reg;
                end if;
            end if;
        end if;	
    end process;

    output <= output_reg;
end structure;
