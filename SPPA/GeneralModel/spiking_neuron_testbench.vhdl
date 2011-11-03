-------------------------------------------------------------------------------
-- General vhdl framework for compact efficient serial spiking neurons
--
-- testbench
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
-- created : 2005/03/03
-- version 2
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.integer_array_package.all;
use work.neuron_config_package.all;

entity spiking_neuron_testbench is
end spiking_neuron_testbench;

architecture impl of spiking_neuron_testbench is    
    signal clk_s, reset_s, start_s, decay_s, write_membr_s, membr_select_s, stop_cycle_s : std_logic;
    signal ctr_s        : std_logic_vector(STATE_WIDTH(NR_DECAY_STATES)-1 downto 0);
    signal reg_select_s : std_logic_vector(REG_WIDTH-1 downto 0);
    signal we_s         : std_logic;
    signal weight_s     : std_logic_vector(WEIGHT_WIDTH_CONST-1 downto 0);
    signal input_s      : std_logic_vector(TOTAL_NR_INPUTS-1 downto 0);
    signal output_s     : std_logic;
    signal enable_s     : std_logic;

    function GEN_MEM_CONTENT () return mem_type is
        variable res : mem_type;
        variable i, j, a : integer;
        variable dec_temp : std_logic_vector(DATA_WIDTH-1 downto 0);
    begin
        a := 0;
        for i = 0 to NR_SYN_CONST loop
            -- decay
            for j = 0 to NR_DECAY_STATES-1 loop
                case NEURON_TYPE is
                    when "li1" =>
                        res(a) := -DECAY(i);
                    when "li2" =>
                        if j = 0
                            res(a) := -DECAY(i);
                        else
                            res(a) := DECAY(i);
                        end if;
                    when "sos" =>
                        if j = 0
                            dec_temp := DECAY(i);
                            dec_temp(DATA_WIDTH-1) := '1';
                            
                            res(a) := DECAY(i);
                            res(a) := not res(a)+1;
                            res(a)(DATA_WIDTH-1) := '0';
                        elsif j = 1
                            res(a)(DATA_WIDTH-1) := dec_temp(0);
                            res(a)(DATA_WIDTH-2 downto 0) := dec_temp(DATA_WIDTH-1 downto 1);

                            dec_temp(DATA_WIDTH-2 downto 0) := dec_temp(DATA_WIDTH-1 downto 1);
                        end if
                    when "dos" =>
                        -- location not used
                        res(a) := 0;
                    when others => 
                        error("unknown neuron type");
                end case;
                a := a + 1;
            end loop
            -- input weights
            for j = 0 to NR_INPUTS_CONST(i) loop
                res(a) := WEIGHTS(i)(j);
                a := a + 1;
            end loop
            -- if not membrane, add synapse to membrane
            if i /= 0
                -- location not used
                res(a) := 0;
                a := a + 1;
            end if
        end loop
        return res;
    end GEN_MEM_CONTENT;
begin
    li1_spiking_neuron_instance : if NEURON_TYPE = "li1" generate
        spiking_neuron_instance: configuration work.linear_1
            generic map(
            N                  => TOTAL_NR_INPUTS,
            NEURON_STATE_WIDTH => STATE_WIDTH(NR_DECAY_STATES),
            MEMBRANE_WIDTH     => MEMBRANE_WIDTH_CONST,
            REG_WIDTH          => REG_WIDTH,
            NR_SYN             => NR_SYN_CONST,
            NR_DECAY_STATES    => NR_DECAY_STATES,
            THRESHOLD          => THRESHOLD_CONST,
            ASP                => ASP_CONST,
            WEIGHT_WIDTH       => WEIGHT_WIDTH_CONST,
            REFR_COMPARE_VALUE => REFR_COMPARE_VALUE_CONST,
            NR_INPUTS          => NR_INPUTS_CONST,
            DOS_SHIFTS         => DOS_SHIFTS_CONST,
            MEMORY_CONTENT     => GEN_MEM_CONTENT
        )
        port map(
            clk_s, reset_s, ctr_s, reg_select_s, decay_s, start_s, write_membr_s, membr_select_s,
            stop_cycle_s, we_s, weight_s, input_s, output_s
        );
    end generate li1_spiking_neuron_instance;
    
    li2_spiking_neuron_instance : if NEURON_TYPE = "li2" generate
        spiking_neuron_instance: configuration work.linear_2
            generic map(
            N                  => TOTAL_NR_INPUTS,
            NEURON_STATE_WIDTH => STATE_WIDTH(NR_DECAY_STATES),
            MEMBRANE_WIDTH     => MEMBRANE_WIDTH_CONST,
            REG_WIDTH          => REG_WIDTH,
            NR_SYN             => NR_SYN_CONST,
            NR_DECAY_STATES    => NR_DECAY_STATES,
            THRESHOLD          => THRESHOLD_CONST,
            ASP                => ASP_CONST,
            WEIGHT_WIDTH       => WEIGHT_WIDTH_CONST,
            REFR_COMPARE_VALUE => REFR_COMPARE_VALUE_CONST,
            NR_INPUTS          => NR_INPUTS_CONST,
            DOS_SHIFTS         => DOS_SHIFTS_CONST,
            MEMORY_CONTENT     => GEN_MEM_CONTENT
        )
        port map(
            clk_s, reset_s, ctr_s, reg_select_s, decay_s, start_s, write_membr_s, membr_select_s,
            stop_cycle_s, we_s, weight_s, input_s, output_s
        );
    end generate li2_spiking_neuron_instance;
     
    sos_spiking_neuron_instance : if NEURON_TYPE = "sos" generate
        spiking_neuron_instance: configuration work.sos
            generic map(
            N                  => TOTAL_NR_INPUTS,
            NEURON_STATE_WIDTH => STATE_WIDTH(NR_DECAY_STATES),
            MEMBRANE_WIDTH     => MEMBRANE_WIDTH_CONST,
            REG_WIDTH          => REG_WIDTH,
            NR_SYN             => NR_SYN_CONST,
            NR_DECAY_STATES    => NR_DECAY_STATES,
            THRESHOLD          => THRESHOLD_CONST,
            ASP                => ASP_CONST,
            WEIGHT_WIDTH       => WEIGHT_WIDTH_CONST,
            REFR_COMPARE_VALUE => REFR_COMPARE_VALUE_CONST,
            NR_INPUTS          => NR_INPUTS_CONST,
            DOS_SHIFTS         => DOS_SHIFTS_CONST,
            MEMORY_CONTENT     => GEN_MEM_CONTENT
        )
        port map(
            clk_s, reset_s, ctr_s, reg_select_s, decay_s, start_s, write_membr_s, membr_select_s,
            stop_cycle_s, we_s, weight_s, input_s, output_s
        );
    end generate sos_spiking_neuron_instance;        
    
    dos_spiking_neuron_instance : if NEURON_TYPE = "dos" generate
        spiking_neuron_instance: configuration work.dos
            generic map(
            N                  => TOTAL_NR_INPUTS,
            NEURON_STATE_WIDTH => STATE_WIDTH(NR_DECAY_STATES),
            MEMBRANE_WIDTH     => MEMBRANE_WIDTH_CONST,
            REG_WIDTH          => REG_WIDTH,
            NR_SYN             => NR_SYN_CONST,
            NR_DECAY_STATES    => NR_DECAY_STATES,
            THRESHOLD          => THRESHOLD_CONST,
            ASP                => ASP_CONST,
            WEIGHT_WIDTH       => WEIGHT_WIDTH_CONST,
            REFR_COMPARE_VALUE => REFR_COMPARE_VALUE_CONST,
            NR_INPUTS          => NR_INPUTS_CONST,
            DOS_SHIFTS         => DOS_SHIFTS_CONST,
            MEMORY_CONTENT     => GEN_MEM_CONTENT
        )
        port map(
            clk_s, reset_s, ctr_s, reg_select_s, decay_s, start_s, write_membr_s, membr_select_s,
            stop_cycle_s, we_s, weight_s, input_s, output_s
        );
    end generate dos_spiking_neuron_instance;

    controller_instance : entity work.controller
    port map (
        clk_s, reset_s, enable_s, ctr_s, reg_select_s, decay_s, start_s, write_membr_s, 
        membr_select_s, stop_cycle_s
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
        enable_s <= '1';        -- to keep counter running to fill weight memory
        
--        -- fill weight-memory
--        we_s <= '1';
--
--                   
--        -------- membrane
--
--        -- lin: 1/2 decay cycle
--        --weight_s <= "111111111"; wait for 10 ns;
--        --weight_s <= "000000001"; wait for 10 ns;
--                    
--        -- sos: (MEMBR_WIDTH-2) decay cycles
--        weight_s <= "001100000"; wait for 10 ns;             
--        weight_s <= "011010000"; wait for 10 ns;
--        weight_s <= "011101000"; wait for 10 ns;
--        weight_s <= "011110100"; wait for 10 ns;
--        weight_s <= "011111010"; wait for 10 ns;
--        weight_s <= "011111101"; wait for 10 ns;
--        weight_s <= "111111110"; wait for 10 ns;
--        weight_s <= "011111111"; wait for 10 ns; 
--        weight_s <= "111111111"; wait for 10 ns; 
--        
--        -- dos: 1 decay cycle
--        --weight_s <= "000000000"; wait for 10 ns; 
--                   
--        weight_s <= "000000101"; wait for 10 ns; 
--        weight_s <= "000100000"; wait for 10 ns;
--        weight_s <= "000000100"; wait for 10 ns;
--        weight_s <= "000010000"; wait for 10 ns;
--        weight_s <= "000000001"; wait for 10 ns;
--        weight_s <= "000001000"; wait for 10 ns;
--        weight_s <= "000000001"; wait for 10 ns;
--        weight_s <= "000001000"; wait for 10 ns;
--        weight_s <= "000000100"; wait for 10 ns;
--        weight_s <= "000000010"; wait for 10 ns;
--
--                   
--        -------- synapse 1
--
--        -- lin: 1/2 decay cycle
--        --weight_s <= "111111110"; wait for 10 ns;
--        --weight_s <= "000000010"; wait for 10 ns;            
--                    
--        -- sos: (MEMBR_WIDTH-2) decay cycles
--        weight_s <= "001100000"; wait for 10 ns;             
--        weight_s <= "011010000"; wait for 10 ns;
--        weight_s <= "011101000"; wait for 10 ns;
--        weight_s <= "011110100"; wait for 10 ns;
--        weight_s <= "011111010"; wait for 10 ns;
--        weight_s <= "011111101"; wait for 10 ns;
--        weight_s <= "111111110"; wait for 10 ns;
--        weight_s <= "011111111"; wait for 10 ns; 
--        weight_s <= "111111111"; wait for 10 ns; 
--        
--        -- dos: 1 decay cycle
--        --weight_s <= "000000000"; wait for 10 ns;            
--        
--        weight_s <= "000000111"; wait for 10 ns;
--        weight_s <= "111111000"; wait for 10 ns;
--        weight_s <= "100000000"; wait for 10 ns;
--        weight_s <= "111111000"; wait for 10 ns;
--        weight_s <= "000010000"; wait for 10 ns;
--        weight_s <= "000001000"; wait for 10 ns;
--        weight_s <= "000000100"; wait for 10 ns;
--        weight_s <= "000000011"; wait for 10 ns;
--        weight_s <= "000100000"; wait for 10 ns;
--        weight_s <= "000010000"; wait for 10 ns;
--        
--        -- one add cycle
--        weight_s <= "000000000"; wait for 10 ns;
--
--            
--        -------- synapse 2
--        
--        -- lin: 1/2 decay cycle
--        --weight_s <= "111111101"; wait for 10 ns;
--        --weight_s <= "000000011"; wait for 10 ns;
--
--        -- sos: (MEMBR_WIDTH-2) decay cycles
--        weight_s <= "001100000"; wait for 10 ns;             
--        weight_s <= "011010000"; wait for 10 ns;
--        weight_s <= "011101000"; wait for 10 ns;
--        weight_s <= "011110100"; wait for 10 ns;
--        weight_s <= "011111010"; wait for 10 ns;
--        weight_s <= "011111101"; wait for 10 ns;
--        weight_s <= "111111110"; wait for 10 ns;
--        weight_s <= "011111111"; wait for 10 ns; 
--        weight_s <= "111111111"; wait for 10 ns; 
--                                
--        -- dos: 1 decay cycle
--        --weight_s <= "000000000"; wait for 10 ns;
--        
--        weight_s <= "000000101"; wait for 10 ns;
--        weight_s <= "000000001"; wait for 10 ns;
--        weight_s <= "000000001"; wait for 10 ns;
--        weight_s <= "000010000"; wait for 10 ns;
--        weight_s <= "000000111"; wait for 10 ns;
--        weight_s <= "000001000"; wait for 10 ns;
--        weight_s <= "000000001"; wait for 10 ns;
--        weight_s <= "000010000"; wait for 10 ns;
--        weight_s <= "000100100"; wait for 10 ns;
--        weight_s <= "111110110"; wait for 10 ns;
--
--        -- one add cycle
--        weight_s <= "000000000"; wait for 10 ns;
--
--        we_s <= '0';
--        reset_s <= '1';
--        enable_s <= '0';
--        wait for 10 ns;
--        reset_s <= '0';
--        enable_s <= '1';          
        
        input_s <= "000000000100000000010000000001";
        
        
        wait for 10 * 32 * 10 ns;
        
        input_s <= "000000000000000000000000000000";

        wait for 30 * 32 * 30 ns;
        
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
        input_s <= "000000000000000000000000000010";
        wait for 1 * 32 * 10 ns;
        input_s <= "000000000000000000000000000000";
        wait for 2 * 32 * 10 ns;
      --  input_s <= "100000000000000000000000000000";
      --  wait for 1 * 32 * 10 ns;
      --  input_s <= "000000000000000000000000000000";
      --  wait for 2 * 32 * 10 ns;
       -- input_s <= "100000000000000000000000000000";
       -- wait for 1 * 32 * 10 ns;
        input_s <= "000000000000000000000000000000";
        wait for 2 * 32 * 10 ns;

        
        
        input_s <= "100000000000000000000000000000";
        wait for 8 * 32 * 10 ns;
        
        input_s <= "000000000000000000000000000000";
        wait for 100 * 32 * 10 ns;

    end process;
end impl;

