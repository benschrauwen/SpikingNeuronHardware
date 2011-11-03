library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;

-- LM 4550  AC '97 Rev 2.1 
-- http://cache.national.com/ds/LM/LM4550.pdf

entity ADC_controller is   
	port(
		SDATA_IN : in STD_LOGIC;
		SDATA_OUT : out STD_LOGIC;
		BIT_CLK : in STD_LOGIC;
		SYNC : out STD_LOGIC;
		DATA_output : out std_logic_vector(15 downto 0)
	);
end ADC_controller;

architecture behaviour of ADC_controller is	
	signal teller : std_logic_vector(8 downto 0):=(others=>'0');
	signal bitbuffer : std_logic_vector(17 downto 0):=(others=>'0');
begin
	process(BIT_CLK)
	begin	   		
		if rising_edge(BIT_CLK) then
			teller <= teller + 1;			

			bitbuffer(0) <= SDATA_IN;
			for i in 17 downto 1 loop
				bitbuffer(i)<=bitbuffer(i-1);	
			end loop;

			if conv_integer(teller(7 downto 0))-2 = 16+3*20-2-1 then
--				DATA_output <= bitbuffer(17 downto 2); -- end of data slot, parallelise
				DATA_output <= bitbuffer(16 downto 1); -- end of data slot, parallelise
			end if;
			
			if teller(8) = '1' then				
				case conv_integer(teller(7 downto 0))-1 is
					when 0|1|2 => SDATA_OUT<='1';		-- set valid frame, control and data
					when (16+3)|(16+4)|(16+5) => SDATA_OUT<='1';		-- command 1Ch (record gain)
					when (16+20+12)|(16+20+13)|(16+20+14)|(16+20+15) => SDATA_OUT<='1';	-- 1111b
					when others => SDATA_OUT<='0';
				end case;
			else
				case conv_integer(teller(7 downto 0))-1 is
					when 0|1|2 => SDATA_OUT<='1';		-- set valid frame, control and data
--					when (16+4)|(16+5)|(16+6) => SDATA_OUT<='1';		-- command 0Eh (mic gain)
					when (16+4)|(16+5)|(16+6) => SDATA_OUT<='1';		-- command 0Eh (mic gain)
					when (16+20+9) => SDATA_OUT<='1';	-- 0001000000b
					when others => SDATA_OUT<='0';
				end case;
			end if;
			
			if conv_integer(teller(7 downto 0)) < 16 then
				SYNC <= '1';			
			else
				SYNC <= '0';			
			end if;
		end if;
	end process;		
end behaviour;
