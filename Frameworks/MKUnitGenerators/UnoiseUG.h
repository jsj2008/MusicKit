/*
  $Id$
  Defined In: The MusicKit
 
  Description:
    UnoiseUG - from dsp macro /usr/lib/dsp/ugsrc/unoise.asm (see source for details).

  You instantiate a subclass of the form UnoiseUG<a>, where 
  <a> = space of output.

  UnoiseUG computes uniform pseudo-white noise using the linear congruential 
  method for random number generation (reference: Knuth, volume II of The Art 
  of Computer Programming).

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Oscillators and Waveform Generators
/*!
  @class UnoiseUG
  @brief <b>UnoiseUG</b> produces white noise at the sampling rate.
  
UnoiseUG produces a series of random values within the range
	
0.0 &lt;= <i>f</i> &lt; 1.0

A new random value is generated every sample.  A similar class, SnoiseUG,
produce a new random value every tick.

<h2>Memory Spaces</h2>

<b>UnoiseUG<i>a</i></b>
<i>a</i>	output 
*/
#ifndef __MK_UnoiseUG_H___
#define __MK_UnoiseUG_H___

#import <MusicKit/MKUnitGenerator.h>

@interface UnoiseUG: MKUnitGenerator

/*!
  @brief You never send this message.

  It's invoked by sending the
  <b>idle</b> message to the object.  
  Sets the output patchpoint to <i>sink</i>, thus ensuring that
  the object does not produce any output.  Note that you must send
  <b>setOutput:</b> and <b>run</b> again to use the MKUnitGenerator
  after sending <b>idle</b>.
  @return Returns an id.
*/
- idleSelf;

/*!
  @brief Specifies that all arguments are to be optimized if possible except seed.
  @param arg is an unsigned.
  @return Returns an BOOL.
*/
+ (BOOL) shouldOptimize: (unsigned) arg;

/*!
  @param  seedVal is an DSPDatum.
  @return Returns <b>self</b>.
  @brief Sets the seed that's used to prime the random number generator.

  To create a unique series of random numbers, you should set the seed
 itself to a randomly generated number. This is the current value and thus is changed
 by the unit generator itself.
*/
- setSeed: (DSPDatum) seedVal;

/*!
  @brief Sets the output patchpoint to <i>aPatchPoint</i>.

  Returns <b>nil</b> if the argument isn't a patchpoint; otherwise returns <b>self</b>.
  @param  aPatchPoint is an id.
  @return Returns an id.
*/
-setOutput: (id) aPatchPoint;

@end

#endif
