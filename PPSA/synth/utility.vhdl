----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- This file contains several utility types and functions used by the framework.
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package utility_package is
    type integer_array is array (natural range <>) of integer;
    type integer_matrix is array (natural range <>, natural range <>) of integer;

    type std_logic_matrix is array (natural range <>, natural range <>) of std_logic;
    
    function LOG2FLOOR(input : integer) return integer;
    function LOG2CEIL(input : integer) return integer;
    function LOG2CEIL_VECT(arg : integer_array) return integer_array;

    function MAXIMUM(left, right : integer) return integer;
    function MAXIMUM(arg : integer_array) return integer;
    function MINIMUM(arg : integer_array) return integer;

    function JOIN_AND(arg : std_logic_vector) return std_logic;
    function JOIN_OR(arg : std_logic_vector) return std_logic;

    function PROJECTION(arg : integer_matrix; index : integer) return integer_array;
    function PROJECTION(arg : std_logic_matrix; index : integer) return std_logic_vector;

    function SUM(arg : integer_array) return integer;
    function SUM(arg : integer_matrix) return integer_array;
    function SUM_END(arg : integer_array; start : integer) return integer;

    function PIPELINE_DEPTH(nr_syn_models : integer; nr_synapses, nr_syn_taps : integer_array) return integer;

    function GEN_SYNAPSE_WEIGHT_MAP(nr_neurons : integer; nr_syn_models : integer; synapse_map : integer_matrix) return integer_matrix;
    function GEN_NR_NEURON_INPUTS(nr_neurons : integer; synapse_map : integer_matrix) return integer_array;

    function REVERSE(arg : std_logic_vector) return std_logic_vector;
    function REVERSE(arg : bit_vector) return bit_vector;
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
        elsif (input >   128) then result :=  7;
        elsif (input >    64) then result :=  7;
        elsif (input >    32) then result :=  6;
        elsif (input >    16) then result :=  5;
        elsif (input >     8) then result :=  4;
        elsif (input >     4) then result :=  3;
        elsif (input >     2) then result :=  2;
        elsif (input >     1) then result :=  1;
        else                       result :=  0;
        end if;
        return result;
    end LOG2CEIL;

    function LOG2CEIL_VECT(arg : integer_array) return integer_array is
        variable result : integer_array(arg'range);
        variable i : integer;
    begin
        i := arg'low;
        while i <= arg'high loop
            result(i) := LOG2CEIL(arg(i));
            i := i + 1;
        end loop;
        return result;
    end LOG2CEIL_VECT;
    
    function MAXIMUM(left, right : integer) return integer is
    begin
        if left > right then 
            return left;
        else 
            return right;
        end if;
    end MAXIMUM;

    function MAXIMUM(arg : integer_array) return integer is
        variable max : integer;
        variable i : integer;
    begin
        max := arg(0);
        --for i in arg'range loop
        --    if arg(i) > max then
        --        max := arg(i);
        --    end if;
        --end loop;
        i := arg'low;
        while i <= arg'high loop
            if arg(i) > max then
                max := arg(i);
            end if;
            i := i + 1;
        end loop;
        return max;
    end MAXIMUM;
    
    function MINIMUM(arg : integer_array) return integer is
        variable min : integer;
        variable i : integer;
    begin
        min := arg(0);
        --for i in arg'range loop
        --    if arg(i) < min then
        --        min := arg(i);
        --    end if;
        --end loop;
        i := arg'low;
        while i <= arg'high loop
            if arg(i) < min then
                min := arg(i);
            end if;
            i := i + 1;
        end loop;
        return min;
    end MINIMUM;
    
    function JOIN_AND(arg : std_logic_vector) return std_logic is
        variable result : std_logic;
        variable i : integer;
    begin
        result := '1';
        --for i in arg'range loop
        --    result := result and arg(i);
        --end loop;
        i := arg'low;
        while i <= arg'high loop
            result := result and arg(i);
            i := i + 1;
        end loop;
        return result;
    end JOIN_AND;

    function JOIN_OR(arg : std_logic_vector) return std_logic is
        variable result : std_logic;
        variable i : integer;
    begin
        result := '0';
        --for i in arg'range loop
        --    result := result or arg(i);
        --end loop;
        i := arg'low;
        while i <= arg'high loop
            result := result or arg(i);
            i := i + 1;
        end loop;
        return result;
    end JOIN_OR;

    function PROJECTION(arg : integer_matrix; index : integer) return integer_array is
        variable res : integer_array(arg'range(2));
        variable i : integer;
    begin
        --for i in arg'range(2) loop
        --    res(i) := arg(index, i);
        --end loop;
        i := arg'low(2);
        while i <= arg'high(2) loop
            res(i) := arg(index, i);
            i := i + 1;
        end loop;
        return res;
    end PROJECTION;
    
    function PROJECTION(arg : std_logic_matrix; index : integer) return std_logic_vector is
        variable res : std_logic_vector(arg'range(2));
        variable i : integer;
    begin
        --for i in arg'range(2) loop
        --    res(i) := arg(index, i);
        --end loop;
        i := arg'low(2);
        while i <= arg'high(2) loop
            res(i) := arg(index, i);
            i := i + 1;
        end loop;
        return res;
    end PROJECTION;
    
    function SUM(arg : integer_array) return integer is
        variable sum : integer;
        variable i : integer;
    begin
        sum := 0;
        --for i in arg'range loop
        --    sum := sum + arg(i);
        --end loop;
        i := arg'low;
        while i <= arg'high loop
            sum := sum + arg(i);
            i := i + 1;
        end loop;
        return sum;
    end SUM;
    
    function SUM(arg : integer_matrix) return integer_array is
        variable tsum : integer_array(arg'range(1));
        variable i, j : integer;
    begin
        --for i in arg'range(1) loop
        --    tsum(i) := SUM(PROJECTION(arg, i));
        --end loop;
        i := arg'low(1);
        while i <= arg'high(1) loop
            j := arg'low(2);
            tsum(i) := 0;
            while j <= arg'high(2) loop
                tsum(i) := arg(i,j);
                j := j + 1;
            end loop;
            i := i + 1;
        end loop;
        return tsum;
    end SUM;
    
    function SUM_END(arg : integer_array; start : integer) return integer is
        variable sum : integer;
        variable i : integer;
    begin
        sum := 0;
        --if start <= arg'high then
        --    for i in start to arg'high loop
        --        sum := sum + arg(i);
        --    end loop;
        --end if;
        i := start;
        if start <= arg'high then
            while i <= arg'high loop
                sum := sum + arg(i);
                i := i + 1;
            end loop;
        end if;
        return sum;
    end SUM_END;
    
    function PIPELINE_DEPTH(nr_syn_models : integer; nr_synapses, nr_syn_taps : integer_array) return integer is
        variable depth : integer_array(nr_syn_models-1 downto 0);
        variable i : integer;
    begin
        --for i in nr_syn_models-1 downto 0 loop
        --    depth(i) := LOG2FLOOR(nr_syn_models*2-1-i);
        --    
        --    if nr_syn_taps(i) > 0 then
        --        depth(i) := depth(i)+1;
        --    end if;

        --    depth(i) := depth(i) + LOG2FLOOR(nr_synapses(i)*2-1);
        --end loop;

        i := nr_syn_models-1;
        while i >= 0 loop
            depth(i) := LOG2FLOOR(nr_syn_models*2-1-i);
            
            if nr_syn_taps(i) > 0 then
                depth(i) := depth(i)+1;
            end if;

            depth(i) := depth(i) + LOG2FLOOR(nr_synapses(i)*2-1);
            i := i - 1;
        end loop;
        
        return MAXIMUM(depth);
    end PIPELINE_DEPTH;

    function GEN_SYNAPSE_WEIGHT_MAP(nr_neurons : integer; nr_syn_models : integer; synapse_map : integer_matrix) return integer_matrix is
        variable res : integer_matrix(0 to nr_neurons-1, 0 to nr_syn_models-1);
        variable i,j : integer;
        variable temp : integer_array(0 to nr_syn_models-1);
    begin
        --for i in 0 to nr_neurons-1 loop
        --    for j in 0 to nr_syn_models-1 loop
        --        res(i,j) := SUM_END(PROJECTION(synapse_map,i), j+1);
        --    end loop;
        --end loop;
        i := 0;
        while i <= nr_neurons-1 loop
            j := 0;
            temp := PROJECTION(synapse_map,i);
            while j <= nr_syn_models-1 loop
                res(i,j) := SUM_END(temp, j+1);
                j := j + 1;
            end loop;
            i := i + 1;
        end loop;
        return res;
    end function;
    
    function GEN_NR_NEURON_INPUTS(nr_neurons : integer; synapse_map : integer_matrix) return integer_array is
        variable res : integer_array(0 to nr_neurons-1);
        variable i : integer;
    begin
        --for i in 0 to nr_neurons-1 loop
        --    res(i) := SUM(PROJECTION(synapse_map,i));
        --end loop;
        i := 0;
        while i <= nr_neurons-1 loop
            res(i) := SUM(PROJECTION(synapse_map,i));
            i := i + 1;
        end loop;
        return res;
    end function;
    
    function REVERSE(arg : std_logic_vector) return std_logic_vector is
        variable res : std_logic_vector(arg'range);
    begin
        for i in arg'range loop
            res(-i+arg'low+arg'high) := arg(i);
        end loop;
        return res;
    end REVERSE;

    function REVERSE(arg : bit_vector) return bit_vector is
        variable res : bit_vector(arg'range);
    begin
        for i in arg'range loop
            res(-i+arg'low+arg'high) := arg(i);
        end loop;
        return res;
    end REVERSE;
end utility_package;

