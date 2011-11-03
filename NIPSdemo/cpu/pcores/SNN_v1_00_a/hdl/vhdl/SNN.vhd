library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v2_00_a;
use proc_common_v2_00_a.proc_common_pkg.all;
use proc_common_v2_00_a.ipif_pkg.all;
library opb_ipif_v3_01_c;
use opb_ipif_v3_01_c.all;

library SNN_v1_00_a;
use SNN_v1_00_a.all;

entity SNN is
  generic
  (
    C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
    C_HIGHADDR                     : std_logic_vector     := X"00000000";
    C_OPB_AWIDTH                   : integer              := 32;
    C_OPB_DWIDTH                   : integer              := 32;
    C_FAMILY                       : string               := "virtex2p"
  );
  port
  (
    ac97_clk                       : in  std_logic;
    ac97_sdata_in                  : in  std_logic;
    ac97_sync                      : out std_logic;
    ac97_sdata_out                 : out std_logic;
    snn_system_clk                 : in  std_logic;
    snn_network_clk                : in  std_logic;
    data                           : in  std_logic_vector(0 to 7);
    cntrl                          : out  std_logic_vector(0 to 1);

    OPB_Clk                        : in  std_logic;
    OPB_Rst                        : in  std_logic;
    Sl_DBus                        : out std_logic_vector(0 to C_OPB_DWIDTH-1);
    Sl_errAck                      : out std_logic;
    Sl_retry                       : out std_logic;
    Sl_toutSup                     : out std_logic;
    Sl_xferAck                     : out std_logic;
    OPB_ABus                       : in  std_logic_vector(0 to C_OPB_AWIDTH-1);
    OPB_BE                         : in  std_logic_vector(0 to C_OPB_DWIDTH/8-1);
    OPB_DBus                       : in  std_logic_vector(0 to C_OPB_DWIDTH-1);
    OPB_RNW                        : in  std_logic;
    OPB_select                     : in  std_logic;
    OPB_seqAddr                    : in  std_logic
  );

  attribute SIGIS : string;
  attribute SIGIS of OPB_Clk       : signal is "Clk";
  attribute SIGIS of OPB_Rst       : signal is "Rst";

end entity SNN;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of SNN is

	signal s_debug : std_logic_vector(0 to 15);
	
  ------------------------------------------
  -- Constant: array of address range identifiers
  ------------------------------------------
  constant ARD_ID_ARRAY                   : INTEGER_ARRAY_TYPE   := 
    (
      0  => USER_00                           -- user logic S/W register address space
    );

  ------------------------------------------
  -- Constant: array of address pairs for each address range
  ------------------------------------------
  constant ZERO_ADDR_PAD                  : std_logic_vector(0 to 64-C_OPB_AWIDTH-1) := (others => '0');

  constant USER_BASEADDR  : std_logic_vector  := C_BASEADDR;
  constant USER_HIGHADDR  : std_logic_vector  := C_HIGHADDR;

  constant ARD_ADDR_RANGE_ARRAY           : SLV64_ARRAY_TYPE     := 
    (
      ZERO_ADDR_PAD & USER_BASEADDR,              -- user logic base address
      ZERO_ADDR_PAD & USER_HIGHADDR               -- user logic high address
    );

  ------------------------------------------
  -- Constant: array of data widths for each target address range
  ------------------------------------------
  constant USER_DWIDTH                    : integer              := 32;

  constant ARD_DWIDTH_ARRAY               : INTEGER_ARRAY_TYPE   := 
    (
      0  => USER_DWIDTH                       -- user logic data width
    );

  ------------------------------------------
  -- Constant: array of desired number of chip enables for each address range
  ------------------------------------------
  constant USER_NUM_CE                    : integer              := 4;

  constant ARD_NUM_CE_ARRAY               : INTEGER_ARRAY_TYPE   := 
    (
      0  => pad_power2(USER_NUM_CE)           -- user logic number of CEs
    );

  ------------------------------------------
  -- Constant: array of unique properties for each address range
  ------------------------------------------
  constant ARD_DEPENDENT_PROPS_ARRAY      : DEPENDENT_PROPS_ARRAY_TYPE := 
    (
      0  => (others => 0)                     -- user logic slave space dependent properties (none defined)
    );

  ------------------------------------------
  -- Constant: pipeline mode
  -- 1 = include OPB-In pipeline registers
  -- 2 = include IP pipeline registers
  -- 3 = include OPB-In and IP pipeline registers
  -- 4 = include OPB-Out pipeline registers
  -- 5 = include OPB-In and OPB-Out pipeline registers
  -- 6 = include IP and OPB-Out pipeline registers
  -- 7 = include OPB-In, IP, and OPB-Out pipeline registers
  -- Note:
  -- only mode 4, 5, 7 are supported for this release
  ------------------------------------------
  constant PIPELINE_MODEL                 : integer              := 5;

  ------------------------------------------
  -- Constant: user core ID code
  ------------------------------------------
  constant DEV_BLK_ID                     : integer              := 0;

  ------------------------------------------
  -- Constant: enable MIR/Reset register
  ------------------------------------------
  constant DEV_MIR_ENABLE                 : integer              := 0;

  ------------------------------------------
  -- Constant: array of IP interrupt mode
  -- 1 = Active-high interrupt condition
  -- 2 = Active-low interrupt condition
  -- 3 = Active-high pulse interrupt event
  -- 4 = Active-low pulse interrupt event
  -- 5 = Positive-edge interrupt event
  -- 6 = Negative-edge interrupt event
  ------------------------------------------
  constant IP_INTR_MODE_ARRAY             : INTEGER_ARRAY_TYPE   := 
    (
      0  => 0  -- not used
    );

  ------------------------------------------
  -- Constant: enable device burst
  ------------------------------------------
  constant DEV_BURST_ENABLE               : integer              := 0;

  ------------------------------------------
  -- Constant: include address counter for burst transfers
  ------------------------------------------
  constant INCLUDE_ADDR_CNTR              : integer              := 0;

  ------------------------------------------
  -- Constant: include write buffer that decouples OPB and IPIC write transactions
  ------------------------------------------
  constant INCLUDE_WR_BUF                 : integer              := 0;

  ------------------------------------------
  -- Constant: index for CS/CE
  ------------------------------------------
  constant USER00_CS_INDEX                : integer              := get_id_index(ARD_ID_ARRAY, USER_00);

  constant USER00_CE_INDEX                : integer              := calc_start_ce_index(ARD_NUM_CE_ARRAY, USER00_CS_INDEX);

  ------------------------------------------
  -- IP Interconnect (IPIC) signal declarations -- do not delete
  -- prefix 'i' stands for IPIF while prefix 'u' stands for user logic
  -- typically user logic will be hooked up to IPIF directly via i<sig>
  -- unless signal slicing and muxing are needed via u<sig>
  ------------------------------------------
  signal iBus2IP_RdCE                   : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
  signal iBus2IP_WrCE                   : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
  signal iBus2IP_Data                   : std_logic_vector(0 to C_OPB_DWIDTH-1);
  signal iBus2IP_BE                     : std_logic_vector(0 to C_OPB_DWIDTH/8-1);
  signal iIP2Bus_Data                   : std_logic_vector(0 to C_OPB_DWIDTH-1)   := (others => '0');
  signal iIP2Bus_Ack                    : std_logic   := '0';
  signal iIP2Bus_Error                  : std_logic   := '0';
  signal iIP2Bus_Retry                  : std_logic   := '0';
  signal iIP2Bus_ToutSup                : std_logic   := '0';
  signal ZERO_IP2Bus_PostedWrInh        : std_logic_vector(0 to ARD_ID_ARRAY'length-1)   := (others => '0'); -- work around for XST not taking (others => '0') in port mapping
  signal ZERO_IP2RFIFO_Data             : std_logic_vector(0 to ARD_DWIDTH_ARRAY(get_id_index_iboe(ARD_ID_ARRAY, IPIF_RDFIFO_DATA))-1)   := (others => '0'); -- work around for XST not taking (others => '0') in port mapping
  signal ZERO_WFIFO2IP_Data             : std_logic_vector(0 to ARD_DWIDTH_ARRAY(get_id_index_iboe(ARD_ID_ARRAY, IPIF_WRFIFO_DATA))-1)   := (others => '0'); -- work around for XST not taking (others => '0') in port mapping
  signal ZERO_IP2Bus_IntrEvent          : std_logic_vector(0 to IP_INTR_MODE_ARRAY'length-1)   := (others => '0'); -- work around for XST not taking (others => '0') in port mapping
  signal iBus2IP_Clk                    : std_logic;
  signal iBus2IP_Reset                  : std_logic;
  signal uBus2IP_Data                   : std_logic_vector(0 to USER_DWIDTH-1);
  signal uBus2IP_BE                     : std_logic_vector(0 to USER_DWIDTH/8-1);
  signal uBus2IP_RdCE                   : std_logic_vector(0 to USER_NUM_CE-1);
  signal uBus2IP_WrCE                   : std_logic_vector(0 to USER_NUM_CE-1);
  signal uIP2Bus_Data                   : std_logic_vector(0 to USER_DWIDTH-1);

begin

  ------------------------------------------
  -- instantiate the OPB IPIF
  ------------------------------------------
  OPB_IPIF_I : entity opb_ipif_v3_01_c.opb_ipif
    generic map
    (
      C_ARD_ID_ARRAY                 => ARD_ID_ARRAY,
      C_ARD_ADDR_RANGE_ARRAY         => ARD_ADDR_RANGE_ARRAY,
      C_ARD_DWIDTH_ARRAY             => ARD_DWIDTH_ARRAY,
      C_ARD_NUM_CE_ARRAY             => ARD_NUM_CE_ARRAY,
      C_ARD_DEPENDENT_PROPS_ARRAY    => ARD_DEPENDENT_PROPS_ARRAY,
      C_PIPELINE_MODEL               => PIPELINE_MODEL,
      C_DEV_BLK_ID                   => DEV_BLK_ID,
      C_DEV_MIR_ENABLE               => DEV_MIR_ENABLE,
      C_OPB_AWIDTH                   => C_OPB_AWIDTH,
      C_OPB_DWIDTH                   => C_OPB_DWIDTH,
      C_FAMILY                       => C_FAMILY,
      C_IP_INTR_MODE_ARRAY           => IP_INTR_MODE_ARRAY,
      C_DEV_BURST_ENABLE             => DEV_BURST_ENABLE,
      C_INCLUDE_ADDR_CNTR            => INCLUDE_ADDR_CNTR,
      C_INCLUDE_WR_BUF               => INCLUDE_WR_BUF
    )
    port map
    (
      OPB_select                     => OPB_select,
      OPB_DBus                       => OPB_DBus,
      OPB_ABus                       => OPB_ABus,
      OPB_BE                         => OPB_BE,
      OPB_RNW                        => OPB_RNW,
      OPB_seqAddr                    => OPB_seqAddr,
      Sln_DBus                       => Sl_DBus,
      Sln_xferAck                    => Sl_xferAck,
      Sln_errAck                     => Sl_errAck,
      Sln_retry                      => Sl_retry,
      Sln_toutSup                    => Sl_toutSup,
      Bus2IP_CS                      => open,
      Bus2IP_CE                      => open,
      Bus2IP_RdCE                    => iBus2IP_RdCE,
      Bus2IP_WrCE                    => iBus2IP_WrCE,
      Bus2IP_Data                    => iBus2IP_Data,
      Bus2IP_Addr                    => open,
      Bus2IP_AddrValid               => open,
      Bus2IP_BE                      => iBus2IP_BE,
      Bus2IP_RNW                     => open,
      Bus2IP_Burst                   => open,
      IP2Bus_Data                    => iIP2Bus_Data,
      IP2Bus_Ack                     => iIP2Bus_Ack,
      IP2Bus_AddrAck                 => '0',
      IP2Bus_Error                   => iIP2Bus_Error,
      IP2Bus_Retry                   => iIP2Bus_Retry,
      IP2Bus_ToutSup                 => iIP2Bus_ToutSup,
      IP2Bus_PostedWrInh             => ZERO_IP2Bus_PostedWrInh,
      IP2RFIFO_Data                  => ZERO_IP2RFIFO_Data,
      IP2RFIFO_WrMark                => '0',
      IP2RFIFO_WrRelease             => '0',
      IP2RFIFO_WrReq                 => '0',
      IP2RFIFO_WrRestore             => '0',
      RFIFO2IP_AlmostFull            => open,
      RFIFO2IP_Full                  => open,
      RFIFO2IP_Vacancy               => open,
      RFIFO2IP_WrAck                 => open,
      IP2WFIFO_RdMark                => '0',
      IP2WFIFO_RdRelease             => '0',
      IP2WFIFO_RdReq                 => '0',
      IP2WFIFO_RdRestore             => '0',
      WFIFO2IP_AlmostEmpty           => open,
      WFIFO2IP_Data                  => ZERO_WFIFO2IP_Data,
      WFIFO2IP_Empty                 => open,
      WFIFO2IP_Occupancy             => open,
      WFIFO2IP_RdAck                 => open,
      IP2Bus_IntrEvent               => ZERO_IP2Bus_IntrEvent,
      IP2INTC_Irpt                   => open,
      Freeze                         => '0',
      Bus2IP_Freeze                  => open,
      OPB_Clk                        => OPB_Clk,
      Bus2IP_Clk                     => iBus2IP_Clk,
      IP2Bus_Clk                     => '0',
      Reset                          => OPB_Rst,
      Bus2IP_Reset                   => iBus2IP_Reset
    );

  ------------------------------------------
  -- instantiate the User Logic
  ------------------------------------------
  USER_LOGIC_I : entity SNN_v1_00_a.user_logic
    generic map
    (
      C_DWIDTH                       => USER_DWIDTH,
      C_NUM_CE                       => USER_NUM_CE
    )
    port map
    (
      audio_clk                      => ac97_clk,
      sdata_in                       => ac97_sdata_in,
      sync                           => ac97_sync,
      sdata_out                      => ac97_sdata_out,
      snn_system_clk                 => snn_system_clk,
      snn_network_clk                => snn_network_clk,

      data                           => data,
      cntrl                          => cntrl,

      Bus2IP_Clk                     => iBus2IP_Clk,
      Bus2IP_Reset                   => iBus2IP_Reset,
      Bus2IP_Data                    => uBus2IP_Data,
      Bus2IP_BE                      => uBus2IP_BE,
      Bus2IP_RdCE                    => uBus2IP_RdCE,
      Bus2IP_WrCE                    => uBus2IP_WrCE,
      IP2Bus_Data                    => uIP2Bus_Data,
      IP2Bus_Ack                     => iIP2Bus_Ack,
      IP2Bus_Retry                   => iIP2Bus_Retry,
      IP2Bus_Error                   => iIP2Bus_Error,
      IP2Bus_ToutSup                 => iIP2Bus_ToutSup
    );

  ------------------------------------------
  -- hooking up signal slicing
  ------------------------------------------
  uBus2IP_BE <= iBus2IP_BE(0 to USER_DWIDTH/8-1);
  uBus2IP_Data <= iBus2IP_Data(0 to USER_DWIDTH-1);
  uBus2IP_RdCE <= iBus2IP_RdCE(USER00_CE_INDEX to USER00_CE_INDEX+USER_NUM_CE-1);
  uBus2IP_WrCE <= iBus2IP_WrCE(USER00_CE_INDEX to USER00_CE_INDEX+USER_NUM_CE-1);
  iIP2Bus_Data(0 to USER_DWIDTH-1) <= uIP2Bus_Data;
end IMP;
