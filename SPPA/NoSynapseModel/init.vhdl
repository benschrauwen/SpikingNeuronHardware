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
    MEMBRANE_WIDTH     : integer
    );
port(
    start    :  in std_logic;
    accum :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    add_1    : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
    );
end init;

--------------------------------------------------------------------------------

architecture membrane_init of init is
begin
    add_1 <= accum;
end membrane_init;

--------------------------------------------------------------------------------

architecture zero_init of init is
begin
    add_1 <= (others => '0') when start = '1' else accum;
end zero_init;

