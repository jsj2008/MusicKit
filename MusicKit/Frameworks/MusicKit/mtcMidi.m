/*
  $Id$
  Defined In: The MusicKit

  Description:
    This file factored out of MKConductor.m for purposes of separate copyright and
    to isolate MIDI time code functions.
    This file contains the MTCPrivate category of Conductor.

  Original Author: David Jaffe

  Copyright (c) Pinnacle Research, 1993
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.5  2000/01/27 19:04:07  leigh
  Now using NSPort replacing C Mach port API

  Revision 1.4  1999/11/14 21:31:03  leigh
  Corrected _MKErrorf arguments to be NSStrings

  Revision 1.3  1999/08/08 01:59:22  leigh
  Removed extraVars cruft

  Revision 1.2  1999/07/29 01:26:10  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#import "MKMidi.h" /*sb...*/

static double mangleTime(MKMidi *self,double driverTime)
{
    if (self->tvs->synchConductor)
      driverTime -= mtcTimeOffset;
    if (MKGetDeltaTMode() == MK_DELTAT_SCHEDULER_ADVANCE)
      driverTime += MKGetDeltaT();
    return driverTime;
}

- getMTCFormat:(short *)format hours:(short*)h min:(short *)m sec:(short *)s 
 frames:(short *)f;
	/* This only works if the receiver is in MTC synch mode.  Unlike 
	 * most of the Music Kit time methods and functions, this one gets the
	 * current time, whether or not [Conductor adjustTime] or 
	 * [Conductor lockPerformacne] was done.  if SCHEDULER_ADVANCE mode
	 * has been set, this time has deltaT added to it. 
	 */
{
    int r = MIDIGetMTCTime([self->devicePort machPort], [self->ownerPort machPort],format,h,m,s,f);
    double seconds;
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"getMTCFormat:");
    seconds = MKConvertMTCToSeconds(*format,*h,*m,*s,*f);
    seconds = mangleTime(self,seconds);
    MKConvertSecondsToMTC(seconds,*format,h,m,s,f);
    return self;
}

-(double)time
  /* Returns time according to the MIDI driver.  If deltaT mode is 
   * MK_DELTAT_SCHEDULER_ADVANCE, deltaT is added to this time.
   * If the receiver is providing time code for a Conductor, that 
   * Conductor's time offset is reflected in the time returned by this method.
   */
{
    int theTime;
    int r; 
    double t;
    if (deviceStatus == MK_devClosed)
      return 0;
    r = MIDIGetClockTime([self->devicePort machPort], [self->ownerPort machPort], &theTime);
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"time");
    t = theTime * _MK_MIDI_QUANTUM_PERIOD;
    return mangleTime(self,t);
}

-synchConductor
{
    return self->tvs->synchConductor;
}
