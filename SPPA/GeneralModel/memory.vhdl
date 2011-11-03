-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Weight memory
--
-- authors    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- created    : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.settings_package.all;
use work.neuron_config_package.all;
use work.mem_settings_package.all;

entity memory is
port(
    clk           :  in std_logic;
    we            :  in std_logic := '0';
    address       :  in std_logic_vector(STATE_WIDTH(0)-1 downto 0);
    data_in       :  in std_logic_vector(WEIGHT_WIDTH*NR_NEURONS-1 downto 0) := (others => '0');
    data_out      : out std_logic_vector(WEIGHT_WIDTH*NR_NEURONS-1 downto 0)
    );
end memory;

architecture inferred of memory is
    signal mem : mem_type(0 to (2**STATE_WIDTH(0)-1)) := MEM;
begin
    process(clk)
    begin
        if (clk'event and clk = '1') then
            if we = '1' then 
		mem(conv_integer(address)) <= data_in;
	    end if;
	    data_out <= mem(conv_integer(address));
	end if;
    end process;
end inferred;

