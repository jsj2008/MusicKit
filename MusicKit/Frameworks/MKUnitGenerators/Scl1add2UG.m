/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif
/* 
Modification history:

  11/22/89/daj - Changed to use UnitGenerator C functions for speed.	 
*/
/* This is a stub of the class you fill in. Generated by dsploadwrap.*/
#import <MusicKit/MusicKit.h>
#import "_unitGeneratorInclude.h"
#import "Scl1add2UG.h"
@implementation Scl1add2UG:MKUnitGenerator
{ /* Instance variables go here */
}
/*    Scl1add2.

	You instantiate a subclass of the form Scl1add2UG<a><b><c>, where 
	<a> = space of output
	<b> = space of input1
	<c> = space of input2

      The scl1add2 unit-generator multiplies the first input by a
      scale factor, and adds it to the second input signal to produce a
      third.  The output vector can be the same as an input vector.
      Faster if space of input1 is not the same as the space of input2.
*/

enum args { i1adr, i1gin, aout, i2adr};

#import "scl1add2UGInclude.m"

#if _MK_UGOPTIMIZE 
+(BOOL)shouldOptimize:(unsigned) arg
{
    return YES;
}
#endif _MK_UGOPTIMIZE

-idleSelf
  /* Sets output to write to sink. */
{
    [self setAddressArgToSink:aout];
    return self;
}

-setInput1:aPatchPoint
{
    return MKSetUGAddressArg(self,i1adr,aPatchPoint);
}

-setInput2:aPatchPoint
{
    return MKSetUGAddressArg(self,i2adr,aPatchPoint);
}

-setOutput:aPatchPoint
{
    return MKSetUGAddressArg(self,aout,aPatchPoint);
}

-setScale:(double)val
  /* Sets scaling of input1. val is assumed between -1 and 1. */
{
    return MKSetUGDatumArg(self,i1gin,DSPDoubleToFix24(val));
}
@end

