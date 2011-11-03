----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- This block is the super compact neuron datapath
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity neuron_datapath is
port (
    clk         :  in std_logic;

    force_one   :  in std_logic;
    sel         :  in std_logic;

    fz_ce       :  in std_logic;
    reset_fz    :  in std_logic;

    neg_ce      :  in std_logic;
    set_neg     :  in std_logic;
    reset_neg   :  in std_logic;

    carry_ce    :  in std_logic;
    reset_carry :  in std_logic;
    sum_out     :  in std_logic;
    bypass      :  in std_logic;

    smm_in_1    :  in std_logic;
    smm_in_2    :  in std_logic;
    smm_out     : out std_logic;

    spike_in    :  in std_logic;
    spike_out   : out std_logic;
    weight_in   :  in std_logic
);
end neuron_datapath;

architecture structure of neuron_datapath is
    signal s_input, s_adder_input_2, s_adder_carry : std_logic;
    signal q_fz, q_neg, q_carry : std_logic;
begin
    -- 4 LUTs

    s_input         <= (spike_in and weight_in) when sel = '0' else smm_in_2;
    s_adder_input_2 <= '0' when q_fz = '1' else
                         '1' when force_one = '1' else
                           not s_input when q_neg = '1' else s_input;
    -- explicit adder-implementation with bypass-function
    smm_out         <= smm_in_1 xor s_adder_input_2 xor q_carry when bypass = '0' else
                         smm_in_1 when q_carry = '0' else s_adder_input_2;
    s_adder_carry   <= (smm_in_1 and s_adder_input_2) or (smm_in_1 and q_carry) or (s_adder_input_2 and q_carry) when sum_out = '0' 
		         else smm_in_1 xor s_adder_input_2 xor q_carry;

    spike_out       <= s_adder_carry;
    -- 3 FFs
    -- carry flip flop (FDRE-type)
    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset_carry = '1') then
                q_carry <= '0';
            elsif (carry_ce = '1') then
                q_carry <= s_adder_carry;
            end if;
        end if;
    end process;

    -- force zero flip flop (FDRE-type)
    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset_fz = '1') then
                q_fz <= '0';
            elsif (fz_ce = '1') then
                q_fz <= s_adder_carry;
            end if;
        end if;
    end process;

    -- select inverted input flip flop (FDRSE-type)
    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (reset_neg = '1') then
                q_neg <= '0';
            elsif (set_neg = '1') then
                q_neg <= '1';
            elsif (neg_ce = '1') then
                q_neg <= s_adder_carry;
            end if;
        end if;
    end process;

end structure;

