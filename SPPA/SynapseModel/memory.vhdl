-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Read-only weight memory
--
-- authors    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- created    : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity memory is
generic(
	ADDRESS_WIDTH : integer;
	DATA_WIDTH    : integer
	);
port(
	clk           :  in std_logic;
	we            :  in std_logic;
	address       :  in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
	data_in       :  in std_logic_vector(DATA_WIDTH-1 downto 0);
	data_out      : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end memory;

architecture inferred of memory is
	type mem_type is array(0 to (2**ADDRESS_WIDTH-1)) of std_logic_vector(DATA_WIDTH-1 downto 0);
	signal mem : mem_type; 
begin
	process(clk)
	begin
		if (clk'event and clk = '1') then
		    if we = '1' then 
              mem(conv_integer("0"& address)) <= data_in;
          end if;
			 data_out <= mem(conv_integer("0"& address));
		end if;
	end process;
end inferred;

