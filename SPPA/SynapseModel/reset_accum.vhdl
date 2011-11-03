-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Reset accum block
--
-- authors    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- created    : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity reset_accum is
port(
	reg_sign        :  in std_logic;
	accum_sign      :  in std_logic;
	
	start_syn       :  in std_logic;
	start_membr     :  in std_logic;
	stop_syn        :  in std_logic;
	stop_membr      :  in std_logic;
	
	reset_in        :  in std_logic;
	membr_enable    :  in std_logic;
		
	reset_out       : out std_logic
	);
end reset_accum;

--------------------------------------------------------------------------------

architecture no of reset_accum is
begin
	reset_out <= reset_in or (not membr_enable and stop_syn);
end no;

--------------------------------------------------------------------------------

architecture reset_accum_stop_membr of reset_accum is
begin
	reset_out <= reset_in or stop_membr or (not membr_enable and stop_syn);
end reset_accum_stop_membr;

--------------------------------------------------------------------------------

architecture reset_accum_syn of reset_accum is
begin
	reset_out <= reset_in or (not reg_sign and accum_sign and start_syn) or (not membr_enable and stop_syn);
end reset_accum_syn;

--------------------------------------------------------------------------------

architecture reset_accum_syn_membr of reset_accum is
begin
	reset_out <= reset_in or (not reg_sign and accum_sign and (start_syn or start_membr)) or (not membr_enable and stop_syn);
end reset_accum_syn_membr;

