library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity MUL12 is 
	generic	(
		bit_lengte : integer :=	16
	);
	port( 
	input1a : in std_logic_vector(bit_lengte - 1 downto 0);
	input2a : in std_logic_vector(bit_lengte - 1 downto 0);
	input3a : in std_logic_vector(bit_lengte - 1 downto 0);
	input4a : in std_logic_vector(bit_lengte - 1 downto 0);
	input5a : in std_logic_vector(bit_lengte - 1 downto 0); 
	input6a : in std_logic_vector(bit_lengte - 1 downto 0);
	input7a : in std_logic_vector(bit_lengte - 1 downto 0);
	input8a : in std_logic_vector(bit_lengte - 1 downto 0); 
	input9a : in std_logic_vector(bit_lengte - 1 downto 0);
	input10a : in std_logic_vector(bit_lengte - 1 downto 0);
	input11a : in std_logic_vector(bit_lengte - 1 downto 0);
	input12a : in std_logic_vector(bit_lengte - 1 downto 0);
	input1b : in std_logic_vector(bit_lengte - 1 downto 0);
	input2b : in std_logic_vector(bit_lengte - 1 downto 0);
	input3b : in std_logic_vector(bit_lengte - 1 downto 0);
	input4b : in std_logic_vector(bit_lengte - 1 downto 0);
	input5b : in std_logic_vector(bit_lengte - 1 downto 0); 
	input6b : in std_logic_vector(bit_lengte - 1 downto 0);
	input7b : in std_logic_vector(bit_lengte - 1 downto 0);
	input8b : in std_logic_vector(bit_lengte - 1 downto 0); 
	input9b : in std_logic_vector(bit_lengte - 1 downto 0);
	input10b : in std_logic_vector(bit_lengte - 1 downto 0);
	input11b : in std_logic_vector(bit_lengte - 1 downto 0);
	input12b : in std_logic_vector(bit_lengte - 1 downto 0);
	output1a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0');
	output2a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0');
	output3a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0');
	output4a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0');
	output5a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0'); 
	output6a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0');
	output7a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0');
	output8a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0'); 
	output9a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0');
	output10a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0');
	output11a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0');
	output12a : out std_logic_vector(bit_lengte - 1 downto 0):=(others => '0');

	selectie : in std_logic
	
	);
end MUL12; 

architecture gedrag of MUL12 is			
begin 
	process(selectie,input1a,input2a,input3a,input4a,input5a,input6a,input7a,input8a,input9a,input10a,input11a,input12a,input1b,input2b,input3b,input4b,input5b,input6b,input7b,input8b,input9b,input10b,input11b,input12b)
	begin
	if selectie = '0' then
		output1a <= input1a; 
		output2a <= input2a;
		output3a <= input3a;
		output4a <= input4a;
		output5a <= input5a; 
		output6a <= input6a;
		output7a <= input7a;
		output8a <= input8a; 
		output9a <= input9a;
		output10a <= input10a;
		output11a <= input11a;
		output12a <= input12a; 
	else
		output1a <= input1b; 
		output2a <= input2b;
		output3a <= input3b;
		output4a <= input4b;
		output5a <= input5b; 
		output6a <= input6b;
		output7a <= input7b;
		output8a <= input8b; 
		output9a <= input9b;
		output10a <= input10b;
		output11a <= input11b;
		output12a <= input12b;
	end if;	
	end process;
end gedrag;