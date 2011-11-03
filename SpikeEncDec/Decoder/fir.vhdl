-------------------------------------------------------------------------------
-- Hardware Spike train Encoders and Decoders
--
-- FIR filter decoding
--
-- authors    : Benjamin Schrauwen
-- created    : 2005/07/08
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity fir is
generic(
    OUTPUT_WIDTH  : integer;
    WINDOW_SIZE   : integer
    );
port(
    clk           :  in std_logic;
    slow_clk      :  in std_logic;
    reset         :  in std_logic;
    counter       :  in std_logic_vector();
        
    spike_input   :  in std_logic;
    analog_output : out std_logic_vector(OUTPUT_WIDTH-1 downto 0)
    );
end fir;

architecture impl of fir is
    type integer_array is array (natural range <>) of integer;
    constant fir_constants : integer_array(WINDOW_SIZE-1 downto 0) := (1, 2, 3, 4, 5, 6);

    signal output_buffer : std_logic_vector(OUTPUT_WIDTH-1 downto 0); 
    signal accumulator   : std_logic_vector(OUTPUT_WIDTH-1 downto 0); 
    signal spike_window  : std_logic_vector(OUTPUT_WIDTH-1 downto 0); 
begin
    process(slow_clk)
    begin
        if slow_clk'event and slow_clk = '1' then
            spike_window <= spike_window(WINDOW_SIZE-2 downto 0) & spike_input;
        end if;
    end process;

    temp <= spike_window(counter) & conv_std_logic_vector(fir_constants(counter), OUTPUT_WIDTH);

    process(reset, clk)
    begin
        if reset = '1' then
            output_buffer <= (others => '0');
            accumulator <= (others => '0');
        elsif clk'event and clk = '1' then
            if counter = (others => '0') then           -- maybe use slow_clk = '1' ?
                accumulator <= temp;
                output_buffer <= accumulator;
            else
                accumulator <= accumulator + temp;
                output_buffer <= output_buffer;
            end if;
        end if;
    end process;

    analog_output <= output_buffer;
end impl;

