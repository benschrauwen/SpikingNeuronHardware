-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- network testbench file
--
-- auteurs    : Michiel D'Haene, Benjamin Schrauwen
-- aangemaakt : 2005/03/04
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.utility_package.all;
use work.settings_package.all;

entity network_tb is
end network_tb;

architecture TB_ARCHITECTURE of network_tb is
    signal s_clk, s_reset, s_enable, s_cycle_end      : std_logic; 
    signal s_inputs     : std_logic_vector(NR_INPUT_NODES-1 downto 0);
    signal s_output     : std_logic_vector(NR_OUTPUT_NODES-1 downto 0);
begin
    netw: entity work.network
    port map (clk => s_clk, reset => s_reset, enable => s_enable, inputs => s_inputs, outputs => s_output, cycle_end => s_cycle_end);

    process
    begin
        s_clk<='1';
        wait for 50 ns;
        s_clk<='0';
        wait for 50 ns;
    end process; 
    
    s_reset <= '1','0' after 200 ns;
    s_enable <= '1';
    
    process(s_clk)
        variable  rest : integer := 0;
        variable  pos  : integer := 299;                      -- random seed
    begin
        if rising_edge(s_clk) then
            if s_reset = '1' then 
                s_inputs <= (others => '0');
            else        
                if s_cycle_end = '1' then
                    for i in NR_INPUT_NODES-1 downto 0 loop
                        if pos mod 299 = 0 then                  -- 1/100 spike generation
                            s_inputs(i) <= '1';
                        else
                            s_inputs(i) <= '0';
                        end if;
                        pos := 1103515245*pos + 12345;          -- rand()
                    end loop;
                end if;
            end if;
        end if;
    end process;
    
end TB_ARCHITECTURE;

