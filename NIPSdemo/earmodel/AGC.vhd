library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.math_real.ALL;

entity AGC is 
generic	(
	bit_lengte       : integer := 16;
	fixed_point_bits : integer;
	aantal_filters   : integer := 88;
	g_target         : real;
	g_epsilon        : real
);
port( 
	input               :  in std_logic_vector(bit_lengte-1 downto 0); 	
	statevorigefilter   :  in std_logic_vector(bit_lengte-1 downto 0);
	state               :  in std_logic_vector(bit_lengte-1 downto 0);	
	statevolgendefilter :  in std_logic_vector(bit_lengte-1 downto 0); 	
	newstate            : out std_logic_vector(bit_lengte-1 downto 0);
	output              : out std_logic_vector(bit_lengte-1 downto 0) 
);
end AGC;

architecture gedrag of AGC is
	constant epsovertarget         : std_logic_vector(fixed_point_bits-1 downto 0) := std_logic_vector(TO_SIGNED(integer(g_epsilon/g_target *real((2.0)**(fixed_point_bits-5))), fixed_point_bits));
	constant eenminepsilon         : std_logic_vector(fixed_point_bits-1 downto 0) := std_logic_vector(TO_SIGNED(integer((1.0-g_epsilon)    *real((2.0)**(fixed_point_bits-1))), fixed_point_bits));
	constant eenminepsilonoverdrie : std_logic_vector(fixed_point_bits-1 downto 0) := std_logic_vector(TO_SIGNED(integer((1.0-g_epsilon)/3.0*real((2.0)**(fixed_point_bits-1))), fixed_point_bits));	
	
	signal inputstate              : std_logic_vector(2*bit_lengte-1 downto 0);	
	signal output_ff               : std_logic_vector(  bit_lengte-1 downto 0);
	signal HWR                     : std_logic_vector(  bit_lengte-1 downto 0);		

	signal epsovertargetvorige     : std_logic_vector(fixed_point_bits+bit_lengte-1 downto 0);
	signal epsovertargethuidig     : std_logic_vector(fixed_point_bits+bit_lengte-1 downto 0);
	signal epsovertargetvolgende   : std_logic_vector(fixed_point_bits+bit_lengte-1 downto 0);
		
	signal statebijhouden          : std_logic_vector(fixed_point_bits+bit_lengte-1 downto 0);
		
begin
	inputstate <= std_logic_vector(signed(input)*signed(state));		   
--	output_ff  <= std_logic_vector(signed(input) - (signed(inputstate(2*bit_lengte-1 downto bit_lengte)) sll 1 ));
	output_ff  <= std_logic_vector(signed(input) - signed(inputstate(2*bit_lengte-1 downto bit_lengte)));	

	HWR        <= output_ff when output_ff(output_ff'high) = '0' else (others => '0');	
	output     <= HWR;
	
	epsovertargetvorige   <= std_logic_vector(signed(eenminepsilonoverdrie)*signed(statevorigefilter));
	epsovertargethuidig   <= std_logic_vector(signed(eenminepsilonoverdrie)*signed(state));
	epsovertargetvolgende <= std_logic_vector(signed(eenminepsilonoverdrie)*signed(statevolgendefilter));
--	statebijhouden        <= std_logic_vector((signed(HWR)*signed(epsovertarget) sll 1)+(signed(epsovertargetvorige)+signed(epsovertargethuidig)+signed(epsovertargetvolgende)) sll 1);
	statebijhouden        <= std_logic_vector((signed(HWR)*signed(epsovertarget) sll 4)+(signed(epsovertargetvorige)+signed(epsovertargethuidig)+signed(epsovertargetvolgende)));	

	-- assign minimum of two values
	newstate <= eenminepsilon(fixed_point_bits-1 downto fixed_point_bits-bit_lengte) 
		when signed(statebijhouden(fixed_point_bits+bit_lengte-1 downto fixed_point_bits)) > signed(eenminepsilon(fixed_point_bits-1 downto fixed_point_bits-bit_lengte)) 
		else statebijhouden(fixed_point_bits+bit_lengte-1 downto fixed_point_bits);
end gedrag;
