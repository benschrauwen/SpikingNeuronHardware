-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Absolute refractory block
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
-- created : 2005/03/03
-- version 3
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use work.neuron_config_package.MEMBRANE_WIDTH;

entity abs_refractory is
generic(
    COMPARE_VALUE  : integer := 0
    );
port(
    clk             :  in std_logic;
    reset           :  in std_logic;

    end_membr_decay :  in std_logic;
    
    spike_out       :  in std_logic;
    adder           :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);

    ASP_enable      : out std_logic;            -- enabling this signal will write ASP in registers
    refract         : out std_logic             
);
end abs_refractory;

--------------------------------------------------------------------------------

architecture no_refr of abs_refractory is
begin
    refract <= '0';
    ASP_enable   <= spike_out and end_membr_decay;
end no_refr;

--------------------------------------------------------------------------------

architecture membr_compared of abs_refractory is
    signal refract_period_ff : std_logic;
    signal compare_adder     : std_logic;
begin
    compare_adder <= '1' when conv_integer(adder) < COMPARE_VALUE else '0';

    process(reset, clk)
    begin
        if reset = '1' then
            refract_period_ff <= '0';
        elsif rising_edge(clk) then
            if end_membr_decay = '1' then
              if spike_out = '1' then
                refract_period_ff <= '1';
              else  
                refract_period_ff <= refract_period_ff and compare_adder;
              end if;
            end if;
        end if;
    end process;

    refract    <= refract_period_ff;
    ASP_enable <= spike_out and end_membr_decay;
end membr_compared;

--------------------------------------------------------------------------------
-- this is optimization of compared for negative values
-- TODO: test if this is not done automatically by the synthesizer?

architecture membr_neg of abs_refractory is
    signal refract_period_ff : std_logic;
    signal compare_adder     : std_logic;
begin
    compare_adder <= adder(MEMBRANE_WIDTH-1);

    process(reset, clk)
    begin
        if reset = '1' then
            refract_period_ff <= '0';
        elsif rising_edge(clk) then
            if end_membr_decay = '1' then
              if spike_out = '1' then
                refract_period_ff <= '1';
              else  
                refract_period_ff <= refract_period_ff and compare_adder;
              end if;
            end if;
        end if;
    end process;

    refract    <= refract_period_ff;
    ASP_enable <= spike_out and end_membr_decay;
end membr_neg;

