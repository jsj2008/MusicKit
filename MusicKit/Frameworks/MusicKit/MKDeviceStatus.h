/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
  $Id$ 
    
  This file is part of the Music Kit.
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:44  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/* This file defines status protocol for the Music Kit "devices". Music 
   Kit "devices" are objects that interface to a Mach device. The two
   Music Kit devices are Midi and Orchestra. */

#ifndef __MK_devstatus_H___
#define __MK_devstatus_H___

/* Status for Midi/Orchestra Music Kit classes. */

typedef enum _MKDeviceStatus { 
    MK_devClosed = 0,
    MK_devOpen,
    MK_devRunning,
    MK_devStopped
  } MKDeviceStatus;

 /* These states are defined as follows:
  * 
  * devClosed = Mach device is closed.
  * devOpen   = Mach device is open but its clock has not yet begun to run.
  *             It's clock is in a reset state.
  * devRunning= Mach device is open and its clock is running.
  * devStopped = Mach device is open, its clock has run, but it has been
  *             temporarily stopped.
  * 
  * There are four methods for changing the state, defined in all Music Kit 
  * device classes:
  * 
  * -open 
  *    Opens Mach device if not already open.
  *    Resets object if needed. Sets status to MK_devOpen.
  *    Returns nil if some problem occurs, else self.
  *   
  * -run
  *   If not open, does a [self open].
  *   If not already running, starts Mach device clock. 
  *   Sets status to MK_devRunning.
  * 
  * -stop
  *   If not open, does a [self open].
  *   Otherwise, stops Mach device clock and sets status to MK_devStopped.
  * 
  * -close
  *   Closes the Mach device after waiting for all enqueued events to 
  *   finish. Returns self and sets status to MK_devClosed unless there's some 
  *   problem closing the device, in which case, returns nil.
  * 
  * -abort
  *   Like close, but doesn't wait for enqueued events to finish.
  */



#endif
