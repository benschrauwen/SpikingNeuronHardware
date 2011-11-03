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
    REG_WIDTH          : integer;
    NR_STATES          : integer;
    NR_SYN_STATES      : integer
    );
port(
    clk              :  in std_logic;
    reset            :  in std_logic;
    enable           :  in std_logic;
    
    ctr              : out std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);
    reg_select       : out std_logic_vector(REG_WIDTH-1 downto 0);
    start_syn        : out std_logic;
    stop_syn         : out std_logic;
    start_membr      : out std_logic;
    stop_membr       : out std_logic
    );
end controller;

architecture impl of controller is
    signal counter       : std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);
    signal stop_syn_s    : std_logic;
    signal stop_membr_s  : std_logic;
    signal start_syn_s   : std_logic;
    signal start_membr_s : std_logic;
    signal reg_select_s  : std_logic_vector(REG_WIDTH-1 downto 0);
begin
    process(clk)
    begin
        if (clk'event and clk = '1') then
            if reset = '1' then
                counter       <= (conv_std_logic_vector(NR_STATES-1, NEURON_STATE_WIDTH));
                start_syn_s   <= '0';
                start_membr_s <= '0';
                stop_syn_s    <= '0';
                stop_membr_s  <= '1';
                reg_select_s  <= conv_std_logic_vector(0, REG_WIDTH);
            else
                counter       <= counter;
                stop_syn_s    <= stop_syn_s;
                stop_membr_s  <= stop_membr_s;
                start_membr_s <= start_membr_s;
                start_syn_s   <= start_syn_s;
                reg_select_s  <= reg_select_s;

                if enable = '1' then
                    if counter = NR_STATES-1 then
                        counter <= (others => '0');
                    else
                        counter <= counter + 1;
                    end if;

                    start_syn_s   <= '0';
                    start_membr_s <= '0';
                    stop_syn_s    <= '0';
                    stop_membr_s  <= '0';

                    if counter = conv_std_logic_vector(NR_STATES-1, NEURON_STATE_WIDTH) then
                        start_syn_s   <= '1';
                        reg_select_s  <= conv_std_logic_vector(1, REG_WIDTH);
                    elsif counter = conv_std_logic_vector(NR_SYN_STATES-2, NEURON_STATE_WIDTH) then
                        stop_syn_s    <= '1';
                    elsif counter = conv_std_logic_vector(NR_SYN_STATES-1, NEURON_STATE_WIDTH) then
                        start_membr_s <= '1';
                        reg_select_s  <= conv_std_logic_vector(0, REG_WIDTH);
                    elsif counter = conv_std_logic_vector(NR_STATES-2, NEURON_STATE_WIDTH) then
                        stop_membr_s  <= '1';
                    end if;
                end if;
            end if; 
        end if;
    end process;
      
    reg_select  <= reg_select_s;
    start_syn   <= start_syn_s;
    start_membr <= start_membr_s;
    stop_syn    <= stop_syn_s;
    stop_membr  <= stop_membr_s;
    ctr         <= counter;
end impl;
      
                                                                                                