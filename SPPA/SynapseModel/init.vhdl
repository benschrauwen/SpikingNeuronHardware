-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Init block
--
-- authors    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- created    : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity init is
generic(
    MEMBRANE_WIDTH  : integer
    );
port(
    start_syn       :  in std_logic;
    start_membr     :  in std_logic;

    accum           :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    reg_bank        :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

    add_1           : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
    );
end init;

--------------------------------------------------------------------------------

architecture no_init of init is
begin
    add_1 <= accum;
end no_init;

--------------------------------------------------------------------------------

architecture regbank_init_syn of init is
begin
    add_1 <= reg_bank when start_syn = '1' else accum;
end regbank_init_syn;

--------------------------------------------------------------------------------

architecture zero_init_syn of init is
begin
    add_1 <= (others => '0') when start_syn = '1' else accum;
end zero_init_syn;

--------------------------------------------------------------------------------

architecture regbank_init_syn_membr of init is
begin
    add_1 <= reg_bank when start_syn = '1' or start_membr = '1' else accum;
end regbank_init_syn_membr;

--------------------------------------------------------------------------------

architecture zero_init_syn_membr of init is
begin
    add_1 <= (others => '0') when start_syn = '1' or start_membr = '1' else accum;
end zero_init_syn_membr;

