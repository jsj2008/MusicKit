/*
  $Id$
  Defined In: The MusicKit

  Description:
    This file factored out of MKConductor.m for purposes of separate copyright and
    to isolate MIDI time code functions.
    This file contains the MTCPrivate category of MKConductor.

  Original Author: David Jaffe

  Copyright (c) Pinnacle Research, 1993
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
Modification history:

  $Log$
  Revision 1.7  2000/11/13 23:23:03  leigh
  Replaced exception macros with more explicit MKMD versions

  Revision 1.6  2000/04/07 18:41:45  leigh
  Upgraded logging to NSLog

  Revision 1.5  2000/04/01 00:31:34  leigh
  Replaced getTime with NSDate use

  Revision 1.4  1999/09/24 05:36:24  leigh
  Uses new MKPerformSndMIDI framework

  Revision 1.3  1999/09/04 23:00:01  leigh
  midi_driver.h now included from MKPerformMIDI framework

  Revision 1.2  1999/07/29 01:26:09  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#import "_musickit.h"
#import <MKPerformSndMIDI/midi_driver.h>

@implementation MKConductor(MTCPrivate)

#define SEEK_THRESHOLD 1.0  /* If a time difference this big or bigger occurs, seek */

-_MTCException:(int)exception
{
    double newTime;
    if (![MKConductor inPerformance])         /* This can happen if we're not separate-threaded */
      return self;
    if (MKIsTraced(MK_TRACEMIDI))
      NSLog(@"Midi time code exception: %s\n",
	      (exception == MKMD_EXCEPTION_MTC_STARTED_FORWARD) ? "time code started" :
	      (exception == MKMD_EXCEPTION_MTC_STOPPED) ? "time code stopped" :
	      (exception == MKMD_EXCEPTION_MTC_STARTED_REVERSE) ? "reverse time code started" :
	      "unknown exception");
    switch (exception) {
      case MKMD_EXCEPTION_MTC_STARTED_FORWARD:  
	switch (mtcStatus) {
	  case MTC_UNDEFINED: 
	    if (!startMTC(self,YES))
	      return nil;
	    break;
	  case MTC_STOPPED:  
	    newTime = [MTCSynch _time];
	    /* MTCTime is set in stopMTC() */
	    if (!startMTC(self,(ABS(newTime - MTCTime) > SEEK_THRESHOLD)))
	      return nil;
	    break;
	  case MTC_REVERSE: 
	    if (!startMTC(self,YES))
	      return nil;
	  default:
	  case MTC_FORWARD:
	    break;  /* Should never happen */
	}
	break;
      case MKMD_EXCEPTION_MTC_STOPPED:
	stopMTC(self);
	break;
      case MKMD_EXCEPTION_MTC_STARTED_REVERSE:
	reverseMTC(self);
	break;
      default:
	break;    
    }
    return self;
}

-_addActivePerformer:perf
{
    [activePerformers addObject:perf];
    return self;
}

-_removeActivePerformer:perf
{
    [activePerformers removeObject:perf];
    return self;
}

-_setMTCSynch:aMidiObj
{
    /* Sets up alarm and exception port, etc. 
     * This must be sent to when the performance is not in progress yet.
     * The MIDI object may be in any state (open, closed, etc.)
     *
     * Another restriction implied here is that only one conductor can use a 
     * particular midi object.  Hence if aMidiObj is already in use by a Conductor 
     * (and that Conductor is not the receiver), setMTCSynch: steals the synch
     * function from that Conductor.
     *
     */
    if (MTCSynch == aMidiObj) /* Already synched */
      return self;
    else if (theMTCCond != self)    
      [theMTCCond _setMTCSynch:nil];
    if (aMidiObj)
      theMTCCond = self;
    else theMTCCond = nil;
    [MTCSynch _setSynchConductor:nil];
    [aMidiObj _setSynchConductor:theMTCCond];
    MTCSynch = aMidiObj;
    [self setTimeOffset:timeOffset]; /* Resets it appropriately */
    if (MTCSynch) {
	if (!mtcHelper) 
	  mtcHelper = [[_MTCHelper alloc] init];
    } else {
        [mtcHelper release];
        mtcHelper = nil;
    }
    return self;
}

-(double)_MTCPerformerActivateOffset:sender
{
    if (!MTCSynch)
      return 0;
    return -[sender firstTimeTag];
}

static double slipThreshold = .01;

-setMTCSlipThreshold:(double)thresh
{
    slipThreshold = thresh;
    return self;
}

-_runMTC:(double)requestedTime :(double)actualTime
  /* This is invoked by the MIDI driver.  */
{
    #define SEEK_THRESHOLD 1.0
    double MTCTimeJump = requestedTime - actualTime;
    if (!inPerformance)         /* This can happen if we're not separate-threaded */
      return self;
    if (ABS(MTCTimeJump) > SEEK_THRESHOLD) {
	startMTC(self,YES);
	return self;
    }
    else {
	NSDate *newSysTime = [NSDate date];
	double newMTCTime = [MTCSynch _time];
	/* Using [MTCSynch _time] works MUCH better than using actualTime!
	 * Apparently, the time it takes to get the mach message from the
	 * driver is significant. (This makes sense, since the Conductor could
	 * be running so "actualTime" could be relatively old.)
	 */
        double sysTimeDiff = [sysTime timeIntervalSinceDate:newSysTime];//newSysTime - sysTime;
	double MTCTimeDiff = newMTCTime - MTCTime;
	double clockDiff = sysTimeDiff - MTCTimeDiff;
	/* If MTC is running slow, its time diff will be less than the sys clock.
	 * In this case, we want to add to our pauseOffset.  We don't do it here
	 * because we'd have to do an adjustTime(), which would mess up the
	 * Conductor's logical time.
	 */
	if (ABS(clockDiff) > slipThreshold)
	  [mtcHelper setTimeSlip:clockDiff];
	[MTCSynch _alarm:(double)actualTime + mtcPollPeriod];   
    }
    return self;
}

-_adjustPauseOffset:(double)v
    /* Invoked by _MTCHelper */
{
    if (MKIsTraced(MK_TRACEMIDI))
      NSLog(@"Slipping MIDI time code time by %f\n", v);
    _pauseOffset += v;
    sysTime = [[NSDate date] retain];
    MTCTime = [MTCSynch _time];
    repositionCond(self,beatToClock(self,PEEKTIME(_msgQueue))); 
    return self;
}

-(double) _setMTCTime:(double)desiredTime
/* This is invoked by the Midi object when an incoming MIDI message is received
 * and useInputTimeStamps is YES.
 */
{
    return [MKConductor _adjustTimeNoTE:desiredTime + _pauseOffset];
}

@end

