#ifndef __MK_Out1bUG_H___
#define __MK_Out1bUG_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	Out1bUG.h 

	This class is part of the Music Kit UnitGenerator Library.
*/

#import <MusicKit/MKUnitGenerator.h>

@interface Out1bUG : MKUnitGenerator
/* Out1bUG - from dsp macro /usr/lib/dsp/ugsrc/out1b.asm (see source for details).

   Out1b writes its input signal to the mono output stream, or channel 1 (right)
   of the stereo output sample stream of the DSP, adding into that stream.
   The stream is cleared before each DSP tick (each orchestra program 
   iteration). Out1b also provides a scaling on the output channel.

   You instantiate a subclass of the form 
   Out1bUG<a>, where <a> = space of input

   */
{
  BOOL _reservedOut1b1; 
}

+(BOOL)shouldOptimize:(unsigned) arg;
/* Specifies that all arguments are to be optimized if possible. */

-setScale:(double)val;
/* Sets scaling for right channel. */ 

-runSelf;
/* If scaling has not been set, sets it to 1-e. */

-setInput:aPatchPoint;
/* Sets input patch point. */
@end

#endif
