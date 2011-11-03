library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
--use IEEE.STD_LOGIC_SIGNED.ALL;
entity tweedeordefilter is 

	generic	(
	bit_lengte : integer;
	rom_lengte : integer := 16;
	aantal_filters: integer:=88
	 
	);
	port( 
	A0: in std_logic_vector(rom_lengte-1 downto 0);
	A1: in std_logic_vector(rom_lengte-1 downto 0);
	A2: in std_logic_vector(rom_lengte-1 downto 0);
	B0: in std_logic_vector(rom_lengte-1 downto 0); 
	B1: in std_logic_vector(rom_lengte-1 downto 0);
	xn1_lees_in : in std_logic_vector(bit_lengte-1 downto 0);
	xn2_lees_in  : in std_logic_vector(bit_lengte-1 downto 0);
	yn1_lees_in : in std_logic_vector(bit_lengte-1 downto 0);
	yn2_lees_in : in std_logic_vector(bit_lengte-1 downto 0);
	input : in std_logic_vector(bit_lengte-1 downto 0);
	start_sample : in std_logic;  
	input_ADC : in std_logic_vector(bit_lengte-1 downto 0);
	xn1_schrijf_weg : out std_logic_vector(bit_lengte-1 downto 0):=(others => '0');
	xn2_schrijf_weg : out std_logic_vector(bit_lengte-1 downto 0):=(others => '0');
	yn1_schrijf_weg : out std_logic_vector(bit_lengte-1 downto 0):=(others => '0');
	yn2_schrijf_weg : out std_logic_vector(bit_lengte-1 downto 0):=(others => '0');
	output_schrijf_weg : out std_logic_vector(bit_lengte-1 downto 0):=std_logic_vector(to_signed(0,bit_lengte))
	);
	
end tweedeordefilter;

architecture gedrag of tweedeordefilter is
begin 
	
	process(A0,A1,A2,B0,B1,xn1_lees_in,xn2_lees_in,yn1_lees_in,yn2_lees_in,start_sample,input,input_ADC)	
	variable y_n : std_logic_vector(bit_lengte-1 downto 0);
	variable A0input : std_logic_vector(rom_lengte+bit_lengte-1 downto 0);
	variable A1xn1_lees_in : std_logic_vector(rom_lengte+bit_lengte-1 downto 0);
	variable A2xn2_lees_in	: std_logic_vector(rom_lengte+bit_lengte-1 downto 0);
	variable B0yn1_lees_in: std_logic_vector(rom_lengte+bit_lengte-1 downto 0);
	variable B1yn2_lees_in : std_logic_vector(rom_lengte+bit_lengte-1 downto 0);
	variable A0input_ADC : std_logic_vector(rom_lengte+bit_lengte-1 downto 0);
	variable y_n_optel : std_logic_vector(rom_lengte+bit_lengte-1 downto 0);	
--	variable A0: std_logic_vector(bit_lengte-1 downto 0);
--	variable A1: std_logic_vector(bit_lengte-1 downto 0);
--	variable A2: std_logic_vector(bit_lengte-1 downto 0);
--	variable B0: std_logic_vector(bit_lengte-1 downto 0); 
--	variable B1: std_logic_vector(bit_lengte-1 downto 0);
	--variable y_n_optel_aanpas : std_logic_vector(3*bit_lengte-1 downto 0);
	begin 
		--A0:=std_logic_vector(TO_SIGNED(13719,bit_lengte));
--		A1:=std_logic_vector(TO_SIGNED(0,bit_lengte));
--		A2:=std_logic_vector(TO_SIGNED(-13719,bit_lengte));
--		B0:=std_logic_vector(TO_SIGNED(26923,bit_lengte));
--		B1:=std_logic_vector(TO_SIGNED(11095,bit_lengte));
		
		A1xn1_lees_in:=std_logic_vector(signed(A1) * signed(xn1_lees_in));
		A2xn2_lees_in:=std_logic_vector(signed(A2) * signed(xn2_lees_in));
		B0yn1_lees_in:=std_logic_vector(signed(B0) * signed(yn1_lees_in));
		B1yn2_lees_in:=std_logic_vector(signed(B1) * signed(yn2_lees_in));	
	   if start_sample = '0' then 
			A0input := std_logic_vector(signed(A0) * signed(input));
		  	xn1_schrijf_weg <= input;
	   else
			A0input := std_logic_vector(signed(A0) * signed(input_ADC));
		  	xn1_schrijf_weg <= input_ADC;
	   end if;
   	y_n_optel := std_logic_vector(signed(A0input) +signed(A1xn1_lees_in)+ signed(A2xn2_lees_in) - signed(B0yn1_lees_in) - signed(B1yn2_lees_in)); 
   	--y_n_optel_aanpas:= conv_std_logic_vector(128,bit_lengte)*y_n_optel + conv_std_logic_vector(128,bit_lengte)*y_n_optel;
--		y_n_optel := std_logic_vector(signed(y_n_optel) * 4);
		y_n_optel := std_logic_vector(signed(y_n_optel)sll 2);
		y_n := y_n_optel(rom_lengte+bit_lengte-1 downto rom_lengte);
   	xn2_schrijf_weg <= xn1_lees_in;
		yn2_schrijf_weg <= yn1_lees_in;				  
		yn1_schrijf_weg <= y_n;
		output_schrijf_weg <= y_n;	
	end process;
end gedrag;
	            	            
		
		
		




	
	
	
	
	