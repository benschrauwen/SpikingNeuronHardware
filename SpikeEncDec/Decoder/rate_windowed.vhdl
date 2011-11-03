-------------------------------------------------------------------------------
-- Hardware Spike train Encoders and Decoders
--
-- Windowed rate decoding
--
-- authors    : Benjamin Schrauwen
-- created    : 2005/07/08
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity rate_windowed is
generic(
    OUTPUT_WIDTH  : integer;
    WINDOW_SIZE   : integer
    );
port(
    clk           :  in std_logic;
    reset         :  in std_logic;
        
    spike_input   :  in std_logic;
    analog_output : out std_logic_vector(OUTPUT_WIDTH-1 downto 0)
    );
end rate_windowed;

architecture impl of rate_windowed is
    signal spike_counter : std_logic_vector(OUTPUT_WIDTH-1 downto 0); 
    signal spike_window  : std_logic_vector(WINDOW_SIZE-1 downto 0);
begin
    process(clk)
    begin
        if clk'event and clk = '1' then
            spike_window <= spike_window(WINDOW_SIZE-2 downto 0) & spike_input;
        end if;
    end process;

    process(reset, clk)
    begin
        if reset = '1' then
            spike_counter <= (others => '0');
        elsif clk'event and clk = '1' then
            if spike_window(WINDOW_SIZE-1) = '1' then
                spike_counter <= spike_counter - not spike_input;
            elsif spike_window(WINDOW_SIZE-1) = '0' then
                spike_counter <= spike_counter + spike_input;
            end if;
        end if;
    end process;

    analog_output <= output_buffer;
end impl;
