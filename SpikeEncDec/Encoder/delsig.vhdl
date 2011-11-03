-------------------------------------------------------------------------------
-- Hardware Spike train Encoders and Decoders
--
-- First Order Delta-Sigma Encoder
--
-- authors    : Benjamin Schrauwen
-- created    : 2005/07/08
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity delsig is
generic (
    INPUT_WIDTH         : integer
);
port(
    clk                 :  in std_logic;
    reset               :  in std_logic;
    
    analog_input	:  in std_logic_vector (INPUT_WIDTH-1 downto 0); -- this is a signed integer !!
    spike_output	: out std_logic
);
end delsig;


architecture impl of dac_ds is
    constant zeros      : std_logic_vector (INPUT_WIDTH-1 downto 0) := (others=>'0');
    signal error        : std_logic_vector (INPUT_WIDTH+1 downto 0); -- Error accumulator is 2 bits larger
begin
    process (reset, clk)
        variable val    : std_logic_vector (INPUT_WIDTH+1 downto 0);
    begin
        if reset = '1' then
            error <= (others=>'0');
            dout <= '0';
        elsif clk'event and clk='1' then
            val := (din(din'high) & din(din'high) & din) + error;
            if val(val'high) = '0' then
                dout <= '1';
                error <= val + ("11" & zeros);
            else
                dout <= '0';
                error <= val + ("01" & zeros);
            end if;
        end if;
    end process;
end impl;

