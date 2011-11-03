-------------------------------------------------------------------------------
-- Hardware Spike train Encoders and Decoders
--
-- Inter Spike Interval Encoder
--
-- authors    : Benjamin Schrauwen
-- created    : 2005/07/08
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity isi_encoder is
generic(
    INPUT_WIDTH  : integer;
    BIN_SIZE      : integer
    );
port(
    clk           :  in std_logic;
    reset         :  in std_logic;
        
    analog_input  :  in std_logic_vector(INPUT_WIDTH-1 downto 0);
    spike_output  : out std_logic
    );
end isi_encoder;

architecture impl of isi_encoder is
    signal timing_counter : std_logic_vector(INPUT_WIDTH-1 downto 0); 
begin
    process(reset, clk)
    begin
        if reset = '1' then
            timing_counter <= (others => '0');
        elsif clk'event and clk = '1' then
            if timing_counter = (others => '0') then
                spike_output <= '1';
                timing_counter <= analog_input;
            else
                spike_output <= '0';
                timing_counter <= timing_counter - 1;
            end if;
        end if;
    end process;
end impl;

