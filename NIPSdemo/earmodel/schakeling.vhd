library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.utility_package.log2ceil;

entity schakeling is 
generic(
    bit_lengte            : integer := 16;
    anti_quantisatie_bits : integer := 15;	
    aantal_filters        : integer := 88;
    boost_shifts          : integer :=  2;
    agc_bits              : integer := 32 --this is also the integer maximum
);

port(
    clk        :  in std_logic;
    reset      :  in std_logic;
    SDATA_in   :  in std_logic;

    SYNC       : out std_logic;
    SDATA_OUT  : out std_logic;

    START      : out std_logic;

    adc_data   : in std_logic_vector(7 downto 0);

--    output     : out std_logic_vector(aantal_filters-1 downto 0):=conv_std_logic_vector(0,aantal_filters)

--    test_audio_out     : out std_logic_vector(16-1 downto 0);
--    test_audio_trigger : out std_logic;

    spike_clk  :  in std_logic;
    spike_addr :  in std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
    spike_data : out std_logic
);
end schakeling;

architecture gedrag of schakeling is

signal A0:std_logic_vector(15 downto 0);
signal A1:std_logic_vector(15 downto 0);
signal A2:std_logic_vector(15 downto 0);
signal B0:std_logic_vector(15 downto 0);
signal B1:std_logic_vector(15 downto 0);
signal xn1_lees_in :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal xn2_lees_in  :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal yn1_lees_in :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal yn2_lees_in :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);

--signal input :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal start_sample :std_logic:= '1';  
signal input_ADC :std_logic_vector(bit_lengte-1 downto 0):= conv_std_logic_vector(0,bit_lengte);

signal xn1_schrijf_weg :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal xn2_schrijf_weg :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal yn1_schrijf_weg :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal yn2_schrijf_weg :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal yn_schrijf_weg :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal yn_lees_in :std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);

signal adres_RAM_Lstate_lees   : std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
signal adres_RAM_state_lees    : std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
signal adres_RAM_Rstate_lees   : std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
signal adres_RAM_state_schrijf : std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);

signal ram_data_in  : std_logic_vector(4*(bit_lengte+anti_quantisatie_bits)-1 downto 0);
signal ram_data_out : std_logic_vector(4*(bit_lengte+anti_quantisatie_bits)-1 downto 0);

signal state1 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state2 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state3 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state4 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state1_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state2_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state3_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state4_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state1_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state2_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state3_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal state4_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);

signal Lstate1 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate2 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate3 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate4 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate1_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate2_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate3_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate4_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate1_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate2_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate3_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Lstate4_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);

signal Rstate1 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate2 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate3 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate4 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate1_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate2_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate3_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate4_geha : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate1_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate2_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate3_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal Rstate4_gehb : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);

signal new_state1 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal new_state2 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal new_state3 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal new_state4 : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);

signal write_enable       : std_logic:= '1';
signal state_selectie     : std_logic;
signal clk_enable         : std_logic;
signal not_state_selectie : std_logic;

--signal toeval             : std_logic_vector(bit_lengte-1 downto 0):= conv_std_logic_vector(0,bit_lengte);
signal spike_train        : std_logic;
signal signed_output_agc4 : std_logic_vector(bit_lengte-boost_shifts downto 0);
signal s_switch           : std_logic;
signal s_sync             : std_logic;
signal s_adc_expanded     : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0);
constant zeros            : std_logic_vector (bit_lengte-boost_shifts-2 downto 0) := (others=>'0');
constant adc_zeros        : std_logic_vector (6+anti_quantisatie_bits-1 downto 0) := (others=>'0');
constant adc_ones         : std_logic_vector (anti_quantisatie_bits-1 downto 0) := (others=>'1');

signal output_agc1    : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits); 
signal output_agc2    : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal output_agc3    : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);
signal output_agc4    : std_logic_vector(bit_lengte+anti_quantisatie_bits-1 downto 0):= conv_std_logic_vector(0,bit_lengte+anti_quantisatie_bits);

--helper signals for VHDL suffering...
signal tmp_spike_train : std_logic_vector(0 downto 0);
signal tmp_spike_data  : std_logic_vector(0 downto 0);

--signal spike_clk  : std_logic;
signal s_spike_addr : std_logic_vector(LOG2CEIL(aantal_filters)-1 downto 0);
--signal spike_data : std_logic;


--signal test_counter : std_logic_vector(6*LOG2CEIL(aantal_filters)-1 downto 0);
--signal test_counter : std_logic_vector(16-1 downto 0);
--signal test_output  : std_logic_vector(0 downto 0);
--signal s_sync_old   : std_logic;

begin
   SYNC           <= s_sync;
   -- expand with sign extention -> or always zeros?
--    s_adc_expanded <= input_ADC & adc_zeros;
   s_adc_expanded <= adc_data(adc_data'left) & adc_data(adc_data'left) & adc_data & adc_zeros;

   -- s_adc_expanded <= input_ADC & adc_zeros when input_ADC(bit_lengte-1) = '0' else input_ADC & adc_ones;
--    s_adc_expanded <= "0" & test_counter(6-1 downto 0) & "000000000" & adc_zeros when test_counter < 8192 else (others => '0');

-- ADC test code!
--     process(clk, reset)
--     begin
--         if reset= '1' then
--             s_sync_old <= '0';
--             test_counter <= (others => '0');
--         elsif rising_edge(clk) then
--             s_sync_old <= s_sync;
--
--             -- if rising edge of s_sync
--             if s_sync = '1' and s_sync_old = '0' then
--                 test_counter <= test_counter + 1;
--             end if;
--         end if;
--     end process;
--
--     test_audio_trigger <= '1' when s_sync_old = '1' else '0'; --and test_counter(1 downto 0) = 0 else '0';
--     test_audio_out     <= input_ADC;
-- end ADC test code!


--   test_output <= "1" when adres_RAM_state_schrijf < test_counter(6*LOG2CEIL(aantal_filters)-1 downto 6) else "0";

--     process(clk, reset)
--     begin
--         if reset= '1' then
--             test_counter <= (others => '0');
--         elsif rising_edge(clk) then
--             if s_switch = '1' then
--                 if test_counter < conv_std_logic_vector((2**6)*aantal_filters, 6*LOG2CEIL(aantal_filters)) then
--                     test_counter <= test_counter + 1;
--                 else
--                     test_counter <= (others => '0');
--                 end if;
--             end if;
--         end if;
--     end process;


    fsm: entity work.FSM generic map(aantal_filters) --, LOG2CEIL(aantal_filters))	
    port map (clk,reset,adres_RAM_Lstate_lees,adres_RAM_state_lees,adres_RAM_Rstate_lees,adres_RAM_state_schrijf,s_sync,start_sample,write_enable,state_selectie,clk_enable);

    ADC: entity work.ADC_controller  
    port map(SDATA_IN,SDATA_OUT,clk,s_sync,input_ADC);

    not_state_selectie <= not(state_selectie);

    mul12 : entity work.MUL12 generic map(bit_lengte+anti_quantisatie_bits)
        port map(Lstate1_geha,state1_geha,Rstate1_geha,Lstate2_geha,state2_geha,Rstate2_geha,Lstate3_geha,state3_geha,Rstate3_geha,Lstate4_geha,state4_geha,Rstate4_geha,Lstate1_gehb,state1_gehb,Rstate1_gehb,Lstate2_gehb,state2_gehb,Rstate2_gehb,Lstate3_gehb,state3_gehb,Rstate3_gehb,Lstate4_gehb,state4_gehb,Rstate4_gehb,Lstate1,state1,Rstate1,Lstate2,state2,Rstate2,Lstate3,state3,Rstate3,Lstate4,state4,Rstate4,not_state_selectie
        );

    --fixed precalculated values with 16 bits
    rom:entity work.ROM generic map(16,aantal_filters)
        port map(clk,adres_RAM_state_lees,A0,A1,A2,B0,B1,clk_enable
        );

    ram_data_in <= xn1_schrijf_weg & xn2_schrijf_weg & yn1_schrijf_weg & yn2_schrijf_weg;

    xn1_lees_in <= ram_data_out(4*(bit_lengte+anti_quantisatie_bits)-1 downto 3*(bit_lengte+anti_quantisatie_bits));
    xn2_lees_in <= ram_data_out(3*(bit_lengte+anti_quantisatie_bits)-1 downto 2*(bit_lengte+anti_quantisatie_bits));
    yn1_lees_in <= ram_data_out(2*(bit_lengte+anti_quantisatie_bits)-1 downto 1*(bit_lengte+anti_quantisatie_bits));
    yn2_lees_in <= ram_data_out(1*(bit_lengte+anti_quantisatie_bits)-1 downto   (                               0));

    ram_1: entity work.twoportrw_mem
        generic map (
            DATA_WIDTH    => 4*(bit_lengte+anti_quantisatie_bits),
            ADDRESS_WIDTH => LOG2CEIL(aantal_filters),
            MEMORY_AMOUNT => aantal_filters
        )
        port map (
            clk       => clk,
            ce        => clk_enable,
            we        => write_enable,
            address_r => adres_RAM_state_lees,
            q         => ram_data_in,
            address_w => adres_RAM_state_schrijf,
            d         => ram_data_out
        );

    ram_2: entity work.twoportrw_mem
        generic map (
            DATA_WIDTH    => (bit_lengte+anti_quantisatie_bits),
            ADDRESS_WIDTH => LOG2CEIL(aantal_filters),
            MEMORY_AMOUNT => aantal_filters
        )
        port map (
            clk       => clk,
            ce        => clk_enable,
            we        => write_enable,
            address_r => adres_RAM_Lstate_lees,
            q         => yn_schrijf_weg,
            address_w => adres_RAM_state_schrijf,
            d         => yn_lees_in
        );

    filter:entity work.tweedeordefilter generic map(bit_lengte+anti_quantisatie_bits,16,aantal_filters)
        port map (A0,A1,A2,B0,B1,xn1_lees_in,xn2_lees_in,yn1_lees_in,yn2_lees_in,yn_lees_in,start_sample,s_adc_expanded,xn1_schrijf_weg,xn2_schrijf_weg,yn1_schrijf_weg,yn2_schrijf_weg,yn_schrijf_weg
        );


    RAM_AGCA : entity work.RAM_AGC generic map(bit_lengte+anti_quantisatie_bits,aantal_filters)
        port map(clk,clk_enable,write_enable,adres_RAM_Lstate_lees,adres_RAM_state_lees, adres_RAM_Rstate_lees,adres_RAM_state_schrijf,Lstate1_geha,state1_geha,Rstate1_geha,new_state1,Lstate2_geha,state2_geha,Rstate2_geha,new_state2,Lstate3_geha,state3_geha,Rstate3_geha,new_state3,Lstate4_geha,state4_geha,Rstate4_geha,new_state4,not_state_selectie
        );
    RAM_AGCB : entity work.RAM_AGC generic map(bit_lengte+anti_quantisatie_bits,aantal_filters)
        port map(clk,clk_enable,write_enable,adres_RAM_Lstate_lees,adres_RAM_state_lees, adres_RAM_Rstate_lees,adres_RAM_state_schrijf,Lstate1_gehb,state1_gehb,Rstate1_gehb,new_state1,Lstate2_gehb,state2_gehb,Rstate2_gehb,new_state2,Lstate3_gehb,state3_gehb,Rstate3_gehb,new_state3,Lstate4_gehb,state4_gehb,Rstate4_gehb,new_state4,state_selectie
        );
    agc1: entity work.AGC generic map(bit_lengte+anti_quantisatie_bits,agc_bits,aantal_filters,0.0032,0.00009765)
    port map(yn_schrijf_weg,Lstate1,state1,Rstate1,new_state1,output_agc1);
    agc2: entity work.AGC generic map(bit_lengte+anti_quantisatie_bits,agc_bits,aantal_filters,0.0016,0.0003905)
    port map(output_agc1,Lstate2,state2,Rstate2,new_state2,output_agc2);		
    agc3: entity work.AGC generic map(bit_lengte+anti_quantisatie_bits,agc_bits,aantal_filters,0.0008,0.0015136)
    port map(output_agc2,Lstate3,state3,Rstate3,new_state3,output_agc3);		
    agc4: entity work.AGC generic map(bit_lengte+anti_quantisatie_bits,agc_bits,aantal_filters,0.0004,0.0062305)
    port map(output_agc3,Lstate4,state4,Rstate4,new_state4,output_agc4);


--    random: entity work.LFSR_GENERIC generic map(bit_lengte)		-- length of pseudo-random sequence
--        port map (clk2,reset,toeval
--        );

--        pois: entity work.poisson generic map (bit_lengte)
--        port map( output_agc4,toeval,clk ,spike_train
--        );

--    signed_output_agc4 <= std_logic_vector(signed("0" & output_agc4(bit_lengte+anti_quantisatie_bits-boost_shifts-1 downto anti_quantisatie_bits)) + signed("11" & zeros));
    signed_output_agc4 <= signed("0" & output_agc4(bit_lengte+anti_quantisatie_bits-boost_shifts-1 downto anti_quantisatie_bits)) + signed("11" & zeros);

    delsig: entity work.delsig_mem 
        generic map (
            INPUT_WIDTH   => bit_lengte-boost_shifts,
            ADDRESS_WIDTH => LOG2CEIL(aantal_filters),
            NB_INSTANCES  => aantal_filters
        )
        port map(
            clk           => clk,
            clk_enable    => clk_enable,
            write_enable  => write_enable,
            address_in    => adres_RAM_state_schrijf,
            analog_input  => signed_output_agc4(bit_lengte-boost_shifts-1 downto 0),
            spike_output  => spike_train
        );

    -- output switch is activated just before new values are written in the next cycle
    s_switch           <= start_sample and clk_enable and not write_enable;
    -- start signal for the neural network, generated just after switching
    START              <= start_sample and clk_enable and write_enable;

    tmp_spike_train(0) <= spike_train;
    spike_data         <= tmp_spike_data(0);

    spike_out_mem: entity work.twoportclk_switching_fast
        generic map(
            DATA_WIDTH    => 1,
            ADDRESS_WIDTH => LOG2CEIL(aantal_filters),
            MEMORY_AMOUNT => aantal_filters
        )
        port map(
            reset      => reset,
            switch     => s_switch,

            clk_1      => clk,
            ce_1       => '1',
            we_1       => write_enable,
            address_1  => adres_RAM_state_schrijf,
            d_1        => open,
            q_1        => tmp_spike_train,

            clk_2      => spike_clk,
            ce_2       => '1',
            address_2  => s_spike_addr,
            d_2        => tmp_spike_data
        );

    s_spike_addr <= spike_addr + conv_std_logic_vector(10, LOG2CEIL(aantal_filters));

--    buffersp: entity work.buffer_spike generic map(bit_lengte,aantal_filters)
--        port map(clk,reset,adres_RAM_state_schrijf,spike_train,clk_enable,s_switch,output
--        );

end gedrag;
