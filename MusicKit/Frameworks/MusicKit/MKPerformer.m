/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    A Performer produces a series of time-ordered Note
    objects and initiates their distribution to
    a set of Instruments during a Music Kit performance.
    Performer is an abstract class which managed an List
    of NoteSenders. These NoteSenders are "Note outputs" of the
    Performer. For convenience,
    Performers support a subset of the MKNoteSender connection methods.
    Sending one of the connection messages to a Performer merely
    broadcasts the message to its NoteSenders.
    The Performer class creates and frees the List for you.

    Every Performer object is owned by exactly one Conductor.
    Unless you set its Conductor
    by sending it the setConductor: message, a Performer
    is owned by the defaultConductor (see the Conductor class).
    During a performance, the Conductor sends
    perform messages to the Performer according
    to requests scheduled by the Performer.
   
    perform is the most important method for a Performer.
    A subclass responsibility, each implementation of the
    method should include two activities:
   
     * It may send a Note object to one of its NoteSenders.
     * It must schedule the next invocation of perform.
   
    A Performer usually sends a Note by sending the sendNote: message
    to one of its NoteSenders.
    The Note object to be sent can be supplied in any manner:  for example
    the Performer
    can read Notes from a file, or from another object, or it can
    create them itself.
   
    The second step, scheduling the next invocation of perform, is
    accomplished simply by setting the value of the variable nextPerform.
    The value of nextPerform is the amount of time, in beats,
    that the Conductor waits before sending the next
    perform message to the Performer.
    The perform method should only be invoked in this way --
    an application shouldn't send the perform message itself.
   
    To use a Performer in a performance,
    you must first activate it by invoking its
    activate method.  This prepares the Performer
    by first invoking the activateSelf method and then scheduling
    the first perform message request.
    activateSelf can be overridden to provide
    further initialization of the Performer.  For instance,
    the PartSegment subclass implements activateSelf
    to set the value of nextPerform
    to the timeTag value of its first Note.
   
    The performance begins when the Conductor factory receives the
    startPerformance message.
    It's legal to activate a Performer after the performance has started.
   
    Sending the deactivate message removes the Performer
    from the performance.
    This method can be overridden to implement
    any necessary finalization, such as freeing contained objects.
   
    During a performance, a Performer can be stopped and restarted by
    sending it the
    paused and resume messages, respectively.
    perform messages destined for a paused Performer are suppressed.
    When a paused Performer is resumed, it recommences
    performing from the point at which it was stopped.
    (Compare this with the squelch
    method, inherited from MKNoteSender, which doesn't suppress
    perform messages
    but simply prevents Notes from
    being sent.)
   
    Each Performer has two instance variables
    that can adjust its performance time window:
    timeShift, and duration.
    timeShift and duration set the time, in beats, that the
    first Note will be sent and the maximum duration of the Performer's
    performance,
    respectively.  A Performer is automatically deactivated if its
    performance extends beyond duration beats.
   
    A Performer has a status, represented as one of the
    following MKPerformerStatus values:
   
     * MK_inactive.  A deactivated or not-yet-activated Performer.
     * MK_active.  An activated, unpaused Performer.
     * MK_paused.  The Performer is activated but currently paused.
   
    Some messages can only be sent to an inactive (MK_inactive)
    Performer.  A Performer's status can be queried with the status
    message.  

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
*/
/* 
Modification history:

  $Log$
  Revision 1.5  2000/04/25 02:09:53  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.4  2000/04/16 04:22:01  leigh
  Comment cleanup

  Revision 1.3  2000/03/29 03:17:08  leigh
  Cleaned up doco and ivar declarations

  Revision 1.2  1999/07/29 01:16:40  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  12/13/89/daj - Fixed deactivate to always reinitialize _performMsgPtr
  01/09/90/daj - Changed pause/resume mechanism to fix bug 4310.
  03/08/90/daj - Fixed bug in _performerBody (lbj).
  03/13/90/daj - Moved private methods to a category.
  03/17/90/daj - Added delegate mechanism.
  03/21/90/daj - Added archiving.
  03/27/90/daj - Added pauseFor:.
  04/06/90/mmm - Added timeOffset instance var to make -time work as advertised,
                 (i.e., time since activation, not including pauses.)
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  07/23/90/daj - Fixed bug in timeOffset setting. 
  08/01/90/daj - Fixed another bug in timeOffset setting. 
  08/14/90/daj - Fixed bug in awake method (wasn't initializing extra instance vars). 
  08/23/90/daj - Changed to use zone API.
  09/26/90/daj & lbj - Added check for [owner inPerformance] in 
                       addNoteSener and check for _noteSeen in 
		       freeNoteSeners. Added missing method inPerformance.
  12/19/90/daj - Fixed leak of _extraPerformerVars
  03/04/91/daj - Fixed copy of _extraPerformerVars
  03/13/91/daj - Added clearing of _pauseOffset in -deactivate
  08/22/91/daj - Fixed weird possible bug in _performerBody
  10/02/92/daj - Changes for MTC
  10/09/92/daj - Flushed _timeOffset (not needed) and extraPerformerVars.
   6/26/93/daj - Added rescheduleAtTime: and rescheduleBy:
   7/23/93/daj - Changed calculation of _endTime in activate.
*/

#import "_musickit.h"

#import "ConductorPrivate.h"
#import "NotePrivate.h"
#import "MKNoteSender.h"
#import "PerformerPrivate.h"

@implementation MKPerformer

#import "PerformerPrivate.h"

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKPerformer class])
      return;
//    [self setVersion:VERSION2];
    (void)[MKPerformer setVersion:VERSION2];//sb: suggested by Stone conversion guide
    _MKCheckInit();
    return;
}

+new
  /* Create a new instance and sends [self init]. */
{
    self = [self allocWithZone:NSDefaultMallocZone()];
    [self init];
//    [self initialize]; /* Avoid breaking pre-2.0 apps. */ //sb: removed. Unnec.
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives noteSender List, timeShift, and duration. Also archives
     conductor and delegate using NXWriteObjectReference().
     */
{
    /*[super encodeWithCoder:aCoder];*/ /*sb: unnec according to Stone porting guide */
    [aCoder encodeValuesOfObjCTypes:"@dd",&noteSenders,&timeShift,&duration];
    [aCoder encodeConditionalObject:conductor];
    [aCoder encodeConditionalObject:delegate];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    /*[super initWithCoder:aDecoder];*/ /*sb: unnec according to Stone porting guide */
    if ([aDecoder versionForClassName:@"Performer"] == VERSION2) {
	[aDecoder decodeValuesOfObjCTypes:"@dd",&noteSenders,&timeShift,&duration];
	conductor = [[aDecoder decodeObject] retain];
	delegate = [[aDecoder decodeObject] retain];
    }
/* from awake(sb) */
    if (!conductor)
      conductor=[MKConductor defaultConductor];
    status = MK_inactive;
    _performMsgPtr= MKNewMsgRequest(0.0,@selector(_performerBody),self,0);
/*****/
    return self;
}

//- awake
//{
//#warning DONE ArchiverConversion: put the contents of your 'awake' method at the end of your 'initWithCoder:' method instead
    /*[super awake]; */ /*sb: hmmm. NSObject does not respond to this. */
/***
    if (!conductor)
      conductor=[Conductor defaultConductor];
    status = MK_inactive;
    _performMsgPtr= MKNewMsgRequest(0.0,@selector(_performerBody),self,0);
***/
//    return self;
//}

#import "noteDispatcherMethods.m"

/* Implement a dummy protocol for firstTimeTag/lastTimeTag. */
-setFirstTimeTag:(double)v { return self; }
-setLastTimeTag:(double)v  { return self; }

-(double)firstTimeTag { return 0; }
-(double)lastTimeTag { return MK_ENDOFTIME; }

-removeNoteSender:(id)aNoteSender
  /* If aNoteSender is not owned by the receiver, returns nil.
     Otherwise, removes aNoteSender from the receiver's MKNoteSender List
     and returns aNoteSender.
     For some subclasses, it is inappropriate for anyone
     other than the subclass instance itself to send this message. 
     It is illegal to modify an active Performer. Returns nil in this case,
     else aNoteSender. */
{
    if ([aNoteSender owner] != self)
      return nil;
    if (status != MK_inactive)
      return nil;
    [noteSenders removeObject:aNoteSender];
    [aNoteSender _setOwner:nil];
    return aNoteSender;
}

-addNoteSender:(id)aNoteSender
  /* If aNoteSender is already owned by the receiver or the receiver is 
     not inactive, returns nil.
     Otherwise, aNoteSender is removed from its owner, the owner
     of aNoteSender is set to self, aNoteSender is added to 
     noteSenders (as the last element) and aNoteSender is returned. 
     For some subclasses, it is inappropriate for anyone
     other than the subclass instance itself to send this message. 
     If you override this method, first forward it to super.
     */
{
    id owner = [aNoteSender owner];
    if ((status != MK_inactive) || /* in performance */
	(owner && (![owner removeNoteSender:aNoteSender])))
        /* owner might be in perf */
	return nil;
    if (!noteSenders) /* Just in case init wasn't called */
      noteSenders = [[NSMutableArray alloc] init];
    [noteSenders addObject:aNoteSender];
    [aNoteSender _setPerformer:self];
    return aNoteSender;
}

/* Conductor control ------------------------------------------------ */

-setConductor:(id)aConductor
  /* TYPE: Accessing the Conductor; Sets the receiver's Conductor to aConductor.
   * Sets the receiver's Conductor to aConductor
   * and returns the receiver.
   * Illegal while the receiver is active. Returns nil in this case, else self.
   */
{
    if (status != MK_inactive)
      return nil;
    conductor = aConductor;
    if (!conductor)
      conductor = [MKConductor defaultConductor];
    return self;
}

-conductor
  /* TYPE: Accessing the Conductor;  Returns the receiver's Conductor.
   * Returns the receiver's Conductor.
   */
{
    return conductor;
}

/* Activation and deactivation  --------------------------------- */

-activateSelf
  /* TYPE: Performing; Does nothing; subclass may override for special behavior.
   * Invoked from the activate method,
   * a subclass can implement
   * this method to perform pre-performance activities.
   * In particular, if the subclass needs to
   * alter the initial nextPerform value, it should be 
   * done here (nextPerform is guaranteed to be 0.0 when this
   * method is invoked).
   * If activateSelf returns nil, the receiver
   * is deactivated.
   * The default does nothing and returns the receiver.
   */
{
    return self;
}
/* Perform ------------------------------------------------------------ */

-perform	
  /* TYPE: Performing; Subclass responsibility; sends Notes and sets nextPerform.
   * This is a subclass responsibility 
   * expected to send Notes and set the value of the nextPerform
   * variable.
   * The value returned by perform is ignored.
   */
{
    [NSException raise:NSInvalidArgumentException format:@"*** Subclass responsibility: %s", sel_getName(_cmd)]; return nil;
}



-_performerBody
    /* _performerBody is a private method that wraps around the
       subclass's perform method. */
{	
    /* perform before daemon. */
    if (status != MK_active)  /* This check might be unnecessary? */
      return nil;
    performCount++;
    time = _performMsgPtr->_timeOfMsg - _pauseOffset;

    [self perform];

    /* Performer perform after daemon. */
    switch (status) {
      case MK_paused: 
	return self;
      case MK_active:
	_performMsgPtr->_timeOfMsg += nextPerform;
	if (_endTime <= _performMsgPtr->_timeOfMsg) /* Duration expired? */
	  break;
	MKScheduleMsgRequest(_performMsgPtr,conductor);
	return self;
      case MK_inactive:  
	/* Subclass perform method may have sent deactivate */
      	return self;
      default:
	break;
    }
    status = MK_paused;
    [self deactivate];
    return self;
}

/* Time window variables ------------------------------------------- */

-setTimeShift:(double)shift
  /* TYPE: Accessing time; Delays performance for shift beats.
   * Sets the begin time of the receiver;
   * the receiver's performance is delayed by shift beats.
   * Returns the receiver.
   * Illegal while the receiver is active. Returns nil in this case, else self.
   */
{	
    if (status != MK_inactive) 
      return nil;
    timeShift = shift;
    return self;
}		

-setDuration:(double)dur
  /* TYPE: Accessing time;Sets max duration of the receiver to dur beats.
   * Sets the maximum duration of the receiver to dur beats.
   * Returns the receiver.
   * Illegal while the receiver is active. Returns nil in this case, else self.
   */
{
    if (status != MK_inactive) 
      return nil;
    duration = dur;
    return self;
}		


-(double)timeShift 
  /* TYPE: Accessing time; Returns the receiver's performance begin time.
   * Returns the receiver's performance begin time, as set through
   * setTimeShift:.
   */
{
	return timeShift;
}

-(double)duration 
  /* TYPE: Accessing time; Returns the reciever's performance duration.
   * Returns the receiver's maximum performance duration, as 
   * set through setDuration:.
   */
{
	return duration;
}

-(int) status
  /* TYPE: Querying; Returns the receiver's status.
   * Returns the receiver's status as one of the
   * following values:
   *
   *  *   	Status	Meaning
   *  *		MK_inactive	between performances
   *  *		MK_active	in performance
   *  * 	MK_paused	in performance but currently paused
   *
   * A performer's status is set as a side effect of 
   * methods such as activate and pause.
   */
{
    return (int) status;
}

-(int) performCount
  /* TYPE: Querying; Returns the number of Notes the receiver has performed.
   * Returns the number Notes the receiver has performed in the
   * current performance.  Does this by counting the number of
   * perform messages it has received. 
   */
{
    return performCount;
}

/* Activation and deactivation ------------------------------------------ */

-activate
  /* TYPE: Performing; Prepares the receiver for a performance.
   * If the receiver isn't MK_inactive, immediately returns the receiver;
   * Otherwise 
   * prepares the receiver for a performance by 
   * setting nextPerform to 0.0, invoking activateSelf,
   * scheduling the first perform message request with the Conductor,
   * and setting the receiver's status to MK_active.
   * If a subclass needs to alter the initial value of 
   * nextPerform, it should do so in its implementation
   * of the activateSelf method.
   * Returns the receiver.
   */
{
    double condTime;
    if (status != MK_inactive) 
      return self;
    if (duration <= 0)
      return nil;
    nextPerform = 0;
    if (![self activateSelf])
      return nil;
    performCount = 0;
    condTime = [conductor time];
    self->time = 0.0;
    _pauseOffset = condTime + timeShift; 
    _performMsgPtr->_timeOfMsg = (_pauseOffset + nextPerform +
				  [conductor _MTCPerformerActivateOffset:self]);
    _endTime = condTime + (MAX(timeShift,0)) + duration;
    /* Old version:   _endTime = _pauseOffset + duration; */
    _endTime = MIN(_endTime,  MK_ENDOFTIME);
    if (_endTime <= _performMsgPtr->_timeOfMsg)
      return nil;
    MKScheduleMsgRequest(_performMsgPtr,conductor);
    [conductor _addActivePerformer:self];
    status = MK_active;
    _deactivateMsgPtr = [MKConductor _afterPerformanceSel:
			 @selector(deactivate) to:self argCount:0];
    if ([delegate respondsToSelector:@selector(performerDidActivate:)])
      [delegate performerDidActivate:self];
    return self;
}

- (void)deactivate
  /* TYPE: Performing; Removes the receiver from the performance.
   * If the receiver's status is already MK_inactive, this
   * does nothing and immediately returns the receiver.
   * Otherwise removes the receiver from the performance,
   * and sets the receiver's status to MK_inactive.
   * Returns the receiver.
   */
{
    if (status == MK_inactive)
      return;
    _performMsgPtr = MKCancelMsgRequest(_performMsgPtr);
    _pauseForMsgPtr = MKCancelMsgRequest(_pauseForMsgPtr);
    _performMsgPtr = MKNewMsgRequest(0.0,@selector(_performerBody),self,0);
    _deactivateMsgPtr = MKCancelMsgRequest(_deactivateMsgPtr);
    _pauseOffset = 0;
    status = MK_inactive;
    [conductor _removeActivePerformer:self];
    if ([delegate respondsToSelector:@selector(performerDidDeactivate:)])
      [delegate performerDidDeactivate:self];
}

/* Creation ------------------------------------------------------- */

-init
  /* TYPE: Initializing; Initializes the receiver.
   * Initializes the receiver.
   * You never invoke this method directly,
   * it's sent by the superclass upon creation.
   * An overriding subclass method must send [super\ init]
   * before setting its own defaults. 
   */
{
    noteSenders = [[NSMutableArray alloc] init];
    conductor=[MKConductor defaultConductor];
    duration = MK_ENDOFTIME;
    _endTime = MK_ENDOFTIME;
    status = MK_inactive;
    _performMsgPtr= MKNewMsgRequest(0.0,@selector(_performerBody),self,0);
    return self;
}


/* Changing status during a performance ---------------------------------- */

-pause   
  /* TYPE: Performing; Suspends the the receiver's performance.
   * If the receiver is MK_active, this changes its 
   * status to MK_paused, suspends its performance, 
   * and returns the receiver.  
   * Otherwise does nothing and returns the receiver.
   *
   * If you want to free a paused Performer during a performance,
   * you should first send it the deactivate message.
   */
{  
    if (status == MK_inactive || status == MK_paused) 
      return self;
    _performMsgPtr = MKCancelMsgRequest(_performMsgPtr);
    _pauseOffset -= [conductor time];
    status = MK_paused;
    if ([delegate respondsToSelector:@selector(performerDidPause:)])
      [delegate performerDidPause:self];
    return self;	
}

-pauseFor:(double)beats
{
    if (beats <= 0.0) 
      return nil;
    [self pause];
    if (_pauseForMsgPtr)/* Already doing a "pauseFor"? */
      MKRepositionMsgRequest(_pauseForMsgPtr,[conductor time] + beats);
    else {             /* New "pauseFor". */
	_pauseForMsgPtr = MKNewMsgRequest([conductor time] + beats,
					  @selector(resume),self,0);
	MKScheduleMsgRequest(_pauseForMsgPtr,conductor);
    }
    return self;
}

-resume
  /* TYPE: Performing; Resumes the receiver's performance.
   * If the receiver is paused, this changes its status to MK_active,
   * resumes its performance and returns the receiver.
   * Otherwise does nothing and returns the receiver.
   */
{
    double resumeTime;
    if (status != MK_paused)
      return self;
    _pauseOffset += [conductor time];
    resumeTime = nextPerform + self->time + _pauseOffset;
    if (resumeTime > _endTime)
      return nil;
    _performMsgPtr = 
      MKRescheduleMsgRequest(_performMsgPtr,conductor,resumeTime,
			     @selector(_performerBody),self,0);
    _pauseForMsgPtr = MKCancelMsgRequest(_pauseForMsgPtr);
    status = MK_active;
    if ([delegate respondsToSelector:@selector(performerDidResume:)])
      [delegate performerDidResume:self];
    return self;
}

#if 1
-rescheduleAtTime:(double)aTime
  /* Reschedules at aTime, which is in terms of the receiver's Conductor's time 
     base. Returns nil and does nothing if the receiver is not active. */
{
    double condTime;
    if (status != MK_active)
      return nil;
    condTime = [conductor time];
    if (aTime < condTime)
      aTime = condTime;
    /* Try to keep nextPerform reasonable, in case subclass depends on it. */ 
    nextPerform += aTime - _performMsgPtr->_timeOfMsg;
    if (nextPerform < 0)
      nextPerform = 0;
    _performMsgPtr = 
      MKRescheduleMsgRequest(_performMsgPtr,conductor,aTime,
			     @selector(_performerBody),self,0);
    return self;
}

-rescheduleBy:(double)aTimeIncrement
  /* Reschedules by aTimeIncrement, which is in terms of the receiver's 
     Conductor's time base. Returns nil and does nothing if the receiver 
     is not active. */
{
    double condTime;
    if (status != MK_active)
      return nil;
    condTime = [conductor time];
    if (_performMsgPtr->_timeOfMsg + aTimeIncrement < condTime) 
      aTimeIncrement = condTime - _performMsgPtr->_timeOfMsg;
    /* Try to keep nextPerform reasonable, in case subclass depends on it. */ 
    nextPerform += aTimeIncrement;
    /* nextPerform can't be negative here because time has only advanced (or
       stood still) since it was last set. 
       */
    _performMsgPtr = 
      MKRescheduleMsgRequest(_performMsgPtr,conductor,
			     _performMsgPtr->_timeOfMsg + aTimeIncrement,
			     @selector(_performerBody),self,0);
    return self;
}
#endif

/* Copy ---------------------------------------------------------------- */


static id copyFields(MKPerformer *self,MKPerformer *newObj)
  /* Same as copy but doesn't copy NoteSenders. */
{
    newObj->timeShift = self->timeShift;
    newObj->duration = self->duration;
    newObj->time = newObj->nextPerform = 0;
    newObj->_pauseOffset = 0;
    newObj->_deactivateMsgPtr = NULL;
    newObj->_performMsgPtr=
      MKNewMsgRequest(0.0,@selector(_performerBody),newObj,0);
    newObj->status = MK_inactive;
    return newObj;
}

-copy
{
    return [self copyWithZone:[self zone]];
}

- copyWithZone:(NSZone *)zone;
  /* TYPE: Copying: Returns a copy of the receiver.
   * Creates and returns a new inactive Performer as
   * a copy of the receiver.  
   * The new object has the same timeShift and 
   * duration values as the reciever. Its
   * time and nextPerform variables 
   * are set to 0.0. It has its own noteSenders which contains
   * copies of the values in the receiver's collection. The copies are 
   * added to the collection by addNoteSender:. 
   */
{
    MKPerformer *newObj = NSCopyObject(self, 0, zone);
    unsigned n,i;
    newObj = copyFields(self,newObj);
    newObj->noteSenders = [[NSMutableArray arrayWithCapacity:n = [noteSenders count]] retain];
    for (i = 0; i < n; i++) [newObj addNoteSender:[[noteSenders objectAtIndex:i] copy]];
    return newObj;
}


- (void)dealloc
  /* TYPE: Creating
   * This invokes freeContents and then frees the receiver
   * and its NoteSenders. This message is ignored if the receiver is not
   * inactive. In this case, returns self; otherwise returns nil.
   */
{
    /*sb: FIXME!!! This is not the right place to decide whether or not to dealloc.
     * maybe need to put self in a global list of non-dealloced objects for later cleanup */
    if (status != MK_inactive)
      return;
    free(_performMsgPtr);
    [self releaseNoteSenders];
    [noteSenders release];
    [super dealloc];
}

-(double)time
/* TYPE: Accessing time; Returns the receiver's latest performance time.
   Returns the time, in beats, that the receiver last received the perform
   message.  If the receiver is inactive, returns MK_ENDOFTIME.  The return
   value is measured from the beginning of the performance and doesn't include any
   time that the receiver has been paused.  
   */
{
    return (status != MK_inactive) ? self->time : MK_ENDOFTIME;
}

- (void)setDelegate:(id)object
{
    delegate = object;
}

-delegate
{
    return delegate;
}

/* FIXME Needed due to a compiler bug. */
static void setNoteSenders(MKPerformer *newObj,id aList)
{
    newObj->noteSenders = aList;
}

-(BOOL)inPerformance
{
    return status != MK_inactive;
}

@end

@implementation MKPerformer(Private)

-_copyFromZone:(NSZone *)zone
{
    /* This is like copyFromZone: except that the NoteSenders are not copied.
       Instead, a virgin empty List is given. */
    MKPerformer *newObj = NSCopyObject(self, 0, zone);
    newObj = copyFields(self,newObj);
    setNoteSenders(newObj,[[NSMutableArray alloc] init]);
    return newObj;
}

@end

