#ifndef __MK_Allpass1UG_H___
#define __MK_Allpass1UG_H___
/* 
	Allpass1UG.h 

	This class is part of the Music Kit UnitGenerator Library.
*/
#import <MusicKit/MKUnitGenerator.h>
@interface Allpass1UG:MKUnitGenerator
/* Allpass1UG  - from dsp macro /usr/lib/dsp/ugsrc/allpass1.asm. (see source for details)

   First order all pass filter.
	
   You allocate a subclass of the form Allpass1UG<a><b>, where 
   <a> = space of output and <b> = space of input.

   The allpass1 unit-generator implements a one-pole, one-zero
   allpass filter section in direct form. 

   The transfer function implemented is

		bb0 + 1/z
	H(z) =	---------
		1 + bb0/z

		
      */

+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible except the
 state variable. */

-setInput:aPatchPoint;
/* Sets input of filter. */
-setOutput:aPatchPoint;
/* Sets output of filter. */
-setBB0:(double)val;
/* Sets BB0 coefficient in equation above. */
-clear;
/* Clears filter state variable. */

-(double)delayAtFreq:(double)hzVal;
/* Returns filter delay at given frequency. */

@end

#endif
