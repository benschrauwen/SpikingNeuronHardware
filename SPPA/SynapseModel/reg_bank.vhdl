-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Register bank
--
-- authors    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- created    : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity register_bank is
generic (
        MEMBRANE_WIDTH : integer;
        REG_WIDTH : integer
    );
port(
        clk            :  in std_logic;
        reset          :  in std_logic;
	
        stop_syn       :  in std_logic;
        stop_membr     :  in std_logic;
        reg_select     :  in std_logic_vector(REG_WIDTH-1 downto 0);
        
        adder          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
	
        output         : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0) 
    );
end register_bank;

--------------------------------------------------------------------------------

architecture impl of register_bank is
	type reg_type is array (2**REG_WIDTH-1 downto 0) of std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
	signal registers : reg_type;
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				registers <= (others => (others => '0'));
			else
				registers <= registers;
				if stop_syn = '1' or stop_membr = '1' then
					registers(conv_integer("0" & reg_select)) <= adder;
				end if;
			end if;
		end if;
	end process;

	output <= registers(conv_integer("0" & reg_select));
end impl;

