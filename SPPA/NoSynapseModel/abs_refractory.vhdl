-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Absolute refractory block
--
-- authors    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- created    : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity abs_refractory is
generic(
    MEMBRANE_WIDTH : integer;
    COMPARE_VALUE  : integer := 0;
    COUNTER_WIDTH  : integer := 0;
    COUNTER_VALUE  : integer := 0
    );
port(
    reset          :  in std_logic;
    clk            :  in std_logic;
    start          :  in std_logic;
    stop           :  in std_logic;    
    
    spike_out      :  in std_logic;
    accum          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    membr_pot_buff :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    
    ASP_enable     : out std_logic;
    input_enable   : out std_logic
    );
end abs_refractory;

--------------------------------------------------------------------------------

architecture no of abs_refractory is
begin
    input_enable <= '1';
    ASP_enable   <= spike_out and start;
end no;

--------------------------------------------------------------------------------

architecture one_clk of abs_refractory is
begin
    input_enable <= '1';
    ASP_enable   <= spike_out;
end one_clk;

--------------------------------------------------------------------------------

architecture one_clk_and_acc_neg of abs_refractory is
begin
    input_enable <= not membr_pot_buff(MEMBRANE_WIDTH-1);
    ASP_enable   <= spike_out;
end one_clk_and_acc_neg;

--------------------------------------------------------------------------------

architecture one_clk_and_acc_compared of abs_refractory is
    signal    refract_ff    : std_logic;
    signal compare_accum : std_logic;
begin
    process(reset, clk)
    begin
        if reset = '1' then
            refract_ff <= '0';
        elsif (clk'event and clk = '1') then
            -- store if current membrane potential < COMPARE_VALUE
            if stop = '1' then refract_ff <= compare_accum; end if;
        end if;
    end process;
    
    compare_accum <= '1' when conv_integer(accum) < COMPARE_VALUE else '0';
    input_enable  <= not refract_ff;
    ASP_enable    <= spike_out;
end one_clk_and_acc_compared;

--------------------------------------------------------------------------------

architecture counted of abs_refractory is
    signal    counter    : std_logic_vector(COUNTER_WIDTH-1 downto 0);
    signal refract_ff : std_logic;
begin
    process(reset, clk)
    begin
        if reset = '1' then
            counter    <= (others => '0');
            refract_ff <= '0';
        elsif (clk'event and clk = '1') then
           if stop = '1' then 
            counter    <= counter;
            refract_ff <= refract_ff;
            
            if spike_out = '1' then
                counter    <= (others => '0');
                refract_ff <= '1';
            elsif conv_integer(counter) = COUNTER_VALUE then
                refract_ff <= '0';
            elsif refract_ff = '1' then
                counter    <= counter + 1;
            end if;
         end if;
        end if;
    end process;
    
    input_enable <= not refract_ff;
    ASP_enable   <= refract_ff;
end counted;

