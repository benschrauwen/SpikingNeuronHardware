library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use work.utility_package.all;

package settings_package is
constant CONST_NR_PARALLEL_NEURONS : integer := 100;
constant CONST_NR_BITS             : integer := 11;
constant CONST_NR_SERIAL_NEURONS   : integer := 5;
constant CONST_NR_SYNAPSES         : integer_array  := (2,2,2,2,2);
constant CONST_NR_WEIGHTS          : integer_matrix := ((12,0),(12,0),(12,0),(12,0),(12,0));
constant CONST_REFRACTORINESS      : boolean := TRUE;
constant CONST_REFRACTORY_WIDTH    : integer := 11;
constant CONST_DECAY_SHIFT         : integer_matrix := ((3,4),(3,4),(3,4),(3,4),(3,4));
type weight_mem_type is array(0 to TOTAL_NR_WEIGHTS(CONST_NR_WEIGHTS)*CONST_NR_BITS-1) of std_logic_vector(CONST_NR_PARALLEL_NEURONS-1 downto 0);
type con_mem_type    is array(TOTAL_NR_WEIGHTS(CONST_NR_WEIGHTS)*CONST_NR_PARALLEL_NEURONS-1 downto 0) of std_logic_vector(1+LOG2CEIL(CONST_NR_SERIAL_NEURONS)+LOG2CEIL(CONST_NR_PARALLEL_NEURONS)-1 downto 0);
type reg_mem_type    is array(0 to TOTAL_MEM(CONST_NR_BITS,CONST_NR_SYNAPSES,CONST_DECAY_SHIFT,CONST_REFRACTORINESS,CONST_REFRACTORY_WIDTH)-1) of std_logic_vector(CONST_NR_PARALLEL_NEURONS-1 downto 0);
end settings_package;
package body settings_package is
end settings_package;
