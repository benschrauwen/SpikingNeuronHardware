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
    NEURON_STATE_WIDTH : integer :=  6; -- 6 for sos, else 5 is sufficient
    WEIGHT_WIDTH       : integer :=  9
    );
end spiking_neuron_testbench;

architecture impl of spiking_neuron_testbench is

    component spiking_neuron
    generic(
        N                  : integer;
        NEURON_STATE_WIDTH : integer;
        WEIGHT_WIDTH       : integer
        );
        
    port(
        clk            :  in std_logic;
        start          :  in std_logic; -- high 1 clockcycle at start new cycle
        stop           :  in std_logic;
        reset          :  in std_logic;
        ctr            :  in std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);	
        we             :  in std_logic;
        weight         :  in std_logic_vector(WEIGHT_WIDTH-1 downto 0);
        input          :  in std_logic_vector(N-1 downto 0);
        output         : out std_logic
        );
    end component;

    component controller
    generic (
        NEURON_STATE_WIDTH : integer
        );
    port(
        clk            :  in std_logic;
        reset          :  in std_logic;
        enable         :  in std_logic;
        start          : out std_logic;
        stop           : out std_logic;
        ctr            : out std_logic_vector(NEURON_STATE_WIDTH-1 downto 0)
        );
    end component;
    
    signal clk_s, start_s, stop_s, reset_s : std_logic;
    signal ctr_s    : std_logic_vector(NEURON_STATE_WIDTH-1 downto 0);
    signal we_s     : std_logic;
    signal weight_s : std_logic_vector(WEIGHT_WIDTH-1 downto 0);
    signal input_s  : std_logic_vector(N-1 downto 0);
    signal output_s : std_logic;
    signal enable_s : std_logic;
    
    begin
        spiking_neuron_instance : spiking_neuron
        generic map(
            N                  => N,
            NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
            WEIGHT_WIDTH       => WEIGHT_WIDTH
        )
        port map(clk_s, start_s, stop_s, reset_s, ctr_s, we_s, weight_s, input_s, output_s
        );

        controller_instance : controller
        generic map(
            NEURON_STATE_WIDTH => NEURON_STATE_WIDTH
        )
        port map (clk_s, reset_s, enable_s, start_s, stop_s, ctr_s
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
            enable_s <= '0';
            we_s <= '0';

            wait for 7 ns;
            reset_s <= '0';
            enable_s <= '1';
            
            -- fill weight-memory
            we_s <= '1';
            
            -- dos: 1 empty cycle
            --weight_s <= "000000000"; wait for 10 ns; -- must be zero with dos (shifting cycle)

            -- sos: 7 empty cycles
            --weight_s <= "000000001"; wait for 10 ns; 
            --weight_s <= "000000011"; wait for 10 ns;
            --weight_s <= "000000111"; wait for 10 ns;
            --weight_s <= "000001111"; wait for 10 ns;
            --weight_s <= "000011111"; wait for 10 ns;
            --weight_s <= "000111111"; wait for 10 ns;
            --weight_s <= "001111111"; wait for 10 ns;
            --weight_s <= "100000000"; wait for 10 ns;
            
            -- linear decay
            weight_s <= "111111111"; wait for 10 ns;
            weight_s <= "000000001"; wait for 10 ns;
            
            weight_s <= "000000011"; wait for 10 ns; 
            weight_s <= "000000011"; wait for 10 ns;
            weight_s <= "000000100"; wait for 10 ns;
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
            weight_s <= "000000100"; wait for 10 ns;
            weight_s <= "000100000"; wait for 10 ns;
            
            we_s <= '0';
            reset_s <= '1';
            enable_s <= '0';
            wait for 10 ns;
            reset_s <= '0';
            enable_s <= '1';          
            
            
            input_s <= "000000000000000000000000000001";
            
            wait for 20 * 32 * 10 ns;
     --       enable_s <= '0';
     --       wait for 10 * 32 *  10 ns;
     --       enable_s <= '1';
            wait for 20 * 32 * 10 ns;
            
            input_s <= "000000000000000000000000000000";

            wait for 50 * 32 * 30 ns;

            input_s <= "100000000000000000000000000000";

            wait for 20 * 32 * 10 ns;
            
            input_s <= "000000000000000000000000000000";

            wait for 20 * 32 * 10 ns;

        end process;
end impl;

--------------------------------------------------------------------------------

configuration upegui_test of spiking_neuron_testbench is
    for impl
       for spiking_neuron_instance: spiking_neuron
           use configuration WORK.upegui
             generic map (
                 N                  =>  N,
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 MEMBRANE_WIDTH     =>  9,
                 THRESHOLD          => 100,
                 ASP                =>  -10,
                 MEMBRANE_RESET     =>  0,
                 -- value selection constants
                 WEIGHT_WIDTH       =>  WEIGHT_WIDTH,
                 DOS_SHIFT          =>  0,
                 FIXED_WEIGHT       =>  1,
                 FIXED_DECAY        =>  1,
                 -- absolute refractory constants
                 REFR_COMPARE_VALUE =>  0,
                 REFR_COUNTER_WIDTH =>  0,
                 REFR_COUNTER_VALUE =>  0
             )
             port map (clk_s, start_s, stop_s, reset_s, ctr_s, we_s, weight_s, input_s, output_s
             );          
           end for;

       for controller_instance: controller 
           use entity WORK.controller(impl)
             generic map (
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 NR_STATES          => 32
             );
       end for;
    end for;
end upegui_test;

--------------------------------------------------------------------------------

configuration dos_no_refractory_test of spiking_neuron_testbench is
    for impl
       for spiking_neuron_instance: spiking_neuron
           use configuration WORK.dos_no_refractory
             generic map (
                 N                  =>  N,
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 MEMBRANE_WIDTH     =>  9,
                 THRESHOLD          => 40,
                 ASP                =>-10,
                 MEMBRANE_RESET     =>  0,
                 -- value selection constants
                 WEIGHT_WIDTH       =>  WEIGHT_WIDTH,
                 DOS_SHIFT          =>  3,
                 FIXED_WEIGHT       =>  1,
                 FIXED_DECAY        =>  1,
                 -- absolute refractory constants
                 REFR_COMPARE_VALUE =>  0,
                 REFR_COUNTER_WIDTH =>  0,
                 REFR_COUNTER_VALUE =>  0
             )
             port map (clk_s, start_s, stop_s, reset_s, ctr_s, we_s, weight_s, input_s, output_s
             );          
           end for;

       for controller_instance: controller 
           use entity WORK.controller(impl)
             generic map (
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 NR_STATES          => 31
             );
       end for;
    end for;
end dos_no_refractory_test;

--------------------------------------------------------------------------------

configuration dos_with_refractory_test of spiking_neuron_testbench is
    for impl
       for spiking_neuron_instance: spiking_neuron
           use configuration WORK.dos_with_refractory
             generic map (
                 N                  =>  N,
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 MEMBRANE_WIDTH     =>  9,
                 THRESHOLD          => 40,
                 ASP                =>-10,
                 MEMBRANE_RESET     =>  0,
                 -- value selection constants
                 WEIGHT_WIDTH       =>  WEIGHT_WIDTH,
                 DOS_SHIFT          =>  5,
                 FIXED_WEIGHT       =>  1,
                 FIXED_DECAY        =>  1,
                 -- absolute refractory constants
                 REFR_COMPARE_VALUE =>  0,
                 REFR_COUNTER_WIDTH =>  0,
                 REFR_COUNTER_VALUE =>  0
             )
             port map (clk_s, start_s, stop_s, reset_s, ctr_s, we_s, weight_s, input_s, output_s
             );          
           end for;

       for controller_instance: controller 
           use entity WORK.controller(impl)
             generic map (
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 NR_STATES          => 31
             );
       end for;
    end for;
end dos_with_refractory_test;

--------------------------------------------------------------------------------

configuration dos_with_refractory_test_2 of spiking_neuron_testbench is
    for impl
       for spiking_neuron_instance: spiking_neuron
           use configuration WORK.dos_with_refractory_2
             generic map (
                 N                  =>  N,
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 MEMBRANE_WIDTH     =>  9,
                 THRESHOLD          => 40,
                 ASP                =>-10,
                 MEMBRANE_RESET     =>  0,
                 -- value selection constants
                 WEIGHT_WIDTH       =>  WEIGHT_WIDTH,
                 DOS_SHIFT          =>  3,
                 FIXED_WEIGHT       =>  1,
                 FIXED_DECAY        =>  1,
                 -- absolute refractory constants
                 REFR_COMPARE_VALUE => -5,
                 REFR_COUNTER_WIDTH =>  0,
                 REFR_COUNTER_VALUE =>  0
             )
             port map (clk_s, start_s, stop_s, reset_s, ctr_s, we_s, weight_s, input_s, output_s
             );          
           end for;

       for controller_instance: controller 
           use entity WORK.controller(impl)
             generic map (
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 NR_STATES          => 31
             );
       end for;
    end for;
end dos_with_refractory_test_2;

--------------------------------------------------------------------------------

configuration dos_with_refractory_test_3 of spiking_neuron_testbench is
    for impl
       for spiking_neuron_instance: spiking_neuron
           use configuration WORK.dos_with_refractory_3
             generic map (
                 N                  =>  N,
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 MEMBRANE_WIDTH     =>  9,
                 THRESHOLD          => 40,
                 ASP                =>-10,
                 MEMBRANE_RESET     =>  0,
                 -- value selection constants
                 WEIGHT_WIDTH       =>  WEIGHT_WIDTH,
                 DOS_SHIFT          =>  3,
                 FIXED_WEIGHT       =>  1,
                 FIXED_DECAY        =>  1,
                 -- absolute refractory constants
                 REFR_COMPARE_VALUE =>  0,
                 REFR_COUNTER_WIDTH =>  4,
                 REFR_COUNTER_VALUE =>  2
             )
             port map (clk_s, start_s, stop_s, reset_s, ctr_s, we_s, weight_s, input_s, output_s
             );          
           end for;

       for controller_instance: controller 
           use entity WORK.controller(impl)
             generic map (
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 NR_STATES          => 31
             );
       end for;
    end for;
end dos_with_refractory_test_3;

--------------------------------------------------------------------------------

configuration sos_mem_test of spiking_neuron_testbench is
    for impl
       for spiking_neuron_instance: spiking_neuron
           use configuration WORK.sos_mem
             generic map (
                 N                  =>  N,
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 MEMBRANE_WIDTH     =>  9,
                 THRESHOLD          => 40,
                 ASP                => 0,
                 MEMBRANE_RESET     =>  0,
                 -- value selection constants
                 WEIGHT_WIDTH       =>  WEIGHT_WIDTH,
                 DOS_SHIFT          =>  3,
                 FIXED_WEIGHT       =>  1,
                 FIXED_DECAY        =>  1,
                 -- absolute refractory constants
                 REFR_COMPARE_VALUE =>  0,
                 REFR_COUNTER_WIDTH =>  4,
                 REFR_COUNTER_VALUE =>  2
             )
             port map (clk_s, start_s, stop_s, reset_s, ctr_s, we_s, weight_s, input_s, output_s
             );          
           end for;

       for controller_instance: controller 
           use entity WORK.controller(impl)
             generic map (
                 NEURON_STATE_WIDTH => NEURON_STATE_WIDTH,
                 NR_STATES          => 38
             );
       end for;
    end for;
end sos_mem_test;
