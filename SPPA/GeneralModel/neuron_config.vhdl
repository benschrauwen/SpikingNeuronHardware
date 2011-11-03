-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Configuration constants and functions
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
-- created : 2005/03/03
-- version 2
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use work.utility_package.all;
use work.settings_package.all;

package neuron_config_package is
    constant NEURON_TYPE              : string := "dos";  --li1, li2, sos, dos
    
    constant WEIGHT_WIDTH             : integer := 10;
    constant MEMBRANE_WIDTH           : integer := 10;
    
    constant THRESHOLD                : integer := 255;
    constant ASP                      : integer := -255;
    constant REFR_COMPARE_VALUE       : integer := -127;

    function NR_DECAY_STATES return integer;
    function REG_WIDTH return integer;
    function NR_STATES(neuron_nr : integer) return integer;
    function STATE_WIDTH(neuron_nr : integer) return integer;

    type mem_type is array(natural range <>) of std_logic_vector(WEIGHT_WIDTH*NR_NEURONS-1 downto 0);
    
    function CALC_MEM_DECAY(lin_decay : integer) return integer;
    function CALC_HARD_DECAY(lin_decay : integer) return integer;
    -- TODO: maak een CALC_LIN_DECAY
end neuron_config_package;

package body neuron_config_package is
        
    function NR_DECAY_STATES return integer is
    begin
        case NEURON_TYPE is
            when "li1" => return 1;
            when "li2" => return 2;
            when "dos" => return 1;
            when "sos" => return MEMBRANE_WIDTH;
            when others => return 0;
        end case;
    end NR_DECAY_STATES;    
        
    function REG_WIDTH return integer is
    begin
        return LOG2CEIL(NR_SYN)+1;
    end REG_WIDTH;
        
    function NR_STATES(neuron_nr : integer) return integer is
        variable result : integer := 0;
        variable temp : integer_array(NR_SYN downto 0);
    begin
        temp := PROJECTION(SYNAPSE_MAP,neuron_nr);
        for i in temp'range loop
            result := result + NR_DECAY_STATES + 1 + temp(i);
        end loop;
        return result - 1;
    end NR_STATES;    
    
    function STATE_WIDTH(neuron_nr : integer) return integer is
    begin
        return LOG2CEIL(NR_STATES(neuron_nr));
    end STATE_WIDTH;

    function CALC_MEM_DECAY(lin_decay : integer) return integer is
        -- round(exp(-(0:100)/2^8)*256)
        constant mapping : integer_array(0 to 100) := (
            256, 255, 254, 253, 252, 251, 250, 249, 248, 247, 246, 245, 244,
            243, 242, 241, 240, 240, 239, 238, 237, 236, 235, 234, 233, 232,
            231, 230, 229, 229, 228, 227, 226, 225, 224, 223, 222, 222, 221,
            220, 219, 218, 217, 216, 216, 215, 214, 213, 212, 211, 211, 210,
            209, 208, 207, 207, 206, 205, 204, 203, 203, 202, 201, 200, 199,
            199, 198, 197, 196, 196, 195, 194, 193, 192, 192, 191, 190, 190,
            189, 188, 187, 187, 186, 185, 184, 184, 183, 182, 182, 181, 180,
            179, 179, 178, 177, 177, 176, 175, 175, 174, 173);
    begin
        return mapping(lin_decay);
    end CALC_MEM_DECAY;

    function CALC_HARD_DECAY(lin_decay : integer) return integer is
        -- round(8-log2(256-exp(-(0:100)/256)*256))
        constant mapping : integer_array(0 to 100) := (
            0, 8, 7, 6, 6, 6, 5, 5, 5, 5, 5, 5, 4,
            4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2);
    begin
        return mapping(lin_decay);
    end CALC_HARD_DECAY;

end neuron_config_package;

