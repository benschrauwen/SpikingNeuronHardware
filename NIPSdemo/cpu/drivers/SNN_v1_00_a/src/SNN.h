//////////////////////////////////////////////////////////////////////////////
// Filename:          C:\temp\nipsedk/drivers/SNN_v1_00_a/src/SNN.h
// Version:           1.00.a
// Description:       SNN Driver Header File
// Date:              Tue Nov 21 16:04:57 2006 (by Create and Import Peripheral Wizard)
//////////////////////////////////////////////////////////////////////////////

#ifndef SNN_H
#define SNN_H

/***************************** Include Files *******************************/

#include "xbasic_types.h"
#include "xstatus.h"
#include "xio.h"

/************************** Constant Definitions ***************************/


/**
 * User Logic Slave Space Offsets
 * -- SLAVE_REG0 : user logic slave module register 0
 * -- SLAVE_REG1 : user logic slave module register 1
 * -- SLAVE_REG2 : user logic slave module register 2
 */
#define SNN_USER_SLAVE_SPACE_OFFSET (0x00000000)
#define SNN_SLAVE_REG0_OFFSET (SNN_USER_SLAVE_SPACE_OFFSET + 0x00000000)
#define SNN_SLAVE_REG1_OFFSET (SNN_USER_SLAVE_SPACE_OFFSET + 0x00000004)
#define SNN_SLAVE_REG2_OFFSET (SNN_USER_SLAVE_SPACE_OFFSET + 0x00000008)

/***************** Macros (Inline Functions) Definitions *******************/

/**
 *
 * Write a value to a SNN register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the SNN device.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note    None.
 *
 * C-style signature:
 * 	void SNN_mWriteReg(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Data)
 *
 */
#define SNN_mWriteReg(BaseAddress, RegOffset, Data) \
 	XIo_Out32((BaseAddress) + (RegOffset), (Xuint32)(Data))

/**
 *
 * Read a value from a SNN register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the SNN device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note    None.
 *
 * C-style signature:
 * 	Xuint32 SNN_mReadReg(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
#define SNN_mReadReg(BaseAddress, RegOffset) \
 	XIo_In32((BaseAddress) + (RegOffset))


/**
 *
 * Write/Read value to/from SNN user logic slave registers.
 *
 * @param   BaseAddress is the base address of the SNN device.
 * @param   Value is the data written to the register.
 *
 * @return  Data is the data from the user logic slave register.
 *
 * @note    None.
 *
 * C-style signature:
 * 	Xuint32 SNN_mReadSlaveRegn(Xuint32 BaseAddress)
 *
 */
#define SNN_mWriteSlaveReg0(BaseAddress, Value) \
 	XIo_Out32((BaseAddress) + (SNN_SLAVE_REG0_OFFSET), (Xuint32)(Value))
#define SNN_mWriteSlaveReg1(BaseAddress, Value) \
 	XIo_Out32((BaseAddress) + (SNN_SLAVE_REG1_OFFSET), (Xuint32)(Value))
#define SNN_mWriteSlaveReg2(BaseAddress, Value) \
 	XIo_Out32((BaseAddress) + (SNN_SLAVE_REG2_OFFSET), (Xuint32)(Value))

#define SNN_mReadSlaveReg0(BaseAddress) \
 	XIo_In32((BaseAddress) + (SNN_SLAVE_REG0_OFFSET))
#define SNN_mReadSlaveReg1(BaseAddress) \
 	XIo_In32((BaseAddress) + (SNN_SLAVE_REG1_OFFSET))
#define SNN_mReadSlaveReg2(BaseAddress) \
 	XIo_In32((BaseAddress) + (SNN_SLAVE_REG2_OFFSET))

/************************** Function Prototypes ****************************/


/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the SNN instance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus SNN_SelfTest(void * baseaddr_p);

#endif // SNN_H
