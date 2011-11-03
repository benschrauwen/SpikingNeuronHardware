-------------------------------------------------------------------------------
-- Hardware Spike train Encoders and Decoders
--
-- Binned rate decoding
--
-- authors    : Benjamin Schrauwen
-- created    : 2005/07/08
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity rate_binned is
generic(
    OUTPUT_WIDTH  : integer;
    BIN_SIZE      : integer
    );
port(
    clk           :  in std_logic;
    reset         :  in std_logic;
        
    spike_input   :  in std_logic;
    analog_output : out std_logic_vector(OUTPUT_WIDTH-1 downto 0)
    );
end rate_binned;

architecture impl of rate_binned is
    signal output_buffer : std_logic_vector(OUTPUT_WIDTH-1 downto 0); 
    signal spike_counter : std_logic_vector(OUTPUT_WIDTH-1 downto 0); 
    signal bin_counter   : std_logic_vector(OUTPUT_WIDTH-1 downto 0); 
begin
    process(reset, clk)
    begin
        if reset = '1' then
            output_buffer <= (others => '0');
            bin_counter <= (others => '0');
            spike_counter <= (others => '0');
        elsif clk'event and clk = '1' then
            if bin_counter = BIN_SIZE then
                output_buffer <= spike_counter;
                spike_counter <= (others => '0') + spike_input;
                bin_counter <= (others => '0');
            else
                output_buffer <= output_buffer;
                spike_counter <= spike_counter + spike_input;
                bin_counter <= bin_counter + 1;
            end if;
        end if;
    end process;

    analog_output <= output_buffer;
end impl;

