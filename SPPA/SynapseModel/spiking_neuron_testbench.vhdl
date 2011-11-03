-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- testbench
--
-- authors    : Michiel D'Haene, Benjamin Schrauwen, David Verstraeten
-- created    : 2005/03/03
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity spiking_neuron_testbench is
generic (
    N                  : integer := 30;
    NEURON_STATE_WIDTH : integer :=  6;
    REG_WIDTH          : integer :=  1;
    WEIGHT_WIDTH       : integer :=  9
    );
end spiking_neuron_testbench;

architecture impl of spiking_neuron_testbench is

    component spiking_neuron
    generic(
        N                  : integer;
        NEURON_STATE_WIDTH : integer;
        REG_WIDTH          : integer;
        WEIGHT_WIDTH       : integer
        );
    port(
        clk            :  in std_logic;
        reset          :  in std_logic;
        ctr            :  in std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);	
        reg_select     :  in std_logic_vector(REG_WIDTH-1 downto 0);	
        start_syn      :  in std_logic;
        start_membr    :  in std_logic;
        stop_syn       :  in std_logic;
        stop_membr     :  in std_logic;
        we             :  in std_logic;
        weight_ext     :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);
        input          :  in std_logic_vector(N-1 downto 0);
        output         : out std_logic        
        );
    end component;

    component controller
    generic (
        NEURON_STATE_WIDTH : integer;
        REG_WIDTH          : integer
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
    end component;
    
    signal clk_s, reset_s, start_syn_s, start_membr_s, stop_syn_s, stop_membr_s : std_logic;
    signal ctr_s        : std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);
    signal reg_select_s : std_logic_vector(REG_WIDTH-1 downto 0);
    signal we_s         : std_logic;
    signal weight_s     : std_logic_vector(WEIGHT_WIDTH-1 downto 0);
    signal input_s      : std_logic_vector(N-1 downto 0);
    signal output_s     : std_logic;
    signal enable_s     : std_logic;
    
    begin
        spiking_neuron_instance : spiking_neuron
        generic map(
            N                  => N,
            NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
            REG_WIDTH          => REG_WIDTH,
            WEIGHT_WIDTH       => WEIGHT_WIDTH
        )
        port map(
            clk_s, reset_s, ctr_s, reg_select_s, start_syn_s, start_membr_s, stop_syn_s, start_membr_s,
            we_s, weight_s, input_s, output_s
        );

        controller_instance : controller
        generic map(
            NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
            REG_WIDTH          => REG_WIDTH
        )
        port map (
            clk_s, reset_s, enable_s, ctr_s, reg_select_s, start_syn_s, stop_syn_s, start_membr_s, stop_membr_s
        );

        -- clockgeneration
       	process
   	    begin
            clk_s <= '1';
          		wait for 5 ns;
          		clk_s <= '0';
          		wait for 5 ns;
  	     end process;

        -- testprocess
        process
        begin
            reset_s <= '1';
            input_s <= "000000000000000000000000000000";
            weight_s <= "000000000";
            enable_s <= '0';
            we_s <= '0';

            wait for 7 ns;
            reset_s <= '0';
            enable_s <= '1';
            
            -- fill weight-memory
            we_s <= '1';
            
	         -- lin
            --weight_s <= "111111110"; wait for 10 ns;
            --weight_s <= "000000010"; wait for 10 ns;
	    
            -- dos: 1 empty cycles before
            weight_s <= "000000000"; wait for 10 ns;

            -- sos: (MEMBR_WIDTH-1) empty cycles
            --weight_s <= "000000001"; wait for 10 ns; 
            --weight_s <= "000000011"; wait for 10 ns;
            --weight_s <= "000000110"; wait for 10 ns;
            --weight_s <= "000001100"; wait for 10 ns;
            --weight_s <= "000011000"; wait for 10 ns;
            --weight_s <= "000110000"; wait for 10 ns;
            --weight_s <= "001100000"; wait for 10 ns;
            --weight_s <= "101000010"; wait for 10 ns;

            weight_s <= "000001001"; wait for 10 ns; 
            weight_s <= "000100000"; wait for 10 ns;
            weight_s <= "000010000"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000001"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000001"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "111111000"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "111111000"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000011"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000001"; wait for 10 ns;
            weight_s <= "000000001"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000111"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000000001"; wait for 10 ns;
            weight_s <= "000000000"; wait for 10 ns;
            weight_s <= "000100000"; wait for 10 ns;
            weight_s <= "111110111"; wait for 10 ns;
	    
            -- sos: (MEMBR_WIDTH-1) empty cycles
            --weight_s <= "000000001"; wait for 10 ns; 
            --weight_s <= "000000011"; wait for 10 ns;
            --weight_s <= "000000111"; wait for 10 ns;
            --weight_s <= "000001111"; wait for 10 ns;
            --weight_s <= "000011110"; wait for 10 ns;
            --weight_s <= "000111100"; wait for 10 ns;
            --weight_s <= "001111000"; wait for 10 ns;
            --weight_s <= "100010100"; wait for 10 ns;

            -- one summation cycle (for lin and dos)
            weight_s <= "000000000"; wait for 10 ns;

            -- dos: one decay cycle            
            weight_s <= "000000000"; wait for 10 ns;
	    
	         -- lin
	         --weight_s <= "111111111"; wait for 10 ns;
    	       --weight_s <= "000000001"; wait for 10 ns;

            we_s <= '0';
            reset_s <= '1';
            enable_s <= '0';
            wait for 10 ns;
            reset_s <= '0';
            enable_s <= '1';          
            
            input_s <= "000000000000000000000000000001";
            wait for 5 * 32 * 10 ns;
            input_s <= "000000000000000000000000000000";
            wait for 30 * 32 * 30 ns;
            
            input_s <= "000000000000000000000000000100";
            wait for 100 * 32 * 10 ns;
            --input_s <= "000000000000000000000000000000";
            --wait for 40 * 32 * 10 ns;            
            --input_s <= "000000000000000000000000000001";
            --wait for 10 * 32 * 10 ns;
            --input_s <= "000000000000000000000000000000";
            --wait for 40 * 32 * 10 ns;            
            
            input_s <= "000000000000000000000000000000";
            wait for 2 * 32 * 10 ns;
            input_s <= "000000000000000000000000000010";
            wait for 1 * 32 * 10 ns;
            input_s <= "000000000000000000000000000000";
            wait for 2 * 32 * 10 ns;
            input_s <= "000000000000000000000000000010";
            wait for 1 * 32 * 10 ns;
            input_s <= "000000000000000000000000000000";
            wait for 2 * 32 * 10 ns;
            input_s <= "000000000000000000000000000010";
            wait for 1 * 32 * 10 ns;
            input_s <= "000000000000000000000000000000";
            wait for 2 * 32 * 10 ns;
            input_s <= "000000000000000000000000000010";
            wait for 1 * 32 * 10 ns;
            input_s <= "000000000000000000000000000000";
            wait for 2 * 32 * 10 ns;            
            input_s <= "000000000000000000000000000010";
            wait for 1 * 32 * 10 ns;
            input_s <= "000000000000000000000000000000";
            wait for 2 * 32 * 10 ns;
            input_s <= "000000000000000000000000000000";
            wait for 20 * 32 * 10 ns;

            input_s <= "100000000000000000000000000000";
            wait for 10 * 32 * 10 ns;
            input_s <= "000000000000000000000000000000";
            wait for 100 * 32 * 10 ns;


        end process;
end impl;

--------------------------------------------------------------------------------

configuration linear_test of spiking_neuron_testbench is
    for impl
       for spiking_neuron_instance: spiking_neuron
           use configuration WORK.linear
             generic map (
                 N                  =>  N,
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 MEMBRANE_WIDTH     =>  9,
                 THRESHOLD          => 180,
                 ASP                =>  -100,
                 -- value selection constants
                 WEIGHT_WIDTH       =>  WEIGHT_WIDTH,
                 DOS_SHIFT1         =>  0,
                 DOS_SHIFT2         =>  0,
                 --register bank constants
                 REG_WIDTH          =>  REG_WIDTH,
                 -- absolute refractory constants
                 REFR_COMPARE_VALUE =>  -40
             )
             port map(
                 clk_s, reset_s, ctr_s, reg_select_s, start_syn_s, start_membr_s, stop_syn_s, stop_membr_s,
                 we_s, weight_s, input_s, output_s
             );
           end for;

       for controller_instance: controller 
           use entity WORK.controller(impl)
             generic map (
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 REG_WIDTH          => REG_WIDTH,
                 NR_STATES          => 35,
                 NR_SYN_STATES      => 32
             );
       end for;
    end for;
end linear_test;

--------------------------------------------------------------------------------

configuration sos_test of spiking_neuron_testbench is
    for impl
       for spiking_neuron_instance: spiking_neuron
           --use configuration WORK.sos
           use configuration WORK.sos_optimized
             generic map (
                 N                  =>  N,
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 MEMBRANE_WIDTH     =>  9,
                 THRESHOLD          => 180,
                 ASP                =>  -100,
                 -- value selection constants
                 WEIGHT_WIDTH       =>  WEIGHT_WIDTH,
                 DOS_SHIFT1         =>  0,
                 DOS_SHIFT2         =>  0,
                 --register bank constants
                 REG_WIDTH          =>  REG_WIDTH,
                 -- absolute refractory constants
                 REFR_COMPARE_VALUE =>  -40
             )
             port map(
                 clk_s, reset_s, ctr_s, reg_select_s, start_syn_s, start_membr_s, stop_syn_s, stop_membr_s,
                 we_s, weight_s, input_s, output_s
             );
           end for;

       for controller_instance: controller 
           use entity WORK.controller(impl)
             generic map (
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 REG_WIDTH          => REG_WIDTH,
                 NR_STATES          => 30+8+8,
                 NR_SYN_STATES      => 30+8
             );
       end for;
    end for;
end sos_test;

--------------------------------------------------------------------------------

configuration dos_reg_bank_test of spiking_neuron_testbench is
    for impl
       for spiking_neuron_instance: spiking_neuron
           use configuration WORK.dos_reg_bank
             generic map (
                 N                  =>  N,
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 MEMBRANE_WIDTH     =>  9,
                 THRESHOLD          => 180,
                 ASP                =>  -100,
                 -- value selection constants
                 WEIGHT_WIDTH       =>  WEIGHT_WIDTH,
                 DOS_SHIFT1         =>  3,
                 DOS_SHIFT2         =>  5,
                 --register bank constants
                 REG_WIDTH          =>  REG_WIDTH,
                 -- absolute refractory constants
                 REFR_COMPARE_VALUE =>  -40
             )
             port map(
                 clk_s, reset_s, ctr_s, reg_select_s, start_syn_s, start_membr_s, stop_syn_s, stop_membr_s,
                 we_s, weight_s, input_s, output_s
             );
           end for;

       for controller_instance: controller 
           use entity WORK.controller(impl)
             generic map (
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 REG_WIDTH          => REG_WIDTH,
                 NR_STATES          => 33,
                 NR_SYN_STATES      => 31
             );
       end for;
    end for;
end dos_reg_bank_test;

--------------------------------------------------------------------------------
