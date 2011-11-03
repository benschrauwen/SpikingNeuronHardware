#include "xparameters.h"
#include "SNN.h"
#include "xgpio_l.h"

void set_michiel_display(int num) {
	const int disp[] = {0x5F    , 0x05    , 0x6E    , 0x2F    , 0x35    , 0x3B    , 0x7B    , 0x0D    , 0x7F    , 0x3D    , 0x7D    , 0x73    , 0x5A    , 0x67    , 0x7A    , 0x78    , 0x00};
	if(num < 17) XGpio_mWriteReg(XPAR_LEDS_4BIT_BASEADDR,XGPIO_DATA_OFFSET ,disp[num]);
}

int main() {
	set_michiel_display(16);

	unsigned int *buffer;
	int h,i,j,k,c, loc;
	
	XGpio_mWriteReg(XPAR_LEDS_4BIT_BASEADDR,XGPIO_TRI_OFFSET,0);
	
	buffer = malloc(sizeof(int)*1000*500);
	if(!buffer) {
		print("aargh, could not malloc memory, quitting");
		return 0;
	}

	for(i = 0;i < 10; i++) {	
		set_michiel_display(14);
		for(i=0;i<1000000000;i++);;;

		set_michiel_display(i);
	
		c = 0;
		for(h=0;h<200;h++) {
			// wait for start
			while(!SNN_mReadSlaveReg0(XPAR_SNN_0_BASEADDR)) ;;;
			
			for(j=0;j<500;j++) {			
				SNN_mWriteSlaveReg1(XPAR_SNN_0_BASEADDR, j);
				buffer[c++] = SNN_mReadSlaveReg1(XPAR_SNN_0_BASEADDR);
			}
					  
			// handshaking: wait until start signal is reset again
			while(SNN_mReadSlaveReg0(XPAR_SNN_0_BASEADDR)) ;;;
		}
	
		set_michiel_display(16);

		for(j=0;j<200*500;j++) {
			xil_printf("%d\n",buffer[j]>>16);
			for(k=0;k<2000;k++);;;
		}
	}
		
	set_michiel_display(13);

	return 0;
}

