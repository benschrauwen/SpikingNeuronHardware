library ieee;
use ieee.std_logic_1164.all;
use work.utility_package.all;

package settings_package is
constant NR_NEURONS         : integer := 4;
constant NR_INPUT_NODES     : integer := 2;
constant CONN_FROM          : integer_matrix := ((-1,-2,0), (-1,-2,0), (-1,-2,0), (1,2,3));
constant NR_OUTPUT_NODES    : integer := 1;
constant OUTPUT_NODES       : integer_array := (0 => 4);
constant WEIGHTS            : integer_matrix := ((1, 2, 0), (3, 4, 0), (5, -1, 0), (1, 2, -3));
constant SYNAPSE_MAP        : integer_matrix := ((0 => 2), (0 => 2), (0 => 2), (0 => 3));
end settings_package;

package body settings_package is
end settings_package;
