-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Main neuron controller
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
-- created : 2005/03/03
-- version 3
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use work.utility_package.all;
use work.settings_package.all;
use work.neuron_config_package.all;

entity controller is
generic(
    -- TODO, FIXME: this should be neuron dependant, or all neurons should be the same !!!
    NEURON_NR      : integer := 0
    );
port(
    clk            :  in std_logic;
    reset          :  in std_logic;
    enable         :  in std_logic;
        
    pre_ctr        : out std_logic_vector(STATE_WIDTH(NEURON_NR)-1 downto 0);
    ctr            : out std_logic_vector(STATE_WIDTH(NEURON_NR)-1 downto 0);
    reg_select     : out std_logic_vector(REG_WIDTH-1 downto 0);

    decay          : out std_logic;
    start          : out std_logic;
    write_membr    : out std_logic;
    membr_select   : out std_logic;
    stop_cycle     : out std_logic
    );
end controller;

architecture impl of controller is
    signal counter        : std_logic_vector(STATE_WIDTH(NEURON_NR)-1 downto 0);
    signal reg_select_s   : std_logic_vector(REG_WIDTH-1 downto 0);
    signal decay_s        : std_logic;
    signal start_s        : std_logic;
    signal stop_syn_s     : std_logic;
    signal membr_cycle_s1 : std_logic;
    signal membr_cycle_s2 : std_logic;

    function SYN_START(nr_inputs : integer_array(0 to NR_SYN); index : integer) return integer is
        variable result : integer := 0;
    begin
        result := 0;
        for i in 0 to index-1 loop
            result := result + NR_DECAY_STATES + nr_inputs(i);
            if (i /= 0) then result := result + 1; end if;
        end loop;
        return result;
    end SYN_START;
    
    function SYN_STOP(nr_inputs : integer_array(0 to NR_SYN); index : integer) return integer is
        variable result : integer;
    begin
        result := NR_DECAY_STATES + nr_inputs(0);
        for i in 1 to index loop
            result := result + NR_DECAY_STATES + nr_inputs(i) + 1;
        end loop;
        return result - 1;
    end SYN_STOP;
begin
    process(reset, clk)
    begin
        if reset = '1' then
            counter <= conv_std_logic_vector(0, STATE_WIDTH(NEURON_NR));
            reg_select_s <= (others => '0');
            start_s      <= '1';
            decay_s      <= '1';
            stop_syn_s   <= '0';
        elsif (clk'event and clk = '1') then
            if enable = '1' then
                start_s      <= '0';
                decay_s      <= decay_s;
                stop_syn_s   <= '0';
                reg_select_s <= reg_select_s;

                if counter = NR_STATES(NEURON_NR)-1 then
                    counter <= (others => '0');
                    start_s      <= '1';
                    decay_s      <= '1';
                    reg_select_s <= conv_std_logic_vector(0, REG_WIDTH);
                else
                    counter <= counter + 1;
                end if;

                for i in 0 to NR_SYN loop
                    if counter = SYN_START(PROJECTION(SYNAPSE_MAP,NEURON_NR), i)-1 then
                        start_s      <= '1';
                        decay_s      <= '1';
                        reg_select_s <= conv_std_logic_vector(i, REG_WIDTH);
                    elsif counter = SYN_START(PROJECTION(SYNAPSE_MAP,NEURON_NR), i)+NR_DECAY_STATES-1 then
                        decay_s      <= '0';
                    end if;
                    if counter = SYN_STOP(PROJECTION(SYNAPSE_MAP,NEURON_NR), i)-1 then
                        stop_syn_s   <= '1';
                    end if;
                end loop;
                
            end if;
        end if;
    end process;

    membr_cycle_s1 <= '1' when (conv_integer("0" & counter) < (NR_DECAY_STATES + PROJECTION(SYNAPSE_MAP,NEURON_NR)(0))) else '0';
    membr_cycle_s2 <= '0' when (conv_integer("0" & counter) < (NR_DECAY_STATES-1))  else membr_cycle_s1;

    -- delay all but pre_ctr which is used for clocked memory
    process(clk,reset)
    begin
        if reset = '1' then
            ctr <= conv_std_logic_vector(0, STATE_WIDTH(NEURON_NR));
            reg_select <= (others => '0');
            start      <= '1';
            decay      <= '1';
            write_membr<= '1';
            membr_select<= '0';
            stop_cycle <= '0';
        elsif rising_edge(clk) then
            write_membr    <= membr_cycle_s1 or stop_syn_s;
            membr_select   <= stop_syn_s and not membr_cycle_s1;
            if counter = NR_STATES(NEURON_NR)-1 then
                stop_cycle     <= '1';
            else
                stop_cycle     <= '0';
            end if;

            start          <= start_s;
            decay          <= decay_s;
            ctr            <= counter;
            reg_select     <= reg_select_s;
        end if;
    end process;
    
    pre_ctr <= counter;
end impl;

