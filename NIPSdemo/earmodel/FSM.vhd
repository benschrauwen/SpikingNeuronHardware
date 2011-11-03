library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
--use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;
use work.utility_package.log2ceil;

entity FSM is 
	generic	(
	aantal_filters : integer := 88
	);
	port( 
	clk   : in std_logic;
	reset : in std_logic;
	adres_RAM_Lstate_lees   : out std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
	adres_RAM_state_lees    : out std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
	adres_RAM_Rstate_lees   : out std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
	adres_RAM_state_schrijf : out std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
	sync            :  in std_logic;
	start_sample    : out std_logic; 
	write_enable    : out std_logic;
	state_selectie  : out std_logic;
	clk_enable      : out std_logic
	);
end FSM;

architecture gedrag of FSM is			
signal selectie : std_logic := '0';
signal current_state : integer := 12;
signal next_state : integer;
signal filterteller : integer := 0;

begin
	state_selectie  <= selectie;
	
	process(current_state, filterteller, sync)
	begin
		case current_state is
			when 7 =>
				if filterteller = aantal_filters then
					next_state <= current_state + 1;
				else
					next_state <= 0;
				end if;
			when 12 =>
				if sync = '1' then
					next_state <= 0;
				else
					next_state <= current_state;
				end if;
			when others =>
				next_state <= current_state + 1;
		end case;
	end process;
	
	process(clk,reset)
	begin
		if reset= '1' then	  
			current_state <= 12;
		elsif rising_edge(clk) then		
			current_state <= next_state;
		end if;
	end process;
	
	process(clk,reset)
	begin
		if reset = '1' then
			filterteller <=  0;	
			selectie     <= '0';
			start_sample <= '0';
			write_enable <= '0';
			clk_enable   <= '0';
			adres_RAM_Lstate_lees   <= conv_std_logic_vector(0,LOG2CEIL(aantal_filters));
			adres_RAM_state_lees    <= conv_std_logic_vector(0,LOG2CEIL(aantal_filters));
			adres_RAM_Rstate_lees   <= conv_std_logic_vector(1,LOG2CEIL(aantal_filters));
			adres_RAM_state_schrijf <= conv_std_logic_vector(0,LOG2CEIL(aantal_filters));			
		elsif rising_edge(clk) then
			case next_state is  			
				when 0 =>
					adres_RAM_state_lees    <= conv_std_logic_vector(filterteller,LOG2CEIL(aantal_filters));
					adres_RAM_state_schrijf <= conv_std_logic_vector(filterteller,LOG2CEIL(aantal_filters));					
					
					case filterteller is 
						when 0 =>
							start_sample<='1';
							adres_RAM_Lstate_lees   <= conv_std_logic_vector(filterteller,LOG2CEIL(aantal_filters));
							adres_RAM_Rstate_lees   <= conv_std_logic_vector(filterteller+1,LOG2CEIL(aantal_filters));
						when 87 =>
							start_sample <= '0';
							adres_RAM_Lstate_lees   <= conv_std_logic_vector(filterteller-1,LOG2CEIL(aantal_filters));
							adres_RAM_Rstate_lees   <= conv_std_logic_vector(filterteller,LOG2CEIL(aantal_filters));
						when others=>
							start_sample <= '0';
							adres_RAM_Lstate_lees   <= conv_std_logic_vector(filterteller-1,LOG2CEIL(aantal_filters));
							adres_RAM_Rstate_lees   <= conv_std_logic_vector(filterteller+1,LOG2CEIL(aantal_filters));
					end case;
					
					clk_enable   <= '1';
				when 1 =>
					clk_enable   <= '0';				
				when 2 =>					
				when 3 =>					
				when 4 =>
				when 5 =>
				 	clk_enable   <= '1';
				 	write_enable <= '1';
				when 6 =>
					clk_enable   <= '0';
				 	write_enable <= '0'; 				
				when 7 =>					
					filterteller <= filterteller+1;
				when 10 =>					
				 	selectie <= not(selectie);
					filterteller <= 0;
				when others =>
					null;
			end case;
				
		end if;
	end process;
end gedrag;
