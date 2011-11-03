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
    DOS_SHIFT          : integer;
    FIXED_WEIGHT       : integer;
    FIXED_DECAY        : integer
    );
port(
    start          :  in std_logic;
    ctr            :  in std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);

    input          :  in std_logic_vector(N-1 downto 0);
    input_enable   :  in std_logic;
    membr_pot_buff :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    accum          :  in std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    weight         :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);
    
    carry          : out std_logic;
    add_2          : out std_logic_vector(MEMBRANE_WIDTH-1 downto 0)
    );
end value_selection;

--------------------------------------------------------------------------------

architecture linear_decay of value_selection is
    signal input_temp : std_logic_vector(N-1 downto 0);
    signal internal_input : std_logic_vector(2+N-1 downto 0);
    signal sign_ff : std_logic;
begin
    carry          <= '0';

    input_temp     <= input when input_enable = '1' else (others => '0');
    internal_input <= input_temp & accum(MEMBRANE_WIDTH-1) & not accum(MEMBRANE_WIDTH-1);
    
    add_2          <= conv_std_logic_vector(conv_integer(weight), MEMBRANE_WIDTH) when internal_input(conv_integer("0" & ctr)) = '1' else conv_std_logic_vector(0, MEMBRANE_WIDTH);
end linear_decay;

--------------------------------------------------------------------------------

architecture sos_mem_decay of value_selection is
   signal input_temp : std_logic_vector(N-1 downto 0);
   signal internal_input : std_logic_vector(MEMBRANE_WIDTH+N-2 downto 0);
begin
   carry          <= '0';

   input_temp     <= input when input_enable = '1' else (others => '0');
   internal_input <= input_temp & membr_pot_buff(MEMBRANE_WIDTH-1 downto 1);
    
   add_2          <= conv_std_logic_vector(conv_integer(weight), MEMBRANE_WIDTH) when internal_input(conv_integer("0" & ctr)) = '1' else (others => '0');
end sos_mem_decay;

--------------------------------------------------------------------------------

architecture dos_hard_decay of value_selection is
    signal internal_input : std_logic_vector(1+N-1 downto 0);
    signal shifted_membr  : std_logic_vector(MEMBRANE_WIDTH-1 downto 0);
    signal weight_input   : std_logic_vector(WEIGHT_WIDTH-1 downto 0);
    signal sign_extend    : std_logic_vector(DOS_SHIFT-1 downto 0);
begin
    carry          <= accum(MEMBRANE_WIDTH-1) when start = '1' else '0';
    internal_input <= input & '0';

    weight_input   <= weight when input_enable = '1' and internal_input(conv_integer("0" & ctr)) = '1' else (others => '0');
    sign_extend    <= (others => accum(MEMBRANE_WIDTH-1));
    shifted_membr  <= not (sign_extend & accum(MEMBRANE_WIDTH-1 downto DOS_SHIFT));
    
    add_2          <= shifted_membr when start = '1' else conv_std_logic_vector(conv_integer(weight_input), MEMBRANE_WIDTH);
end dos_hard_decay;

--------------------------------------------------------------------------------

-- WEIGHT_WIDTH must be = 0 and weight vector now stands for sign of weight
architecture fixed_weight of value_selection is
    signal internal_input_enabled : std_logic;
    signal internal_input : std_logic_vector(1+N-1 downto 0);
begin
   carry          <= '0';

   internal_input <= input & '0';
   internal_input_enabled <= internal_input(conv_integer("0" & ctr)) and input_enable;
    
   add_2 <= conv_std_logic_vector(-FIXED_DECAY, MEMBRANE_WIDTH)  when (start and not internal_input_enabled and not accum(MEMBRANE_WIDTH-1)) = '1' else
            conv_std_logic_vector( FIXED_DECAY, MEMBRANE_WIDTH)  when (start and not internal_input_enabled and accum(MEMBRANE_WIDTH-1)) = '1' else
            conv_std_logic_vector( FIXED_WEIGHT, MEMBRANE_WIDTH) when (internal_input_enabled and not start and weight(0)) = '1' else 
            conv_std_logic_vector(-FIXED_WEIGHT, MEMBRANE_WIDTH) when (internal_input_enabled and not start and not weight(0)) = '1' else
            (others => '0');
end fixed_weight;


