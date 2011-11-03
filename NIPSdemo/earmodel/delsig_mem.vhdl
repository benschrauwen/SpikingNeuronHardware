-------------------------------------------------------------------------------
-- Hardware Spike train Encoders and Decoders using memory
--
-- First Order Delta-Sigma Encoder
--
-- authors    : Benjamin Schrauwen and Michiel D'Haene
-- created    : 2006/11/23
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.utility_package.log2ceil;

entity delsig_mem is
generic (
    INPUT_WIDTH     : integer;
    ADDRESS_WIDTH   : integer;
    NB_INSTANCES    : integer
);
port(
    clk             :  in std_logic;
    clk_enable      :  in std_logic;
    write_enable    :  in std_logic;
    address_in      :  in std_logic_vector (ADDRESS_WIDTH-1 downto 0);

    analog_input    :  in std_logic_vector (INPUT_WIDTH-1 downto 0); -- this is a signed integer !!
    spike_output    : out std_logic
);
end delsig_mem;


architecture impl of delsig_mem is
    constant zeros  : std_logic_vector (INPUT_WIDTH-2 downto 0) := (others=>'0');
    signal data_in  : std_logic_vector (INPUT_WIDTH downto 0); -- Error accumulator is 2 bits larger
    signal data_out : std_logic_vector (INPUT_WIDTH downto 0); -- Error accumulator is 2 bits larger
    signal val      : std_logic_vector (INPUT_WIDTH downto 0);
 
begin
    delsig_mem: entity work.oneport_mem
        generic map(
            DATA_WIDTH    => INPUT_WIDTH+1,
            ADDRESS_WIDTH => LOG2CEIL(NB_INSTANCES),
            MEMORY_AMOUNT => NB_INSTANCES
        )
        port map(
            clk      => clk,
            ce       => clk_enable,
            we       => write_enable,
            address  => address_in,
            d        => data_in,
            q        => data_out
        );

    val          <= signed((analog_input(analog_input'high) & analog_input)) + signed(data_in);
    spike_output <= '1'                                when val(val'high) = '0' else '0';
    data_out     <= signed(val) + signed("11" & zeros) when val(val'high) = '0' else signed(val) + signed("01" & zeros);
end impl;

