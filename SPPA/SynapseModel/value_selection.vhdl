-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- Value selection block
--
-- auteurs    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- aangemaakt : 2005/03/04
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity value_selection is
generic(
    N                  : integer;
    NEURON_STATE_WIDTH : integer;
    MEMBRANE_WIDTH     : integer;
    WEIGHT_WIDTH       : integer;
    DOS_SHIFT1         : integer;
    DOS_SHIFT2         : integer
    );
port(
    ctr            :  in std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);
    start_syn      :  in std_logic;
    start_membr    :  in std_logic;
    stop_membr     :  in std_logic;

    input          :  in std_logic_vector(N-1 downto 0);
    reg_bank       :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    accum          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    weight         :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);

    carry          : out std_logic;
    add_2          : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
    );
end value_selection;

--------------------------------------------------------------------------------

architecture linear_decay of value_selection is
    signal internal_input : std_logic_vector(5+N-1 downto 0);
    signal weight_out : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
begin
    carry          <= '0';

    internal_input <= accum(MEMBRANE_WIDTH-1) & (not accum(MEMBRANE_WIDTH-1)) & '0' & input & accum(MEMBRANE_WIDTH-1) & (not reg_bank(MEMBRANE_WIDTH-1));
    weight_out     <= weight when internal_input(conv_integer("0" & ctr)) = '1' else (others => '0');
    add_2          <= reg_bank when start_membr = '1' else weight_out;
end linear_decay;

--------------------------------------------------------------------------------

architecture sos_mem_decay of value_selection is
    signal internal_input : std_logic_vector(2*(MEMBRANE_WIDTH-1)+N-1 downto 0);
begin
    carry          <= '0';

    internal_input <= reg_bank(MEMBRANE_WIDTH-1 downto 1) & input & reg_bank(MEMBRANE_WIDTH-1 downto 1);
    add_2          <= weight when internal_input(conv_integer("0" & ctr)) = '1' else (others => '0');
end sos_mem_decay;

--------------------------------------------------------------------------------

architecture dos_hard_decay of value_selection is
    signal internal_input : std_logic_vector(3+N-1 downto 0);
    signal shifted_reg1   : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal shifted_reg2   : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal weight_input   : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal sign_extend    : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal add            : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
begin
    carry          <= reg_bank(MEMBRANE_WIDTH-1) when start_syn = '1' or stop_membr = '1' else '0';
    
    internal_input <= '0' & '0' & input & '0';

    sign_extend    <= (others => reg_bank(MEMBRANE_WIDTH-1));
    shifted_reg1   <= not (sign_extend(DOS_SHIFT1-1 downto 0) & reg_bank(MEMBRANE_WIDTH-1 downto DOS_SHIFT1));
    shifted_reg2   <= not (sign_extend(DOS_SHIFT2-1 downto 0) & reg_bank(MEMBRANE_WIDTH-1 downto DOS_SHIFT2));

    add_2 <=  weight when internal_input(conv_integer("0" & ctr)) = '1' else 
              reg_bank when (start_membr and not start_syn and not stop_membr) = '1' else
              shifted_reg1 when (not start_membr and start_syn and not stop_membr) = '1' else
              shifted_reg2 when (not start_membr and not start_syn and stop_membr) = '1' else
              (others => '0');
    
end dos_hard_decay;

--------------------------------------------------------------------------------
