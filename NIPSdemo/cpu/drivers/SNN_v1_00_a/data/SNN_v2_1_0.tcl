##############################################################################
## Filename:          C:\temp\nipsedk/drivers/SNN_v1_00_a/data/SNN_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Tue Nov 21 16:04:57 2006 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "SNN" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" 
}
