-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Value selection block
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
-- created : 2005/03/04
-- version 2
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use work.utility_package.all;
use work.neuron_config_package.all;
use work.settings_package.all;
use work.gen_settings_package.all;

entity value_selection is
generic(
    NEURON_NR      :  integer
    );
port(
    ctr            :  in std_logic_vector(STATE_WIDTH(NEURON_NR)-1 downto 0);
    start          :  in std_logic;
    decay_s        :  in std_logic;
    reg_select     :  in std_logic_vector(REG_WIDTH-1 downto 0);

    input          :  in std_logic_vector(NR_NEURON_INPUTS(NEURON_NR)-1 downto 0);
    reg_bank       :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    weight         :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);

    carry          : out std_logic;
    weight_out     : out std_logic_vector(WEIGHT_WIDTH-1 downto 0)
    );
end value_selection;

-- TODO: if serial inputs, do big parts of input mux get optimised out ??

--------------------------------------------------------------------------------
-- NR_DECAY_STATES must be = 1
-- needs reset block
architecture linear_decay_1clk of value_selection is
    signal internal_input : std_logic_vector(NR_NEURON_INPUTS(NEURON_NR)+NR_DECAY_STATES+(NR_DECAY_STATES+1)*NR_SYN-1 downto 0);
    signal sign_change    : std_logic;
    signal sign_change_vector : std_logic_vector(WEIGHT_WIDTH-1 downto 0);
begin
    carry <= sign_change;

    process(input)
        variable i,j,k : integer;
    begin
        internal_input(0) <= '1';
        internal_input(PROJECTION(SYNAPSE_MAP,NEURON_NR)(0) downto 1) <= input(PROJECTION(SYNAPSE_MAP,NEURON_NR)(0)-1 downto 0);
        j := PROJECTION(SYNAPSE_MAP,NEURON_NR)(0) + 1;
        k := PROJECTION(SYNAPSE_MAP,NEURON_NR)(0);
        for i in 1 to NR_SYN loop
            internal_input(j) <= '1';
            internal_input(j+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i) downto j+1) <= input(k+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)-1 downto k);
            internal_input(j+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)+1) <= '0';
            j := j+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)+2;
            k := k+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i);
        end loop;
    end process;
    
    sign_change <= start and reg_bank(MEMBRANE_WIDTH-1);
    sign_change_vector <= (others => sign_change);
    weight_out <= (weight xor sign_change_vector) when internal_input(conv_integer("0" & ctr)) = '1' else (others => '0');
end linear_decay_1clk;

--------------------------------------------------------------------------------
-- NR_DECAY_STATES must be = 2
-- needs reset block
architecture linear_decay_2clk of value_selection is
    signal internal_input : std_logic_vector(NR_NEURON_INPUTS(NEURON_NR)+NR_DECAY_STATES+(NR_DECAY_STATES+1)*NR_SYN-1 downto 0);
begin
    assert (NR_DECAY_STATES = 2)
        report "NR_DECAY_STATES must be 2"
        severity error;
        
    carry <= '0';

    process(input, reg_bank)
        variable i,j,k : integer;
    begin
        internal_input(NR_DECAY_STATES-1 downto 0) <= reg_bank(MEMBRANE_WIDTH-1) & not reg_bank(MEMBRANE_WIDTH-1);
        internal_input(NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(0)-1 downto NR_DECAY_STATES) <= input(PROJECTION(SYNAPSE_MAP,NEURON_NR)(0)-1 downto 0);
        j := NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(0);
        k := PROJECTION(SYNAPSE_MAP,NEURON_NR)(0);
        for i in 1 to NR_SYN loop
            internal_input(j+NR_DECAY_STATES-1 downto j) <= reg_bank(MEMBRANE_WIDTH-1) & not reg_bank(MEMBRANE_WIDTH-1);
            internal_input(j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)-1 downto j+NR_DECAY_STATES) <= input(k+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)-1 downto k);
            internal_input(j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)) <= '0';
            j := j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)+1;
            k := k+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i);
        end loop;
    end process;

    weight_out <= weight when internal_input(conv_integer("0" & ctr)) = '1' else (others => '0');
end linear_decay_2clk;

--------------------------------------------------------------------------------
-- NR_DECAY_STATES must be = 2 x nr linear decays
architecture linear_decay_mult of value_selection is
    signal internal_input : std_logic_vector(NR_NEURON_INPUTS(NEURON_NR)+NR_DECAY_STATES+(NR_DECAY_STATES+1)*NR_SYN-1 downto 0);
begin
    assert (NR_DECAY_STATES mod 2 = 0)
        report "NR_DECAY_STATES must be even"
        severity error;

    carry <= '0';

    process(input, reg_bank)
        variable i,j,k,l : integer;
    begin
        for l in 0 to NR_DECAY_STATES/2-1 loop
            internal_input(l*2) <= reg_bank(MEMBRANE_WIDTH-1);
            internal_input(l*2+1) <= not reg_bank(MEMBRANE_WIDTH-1);
        end loop;
        internal_input(NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(0)-1 downto NR_DECAY_STATES) <= input(PROJECTION(SYNAPSE_MAP,NEURON_NR)(0)-1 downto 0);
        j := NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(0);
        k := PROJECTION(SYNAPSE_MAP,NEURON_NR)(0);
        for i in 1 to NR_SYN loop
            for l in 0 to NR_DECAY_STATES/2-1 loop
                internal_input(j+l*2) <= reg_bank(MEMBRANE_WIDTH-1);
                internal_input(j+l*2+1) <= not reg_bank(MEMBRANE_WIDTH-1);
            end loop;
            internal_input(j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)-1 downto j+NR_DECAY_STATES) <= input(k+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)-1 downto k);
            internal_input(j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)) <= '0';
            j := j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)+1;
            k := k+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i);
        end loop;
    end process;

    weight_out <= weight when internal_input(conv_integer("0" & ctr)) = '1' else (others => '0');
end linear_decay_mult;

--------------------------------------------------------------------------------
-- NR_DECAY_STATES must be = MEMBRANE_WIDTH-2
-- needs buffered register bank
architecture mem_decay of value_selection is
    signal internal_input : std_logic_vector(NR_NEURON_INPUTS(NEURON_NR)+NR_DECAY_STATES+(NR_DECAY_STATES+1)*NR_SYN-1 downto 0);
    signal sign : std_logic;
begin
    carry <= weight(WEIGHT_WIDTH-1) and reg_bank(MEMBRANE_WIDTH-1) and decay_s;

    process(reg_bank, input)
        variable i,j,k : integer;
    begin
        internal_input(NR_DECAY_STATES-1 downto 0) <= REVERSE(reg_bank(MEMBRANE_WIDTH-1 downto 0));
        internal_input(NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(0)-1 downto NR_DECAY_STATES) <= input(PROJECTION(SYNAPSE_MAP,NEURON_NR)(0)-1 downto 0);
        j := NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(0);
        k := PROJECTION(SYNAPSE_MAP,NEURON_NR)(0);
        for i in 1 to NR_SYN loop
            internal_input(j+NR_DECAY_STATES-1 downto j) <= REVERSE(reg_bank(MEMBRANE_WIDTH-1 downto 0));
            internal_input(j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)-1 downto j+NR_DECAY_STATES) <= input(k+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)-1 downto k);
            internal_input(j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)) <= '0';
            j := j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)+1;
            k := k+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i);
        end loop;
    end process;

    sign <= ((not start and decay_s) or (weight(WEIGHT_WIDTH-1) and not decay_s));
    weight_out <= (sign & weight(WEIGHT_WIDTH-2 downto 0)) when internal_input(conv_integer("0" & ctr)) = '1' else (others => '0');     -- use last bit to store correction
    --weight_out <= weight(WEIGHT_WIDTH-2 downto 0) when internal_input(conv_integer("0" & ctr)) = '1' else (others => '0');              -- or use extra bit to store correction
end mem_decay;

--------------------------------------------------------------------------------
-- NR_DECAY_STATES must be = 1
architecture hard_decay of value_selection is
    signal internal_input : std_logic_vector(NR_NEURON_INPUTS(NEURON_NR)+NR_DECAY_STATES+(NR_DECAY_STATES+1)*NR_SYN-1 downto 0);
    signal weight_temp    : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal sign_extend    : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    type shifted_array is array (NR_SYN downto 0) of std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal shifted_reg    : shifted_array;
    signal correction     : std_logic;

    function join_and(arg: std_logic_vector) return std_logic is
        variable result : std_logic;
    begin
        result := '1';
        for i in arg'range loop
            result := result and arg(i);
        end loop;
        return result;
    end join_and;
begin
    -- TODO: check how costly this is, otherwise use fixed nr of bits
    correction <= join_and(not reg_bank(CALC_HARD_DECAY(DECAY(conv_integer("0" & reg_select)))-1 downto 0));
    carry <= (reg_bank(MEMBRANE_WIDTH-1) or correction) when start = '1' else '0';

    process(input)
        variable i,j,k : integer;
    begin
        internal_input(0) <= '1';
        internal_input(NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(0)-1 downto NR_DECAY_STATES) <= input(PROJECTION(SYNAPSE_MAP,NEURON_NR)(0)-1 downto 0);
        j := NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(0);
        k := PROJECTION(SYNAPSE_MAP,NEURON_NR)(0);
        for i in 1 to NR_SYN loop
            internal_input(j) <= '1';
            internal_input(j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)-1 downto j+NR_DECAY_STATES) <= input(k+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)-1 downto k);
            internal_input(j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)) <= '0';
            j := j+NR_DECAY_STATES+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i)+1;
            k := k+PROJECTION(SYNAPSE_MAP,NEURON_NR)(i);
        end loop;
    end process;

    -- TODO: implement barrel shifter and check if smaller
    sign_extend <= (others => reg_bank(MEMBRANE_WIDTH-1));
    process(sign_extend, reg_bank)
        variable i : integer;
    begin
        for i in 0 to NR_SYN loop
            shifted_reg(i) <= not (sign_extend(CALC_HARD_DECAY(DECAY(i))-1 downto 0) & reg_bank(MEMBRANE_WIDTH-1 downto CALC_HARD_DECAY(DECAY(i))));
        end loop;
    end process;

    weight_temp <= shifted_reg(conv_integer("0" & reg_select)) when (start = '1') else weight;
    weight_out <= weight_temp when internal_input(conv_integer("0" & ctr)) = '1' else (others => '0');
end hard_decay;

