/* The start of this class was generated by dsploadwrap */
#import <musickit/musickit.h>
#import "RampUG.h"
@implementation RampUG:UnitGenerator
{
}

enum args { aout, slp, val}; /* This is provided by dsploadwrap. */

#import "rampUGInclude.m"

/* From here on, we added ourselves, by hand. ------------------------------ */
-setOutput:aPatchPoint
  /* Set output of ramper */
{
    [self setAddressArg:aout to:aPatchPoint];
    return self;
}

-setSlope:(double)aVal
{
    DSPFix48 aFix48;
    DSPDoubleToFix48UseArg(aVal,&aFix48);
    [self setDatumArg:slp toLong:&aFix48];
    return self;
}

-setCurVal:(double)aVal
{
    DSPFix48 aFix48;
    DSPDoubleToFix48UseArg(aVal,&aFix48);
    [self setDatumArg:val toLong:&aFix48];
    return self;
}

-setConstant:(double)aVal
{
    return [[self setSlope:0.0] setCurVal:aVal];
}

-idleSelf
{
    [self setAddressArgToSink:aout]; /* Patch output to sink. */
    return self;
}

@end
