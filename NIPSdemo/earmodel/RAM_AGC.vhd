library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.utility_package.log2ceil;

entity RAM_AGC is 
	generic	(
	bit_lengte : integer :=	16;
	aantal_filters : integer := 88
	);
	port( 
	clk: in std_logic;
	geheugen_enable: in std_logic;
	write_enable: in std_logic;
	
	adres_RAM_Lstate_lees : in std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
	adres_RAM_state_lees : in std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
	adres_RAM_Rstate_lees : in std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
	adres_RAM_state_schrijf : in std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);

	Lstate1 : out std_logic_vector(bit_lengte-1 downto 0);
	state1 : out std_logic_vector(bit_lengte-1 downto 0);
	Rstate1 : out std_logic_vector(bit_lengte-1 downto 0);
	new_state1 : in std_logic_vector(bit_lengte-1 downto 0);
	Lstate2 : out std_logic_vector(bit_lengte-1 downto 0);
	state2 : out std_logic_vector(bit_lengte-1 downto 0);
	Rstate2 : out std_logic_vector(bit_lengte-1 downto 0);
	new_state2 : in std_logic_vector(bit_lengte-1 downto 0);
	Lstate3 : out std_logic_vector(bit_lengte-1 downto 0);
	state3 : out std_logic_vector(bit_lengte-1 downto 0);
	Rstate3 : out std_logic_vector(bit_lengte-1 downto 0);
	new_state3 : in std_logic_vector(bit_lengte-1 downto 0);
	Lstate4 : out std_logic_vector(bit_lengte-1 downto 0);
	state4 : out std_logic_vector(bit_lengte-1 downto 0);
	Rstate4 : out std_logic_vector(bit_lengte-1 downto 0);
	new_state4 : in std_logic_vector(bit_lengte-1 downto 0);
	state_selectie: in std_logic 
	);
	
end RAM_AGC;

architecture gedrag of RAM_AGC is
type geheugen_rij is array(aantal_filters-1 downto 0) of std_logic_vector(bit_lengte-1 downto 0);
	signal Lstate1_rij : geheugen_rij := (others => (others=>'0'));
	signal state1_rij : geheugen_rij := (others => (others=>'0'));
	signal Rstate1_rij : geheugen_rij := (others => (others=>'0'));
	signal Lstate2_rij : geheugen_rij := (others => (others=>'0'));
	signal state2_rij : geheugen_rij := (others => (others=>'0'));
	signal Rstate2_rij : geheugen_rij := (others => (others=>'0'));
	signal Lstate3_rij : geheugen_rij := (others => (others=>'0'));
	signal state3_rij : geheugen_rij := (others => (others=>'0'));
	signal Rstate3_rij : geheugen_rij := (others => (others=>'0'));
	signal Lstate4_rij : geheugen_rij := (others => (others=>'0'));
	signal state4_rij : geheugen_rij := (others => (others=>'0'));
	signal Rstate4_rij : geheugen_rij := (others => (others=>'0'));
begin
process(clk)
begin		
	if (rising_edge(clk)) then 
		if geheugen_enable ='1'  then
				Lstate1 <= Lstate1_rij(conv_integer(unsigned(adres_RAM_Lstate_lees)));
				Lstate2 <= Lstate2_rij(conv_integer(unsigned(adres_RAM_Lstate_lees)));
				Lstate3 <= Lstate3_rij(conv_integer(unsigned(adres_RAM_Lstate_lees)));
				Lstate4 <= Lstate4_rij(conv_integer(unsigned(adres_RAM_Lstate_lees)));

				state1 <= state1_rij(conv_integer(unsigned(adres_RAM_state_lees)));
				state2 <= state2_rij(conv_integer(unsigned(adres_RAM_state_lees)));
				state3 <= state3_rij(conv_integer(unsigned(adres_RAM_state_lees)));
				state4 <= state4_rij(conv_integer(unsigned(adres_RAM_state_lees)));

				Rstate1 <= Rstate1_rij(conv_integer(unsigned(adres_RAM_Rstate_lees)));
				Rstate2 <= Rstate2_rij(conv_integer(unsigned(adres_RAM_Rstate_lees)));
				Rstate3 <= Rstate3_rij(conv_integer(unsigned(adres_RAM_Rstate_lees)));
				Rstate4 <= Rstate4_rij(conv_integer(unsigned(adres_RAM_Rstate_lees)));

			   
				if write_enable='1' and state_selectie ='1' then
				   Lstate1_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state1;
				   Lstate2_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state2;
				   Lstate3_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state3;
				   Lstate4_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state4;

				   state1_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state1;
				   state2_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state2;
				   state3_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state3;
				   state4_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state4;

				   Rstate1_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state1;
				   Rstate2_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state2;
				   Rstate3_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state3;
				   Rstate4_rij(conv_integer(unsigned(adres_RAM_state_schrijf)))<=new_state4;
			   end if;
		end if;
	end if;
end process;
end gedrag;