library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

library work;

use work.utility_package.log2ceil;
use work.utility_package.pow2ceil;

library proc_common_v2_00_a;
use proc_common_v2_00_a.proc_common_pkg.all;
entity user_logic is
  generic
  (
    -- Bus protocol parameters, do not add to or delete
    C_DWIDTH                       : integer              := 32;
    C_NUM_CE                       : integer              := 4
  );
  port
  (
    audio_clk                      : in  std_logic;
    sdata_in                       : in  std_logic;
    sync                           : out std_logic;
    sdata_out                      : out std_logic;
    snn_system_clk                 : in  std_logic;
    snn_network_clk                : in  std_logic;
    data                           : in std_logic_vector(0 to 7);
    cntrl                          : out  std_logic_vector(0 to 1);


    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Reset                   : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(0 to C_DWIDTH-1);
    Bus2IP_BE                      : in  std_logic_vector(0 to C_DWIDTH/8-1);
    Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_CE-1);
    Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_CE-1);
    IP2Bus_Data                    : out std_logic_vector(0 to C_DWIDTH-1);
    IP2Bus_Ack                     : out std_logic;
    IP2Bus_Retry                   : out std_logic;
    IP2Bus_Error                   : out std_logic;
    IP2Bus_ToutSup                 : out std_logic
  );
end entity user_logic;

----------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

  constant NR_SERIAL_NEURONS   : integer := 5;
  constant NR_PARALLEL_NEURONS : integer := 100;
  constant AANTAL_FILTERS      : integer := 88;
  constant NR_WAIT_CYCLES      : integer := 300; --512;
  constant FIXED_POINT_L       : integer := 17;
  constant FIXED_POINT_R       : integer := 17;
  constant ZERO                : std_logic_vector(34-1 downto 0) := (others => '0');


  signal slv_reg1                       : std_logic_vector(C_DWIDTH-1 downto 0);
  signal slv_reg1t                      : std_logic_vector(C_DWIDTH-1 downto 0);
  signal slv_reg2r                      : std_logic_vector(C_DWIDTH-1 downto 0);
--  signal slv_reg2w                      : std_logic_vector(0 to C_DWIDTH-1);
  signal slv_reg_write_select           : std_logic_vector(0 to 3);
  signal slv_reg_read_select            : std_logic_vector(0 to 3);
  signal slv_ip2bus_data                : std_logic_vector(C_DWIDTH-1 downto 0);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;

  signal slv_reg1t_d                    : std_logic_vector(C_DWIDTH-1 downto 0);
  signal slv_reg1t_dd                   : std_logic_vector(C_DWIDTH-1 downto 0);

  signal combined_reset                 : std_logic;
  signal s_sync                         : std_logic;
  signal s_sync_old                     : std_logic;
  signal s_sdata_out                    : std_logic;
  signal s_start                        : std_logic;
  signal s_start2                       : std_logic;
  signal s_start3                       : std_logic;
  signal s_read_ce                      : std_logic;
  signal s_filtered                     : std_logic_vector(FIXED_POINT_L+FIXED_POINT_R-1 downto 0) := (others => '0');

  signal s_mult1                        : std_logic_vector(34-1 downto 0); -- 18x18 multipliers, but for std_logic_vector only 17x17
  signal s_mult1_d                      : std_logic_vector(34-1 downto 0); -- 18x18 multipliers, but for std_logic_vector only 17x17
  signal s_mult2                        : std_logic_vector(34-1 downto 0); -- 18x18 multipliers, but for std_logic_vector only 17x17
  signal s_mult2_d                      : std_logic_vector(34-1 downto 0); -- 18x18 multipliers, but for std_logic_vector only 17x17
  signal s_filtered_old                 : std_logic_vector(FIXED_POINT_L+FIXED_POINT_R-1 downto 0);
  signal s_filtered_new                 : std_logic_vector(FIXED_POINT_L+FIXED_POINT_R-1 downto 0); -- 18x18 multipliers, but for std_logic_vector only 17x17
  signal s_new_filtered_in              : std_logic_vector(FIXED_POINT_L+FIXED_POINT_R-1 downto 0);

  signal s_inject_spikes                : std_logic_vector(FIXED_POINT_L+FIXED_POINT_R-1 downto 0) := (others => '0');
  signal s_inject_spikes_d              : std_logic_vector(FIXED_POINT_L+FIXED_POINT_R-1 downto 0) := (others => '0');
  signal s_inject_spikes_dd             : std_logic_vector(FIXED_POINT_L+FIXED_POINT_R-1 downto 0) := (others => '0');
  signal s_inject_spikes_ddd            : std_logic_vector(FIXED_POINT_L+FIXED_POINT_R-1 downto 0) := (others => '0');
  signal s_inject_spikes_dddd           : std_logic_vector(FIXED_POINT_L+FIXED_POINT_R-1 downto 0) := (others => '0');

  signal s_spike_in_addr        : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);
  signal s_spike_in_data        : std_logic;
  signal s_spike_out_data       : std_logic;
  signal s_spike_out_data_d     : std_logic;
  signal s_spike_out_data_dd    : std_logic;
  signal s_spike_out_data_ddd   : std_logic;

  signal cycle_counter       : integer := 0;
  signal macro_cycle_counter : integer := 0;

  signal filt_count_bits       : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS)-1 downto 0);
  signal filt_count_bits_d     : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS)-1 downto 0);
  signal filt_count_bits_dd    : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS)-1 downto 0);
  signal filt_count_bits_ddd   : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS)-1 downto 0);
  signal filt_count_bits_dddd  : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS)-1 downto 0);
  signal filt_count_bits_ddddd : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS)-1 downto 0);
  signal snn_count_bits        : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);

  signal pe_counter            : integer := 0;
  signal snn_addr_base         : std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);

  signal snn_ready        : std_logic;
  signal fm_we            : std_logic;
  signal fm_we_d          : std_logic;
  signal fm_we_dd         : std_logic;
  signal fm_we_ddd        : std_logic;
  signal fm_we_dddd       : std_logic;

  signal last_cycle       : std_logic;
  signal last_cycle_d     : std_logic;
  signal last_cycle_dd    : std_logic;
  signal last_cycle_ddd   : std_logic;
  signal last_cycle_dddd  : std_logic;

  signal fake_ce          : std_logic;
  signal val_out          : std_logic_vector(FIXED_POINT_L+FIXED_POINT_R-1 downto 0) := (others => '0');
--  signal val_out          : std_logic_vector(16-1 downto 0) := (others => '0');

  signal start_software      : std_logic;
  signal start_software_d    : std_logic;
  signal start_software_dd   : std_logic;
  signal start_software_ddd  : std_logic;
  signal start_software_dddd : std_logic;


  signal snn_ready_d   : std_logic;
  signal snn_ready_dd  : std_logic;
  signal snn_ready_ddd : std_logic;
  signal pe_ready      : std_logic;

   signal lin_reg_we     : std_logic;
   signal lin_reg_addr   : std_logic_vector(9+4-1 downto 0);
   signal lin_reg_data_w : std_logic_vector(C_DWIDTH-1 downto 0);
   signal lin_reg_data_r : std_logic_vector(C_DWIDTH-1 downto 0);
   signal lin_res_weight : std_logic_vector(16*32-1 downto 0);
   signal lin_res_mult   : std_logic_vector(16*32-1 downto 0);
   signal lin_res_accum  : std_logic_vector(16*32-1 downto 0);

  -- 100 : read only, spike memory
  -- 010 : write only, spike address
  -- 001 : read/write, reset IP (bit 0 write), IP ready (bit 0 read)

  signal network_ready, controller_ready, reset : std_logic;
  -- signal audio_clk, snn_system_clk, snn_network_clk, bus2ip_clk : std_logic;

--   signal s_test_audio, s_test_audio1, s_test_audio2 : std_logic_vector(16-1 downto 0);
--   signal s_test_audio_trigger, s_test_audio_trigger1, s_test_audio_trigger2, s_test_audio_trigger3 : std_logic;
--   signal s_test_save_audio : std_logic;
--   signal s_test_address : std_logic_vector(16-1 downto 0);
--   signal s_test_switch : std_logic;

	signal s_adc_data : std_logic_vector(7 downto 0);
	signal temp_data : std_logic_vector(8 downto 0);
	signal temp2_data : std_logic_vector(8 downto 0);
	
component system_snn is
port(
    system_clk       :  in std_logic; -- clock of the processing elements
    network_clk      :  in std_logic; -- clock of the copying proces, must be equal or higher then the system clock!
    reset            :  in std_logic; -- reset network (asynchronous)
    start            :  in std_logic; -- start new processing cycle
    pe_ready         : out std_logic; -- current PE ready
    timestep_ready   : out std_logic; -- current time-step_ready

    spike_in_addr    : out std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);
    spike_in_data    :  in std_logic ;-- must be available one clocktick after the address has been set

    out_clk          :  in std_logic;
    spike_out_ce     :  in std_logic;
    spike_out_addr   :  in std_logic_vector(LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS)-1 downto 0);
    spike_out_data   : out std_logic;

    network_ready    : out std_logic;
    controller_ready : out std_logic
);
end component;

component schakeling is 
port(
	clk        :  in std_logic;
	reset      :  in std_logic;
	SDATA_in   :  in std_logic;

	SYNC       : out std_logic;
	SDATA_OUT  : out std_logic;
	
	START      : out std_logic;


	adc_data : in std_logic_vector(7 downto 0);

--    test_audio_out     : out std_logic_vector(16-1 downto 0);
--    test_audio_trigger : out std_logic;

	spike_clk  :  in std_logic;
	spike_addr :  in std_logic_vector(LOG2CEIL(AANTAL_FILTERS)-1 downto 0);
	spike_data : out std_logic
);
end component;

begin
  slv_reg_write_select <= Bus2IP_WrCE(0 to 3);
  slv_reg_read_select  <= Bus2IP_RdCE(0 to 3);
  slv_write_ack        <= Bus2IP_WrCE(0) or Bus2IP_WrCE(1) or Bus2IP_WrCE(2) or Bus2IP_WrCE(3);
  slv_read_ack         <= Bus2IP_RdCE(0) or Bus2IP_RdCE(1) or Bus2IP_RdCE(2) or Bus2IP_WrCE(3);

  -- implement slave model register(s)
  SLAVE_REG_WRITE_PROC : process( Bus2IP_Clk ) is
  begin
    if rising_edge(Bus2IP_Clk) then
      if Bus2IP_Reset = '1' then
       -- slv_reg1t      <= (others => '0');
        lin_reg_addr   <= (others => '0');
        lin_reg_data_w <= (others => '0');
        lin_reg_we     <= '0';
      else
        lin_reg_we <= '0';
        case slv_reg_write_select is
          when "0100" => slv_reg1t <= slv_reg1; -- reg 1
          when "0010" => lin_reg_addr <= slv_reg1(9+4-1 downto 0); -- reg 2
          when "0001" => -- reg 3
            lin_reg_data_w <= slv_reg1;
            lin_reg_we <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process SLAVE_REG_WRITE_PROC;

  CONV_TO2DOWNTO_BUS : process(Bus2IP_Data) is
  begin
    for byte_index in 0 to C_DWIDTH-1 loop
      slv_reg1(byte_index) <= Bus2IP_Data(C_DWIDTH-1-byte_index);
    end loop;
  end process CONV_TO2DOWNTO_BUS;
--  slv_reg1 <= Bus2IP_Data;

  CONV_DOWNTO2TO_BUS : process(slv_ip2bus_data) is
  begin
    for byte_index in 0 to C_DWIDTH-1 loop
      IP2Bus_Data(byte_index) <= slv_ip2bus_data(C_DWIDTH-1-byte_index);
    end loop;
  end process CONV_DOWNTO2TO_BUS;
--  IP2Bus_Data        <= slv_ip2bus_data;

  -- implement slave model register read mux
  SLAVE_REG_READ_PROC : process( slv_reg_read_select, val_out, lin_reg_data_r, slv_reg2r ) is
  begin
    case slv_reg_read_select is
      when "1000" => slv_ip2bus_data <= slv_reg2r; -- reg 0
      when "0100" => -- reg 1
              slv_ip2bus_data <= val_out(C_DWIDTH-1 downto 0);
--              slv_ip2bus_data(16-1 downto 0)        <= val_out;
--              for zero_fill in C_DWIDTH-1 downto 16 loop
--                slv_ip2bus_data(zero_fill) <= '0';
--              end loop;
--              slv_ip2bus_data(C_DWIDTH-1 downto FIXED_POINT_L+FIXED_POINT_R) <= ZERO(C_DWIDTH-1 downto FIXED_POINT_L+FIXED_POINT_R);
      when "0001" => slv_ip2bus_data <= lin_reg_data_r; -- reg 3
--      when "0000 0000000000000000" =>
      when others => slv_ip2bus_data <= (others => '0');
    end case;
  end process SLAVE_REG_READ_PROC;


  ------------------------------------------
  -- Example code to drive IP to Bus signals
  ------------------------------------------


  IP2Bus_Ack         <= slv_write_ack or slv_read_ack;
  IP2Bus_Error       <= '0';
  IP2Bus_Retry       <= '0';
  IP2Bus_ToutSup     <= '0';
  
  combined_reset <= Bus2IP_Reset; -- and slv_reg2w(0);

-------------------------------------------------

--  debug(0) <= audio_clk;
--  debug(1) <= sdata_in;
--  debug(2) <= s_sync;
--  debug(3) <= s_sdata_out;
--  debug(4) <= s_start;
--  debug(5) <= snn_system_clk;
--  debug(6) <= snn_network_clk;
--  debug(7) <= s_spike_in_data;
--  debug(8) <= Bus2IP_Clk;
--  debug(9) <= pe_ready;
--  debug(10) <= snn_ready;
--  debug(11) <= s_spike_out_data;
--  debug(12) <= slv_reg2r(0);
--  debug(13) <= fm_we;
--  debug(14) <= last_cycle;
--  debug(15) <= combined_reset;

-------------------------------------------------
-- new ADC controller (ADC0820)

	process(data)
	begin
		for i in 0 to 7 loop
			temp2_data(i) <= data(i);
		end loop;
	end process;

	cntrl(1) <= '0';
	temp2_data(temp2_data'left) <= '0';
	temp_data <= temp2_data - 127;
	
	process(audio_clk) 
	begin
		if rising_edge(audio_clk) then
			-- rising edge of sync, clock in data
			if s_sync = '1' and s_sync_old = '0' then
				s_adc_data <= temp_data(7 downto 0);
			end if;
			
			s_sync_old <= s_sync;
			cntrl(0) <= s_sync;
		end if;
	end process;
	
-------------------------------------------------

  audio: component schakeling
  port map (
    clk        => audio_clk,
    reset      => combined_reset,
    SDATA_in   => sdata_in,
    SYNC       => s_sync,
    SDATA_OUT  => s_sdata_out,
    START      => s_start, --slv_reg2r(0),

    adc_data   => s_adc_data,

--    test_audio_out     => s_test_audio,
--    test_audio_trigger => s_test_audio_trigger,

    spike_clk  => Bus2IP_Clk, --snn_network_clk, --Bus2IP_Clk, --snn_system_clk,
    spike_addr => s_spike_in_addr(LOG2CEIL(AANTAL_FILTERS)-1 downto 0), --s_spike_in_addr(LOG2CEIL(AANTAL_FILTERS)-1 downto 0), --filt_count_bits(LOG2CEIL(AANTAL_FILTERS)-1 downto 0), --slv_reg1t(LOG2CEIL(AANTAL_FILTERS)-1 downto 0), --s_spike_in_addr(LOG2CEIL(AANTAL_FILTERS)-1 downto 0)
    spike_data => s_spike_in_data --s_spike_in_data --s_spike_out_data --val_out(0) --s_spike_in_data
  );

--  s_new_filtered_in(FIXED_POINT_L+FIXED_POINT_R-1 downto 1) <= (others => '0');

  sync      <= s_sync;
  sdata_out <= s_sdata_out;


-- -- audio test!
--  process(Bus2IP_Clk, reset)
--  begin
-- 
--    if rising_edge(Bus2IP_Clk) then
--      if reset = '1' then
--        s_test_audio1 <= (others => '0');
--        s_test_audio2 <= (others => '0');
--        s_test_audio_trigger1 <= '0';
--        s_test_audio_trigger2 <= '0';
--        s_test_audio_trigger3 <= '0';
--        s_test_save_audio     <= '0';
--        s_test_address        <= (others => '0');
--        s_test_switch         <= '0';
--      else
--        s_test_audio1 <= s_test_audio;
--        s_test_audio2 <= s_test_audio1;
--        s_test_audio_trigger1 <= s_test_audio_trigger;
--        s_test_audio_trigger2 <= s_test_audio_trigger1;
--        s_test_audio_trigger3 <= s_test_audio_trigger2;
--        if s_test_audio_trigger2 = '1' and s_test_audio_trigger3 = '0' then
--            s_test_save_audio <= '1';
--            s_test_address    <= s_test_address + 1;
--        else
--            s_test_save_audio <= '0';
--        end if;
--        if s_test_address = 0 then
--            s_test_switch <= '1';
--        else
--            s_test_switch <= '0';
--        end if;
--      end if;
--    end if;
--  end process;
-- -- end audio test!
-------------------------------------------------

process(snn_system_clk)
begin
  if rising_edge(snn_system_clk) then
    s_start2 <= s_start;
    s_start3 <= s_start2;
  end if;
end process;

snn: component system_snn
port map (
 system_clk     => snn_system_clk,
 network_clk    => snn_network_clk,
 reset          => combined_reset,
 start          => s_start3,
 pe_ready       => pe_ready,
 timestep_ready => snn_ready, --slv_reg2r(0),

 spike_in_addr  => s_spike_in_addr,
 spike_in_data  => s_spike_in_data,

 out_clk        => Bus2IP_Clk,
 spike_out_ce   => '1',
 spike_out_addr => snn_count_bits,
 spike_out_data => s_spike_out_data, --s_spike_out_data, --open,

 network_ready => network_ready,
 controller_ready => controller_ready
);

-------------------------------------------------

    process(Bus2IP_Clk)
    begin
        if rising_edge(Bus2IP_Clk) then

            if Bus2IP_Reset = '1' then
                cycle_counter       <= 0;
                macro_cycle_counter <= 0;

                pe_counter <= 0;
                snn_addr_base  <= (others => '0');

                start_software_d    <= '0';
                start_software_dd   <= '0';
                start_software_ddd  <= '0';
                start_software_dddd <= '0';
                slv_reg2r(0)        <= '0';

                fm_we       <= '0';
                fm_we_d     <= '0';
                fm_we_dd    <= '0';
                fm_we_ddd   <= '0';
                fm_we_dddd  <= '0';

                fake_ce     <= '0';

             else
                if fm_we = '0' and (snn_ready_dd = '1' and snn_ready_ddd = '0') then
                    if cycle_counter = NR_WAIT_CYCLES-1 then
                        cycle_counter <= 0;
                        macro_cycle_counter <= macro_cycle_counter + 1;
                    else
                        cycle_counter <= cycle_counter + 1;
                    end if;
                    fm_we <= '1';
                elsif fm_we = '1' then

                    if pe_counter < NR_PARALLEL_NEURONS-1 then
                        pe_counter      <= pe_counter + 1;
                        filt_count_bits <= filt_count_bits + 1;
                    else
                        pe_counter <= 0;
                        if filt_count_bits < NR_PARALLEL_NEURONS*NR_SERIAL_NEURONS-1 then
                            filt_count_bits <= filt_count_bits + 1;
                            snn_addr_base   <= snn_addr_base  + POW2CEIL(NR_PARALLEL_NEURONS);
                        else
                            filt_count_bits <= (others => '0');
                            snn_addr_base   <= (others => '0');
                            fm_we           <= '0';
                        end if;
                    end if;

--                      if filt_count_bits < 88-1 then
--                          filt_count_bits <= filt_count_bits + 1;
--                      else
--                          filt_count_bits <= (others => '0');
--                          fm_we           <= '0';
--                      end if;

                end if;

                start_software_d    <= start_software;
                start_software_dd   <= start_software_d;
                start_software_ddd  <= start_software_dd;
                start_software_dddd <= start_software_ddd;
                slv_reg2r(0)        <= start_software_dddd;

                fm_we_d     <= fm_we;
                fm_we_dd    <= fm_we_d;
                fm_we_ddd   <= fm_we_dd;
                fm_we_dddd  <= fm_we_ddd;

                fake_ce     <= '1';

            end if;

--            snn_ready     <= s_start;

            snn_ready_d   <= snn_ready;
            snn_ready_dd  <= snn_ready_d;
            snn_ready_ddd <= snn_ready_dd;

            s_mult1        <= s_filtered_old(17-1 downto 0)  * conv_std_logic_vector(integer(0.9979*real(2**FIXED_POINT_R)),FIXED_POINT_R);
            s_mult2        <= s_filtered_old(34-1 downto 17) * conv_std_logic_vector(integer(0.9979*real(2**FIXED_POINT_R)),FIXED_POINT_R);

            s_mult1_d      <= s_mult1;
            s_mult2_d      <= s_mult2;

--            s_filtered_new <= ZERO(34-1 downto 17) & s_mult1(34-1 downto 17) + s_mult2 + s_inject_spikes_dd;
            s_filtered_new <= ZERO(34-1 downto 17) & s_mult1_d(34-1 downto 17) + s_mult2_d;-- + s_inject_spikes_ddd;

            last_cycle_d     <= last_cycle;
            last_cycle_dd    <= last_cycle_d;
            last_cycle_ddd   <= last_cycle_dd;
            last_cycle_dddd  <= last_cycle_ddd;

            filt_count_bits_d     <= filt_count_bits;
            filt_count_bits_dd    <= filt_count_bits_d;
            filt_count_bits_ddd   <= filt_count_bits_dd;
            filt_count_bits_dddd  <= filt_count_bits_ddd;
            filt_count_bits_ddddd <= filt_count_bits_dddd;

            s_spike_out_data_d   <= s_spike_out_data;
            s_spike_out_data_dd  <= s_spike_out_data_d;
            s_spike_out_data_ddd <= s_spike_out_data_dd;

            slv_reg1t_d  <= slv_reg1t;
            slv_reg1t_dd <= slv_reg1t_d;

            s_inject_spikes_d    <= s_inject_spikes;
            s_inject_spikes_dd   <= s_inject_spikes_d;
            s_inject_spikes_ddd  <= s_inject_spikes_dd;
            s_inject_spikes_dddd <= s_inject_spikes_ddd;

        end if;
    end process;

    snn_count_bits  <= snn_addr_base + conv_std_logic_vector(pe_counter, LOG2CEIL(NR_SERIAL_NEURONS)+LOG2CEIL(NR_PARALLEL_NEURONS));

    last_cycle     <= '1' when cycle_counter = NR_WAIT_CYCLES-2 else '0'; --512
    start_software <= '1' when cycle_counter = NR_WAIT_CYCLES-1 else '0';
--    start_software <= '1' when s_test_switch = '1' else '0';


    -- only for testing purposes
--    s_inject_spikes <= ("00000000000000" & filt_count_bits & "10000000000") when (macro_cycle_counter = 100 or macro_cycle_counter = 200 or macro_cycle_counter = 300 or macro_cycle_counter = 400 or macro_cycle_counter = 405) else (others => '0');
--    s_new_filtered_in <= s_filtered_new + s_inject_spikes_dddd;

    s_new_filtered_in <= s_filtered_new + ("0000000000000000" & s_spike_out_data_ddd & "00000000000000000");  -- 17.17 fixed point notation
--    s_new_filtered_in <= s_filtered_new + ("0000000000000" & s_spike_out_data_ddd & "000000000000000000");  -- 14.18 fixed point notation

     fm: entity work.twoportclk_mem
        generic map(
            DATA_WIDTH    => FIXED_POINT_L+FIXED_POINT_R,
            ADDRESS_WIDTH => LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS),
            MEMORY_AMOUNT => NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS
        )
        port map(
            clk_1        => Bus2IP_Clk,

            -- because of synthesistool error, signal must be delayed with one extra clock cycle (this delay is removed while wrongly optimizing)
            address_1  => filt_count_bits_ddddd,
            ce_1       => fake_ce,
            we_1       => fm_we_dddd,
            d_1        => open,
            q_1        => s_new_filtered_in,

            clk_2      => Bus2IP_Clk,
            address_2  => filt_count_bits,
            ce_2       => '1',
            d_2        => s_filtered_old
        );

    fm2: entity work.twoportclk_mem
        generic map(
            DATA_WIDTH    => FIXED_POINT_L+FIXED_POINT_R,
            ADDRESS_WIDTH => LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS),
            MEMORY_AMOUNT => NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS
        )
        port map(
            clk_1      => Bus2IP_Clk,

            address_1  => filt_count_bits_ddddd,
            ce_1       => last_cycle_dddd,
            we_1       => fm_we_dddd,
            d_1        => open,
            q_1        => s_new_filtered_in,

            clk_2      => Bus2IP_Clk,
            address_2  => slv_reg1t(LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS)-1 downto 0), --(0 to LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS)-1),
            ce_2       => '1',
            d_2        => val_out
        );

-- audio test!
--     fm2: entity work.twoportclk_mem
--         generic map(
--             DATA_WIDTH    => 16,
--             ADDRESS_WIDTH => 16,
--             MEMORY_AMOUNT => 2**16
--         )
--         port map(
--             clk_1      => Bus2IP_Clk,
-- 
--             address_1  => s_test_address,
--             ce_1       => '1',
--             we_1       => s_test_save_audio,
--             d_1        => open,
--             q_1        => s_test_audio2,
-- 
--             clk_2      => Bus2IP_Clk,
--             address_2  => slv_reg1t(16-1 downto 0), --(0 to LOG2CEIL(NR_SERIAL_NEURONS*NR_PARALLEL_NEURONS)-1),
--             ce_2       => '1',
--             d_2        => val_out
--         );
-- end audio test!

--------------------------------

--   linreg : entity work.twoportclk_datawidth_mem
--   generic map (
--       ADDRESS_WIDTH_1 => 9+4,
--       DATA_WIDTH_1    => 32,
--       NB_PORTS_2      => 16,
--       ADDRESS_WIDTH_2 => 9,
--       MEMORY_AMOUNT   => 16*500
--   )
--   port map (
--       clk_1       => Bus2IP_Clk,
--       address_1   => lin_reg_addr,
--       ce_1        => '1',
--       we_1        => lin_reg_we,
--       d_1         => lin_reg_data_r,
--       q_1         => lin_reg_data_w,
-- 
--       clk_2       => Bus2IP_Clk,
--       address_2   => filt_counter_dd_bits(8 downto 0),
--       ce_2        => '1',
--       we_2        => '0',
--       d_2         => lin_res_weight,
--       q_2         => lin_res_weight -- not used
--   );
-- 
--   process(Bus2IP_Clk)
--   begin
--       if rising_edge(Bus2IP_Clk) then
--           if Bus2IP_Reset = '1' or (last_cycle = '1' and filt_counter = 0) then
--               s_filtered_reg <= (others => '0');
--               lin_res_accum <= (others => '0');
--               lin_res_mult <= (others => '0');
--           else
--               s_filtered_reg <= s_filtered;
--               for i in 0 to 15 loop
--                   -- fix these precisions !!
--                   lin_res_mult(i*32 to (i+1)*32-1) <= lin_res_weight(i*32 to (i+1)*32-1) * s_filtered_reg;
--               end loop;
--               if last_cycle_dddd = '1' and fm_we_dddd = '1' then
--                   lin_res_accum <= lin_res_accum + lin_res_mult;
--               end if;
--           end if;
--       end if;
--   end process;

end IMP;
