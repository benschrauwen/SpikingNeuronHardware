-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Absolute refractory block
--
-- authors    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- created    : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity abs_refractory is
generic(
	MEMBRANE_WIDTH : integer;
	COMPARE_VALUE  : integer := 0
	);
port(
	clk          :  in std_logic;
	reset        :  in std_logic;
	
	stop_membr   :  in std_logic;
	thr_exceeded :  in std_logic;
	spike_out    :  in std_logic;
	adder        :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

	ASP_enable   : out std_logic;
	membr_enable : out std_logic
	);
end abs_refractory;

--------------------------------------------------------------------------------
-- this implementation involves no refractory period. However, the critical
-- path of the calculations become a bit longer (lower clockspeed)

architecture no_refr of abs_refractory is
begin
    membr_enable <= '1';
    ASP_enable   <= thr_exceeded and stop_cycle;
end no_refr;

--------------------------------------------------------------------------------

architecture one_clk of abs_refractory is
begin
	membr_enable <= '1';
	ASP_enable   <= spike_out and stop_membr;
end one_clk;

--------------------------------------------------------------------------------

architecture one_clk_and_add_neg of abs_refractory is
	signal refr_period_ff : std_logic;
	signal compare_adder  : std_logic;
begin
	compare_adder <= adder(MEMBRANE_WIDTH-1);
	
	process(reset, clk)
	begin
		if reset = '1' then
			refr_period_ff <= '0';
		elsif rising_edge(clk) then
			if stop_membr = '1' then
			   if (spike_out = '1') then 
			     refr_period_ff <= '1';
			   else 
			     refr_period_ff <= refr_period_ff and compare_adder;
			   end if;
			end if;
		end if;
	end process;
	
	membr_enable <= not refr_period_ff;	
	ASP_enable   <= spike_out and stop_membr;
end one_clk_and_add_neg;

--------------------------------------------------------------------------------

architecture one_clk_and_add_compared of abs_refractory is
	signal refr_period_ff : std_logic;
	signal compare_adder  : std_logic;
begin
	compare_adder <= '1' when conv_integer(adder) < COMPARE_VALUE else '0';
	
	process(reset, clk)
	begin
		if reset = '1' then
			refr_period_ff <= '0';
		elsif rising_edge(clk) then
			if stop_membr = '1' then
			   if (spike_out = '1') then 
			     refr_period_ff <= '1';
			   else 
			     refr_period_ff <= refr_period_ff and compare_adder;
			   end if;
			end if;
		end if;
	end process;
	
	membr_enable <= not refr_period_ff;	
	ASP_enable   <= spike_out and stop_cycle;
end one_clk_and_add_compared;

