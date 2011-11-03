-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Main neuron controller
--
-- auteurs    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- aangemaakt : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity controller is
generic (
    NEURON_STATE_WIDTH : integer;
    NR_STATES          : integer
    );
        
port(
    clk            :  in std_logic;
    reset          :  in std_logic;
    enable         :  in std_logic;
       
    start          : out std_logic;
    stop           : out std_logic;        
    ctr            : out std_logic_vector(NEURON_STATE_WIDTH-1 downto 0)
    );
end controller;

--------------------------------------------------------------------------------

architecture impl of controller is
    signal counter : std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);
    signal start_s : std_logic;
    signal stop_s  : std_logic;
begin
    process(reset, clk)
    begin
        if reset = '1' then --reset to last state -> first state after reset
            counter <= (conv_std_logic_vector(NR_STATES-1,NEURON_STATE_WIDTH));
            start_s <= '1';
            stop_s  <= '0';
        elsif (clk'event and clk = '1') then
            if enable = '1' then
                if counter = NR_STATES-1 then
                    counter <= (others => '0');
                    start_s <= '1';
                else
                    counter <= counter + 1;
                    start_s <= '0';
                end if;
                if counter = NR_STATES-2 then
                    stop_s  <= '1';
                else stop_s <= '0';
                end if;
            else
                counter <= counter;
                start_s <= start_s;
                stop_s  <= stop_s;
            end if;
        end if;
    end process;

    ctr     <= counter;
    stop    <= stop_s;
    start   <= start_s;
end impl;

