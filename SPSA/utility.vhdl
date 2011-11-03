----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- This file contains several utility types and functions used by the framework.
--
-- authors : Benjamin Schrauwen, Michiel D'Haene
----------------------------------------------------------------------------------------
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

package utility_package is
    type integer_array is array (natural range <>) of integer;
    type integer_matrix is array (natural range <>, natural range <>) of integer;

    type std_logic_matrix is array (natural range <>, natural range <>) of std_logic;

    function LOG2FLOOR(input : integer) return integer;
    function LOG2CEIL(input : integer) return integer;
    function POW2CEIL(input : integer) return integer;

    function MAXIMUM(left, right : integer) return integer;
    function MAXIMUM(arg : integer_array) return integer;
    function MAXIMUM(arg : integer_matrix) return integer;
    function MINIMUM(arg : integer_array) return integer;

    function JOIN_AND(arg : std_logic_vector) return std_logic;
    function JOIN_OR(arg : std_logic_vector) return std_logic;

    function PROJECTION(arg : integer_matrix; index : integer) return integer_array;
    function PROJECTION(arg : std_logic_matrix; index : integer) return std_logic_vector;

    function SUM(arg : integer_array) return integer;
    function SUM(arg : integer_matrix) return integer_array;
    function SUM_END(arg : integer_array; start : integer) return integer;

    function TOTAL_MEM(nr_bits : integer; nr_synapses : integer_array; decay_shift : integer_matrix; refractoriness : boolean; refractory_width : integer) return integer;
    function CURRENT_NR_WEIGHTS(nr_weights : integer_matrix; neuron_nr : integer) return integer;
    function MAXIMUM_NR_WEIGHTS(nr_weights : integer_matrix) return integer;
    function TOTAL_NR_WEIGHTS(nr_weights : integer_matrix) return integer;
    function SYN_OFFSET(refr : boolean; offset : integer) return integer;

    function PIPELINE_DEPTH(nr_syn_models : integer; nr_synapses, nr_syn_taps : integer_array) return integer;
end utility_package;

package body utility_package is
    function LOG2FLOOR(input : integer) return integer is
        variable result : integer;
    begin
        if    (input >= 32768) then result := 15;
        elsif (input >= 16384) then result := 14;
        elsif (input >=  8192) then result := 13;
        elsif (input >=  4096) then result := 12;
        elsif (input >=  2048) then result := 11;
        elsif (input >=  1024) then result := 10;
        elsif (input >=   512) then result :=  9;
        elsif (input >=   256) then result :=  8;
        elsif (input >=   128) then result :=  7;
        elsif (input >=    64) then result :=  6;
        elsif (input >=    32) then result :=  5;
        elsif (input >=    16) then result :=  4;
        elsif (input >=     8) then result :=  3;
        elsif (input >=     4) then result :=  2;
        elsif (input >=     2) then result :=  1;
        elsif (input >=     1) then result :=  0;
        else                        result :=  -1;
        end if;
        return result;
    end LOG2FLOOR;

    function LOG2CEIL(input : integer) return integer is
        variable result : integer;
    begin
        if    (input > 32768) then result := 16;
        elsif (input > 16384) then result := 15;
        elsif (input >  8192) then result := 14;
        elsif (input >  4096) then result := 13;
        elsif (input >  2048) then result := 12;
        elsif (input >  1024) then result := 11;
        elsif (input >   512) then result := 10;
        elsif (input >   256) then result :=  9;
        elsif (input >   128) then result :=  8;
        elsif (input >    64) then result :=  7;
        elsif (input >    32) then result :=  6;
        elsif (input >    16) then result :=  5;
        elsif (input >     8) then result :=  4;
        elsif (input >     4) then result :=  3;
        elsif (input >     2) then result :=  2;
        elsif (input >=    1) then result :=  1;
        else                       result :=  0;
        end if;
        return result;
    end LOG2CEIL;

    function MAXIMUM(left, right : integer) return integer is
    begin
        if left > right then 
            return left;
        else 
            return right;
        end if;
    end MAXIMUM;

    function POW2CEIL(input : integer) return integer is
        variable result : integer;
    begin
        if    (input > 32768) then result := 65635;
        elsif (input > 16384) then result := 32768;
        elsif (input >  8192) then result := 16384;
        elsif (input >  4096) then result := 8192;
        elsif (input >  2048) then result := 4096;
        elsif (input >  1024) then result := 2048;
        elsif (input >   512) then result := 1024;
        elsif (input >   256) then result :=  512;
        elsif (input >   128) then result :=  256;
        elsif (input >    64) then result :=  128;
        elsif (input >    32) then result :=  64;
        elsif (input >    16) then result :=  32;
        elsif (input >     8) then result :=  16;
        elsif (input >     4) then result :=  8;
        elsif (input >     2) then result :=  4;
        elsif (input >     1) then result :=  2;
        else                       result :=  1;
        end if;
        return result;
    end POW2CEIL;

    function MAXIMUM(arg : integer_array) return integer is
        variable max : integer;
    begin
        max := arg(0);
        for i in arg'range loop
            if arg(i) > max then
                max := arg(i);
            end if;
        end loop;
        return max;
    end MAXIMUM;

    function MAXIMUM(arg : integer_matrix) return integer is
        variable max : integer;
    begin
        max := arg(0,0);
        for i in arg'range loop
            for j in arg'range(2) loop
                if arg(i,j) > max then
                    max := arg(i,j);
                end if;
            end loop;
        end loop;
        return max;
    end MAXIMUM;

    function MINIMUM(arg : integer_array) return integer is
        variable min : integer;
    begin
        min := arg(0);
        for i in arg'range loop
            if arg(i) < min then
                min := arg(i);
            end if;
        end loop;
        return min;
    end MINIMUM;

    function JOIN_AND(arg : std_logic_vector) return std_logic is
        variable result : std_logic;
    begin
        result := '1';
        for i in arg'range loop
            result := result and arg(i);
        end loop;
        return result;
    end JOIN_AND;

    function JOIN_OR(arg : std_logic_vector) return std_logic is
        variable result : std_logic;
    begin
        result := '0';
        for i in arg'range loop
            result := result or arg(i);
        end loop;
        return result;
    end JOIN_OR;

    function PROJECTION(arg : integer_matrix; index : integer) return integer_array is
        variable res : integer_array(arg'range(2));
    begin
        for i in arg'range(2) loop
            res(i) := arg(index, i);
        end loop;
        return res;
    end PROJECTION;

    function PROJECTION(arg : std_logic_matrix; index : integer) return std_logic_vector is
        variable res : std_logic_vector(arg'range(2));
    begin
        for i in arg'range(2) loop
            res(i) := arg(index, i);
        end loop;
        return res;
    end PROJECTION;

    function SUM(arg : integer_array) return integer is
        variable sum : integer;
    begin
        sum := 0;
        for i in arg'range loop
            sum := sum + arg(i);
        end loop;
        return sum;
    end SUM;

    function SUM(arg : integer_matrix) return integer_array is
        variable tsum : integer_array(arg'range(1));
    begin
        for i in arg'range(1) loop
            tsum(i) := SUM(PROJECTION(arg, i));
        end loop;
        return tsum;
    end SUM;

    function SUM_END(arg : integer_array; start : integer) return integer is
        variable sum : integer;
    begin
        sum := 0;
        for i in start to arg'high loop
            sum := sum + arg(i);
        end loop;
        return sum;
    end SUM_END;

--    function TOTAL_MEM(nr_bits : integer; nr_synapses : integer_array; refractoriness : boolean; refractory_width : integer) return integer is
    function TOTAL_MEM(nr_bits : integer; nr_synapses : integer_array; decay_shift : integer_matrix; refractoriness : boolean; refractory_width : integer) return integer is
        variable sum : integer;
    begin
        sum := 0;
        for i in nr_synapses'range loop -- for each neuron
            -- sum = nr_synapses(potential) + nr_synapses(decay) + threshold + reset potential
            sum := sum + nr_bits*(2+nr_synapses(i));
            -- linear decay : nr_bits extra
            for j in 0 to nr_synapses(i)-1 loop
        	    if decay_shift(i, j) = 0 then
	                sum := sum + nr_bits;
	            end if;
            end loop;
            if refractoriness = TRUE then
                sum := sum + 2*refractory_width;
            end if;
        end loop;
--	sum := 6*11*5;
	return sum;
    end TOTAL_MEM;

    function CURRENT_NR_WEIGHTS(nr_weights : integer_matrix; neuron_nr : integer) return integer is
        variable sum : integer;
    begin
        sum := 0;
        for j in nr_weights'range(2) loop
            -- stupid unecessary loop to make Xilinx happy...
            for i in nr_weights'range loop
				    if i = neuron_nr then
                    sum := sum + nr_weights(i, j);
				    end if;
            end loop;
        end loop;
        return sum;
    end CURRENT_NR_WEIGHTS;

    function MAXIMUM_NR_WEIGHTS(nr_weights : integer_matrix) return integer is
        variable sum, maximum : integer;
    begin
        maximum := 0;
        for i in nr_weights'range loop
            sum := 0;
            for j in nr_weights'range(2) loop
                sum := sum + nr_weights(i, j);
            end loop;
             if sum > maximum then
                 maximum := sum;
             end if;
        end loop;
        return maximum;
    end MAXIMUM_NR_WEIGHTS;

    function TOTAL_NR_WEIGHTS(nr_weights : integer_matrix) return integer is
        variable sum : integer;
    begin
        sum := 0;
        for i in nr_weights'range loop
            for j in nr_weights'range(2) loop
                sum := sum + nr_weights(i, j);
            end loop;
        end loop;
        return sum;
    end TOTAL_NR_WEIGHTS;

    function SYN_OFFSET(refr : boolean; offset : integer) return integer is
    begin
        if refr then
            return offset;
        else 
            return 0;
        end if;
    end SYN_OFFSET;

    function PIPELINE_DEPTH(nr_syn_models : integer; nr_synapses, nr_syn_taps : integer_array) return integer is
        variable depth : integer_array(nr_syn_models-1 downto 0);
    begin
        for i in nr_syn_models-1 downto 0 loop
            depth(i) := LOG2FLOOR(nr_syn_models*2-1-i);

            if nr_syn_taps(i) > 0 then
                depth(i) := depth(i)+1;
            end if;

            depth(i) := depth(i) + LOG2FLOOR(nr_synapses(i)*2-1);
        end loop;

        return MAXIMUM(depth);
    end PIPELINE_DEPTH;

end utility_package;

