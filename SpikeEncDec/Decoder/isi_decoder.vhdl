-------------------------------------------------------------------------------
-- Hardware Spike train Encoders and Decoders
--
-- Inter Spike Interval decoding
--
-- authors    : Benjamin Schrauwen
-- created    : 2005/07/08
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity isi_decoder is
generic(
    OUTPUT_WIDTH  : integer
    );
port(
    clk           :  in std_logic;
    reset         :  in std_logic;
        
    spike_input   :  in std_logic;
    analog_output : out std_logic_vector(OUTPUT_WIDTH-1 downto 0)
    );
end isi_decoder;

architecture impl of isi_decoder is
    signal output_buffer : std_logic_vector(OUTPUT_WIDTH-1 downto 0); 
    signal time_counter  : std_logic_vector(OUTPUT_WIDTH-1 downto 0); 
begin
    process(reset, clk)
    begin
        if reset = '1' then
            output_buffer <= (others => '0');
            time_counter <= (others => '0');
        elsif clk'event and clk = '1' then
            if spike_input = '1' then
                output_buffer <= time_counter;
                time_counter <= (others => '0');
            else
                output_buffer <= output_buffer;
                if spike_counter = (others => '1') then
                    spike_counter <= spike_counter;
                else
                    spike_counter <= spike_counter + 1;
                end if;
            end if;
        end if;
    end process;

    analog_output <= output_buffer;
end impl;

