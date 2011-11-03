-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Register bank
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
-- created : 2005/03/03
-- version 3
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use work.neuron_config_package.MEMBRANE_WIDTH;
use work.neuron_config_package.REG_WIDTH;
use work.settings_package.NR_SYN;

entity register_bank is
port(
    clk            :  in std_logic;
    reset          :  in std_logic;
    reset_synchr   :  in std_logic_vector(NR_SYN downto 0);                     -- every register can be reset independently

    write_enable   :  in std_logic;    
    membr_select   :  in std_logic;                                             -- membrane can be selected independently
    
    capture        :  in std_logic;

    reg_select     :  in std_logic_vector(REG_WIDTH-1 downto 0);
        
    input          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

    output         : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0);           -- output selected register
    membr_out      : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)            -- membrane potential is always output
    );
end register_bank;

--------------------------------------------------------------------------------

architecture impl of register_bank is
    type reg_type is array (NR_SYN downto 0) of std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal registers : reg_type;
    signal registers_stored : reg_type;
begin
    assert (2**REG_WIDTH >= NR_SYN + 1)
        report "REG_WIDTH does not have enough bits to represent selected number of registers"
        severity error;
    
    -- TODO: check if synchronous reset is implemented correctly
    process(clk, reset)
    begin        
        if reset = '1' then
            for i in 0 to NR_SYN loop
                registers(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            registers <= registers;
            if write_enable = '1' then
                if membr_select = '1' then
                    registers(0) <= input;
                else
                    registers(conv_integer("0" & reg_select)) <= input;
                end if;
            end if;
           
            -- synchronous reset overwrites values if reset
            for i in 0 to NR_SYN loop
                if reset_synchr(i) = '1' then
                    registers(i) <= (others => '0');
                end if;
            end loop;
        end if;
    end process;
        
    output    <= registers(conv_integer("0" & reg_select));
    membr_out <= registers(0);

    -- enkel voor observatie
    process(clk)
    begin
        if rising_edge(clk) and capture = '1' then
            registers_stored <= registers;
        end if;
    end process;
end impl;

