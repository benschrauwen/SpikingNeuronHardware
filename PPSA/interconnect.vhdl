----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Parallel Processing and Serial Arithmatic
--
-- The interconnect module generates direct interconnections between neuron outputs,
-- neuron inputs, networks inputs and network outputs. All can be configured via generic
-- connection_from matrix and output_nodes array. The connection from matrix must hold 
-- one row per neuron, holding positive values for connections to neurons, and negative
-- values for connections to input nodes (0 is no connection). The connection order is 
-- respected.
--
-- authors : Benjamin Schrauwen, Jan Van Campenhout
----------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.utility_package.all;

entity interconnect is
generic (
    NR_NEURONS          : integer;
    NR_INPUT_NODES      : integer;
    NR_NEURON_INPUTS    : integer_array;
    CONN_FROM           : integer_matrix;

    NR_OUTPUT_NODES     : integer;
    OUTPUT_NODES        : integer_array
);
port(
    neuron_outputs      :  in std_logic_vector(NR_NEURONS-1 downto 0);
    neuron_inputs       : out std_logic_matrix(NR_NEURONS-1 downto 0, MAXIMUM(NR_NEURON_INPUTS)-1 downto 0);
    inputs              :  in std_logic_vector(NR_INPUT_NODES-1 downto 0);
    outputs             : out std_logic_vector(NR_OUTPUT_NODES-1 downto 0)
);
end interconnect;

architecture structure of interconnect is
begin
    internal_gen : for i in NR_NEURONS-1 downto 0 generate
        internal_connections: for j in 0 to NR_NEURON_INPUTS(i)-1 generate
            input_connection: if CONN_FROM(i, j) < 0 generate
               neuron_inputs(i, j) <= inputs(-CONN_FROM(i, j) - 1);
            end generate;

            internal_connection: if CONN_FROM(i, j) > 0 generate
               neuron_inputs(i, j) <= neuron_outputs(CONN_FROM(i, j) - 1);
            end generate;
        end generate;
    end generate;
    
    output_gen : for i in NR_OUTPUT_NODES-1 downto 0 generate
        input_connection: if OUTPUT_NODES(i) < 0 generate
            outputs(i) <= inputs(-OUTPUT_NODES(i) - 1);
        end generate;
        
        internal_connection: if OUTPUT_NODES(i) > 0 generate
            outputs(i) <= neuron_outputs(OUTPUT_NODES(i) - 1);
        end generate;
    end generate;
end structure;

