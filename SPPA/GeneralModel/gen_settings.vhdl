library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use work.utility_package.all;
use work.neuron_config_package.all;
use work.settings_package.all;

package gen_settings_package is

constant NR_NEURON_INPUTS   : integer_array(0 to NR_NEURONS-1) := GEN_NR_NEURON_INPUTS(NR_NEURONS, SYNAPSE_MAP);
constant SYNAPSE_WEIGHT_MAP : integer_matrix(0 to NR_NEURONS-1, 0 to NR_SYN+1-1) := GEN_SYNAPSE_WEIGHT_MAP(NR_NEURONS, NR_SYN+1, SYNAPSE_MAP);

end gen_settings_package;

package body gen_settings_package is
end gen_settings_package;
