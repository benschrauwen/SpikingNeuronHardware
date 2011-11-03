#include "xparameters.h"
#include "SNN.h"
#include "xgpio_l.h"

void set_michiel_display(int num)
{
// LO M LB B RB O RO
//	const int disp[] = {b1011111, b0000101, b1101110, b0101111, b0110101, b0111011, b1111011, b0001101, b1111111, b0111101, b1111101, b1110011, b1011010, b1100111, b1111010, b1111000, b0000000};
	const int disp[] = {0x5F    , 0x05    , 0x6E    , 0x2F    , 0x35    , 0x3B    , 0x7B    , 0x0D    , 0x7F    , 0x3D    , 0x7D    , 0x73    , 0x5A    , 0x67    , 0x7A    , 0x78    , 0x00};

   if(num < 17)
		XGpio_mWriteReg(XPAR_LEDS_4BIT_BASEADDR,XGPIO_DATA_OFFSET ,disp[num]);
}

int main()
{
	set_michiel_display(16);

	unsigned int *buffer;
	int h,i,j,k,c, loc;
	
	XGpio_mWriteReg(XPAR_LEDS_4BIT_BASEADDR,XGPIO_TRI_OFFSET,0);
	
	for(h=0;h<10;h++) {
		set_michiel_display(h);
		for(i=0;i<500000000;i++);;;
	}

//	print("------------------------------------\r\n");
	
//	buffer = malloc(sizeof(int)*(2^16));	
	buffer = malloc(sizeof(int)*1000*500);
	if(!buffer) {
		print("aargh, could not malloc memory, quitting");
		return 0;
	}

//   for(h=0;h<500*88;h++) buffer[h] = 0;
	
	set_michiel_display(16);	
	
	//while(1) {	
		c = 0;
		for(h=0;h<500;h++) {
		   //print(".");
			// wait for start
			while(!SNN_mReadSlaveReg0(XPAR_SNN_0_BASEADDR)) ;;;
		
         set_michiel_display(16);	
		
			for(j=0;j<500;j++) {			
//			for(j=0;j<50000;j++) {
				//loc = (j%50)+(j/50)*64;
				SNN_mWriteSlaveReg1(XPAR_SNN_0_BASEADDR, j);
	      	buffer[c++] = SNN_mReadSlaveReg1(XPAR_SNN_0_BASEADDR);
//	      	buffer[j] = SNN_mReadSlaveReg1(XPAR_SNN_0_BASEADDR);
			}
			//if (h%10 != 0)
			//  c -= 88;
				  
			// handshaking: wait until start signal is reset again
			while(SNN_mReadSlaveReg0(XPAR_SNN_0_BASEADDR)) ;;;
			
		}
      //print("\r\n");

 		c = 0;
		for(i=0;i<500;i++) {
   		set_michiel_display(i/50);
			for(j=0;j<500;j++) {
				xil_printf("%d\r\n",buffer[c]>>10);
				c++;
				for(k=0;k<2000;k++);;;
//		      set_michiel_display(j*10/(50000));				
			}
		}
		
		set_michiel_display(13);
		
//	}
//	print("------------------------------------\r\n");

	return 0;
}

