-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Membrane buffer
--
-- authors    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- created    : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity membrane_buffer is
generic (
    MEMBRANE_WIDTH : integer;
    MEMBRANE_RESET : integer
    );
port(
    reset          :  in std_logic;
    clk            :  in std_logic;
    stop           :  in std_logic;
    accum          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    membr_pot_buff : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
    );
end membrane_buffer;

--------------------------------------------------------------------------------

architecture no_buffer of membrane_buffer is
begin
    membr_pot_buff <= accum;
end no_buffer;

--------------------------------------------------------------------------------

architecture with_buffer of membrane_buffer is
begin
    process(reset, clk)
    begin
        if reset = '1' then
            membr_pot_buff <= conv_std_logic_vector(MEMBRANE_RESET, MEMBRANE_WIDTH);
        elsif (clk'event and clk = '1') then
            if stop = '1' then
                membr_pot_buff <= accum;
            end if;
        end if;
    end process;
end with_buffer;

