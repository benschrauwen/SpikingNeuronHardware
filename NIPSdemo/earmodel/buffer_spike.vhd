Library IEEE;
library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.std_logic_unsigned.all;
use work.utility_package.log2ceil;


entity buffer_spike is 
	generic	(
	bit_lengte : integer :=	16;
	aantal_filters : integer := 88
	);
	port( 
	clk               : in std_logic;
	reset             : in std_logic;
	adres_RAM_schrijf : in std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
	spike_train       : in std_logic;
	clk_enable        : in std_logic;
	schrijven         : in std_logic;
	output            : out std_logic_vector(aantal_filters-1 downto 0)
	);
	
end buffer_spike;

architecture gedrag of buffer_spike is
signal input_buffer : std_logic_vector(aantal_filters-1 downto 0);


begin
process(clk,reset)
begin
	if reset = '1' then 
		input_buffer <= (others=>'0');
		output <= input_buffer;
	elsif (rising_edge(clk)) then 
		if clk_enable = '1' then
			input_buffer(conv_integer(adres_RAM_schrijf)) <= spike_train ;
			-- write everything when new cycle begins
			if schrijven = '1' then
				output <= input_buffer;
			end if;
		end if;
	end if;
end process;
end gedrag;	 