----------------------------------------------------------------------------------------
-- Spiking Neuron Hardware Framework that uses Serial Processing and Serial Arithmetic
--
-- This is the gluing logic, 
-- combining the different blocks into a neural network system.
--
-- authors : Michiel D'Haene, Benjamin Schrauwen
----------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.utility_package.all;
use work.settings_package.all;
use work.reg_mem_package.all;
use work.weight_mem_package.all;
use work.intercon_mem_package.all;

--pragma translate_off
-- library unisim ;
-- use unisim.vcomponents.all;
--pragma translate_on

entity system_snn is
generic(
    NR_PARALLEL_NEURONS : integer        := CONST_NR_PARALLEL_NEURONS;
    NR_BITS             : integer        := CONST_NR_BITS;
    NR_SERIAL_NEURONS   : integer        := CONST_NR_SERIAL_NEURONS;
    NR_SYNAPSES         : integer_array  := CONST_NR_SYNAPSES;        -- = NR_SYN_CONSTS + 1 (membr) for each neuron
    NR_WEIGHTS          : integer_matrix := CONST_NR_WEIGHTS;       -- S1, S2, M -> number of inputs
    REFRACTORINESS      : boolean        := CONST_REFRACTORINESS;              -- true if all neurons have refractory
    REFRACTORY_WIDTH    : integer        := CONST_REFRACTORY_WIDTH;              -- number of refractory bits
    DECAY_SHIFT         : integer_matrix := CONST_DECAY_SHIFT        -- 0 = lin decay
);
port(
    system_clk     :  in std_logic; -- clock of the processing elements
    network_clk    :  in std_logic; -- clock of the copying proces, must be equal or higher then the system clock!
    reset          :  in std_logic; -- reset network (asynchronous)
    start          :  in std_logic; -- start new processing cycle
    pe_ready       : out std_logic; -- current PE ready
    timestep_ready : out std_logic; -- current time-step_ready

    spike_in_addr  : out std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);
    spike_in_data  :  in std_logic; -- must be available one clocktick after the address has been set

    out_clk        :  in std_logic;
    spike_out_ce   :  in std_logic;
    spike_out_addr :  in std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);
    spike_out_data : out std_logic;

    network_ready  : out std_logic;
    controller_ready : out std_logic
);
end system_snn;

architecture structure of system_snn is
    signal clk_in_buff             : std_logic;
    signal clk, clkx2              : std_logic;
    signal clkx2_dcm               : std_logic;
    signal clk_dcm                 : std_logic;
    signal dcm_locked              : std_logic;
    signal s_smm_in, s_smm_1, s_smm_2 : std_logic_vector(NR_PARALLEL_NEURONS-1 downto 0);
    signal s_spike_in, s_spike_out, s_weight_in : std_logic_vector(NR_PARALLEL_NEURONS-1 downto 0);
    signal s_smm_we                : std_logic;
    signal s_wm_ai, s_sim_ai, s_som_we : std_logic;
    signal s_force_one             : std_logic;
    signal s_sel                   : std_logic;
    signal s_fz_ce, s_reset_fz     : std_logic;
    signal s_carry_ce, s_reset_carry : std_logic;
    signal s_neg_ce, s_set_neg, s_reset_neg : std_logic;
    signal s_bypass                : std_logic;
    signal addr_1, addr_2, addr_3  : std_logic_vector(LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH))-1 downto 0);
    signal s_controlled_reset      : std_logic;
    signal s_switch_sim, s_switch_som : std_logic;
    signal s_ready, s_ready_out, s_network_ready, s_controller_ready : std_logic;
    signal s_con_mem_data          : std_logic_vector(1+LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);
    signal s_next_con              : std_logic;
    signal s_con_data_out          : std_logic;
    signal s_con_data_in           : std_logic_vector(NR_PARALLEL_NEURONS-1 downto 0);
    signal s_con_to_addr_dec       : std_logic;
    signal s_con_to_data_sel       : std_logic_vector(LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);
    signal s_neuron_counter, s_controller_counter : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)-1 downto 0);
    signal s_con_to_we             : std_logic;
    signal s_con_from_addr         : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)-1 downto 0);
    signal s_controller_start, s_network_start : std_logic;
    signal s_last_cycle            : std_logic;
    type   system_state_space is (iteration_ready, run, cycle_ready);
    signal s_system_state          : system_state_space := iteration_ready;
    signal spike_out_data_temp     : std_logic_vector(NR_PARALLEL_NEURONS-1 downto 0);
    signal s_sum_out               : std_logic;

    signal s_we_spike_in_buff : std_logic_vector(NR_PARALLEL_NEURONS-1 downto 0);

    -- double buffering signals
    signal s_network_ready_1, s_network_ready_2 : std_logic;
    signal s_network_start_1, s_network_start_2 : std_logic;

    signal spike_out_addr_d : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);

    -- test signals
    signal cycle_counter : std_logic_vector(13 downto 0);
    signal cycle_counter_buff : std_logic_vector(13 downto 0);
    signal cycle_counter_buff2 : std_logic_vector(13 downto 0);
    signal s_r_addr : std_logic_vector(LOG2CEIL(MAXIMUM_NR_WEIGHTS(NR_WEIGHTS))-1 downto 0);
    signal test_in_data : std_logic;
    signal test_in_addr : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);



-- DCM primitive
component dcm
--    map (
--        CLK_FEEDBACK : string,
--        CLKIN_PERIOD : 10.0
--    )
    port (
		clkin   	: in  std_logic ;
		CLKFB   	: in  std_logic ;
		DSSEN 		: in  std_logic ;
		PSINCDEC	: in  std_logic ;
		PSEN 		: in  std_logic ;
		PSCLK 		: in  std_logic ;
		RST     	: in  std_logic ;
		CLK0    	: out std_logic ;
		CLK90   	: out std_logic ;
		CLK180  	: out std_logic ;
		CLK270  	: out std_logic ;
		CLK2X   	: out std_logic ;
		CLK2X180	: out std_logic ;
		CLKDV   	: out std_logic ;
		CLKFX   	: out std_logic ;
		CLKFX180	: out std_logic ;
		LOCKED  	: out std_logic ;
		PSDONE  	: out std_logic ;
		STATUS  	: out std_logic_vector(7 downto 0)
    );
end component ;
-- BUFG primitive
   component bufg port(i: in std_logic; o: out std_logic); end component;
-- IBUFG primitive
   component ibufg port(i: in std_logic; o: out std_logic); end component;

begin
    network_ready <= s_network_ready;
    controller_ready <= s_controller_ready;

    s_controlled_reset <= reset or not dcm_locked;

    dcm_instance: dcm
--    generic map (
--        CLK_FEEDBACK => "1X"
--        CLKIN_PERIOD => 10.0
--    )
    port map (
        clkin    => clk_in_buff,
        CLKFB    => clk,
        DSSEN    => '0',
        PSINCDEC => '0',
        PSEN     => '0',
        PSCLK    => '0',
        RST      => reset,
        CLK0     => clk_dcm,
        CLK90    => open,
        CLK180   => open,
        CLK270   => open,
        CLK2X    => clkx2_dcm,
        CLK2X180 => open,
        CLKDV    => open,
        CLKFX    => open,
        CLKFX180 => open,
        LOCKED   => dcm_locked,
        PSDONE   => open,
        STATUS   => open
    );

--    ibufga  : ibufg port map (i => system_clk, o => clk_in_buff);
    clk_in_buff <= system_clk;
    bufga   : bufg  port map (i => clk_dcm, o => clk);
    bufgax2 : bufg  port map (i => clkx2_dcm, o => clkx2);

    weight_mem_instance: entity work.cyclic_buffer
        generic map(
            DATA_WIDTH    => NR_PARALLEL_NEURONS,
            ADDRESS_WIDTH => LOG2CEIL(TOTAL_NR_WEIGHTS(NR_WEIGHTS)*NR_BITS),
            MEMORY_AMOUNT => TOTAL_NR_WEIGHTS(NR_WEIGHTS)*NR_BITS,
            CONTENT       => weight_mem
        )
        port map(
            clk      => clk,
            reset    => s_controlled_reset,
--            we       => '0',
            ce       => s_wm_ai,
            addr_dec => s_wm_ai,
            d        => s_weight_in
        );

    -- to shorten the critical path (due to routing delays), we place this here...
    process (s_con_to_we, s_con_to_data_sel)
    begin
        s_we_spike_in_buff <= (others => '0');
        s_we_spike_in_buff(conv_integer(s_con_to_data_sel)) <= s_con_to_we;
    end process;





--     process (clk)
--     begin
--         if rising_edge(clk) then
--             if s_controlled_reset = '1' then
--                 cycle_counter <= (others => '0');
--                 s_r_addr <= conv_std_logic_vector(MAXIMUM_NR_WEIGHTS(NR_WEIGHTS)-1,LOG2CEIL(MAXIMUM_NR_WEIGHTS(NR_WEIGHTS)));
--             else
-- --                 if s_switch_sim = '1' then
-- --                     s_r_addr     <= conv_std_logic_vector(MAXIMUM_NR_WEIGHTS(NR_WEIGHTS)-1,LOG2CEIL(MAXIMUM_NR_WEIGHTS(NR_WEIGHTS)));
-- --                 elsif s_sim_ai = '1' then
-- --                     if conv_integer(s_r_addr) = 0 then
-- --                         s_r_addr <= conv_std_logic_vector(MAXIMUM_NR_WEIGHTS(NR_WEIGHTS)-1,LOG2CEIL(MAXIMUM_NR_WEIGHTS(NR_WEIGHTS)));
-- --                     else
-- --                         s_r_addr <= s_r_addr - 1;
-- --                     end if;
-- --                 end if;
-- 
--                 if s_som_we = '1' and s_last_cycle = '1' then
--                     cycle_counter <= cycle_counter + 1;
--                 end if;
-- 
-- --                if s_r_addr > 20 and cycle_counter < 5 then
--                 if cycle_counter < 7 then
--                     s_spike_in <= "1111111111111111111100000000000000000000111111111111111111111111111111000000000000000000000000000000";
--                 else
--                     s_spike_in <= (others => '0');
--                 end if;
-- 
--             end if;
--         end if;
--     end process;





    spike_in_buff: entity work.distrib_preload_buff
        generic map(
            ADDRESS_WIDTH => LOG2CEIL(MAXIMUM_NR_WEIGHTS(NR_WEIGHTS)),
            MEMORY_AMOUNT => MAXIMUM_NR_WEIGHTS(NR_WEIGHTS),
            SELECT_WIDTH  => LOG2CEIL(NR_PARALLEL_NEURONS),
            R_DATA_WIDTH  => NR_PARALLEL_NEURONS
        )
        port map(
            reset       => s_controlled_reset,
            r_clk       => clk,
            switch      => s_switch_sim,
            r_addr_dec  => s_sim_ai,
            data_out    => s_spike_in,
            w_clk       => network_clk,
            we_array    => s_we_spike_in_buff,
--            we          => s_con_to_we,
            w_addr_dec  => s_con_to_addr_dec,
            data_select => s_con_to_data_sel,
            data_in     => s_con_data_out
        );

    spike_out_mem: entity work.twoport_switching_cyclic_buffer_fast
        generic map(
            DATA_WIDTH    => NR_PARALLEL_NEURONS,
            ADDRESS_WIDTH => LOG2CEIL(NR_SERIAL_NEURONS),
            MEMORY_AMOUNT => NR_SERIAL_NEURONS
        )
        port map(
            reset      => s_controlled_reset,
            switch     => s_switch_som,
            clk_1      => clk,
            ce_1       => s_som_we,
            we_1       => s_som_we,
--            addr_1_dec => s_som_we,
            addr_1_inc => s_som_we,
            d_1        => open,
            q_1        => s_spike_out,
            clk_2      => network_clk,
            ce_2       => '1',
--            we_2       => '0',
            address_2  => s_con_from_addr,
            d_2        => s_con_data_in
--            q_2        => (others => '-')
        );




--     process (clk)
--     begin
--         if rising_edge(clk) then
--             if s_controlled_reset = '1' then
--                 cycle_counter <= (others => '0');
--             else
--                 if s_controller_counter >= cycle_counter then
--                     s_spike_out <= (others => '1');
--                 else
--                     s_spike_out <= (others => '0');
--                 end if;
-- 
--                 if s_som_we = '1' and s_last_cycle = '1' then
--                     cycle_counter <= cycle_counter + 1;
--                 end if;
--             end if;
--         end if;
--     end process;




    spike_out_mem2: entity work.twoport_switching_cyclic_buffer_fast
        generic map(
            DATA_WIDTH    => NR_PARALLEL_NEURONS,
            ADDRESS_WIDTH => LOG2CEIL(NR_SERIAL_NEURONS),
            MEMORY_AMOUNT => NR_SERIAL_NEURONS
        )
        port map(
            reset      => s_controlled_reset,
            switch     => s_switch_som,
            clk_1      => clk,
            ce_1       => s_som_we,
            we_1       => s_som_we,
--            addr_1_dec => s_som_we,
            addr_1_inc => s_som_we,
            d_1        => open,
            q_1        => s_spike_out,
            clk_2      => out_clk,
            ce_2       => spike_out_ce,
            address_2  => spike_out_addr(LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto LOG2CEIL(NR_PARALLEL_NEURONS)),
            d_2        => spike_out_data_temp
        );

    process (out_clk)
    begin
        if rising_edge(out_clk) then
            spike_out_addr_d <= spike_out_addr;
        end if;
    end process;

    spike_out_data <= spike_out_data_temp(conv_integer("0"&spike_out_addr_d(LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0)));

    con_mem: entity work.cyclic_buffer_2
        generic map(
            DATA_WIDTH    => 1+LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS),
            ADDRESS_WIDTH => LOG2CEIL(TOTAL_NR_WEIGHTS(NR_WEIGHTS)*CONST_NR_PARALLEL_NEURONS),
            MEMORY_AMOUNT => TOTAL_NR_WEIGHTS(NR_WEIGHTS)*CONST_NR_PARALLEL_NEURONS,
            CONTENT       => intercon_mem
        )
        port map(
            clk      => network_clk,
            reset    => s_controlled_reset,
--            we       => '0',
            ce       => s_next_con,
            addr_dec => s_next_con,
            d        => s_con_mem_data
        );

    network_instance: entity work.network
        generic map(
            NR_PARALLEL_NEURONS    => NR_PARALLEL_NEURONS,
            NR_SERIAL_NEURONS      => NR_SERIAL_NEURONS,
            NR_WEIGHTS             => NR_WEIGHTS,
            WEIGHT_WIDTH           => LOG2CEIL(MAXIMUM_NR_WEIGHTS(NR_WEIGHTS)),
            FROM_MEM_ADDRESS_WIDTH => LOG2CEIL(NR_SERIAL_NEURONS),
            CON_MEM_DATA_WIDTH     => 1+LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)
        )
        port map(
            clk               => network_clk,
            reset             => s_controlled_reset,
            start             => s_network_start,
            neuron_number     => s_neuron_counter,
            ready             => s_network_ready,
            from_mem_addr     => s_con_from_addr,
            from_mem_data     => s_con_data_in,
            to_mem_we         => s_con_to_we,
            to_mem_addr_dec   => s_con_to_addr_dec,
            to_mem_data_sel   => s_con_to_data_sel,
            to_mem_data       => s_con_data_out,
            con_mem_dec       => s_next_con,
            con_mem_data      => s_con_mem_data,
            ext_input_addr    => spike_in_addr, -- test_in_addr,
            ext_input_data    => spike_in_data -- test_in_data
        );


--     process (network_clk)
--     begin
--         if rising_edge(network_clk) then
--             cycle_counter_buff  <= cycle_counter;
--             cycle_counter_buff2 <= cycle_counter_buff;
-- 
--             if s_controlled_reset = '1' then
--                 test_in_data <= '0';
--             else
--                 if test_in_addr < 40 and cycle_counter_buff2 < 8 then
--                     test_in_data <= '1';
--                 else
--                     test_in_data <= '0';
--                 end if;
-- 
--             end if;
--         end if;
--     end process;
-- 
-- 
--     process (clk)
--     begin
--         if rising_edge(clk) then
--             if s_controlled_reset = '1' then
--                 cycle_counter <= (others => '0');
--             elsif s_som_we = '1' and s_last_cycle = '1' then
--                 cycle_counter <= cycle_counter + 1;
--             end if;
--         end if;
--     end process;



    syn_membr_mem: entity work.treeport_mem
        generic map(
            DATA_WIDTH    => NR_PARALLEL_NEURONS,
            ADDRESS_WIDTH => LOG2CEIL(TOTAL_MEM(NR_BITS,NR_SYNAPSES,DECAY_SHIFT,REFRACTORINESS,REFRACTORY_WIDTH)),
            CONTENT       => reg_mem
        )
        port map(
            clk   => clk,
            clkx2 => clkx2,
--            dia   => (others => '-'),
            dic   => s_smm_in,
--            dic   => (others => '-'),
--            wea   => '0',
            wec   => s_smm_we,
--            wec   => '0',
            addra => addr_1,
            addrb => addr_2,
            addrc => addr_3,
            doa   => s_smm_1,
            dob   => s_smm_2
--            doc   => open
        );

    datapath: for i in 0 to NR_PARALLEL_NEURONS-1 generate
        datapath_i: entity work.neuron_datapath
            port map(
                clk         => clk,
                force_one   => s_force_one,
                sel         => s_sel,
                fz_ce       => s_fz_ce,
                reset_fz    => s_reset_fz,
                neg_ce      => s_neg_ce,
                set_neg     => s_set_neg,
                reset_neg   => s_reset_neg,
                carry_ce    => s_carry_ce,
                reset_carry => s_reset_carry,
                sum_out     => s_sum_out,
                bypass      => s_bypass,
                smm_in_1    => s_smm_1(i),
                smm_in_2    => s_smm_2(i),
                smm_out     => s_smm_in(i),
                spike_in    => s_spike_in(i),
                spike_out   => s_spike_out(i),
                weight_in   => s_weight_in(i)
            );
    end generate;

    control: entity work.controller
        generic map(
            NR_BITS          => NR_BITS,
            NR_NEURONS       => NR_SERIAL_NEURONS,
            NR_SYNAPSES      => NR_SYNAPSES,
            NR_WEIGHTS       => NR_WEIGHTS,
            REFRACTORINESS   => REFRACTORINESS,
            REFRACTORY_WIDTH => REFRACTORY_WIDTH,
            DECAY_SHIFT      => DECAY_SHIFT
        )
        port map(
            clk              => clk,
            reset            => reset,
            start            => s_controller_start,
            neuron_number    => s_controller_counter,
            ready            => s_controller_ready,
            address_read_1   => addr_1,
            address_read_2   => addr_2,
            address_write    => addr_3,
            smm_we           => s_smm_we,
            wm_ai            => s_wm_ai,  -- both ce and shift signal
            sim_ai           => s_sim_ai, -- both ce and shift signal
            som_we           => s_som_we, -- both ce and shift signal
            force_one        => s_force_one,
            sel              => s_sel,
            fz_ce            => s_fz_ce,
            reset_fz         => s_reset_fz,
            neg_ce           => s_neg_ce,
            set_neg          => s_set_neg,
            reset_neg        => s_reset_neg,
            carry_ce         => s_carry_ce,
            reset_carry      => s_reset_carry,
	    sum_out          => s_sum_out,
            bypass           => s_bypass
        );

    --s_ready          <= s_controller_ready and s_network_ready;
    s_last_cycle     <= '1' when s_controller_counter = conv_std_logic_vector(NR_SERIAL_NEURONS-1, LOG2CEIL(NR_SERIAL_NEURONS)) else '0';

--  -- write spikes to output
--  process(clk,reset)
--  begin
--      if reset = '1' then
--          spike_out_data <= (others => '0');
--      elsif clk'event and clk = '1' then
--          if s_som_we = '1' then
--              spike_out_data <= s_spike_out;
--          end if;
--      end if;
--  end process;
--

    -- double buffering to reduce meta-stability
    process (clk)
    begin
        if rising_edge(clk) then
            s_network_ready_1 <= s_network_ready;
            s_network_ready_2 <= s_network_ready_1;
        end if;
    end process;
    s_ready <= s_controller_ready and s_network_ready_2;

    process (network_clk)
    begin
        if rising_edge(network_clk) then
            s_network_start_1 <= s_network_start;
            s_network_start_2 <= s_network_start_1;
        end if;
    end process;

    -- count neuron number and switch spike_in memory bank
    -- add the end of an interation step, also switch the spike_out memory bank
    process (clk, reset)
    begin
        if reset = '1' then
            s_system_state <= iteration_ready;
            s_switch_sim         <= '0';
            s_switch_som         <= '0';
            s_ready_out          <= '1';
            pe_ready             <= '0';
            timestep_ready       <= '0';
            s_neuron_counter     <= (others => '0');
            s_controller_counter <= (others => '0');
            s_controller_start   <= '0';
            s_network_start      <= '0';
        elsif rising_edge(clk) then
            case s_system_state is
                when iteration_ready =>
                    s_switch_sim       <= '0';
                    s_switch_som       <= '0';

                    if (start and s_ready) = '1' then
                        s_network_start <= '1';
                        pe_ready        <= '0';
                        timestep_ready  <= '0';
                        s_system_state  <= run;
                    end if;
                    s_ready_out <= '1';

                when run =>
                    s_network_start    <= '0';
                    s_controller_start <= '0';

                    if s_ready = '0' then
                        s_ready_out <= '0';
                    end if;

                    if (not s_ready_out and s_ready) = '1' then

                        s_switch_sim <= '1';
                        pe_ready     <= '1';

                        if s_last_cycle = '1' then
                            s_switch_som   <= '1';
                            timestep_ready <= '1';
                            s_system_state <= iteration_ready;
                        else
                            s_system_state <= cycle_ready;
                        end if;

                        -- update neuron counters
                        s_controller_counter <= s_neuron_counter;
                        if (s_neuron_counter /= conv_std_logic_vector(NR_SERIAL_NEURONS-1, LOG2CEIL(NR_SERIAL_NEURONS))) and (s_last_cycle = '0') then
                            s_neuron_counter <= s_neuron_counter + 1;
                        else
                            s_neuron_counter <= (others => '0');
                        end if;

                    end if;

                -- we insert one extra state to allow the controller reading the new neuron address
                -- we could also do it without, but this would decrease the clock speed
                when cycle_ready =>
                    s_switch_sim       <= '0';
                    s_switch_som       <= '0';

                    --if start = '1' then
                        s_network_start    <= not s_last_cycle;
                        s_controller_start <= '1';
                        pe_ready           <= '0';
                        timestep_ready     <= '0';
                        s_system_state     <= run;
                    --end if;
                    s_ready_out <= '1';

                --------------------------------------------------------------------------------    
                when others =>
                    assert false report "Unknown state!" severity error;
            end case;
        end if;
    end process;

end structure;
