/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    A SynthPatch contains a List of unit generators which behave as
    a functional unit.
    SynthPatches are not created by the application. Rather, they
    are created by the Orchestra. The Orchestra is also
    responsible for filling the SynthPatch instance with UnitGenerator and
    SynthData instances. It does this on the basis of a template provided by the
    SynthPatch class method +patchTemplate. The subclass designer implements
    this method to provide a PatchTemplate which specifies what the mix of
    UnitGenerators and SynthData objects should
    be, in what order it should be allocated, and how to connect them up.
    (See PatchTemplate.)
    The SynthPatch instance, thus, is List
    containing the UnitGenerators and SynthData objects in the order they were
    specified in the template and connected as specified in the temlate.

    SynthPatches can be in one of three states:
    MK_running
    MK_finishing
    MK_idle

    The subclass may supply methods to be invoked at the initialiation
    (creation), noteOn, noteOff, noteUpdate and end-of-note (noteEnd) times, as
    described below.

    SynthPatches are ordinarilly used in conjunction with a Conducted
    performance
    by using a SynthInstrument. The SynthInstrument manages the allocation
    of SynthPatches in response to incoming Notes. Alternatively, SynthPatches
    may be used in a stand-alone fashion. In this case, you must allocate the
    SynthPatch by sending the Orchestra the -allocSynthPatch: or
    allocSynthPatch:patchTemplate: method.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:

  $Log$
  Revision 1.7  2000/07/22 00:32:21  leigh
  Minor doco and typing cleanups.

  Revision 1.6  2000/04/16 04:24:28  leigh
  Removed assignment in condition warning

  Revision 1.5  2000/03/24 21:11:35  leigh
  Cleanups of doco, removed the objc_loadmodules include causing compilation probs on MOXS 1.2

  Revision 1.4  1999/09/04 22:45:36  leigh
  modules is now const char to stop warnings

  Revision 1.3  1999/08/26 19:56:56  leigh
  using new MKError prototype

  Revision 1.2  1999/07/29 01:16:43  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  10/08/89/mtm - Changed _noteEndAndScheduleOff: to work without a conductor.
  11/11/89/daj - Added supression of multiple noteOffs in -noteOff and
                 -_noteOffAndScheduleEnd:
  11/20/89/daj - Minor change for new lazy shared data garbage collection. 
  11/22/89/daj - Optimized cancelMsgs(). 
  11/26/89/daj - Added UG blocks to allow UG optimization. 
  12/15/89/daj - Flushed _noteOffAndScheduleEnd: and rolled it into noteOff:.
                 This is a minor API change, but is really the correct thing
		 to do. Since the old behavior wasn't fully documented, I 
		 think it's ok to make the change. Also added check if 
		 SynthPatch is idle in noteUpdate:.
  01/8/90/daj  - Changed MKPreemptDuration() to MKGetPreemptDuration().
  01/23/90/daj - Significant changes to preemption mechanism:
                 Changed noteOff: to check for preempted but not-yet-executed
                 note. I.e. if a noteOn on tag N preempts a patch and then
		 the noteOff on tag N comes before the rescheduled noteOn on 
		 tag N, the noteOffSelf should not happen and a noteEnd
		 should replace the scheduled noteOn. 
		 Moved cancelMsgs() to after noteOnSelf: in noteOn:
		 Changed _MKSynthPatchPreempt().
		 Got rid of _preempted and _noteDurOff instance variables.
		 Added free of preemption note in cancelMsgs().
		 Flushed ATOMIC_KLUDGE.
		 Changed _freeSelf to do a cancelMsgs().
  01/24/90/daj - Changed _MKReplaceSynthPatch to _MKReplaceFinishingPatch.
                 It now adds at the END of the finishing patch list rather
		 than at its start. This is the correct thing. Unfortunately,
		 slightly less efficient in the current implementation.
		 (The alternative is to go to two lists, one for running and
		 one for finishing patches -- this would be an API change
		 in SynthInstrument.)
  01/31/90/daj - Added dummy instance variables for 1.0 backward header file
                 compatability.
  03/13/90/daj - Moved private methods to category.
  03/19/90/daj - Added call to _MKOrchResetPreviousLosingTemplate() in
                 _deallocate.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  04/27/90/daj - Got rid of checks for _MKClassConductor, since we're now
                 a shlib. Thus, Conductor is always linked.
  08/27/90/daj - Changes for zone API.
  11/29/90/daj - Fixed bugs in preemption.
  11/17/92/daj - Fixed bug in findSynthPatchClass (was closing bogus stream)
  12/17/93/daj - Fixed eMemSegment stuff (it was totally broken)
  2/23/94/daj - Fixed bug in automatic noteOff invocation
*/

#import "_musickit.h"
#define INT(_x) ((int)_x)
#import "_SharedSynthInfo.h"
#import "PatchTemplatePrivate.h"
#import "ConductorPrivate.h" // @requires
#import "OrchestraPrivate.h" // @requires
#import "UnitGeneratorPrivate.h"
#import "SynthInstrumentPrivate.h"
#import "NotePrivate.h"
#import "SynthPatchPrivate.h"

//#import <objc/objc-load.h> // for objc_loadModules - to replace with Foundation approach

#define PERMS 0660 /* RW for owner and group. */
#define HOME_SYNTHPATCH_DIR @"/Library/Music/SynthPatches/"
#define LOCAL_SYNTHPATCH_DIR @"/Local/Library/Music/SynthPatches/"
#define SYNTHPATCH_EXTENSION @"o"

#import <stdio.h>

#define SOUND_OUT_PAUSE_BUG 1

@implementation MKSynthPatch

/* Low-level functions for canceling msgs. The conductor class is passed
   in as a (dubious) optimization. */

static void cancelNoteDurMsg(register MKSynthPatch *self,register id condClass) 
{
    if (self->_noteDurMsgPtr) {
	[self->_noteDurMsgPtr->_arg1 release]; /* Free noteDurOff */
	self->_noteDurMsgPtr = 
	  [condClass _cancelMsgRequest:self->_noteDurMsgPtr]; 
    }
}

static void cancelNoteEndMsg(register MKSynthPatch *self,register id condClass) 
{
    if (self->_noteEndMsgPtr)
      self->_noteEndMsgPtr = 
	[condClass _cancelMsgRequest:self->_noteEndMsgPtr]; 
}

static void cancelPreemptMsg(register MKSynthPatch *self,register id condClass)
{
    if (self->_notePreemptMsgPtr) {
	if (self->_notePreemptMsgPtr->_aSelector == 
	    @selector(_preemptNoteOn:controllers:)) /* See noteOff: */
	  [self->_notePreemptMsgPtr->_arg1 release]; /* Free Note */
	self->_notePreemptMsgPtr = 
	  [condClass _cancelMsgRequest:self->_notePreemptMsgPtr]; 
    }
}

static void cancelMsgs(register id self)
    /* Cancel all of the above. */
{
    register id condClass = _MKClassConductor();
    if (condClass) {
	cancelNoteDurMsg(self,condClass);
	cancelPreemptMsg(self,condClass);
	cancelNoteEndMsg(self,condClass);
    }
}

+orchestraClass
  /* This method always returns the Orchestra factory. It is provided for
   applications that extend the Music Kit to use other hardware. Each 
   SynthPatch subclass is associated with a particular kind of hardware.
   The default hardware is that represented by Orchestra, the DSP56001.

   If you have some other hardware, you do the following:
   1. Make an analog to the Orchestra class for your hardware. 
   2. Add this class to the List returned by MKOrchestraFactories(). [not implemented]
   3. Make a SynthPatch subclass and override +orchestraFactory to return the
   class you designed. 
   4. You also need to override some other SynthPatch methods. This procedure
   is not documented yet. Talk to the NeXT developer support group for more
   information. They can also tell you exactly what part of the Orchestra
   protocol your Orchestra analog needs to support.
   */
{
    return _MKClassOrchestra();
}

+new 
  /* We override this method since instances are never created directly; they
     are always created by the Orchestra. 
     A private version of +new is used internally. */
{
    [self doesNotRecognizeSelector:_cmd];  return nil;
}

-copy
  /* We override this method since instances are never created directly. 
     They are always created by the Orchestra. */
{
    [self doesNotRecognizeSelector:_cmd];  return nil;
}

+ allocWithZone:(NSZone *)zone
  /* We override this method since instances are never created directly.
     They are always created by the Orchestra.
     A private version of +new is used internally. */
{
    [self doesNotRecognizeSelector:_cmd];  return nil;
}

+alloc
  /* We override this method since instances are never created directly.
     They are always created by the Orchestra.
     A private version of +new is used internally. */
{
    [self doesNotRecognizeSelector:_cmd];  return nil;
}

- (void)dealloc /*sb: was -free before OS conversion */
{
    if (isAllocated) [self mkdealloc];
    [super dealloc]; /*sb: added manually */
}

- copyWithZone:(NSZone *)zone
  /* We override this method since instances are never created directly. 
     They are always created by the Orchestra. */
{
    [self doesNotRecognizeSelector:_cmd];  return nil;
}

-synthElementAt:(unsigned)anIndex
  /* Returns the UnitGenerator or SynthData at the specified index or nil if 
     anIndex is out of bounds. */
{
    return [synthElements objectAtIndex:anIndex];
}

+patchTemplateFor:(id)currentNote
    /* patchTemplateFor: determines
       an appropriate patchTemplate and returns it. 
       In some cases, it is necessary to look at the current note to 
       determine which patch to use. See documentation for details.
       patchTemplateFor: is sent by the SynthInstrument 
       when a new SynthPatch is to be created. It may also be sent by
       an application to obtain the template to be used as an argument to 
       SynthInstrument's -setSynthPatchCount:patchTemplate:.
       Implementation of this method is a subclass responsibility. 
       The subclass should implement this method such that when
       currentNote is nil, a default template is returned. */
{
    [NSException raise:NSInvalidArgumentException format:@"*** Subclass responsibility: %s", sel_getName(_cmd)];
    return nil;
}

+defaultPatchTemplate
  /* You never implement this method. It is the same as 
     return [self patchTemplateFor:nil]. */
{
    return [self patchTemplateFor:nil];
}

-synthElements
  /* Returns a copy of the Array of UnitGenerators and SynthData. 
     The elements themselves are not copied. */
{
    return _MKLightweightArrayCopy(synthElements);
}

-(id)init
    /* Init is sent by the orchestra 
       only when a new SynthPatch has just been created and before its
       connections have been made, as defined by the PatchTemplate.
       Subclass may override the init method to provide additional 
       initialization. The subclass method may return nil to 
       abort the creation. In this case, the new SynthPatch is freed.
       The patchTemplate is available in the instance variable patchTemplate.
       Default implementation just returns self.
       */
{
    return self;
}

#if 0
- (void)initialize
  /* Obsolete */
{
    
}
#endif

-controllerValues:controllers
  /* This message is sent by the SynthInstrument 
     to a SynthPatch when a new tag stream begins, before the noteOn:
     message is sent. The argument, 'controllers' describing the state of
     the MIDI controllers. It is a HashTable object 
     (see /usr/include/objc/HashTable.h), mapping integer controller
     number to integer controller value. The default implementation of this 
     method does nothing. You may override it in a subclass as desired.

     Note that pitchbend is not a controller in MIDI. Thus the current
     pitchbend is included in the Note passed to noteOn:, not in the
     HashTable. See the HashTable spec sheet for details on how to 
     access the values in controllers. The table should not be altered
     by the receiver. 

     Note also that the sustain pedal controller is handled automatically
     by the SynthPatch abstract class.
     */
{
    return self;
}

static id noteOnGuts(register MKSynthPatch *self,register MKNote *aNote)
    /* This is factored out of noteOn: because of special treatment during
       preemption. (cf. noteOn: and _preemptNoteOn:controllers:) */
{
    _MKBeginUGBlock(self->orchestra,_MKOrchLateDeltaTMode(self->orchestra));
    if ((!aNote) || (![self noteOnSelf:aNote])) {
	_MKEndUGBlock();
	[self noteEnd];
	return nil;
    }
    self->status = MK_running;
    self->_phraseStatus = MK_noPhraseActivity;
    _MKEndUGBlock();
    return self;
}

-noteOn:aNote
  /* Sends [self noteOnSelf:aNote]. If noteOnSelf:aNote returns self, 
     sets status to MK_running, returns self. Otherwise,
     if noteOnSelf returns nil, sends [self noteEnd] and returns nil.
     Ordinarily sent only by SynthInstrument.
     */
{
    _phraseStatus = ((status == MK_idle) ? MK_phraseOn : MK_phraseRearticulate);
    if (noteOnGuts(self,aNote)) {
	cancelMsgs(self);
	return self;
    }
    else return nil;
}

-noteOnSelf:aNote
  /* You never call this method. Sent by noteOn: method.
     Subclass may override this method to do any initialization needed for 
     each new note. noteOnSelf: is sent whenever a new note commences, even if
     the SynthPatch is already running. (Subclass can determine whether or not
     the SynthPatch is already running by examing the status instance
     variable. A more convenient way to do this is with the phraseStatus
     method.) 
     Returns self or nil if the SynthPatch should immediately
     become idle. The message -noteEnd is sent to the SynthPatch
     if noteOnSelf: returns nil.
     The default implementation just returns self. */
{
  return self;
}

-noteUpdate:aNote
  /* Sent ordinarily only by the SynthInstrument when an update note is 
     received. Implemented simply as [self noteUpdateSelf:aNote]. */
{
    if (status == MK_idle)
      return nil;
    _MKBeginUGBlock(orchestra,_MKOrchLateDeltaTMode(orchestra)); 
    if (!aNote)
      return nil;
    _phraseStatus = MK_phraseUpdate;
    [self noteUpdateSelf:aNote];
    _phraseStatus = MK_noPhraseActivity;
    _MKEndUGBlock();
    return self;
}

-noteUpdateSelf:aNote
  /* You override but never send this message. It is sent by the noteUpdate:
     method. noteUpdateSelf: should send whatever messages are necessary
     to update the state of the DSP as reflected by the parameters in 
     aNote. */
{
    return self;
}

-(double)noteOff:aNote
  /* Sends [self noteOffSelf:aNote]. Sets status to MK_finishing.
     Returns the release duration as returned by noteOffSelf:.
     Ordinarily sent only by SynthInstrument.
     */
{
    id condClass = _MKClassConductor();
    double releaseDur;
    if (_notePreemptMsgPtr) {
	/* It's possible that we've been preempted for a noteOn and 
	   a noteOff (on that tag) arrives even before the delayed noteOn 
	   has a chance to occur. */
	double noteEndTime = _notePreemptMsgPtr->_timeOfMsg;
	cancelMsgs(self);
	/* We use _preemptMsgPtr instead of _noteEndMsgPtr here
	   because we want to be able to know that we were originally 
	   preempted. This enables us to be smart about when to schedule
	   a new note if another noteOn sneaks in before the noteEnd. */ 
	_notePreemptMsgPtr = [[condClass clockConductor]
			  _rescheduleMsgRequest:_notePreemptMsgPtr 
			  atTime:noteEndTime sel:@selector(noteEnd) to:self 
			  argCount:0];
	return noteEndTime - MKGetTime();
    }
    if (status == MK_finishing)
      return 0.0;
    [synthInstrument _repositionInActiveList:self template:patchTemplate];
    /* Here's where we'd put a sustain pedal check, if we ever implement a
       sustain pedal at this level. I.e. we check after the reposition. */
    _MKBeginUGBlock(orchestra,_MKOrchLateDeltaTMode(orchestra)); 
    if (aNote) {
	_phraseStatus = MK_phraseOff;
	releaseDur = [self noteOffSelf:aNote];
	_phraseStatus = MK_noPhraseActivity;
    } else releaseDur = 0;
    cancelMsgs(self);
    status = MK_finishing;
    _MKEndUGBlock();
    if ([condClass inPerformance])
      _noteEndMsgPtr = 
	[[condClass clockConductor] 
	 _rescheduleMsgRequest:_noteEndMsgPtr 
       atTime:releaseDur + MKGetTime() - _MK_TINYTIME
       sel:@selector(noteEnd) 
       to:self
       argCount:0];
    else 
      [self noteEnd]; /* Try and do sort-of the right thing here. (mtm) */
    return releaseDur;
}

-(double)noteOffSelf:aNote
  /* You may override but never call this method. It is sent when a noteOff
     or end-of-noteDur is received. The subclass may override it to do whatever
     it needs to do to begin the final segment of the phrase.
     The return value is a duration to wait before releasing the 
     SynthPatch.
     For example, a SynthPatch that has 2 envelope handlers should implement
     this method to send finish to each envelope handler and return
     the maximum of the two. The default implementation returns 0. */
{
    return 0;
}

-noteEnd
    /* Causes the receiver to become idle.
       The message noteEndSelf is sent to self, the status
       is set to MK_idle and returns self.
       Ordinarily sent automatically only, but may be sent by anyone to
       immediately stop a patch. 
       */
{
    _MKBeginUGBlock(orchestra,
		    (_MKOrchLateDeltaTMode(orchestra) && (status != MK_idle)));
    /* If status is idle it means we're loading patches (probably) so don't do 
       an adjusttime as this could cause the dsp to be left in an indeterminate
       state. Sigh -- more jumping through hoops for soft timed mode. */
    cancelMsgs(self);
    _phraseStatus = MK_phraseEnd;
    [self noteEndSelf];
    _phraseStatus = MK_noPhraseActivity;
    status = MK_idle;
    [synthInstrument _deallocSynthPatch:self template:patchTemplate
     tag:noteTag];
    _MKEndUGBlock();
    return self;
}

-noteEndSelf
  /* You never call this method directly. It is sent automatically when
     the phrase is completed. 
     Subclass may override this to do what it needs to do to insure that
     the SynthPatch produces no output. Usually, the subclass implementation
     sends the -idle message to the Out2sumUGx or Out2sumUGy UnitGenerator. 
     The default implementation just returns self. */
{
  return self;
}

-(BOOL ) isEqual:anObject 
  /* Obsolete. */
{
    int otherTag = [anObject noteTag];
    return (otherTag == noteTag);
}

-(unsigned ) hash;  
  /* Obsolete. */
{
    return noteTag;
}

-synthInstrument
  /* Returns the synthInstrument owning the receiver, if any. */
{
    return synthInstrument;
}

id _MKSynthPatchPreempt(MKSynthPatch *aPatch,id aNote,id controllers)
    /* This function returns aPatch almost all the time. The exception is 
       when the preemption happens right now and the SynthPatch noteOn
       method aborts. */
{
    id condClass;
    double preemptTime,preemptDur;
    if (aPatch->_notePreemptMsgPtr) { /* Already preempted? */
	/* Use old time. The point here is to avoid accumulating preemption
	   delays. */
	preemptTime = aPatch->_notePreemptMsgPtr->_timeOfMsg;
	preemptDur = preemptTime - MKGetTime(); 
    }
    else {
	/* Preempt it. */
	if (![aPatch preemptFor:aNote])
	  preemptDur = 0;
	else preemptDur = MKGetPreemptDuration();
	preemptTime = preemptDur + MKGetTime();
    }
    cancelMsgs(aPatch);
    if ((preemptDur > 0) && 
	[(condClass = _MKClassConductor()) inPerformance]) {
	aPatch->_notePreemptMsgPtr = 
	    [[condClass clockConductor] 
	     _rescheduleMsgRequest:aPatch->_notePreemptMsgPtr 
	   atTime:preemptTime
	   sel:@selector(_preemptNoteOn:controllers:) 
	   to:aPatch
	   argCount:2, aNote,controllers]; 
	return aPatch;
    }
    else 
	return [aPatch _preemptNoteOn:aNote controllers:controllers]; /* returns self */
    /* Do it now */
}

-preemptFor:aNote
  /* The preemptFor: message is sent when a running or finishing SynthPatch
     is 'preempted'. This happens, for example, when a SynthInstrument with 
     3 voices receives a fourth note. It preempts one of the voices by 
     sending it preemptFor:newNote followed by noteOn:newNote. The default
     implementation does nothing. */
{
    return self;
}

-moved:aUG
  /* 
     The moved: message is sent when the Orchestra moves a SynthPatch's
     UnitGenerator during DSP memory compaction. aUG is the unit generator that
     was moved.
     Subclass occasionally overrides this method.
     The default method does nothing. See also phraseStatus.
     */
{
    return self;
}

-(MKPhraseStatus)phraseStatus
/* This is a convenience method for SynthPatch subclass implementors.
   The value returned takes into account whether the phrase is preempted.
   the type of the current note and the status of the synthPatch. 
   If not called by a SynthPatch subclass, returns MK_noPhraseActivity */
{
    return _phraseStatus;
}

-(int) status
    /* Returns status of this SynthPatch. This is not necessarily the status
       of all contained synthElements. For example, it is not unusual
       for a SynthPatch to be idle but most of its UnitGenerators, with the
       exception of the Out2sum, to be running. */
{
    return (int)status;
}

-patchTemplate
    /* Returns patch template associated with the receiver. */
{
    return patchTemplate;
}

-(int)noteTag
    /* Returns the noteTag associated with the receiver. */
{
    return noteTag;
}

-orchestra
    /* Returns the orchestra instance to which the receiver belongs. All
       UnitGenerators and SynthData in an instance of SynthPatch are on
       the same Orchestra instance. In the standard NeXT configuration, there
       is one DSP and, thus, one Orchestra instance. */
{
    return orchestra;
}

-(BOOL)isFreeable
  /* Returns whether or not the receiver may be freed. A SynthPatch may only
     be freed if it is idle and not owned by any SynthInstrument in 
     MK_MANUALALLOC mode. */
{
    return (!(isAllocated));
}


- (void)mkdealloc /*sb: used to be dealloc, but changed to prevent conflict with foundation kit */
  /* This is used to explicitly deallocate a SynthPatch you previously
     allocated manually from the Orchestra with allocSynthPatch: or 
     allocSynthPatch:patchTemplate:.
     It sends noteEnd to the receiver, then causes the receiver to become 
     deallocated and returns nil. This message is ignored (and self is returned)
     if the receiver is owned by a SynthInstrument. 
     */
{
    if (synthInstrument)
      return;
    if (_sharedKey) {
	if (_MKReleaseSharedSynthClaim(_sharedKey,NO))
	  return;
	else _sharedKey = nil;
    }
    [self noteEnd];
    [self _deallocate];
    return;
}

-next
  /* This method is used in conjunction with a SynthInstrument's
     -preemptSynthPatchFor:patches: method. If you send -next to a SynthPatch
     which is active (not idle) and which is managed by a 
     SynthInstrument,
     the value returned is the next in the list of active SynthPatches (for
     a given PatchTemplate) managed 
     by that SynthInstrument. The list is in the order of the onset times
     of the phrases played by the SynthPatches. */
{
    switch (status) {
      case MK_running:
      case MK_finishing:
	return _next;
      default:
	return nil;
    }
}

-freeSelf
  /* You can optionally implement this method. FreeSelf is sent to the object
     before it is freed. */
{
    return nil;
}


id _MKSynthPatchSetInfo(MKSynthPatch *synthP, int aNoteTag, id synthIns)
    /* Associate noteTag with receiver. Returns self. */
{
    synthP->noteTag = aNoteTag;
    synthP->synthInstrument = synthIns;
    return synthP;
}

-_receiveNoteDurNoteOff:aNote
{
    /* We have to do it like this so that realizeNote:fromNoteReceiver: can
       alter the note and restore it.  Otherwise, the Note gets freed  
       prematurely. */
    _noteDurMsgPtr->_arg1 = nil; 
    [[synthInstrument noteReceiver] receiveNote:aNote];
    [aNote release];
    return self;
}

id _MKSynthPatchNoteDur(MKSynthPatch *synthP,id aNoteDur,BOOL noTag)
  /* Private method that enqueues a noteOff:aNote to self at the
     end of the noteDur. */
{
    id cond,noteDurOff;
    double time;
    SEL aSel;
    id msgReceiver;
    cond = [aNoteDur conductor];
    /* If the noteTag is MAXINT,
       there can never be another noteOff coming directed to this patch. 
       Therefore, we can optimize by sending the noteOff:
       directly to the SynthPatch */
    if (synthP->_noteDurMsgPtr) 
      [synthP->_noteDurMsgPtr->_arg1 release];
    noteDurOff = [aNoteDur _noteOffForNoteDur];      
    time = [cond time] + [aNoteDur dur];
    if (noTag) {
	aSel = @selector(noteOff:);
	msgReceiver = synthP;
    } 
    else {
	aSel = @selector(_receiveNoteDurNoteOff:);
	msgReceiver = synthP;
    }
    /* We subtract TINY here to make sure that a series of NoteDurs where
       the next note begins at exactly the time of the first plus dur works
       ok. That is, we move up the noteOff from the first noteDur to make
       sure it doesn't clobber the note begun by the second noteDur.

       Subtracting TINY here can cause note updates
       to appear out-of-order with respect to the noteOff generated
       here (this only can occur if there is a tag.)  But Doug Fulton 
       convinced me that this is less objectionable than having new notes
       cut off. */
    synthP->_noteDurMsgPtr = 
      [cond _rescheduleMsgRequest:synthP->_noteDurMsgPtr atTime:
       (time - _MK_TINYTIME) sel:aSel to:msgReceiver argCount:
       1,noteDurOff];
    return noteDurOff;
}

//#define DUMMY self
#define DUMMY @""
/*sb: defining DUMMY as self meant that when releasing an array containing the dummy,
 * self would also be deallocated. THe null string can be dealoced as many times as necessary.
 */

- (void)doesNotRecognizeSelector:(SEL)aSelector
    /* Don't document this -- it's just for better error handling. */
{
    if (!isAllocated) {
	MKError(@"Attempt to use a deallocated SynthPatch.");
        return;
    }
    if (synthElements) {
	int count,i;
	for (i = 0,count = [synthElements count]; i<count; i++) 
	    if ([synthElements objectAtIndex:i] == DUMMY) {
		MKError(@"Attempt to use a freed SynthPatch.");
                return;
            }
    }
    [super doesNotRecognizeSelector:aSelector];  return;
}

@end

@implementation MKSynthPatch(Private)

+_newWithTemplate:(id)aTemplate
 inOrch:(id)anOrch index:(int)whichDSP
    /* Private method sent by Orchestra to create a new instance. The
       new instance is sent the noteEndSelf message. */
{
    MKSynthPatch *newObj = [super allocWithZone:NSDefaultMallocZone()];
    newObj->synthElements = [[NSMutableArray arrayWithCapacity:[aTemplate synthElementCount]] retain];
    newObj->status = MK_idle;
    newObj->orchestra = anOrch;
    newObj->_orchIndex = whichDSP;
    newObj->patchTemplate = aTemplate;
    newObj->_notePreemptMsgPtr = NULL;
    newObj->_noteEndMsgPtr = NULL;
    newObj->_noteDurMsgPtr = NULL;
    newObj->isAllocated = YES;     
    /* Must be here to avoid it getting taken apart before it's built! */
    return newObj;
}

-_free
    /* Should only be sent by Orchestra. 
       Deallocates all contained unit generators and frees the receiver. 
     */
{
    id el;
    unsigned n;
    int i;
    cancelMsgs(self);
    [self freeSelf];
    n = [synthElements count];
    for (i=0;i<n;i++) {
        el = [synthElements objectAtIndex:i];
        if (el != DUMMY)
            _MKDeallocSynthElement(el,YES);
        }
    /* We know it can't be shared because you can't specify shared 
       synthElements in the Template. */
    if (_MK_ORCHTRACE(orchestra,MK_TRACEORCHALLOC))
        _MKOrchTrace(orchestra,MK_TRACEORCHALLOC,"Freeing %s_%p",[NSStringFromClass([self class]) cString],
		     self);
//    [synthElements makeObjectsPerformSelector:@selector(retain)]; /*sb: this defers the deallocation of the objects from the following statement to a later time. This may be a leak. */
    [synthElements release];
//    [super release]; /*sb: removed, following advice from NSObject class docs. Ok to do super dealloc though, in dealloc methods */
    return nil;
}

-(BOOL)_usesEMem:(MKOrchMemSegment) segment
    /* Returns YES if the given external dsp memory segment is utilized in one
       of the contained unit generators or synthdata.  
       This method is used by Orchestra
       to determine when it is advantageous to free a SynthPatch to
       possibly gain off-chip  memory. */
{
    /* Note that if the compile-time
       variable DSP_SEPARATEOFFCHIPADDRESSING is undefined, this method returns
       YES if its contents uses any off-chip memory, independent of the
       value of the segment argument. */
    unsigned int eMemSegments = _MKGetTemplateEMemUsage(patchTemplate);
#   ifdef DSP_SEPARATEOFFCHIPADDRESSING
    return eMemSegments & (1 << INT(segment));
#   else
    return (eMemSegments != 0);
#   endif
}

-_preemptNoteOn:aNote controllers:controllers
{
    id condClass;
    id success;
    /* Can't do a cancelPreemptMsg() here because it would free the message
       argument, aNote! */
    if (self->_notePreemptMsgPtr) 
	self->_notePreemptMsgPtr = 
	    MKCancelMsgRequest(self->_notePreemptMsgPtr); 
    _phraseStatus = MK_phraseOnPreempt; 
    [self controllerValues:controllers];
    success = noteOnGuts(self,aNote);
    if (!success)
	return nil;
    /* We have to break up the cancels, rather than using cancelMsgs() 
       below because aNote is the _preemptMsgPtr argument. */
    condClass = _MKClassConductor();
    cancelNoteDurMsg(self,condClass);
    if ([aNote noteType] == MK_noteDur) /* New noteDur off */
      _MKSynthPatchNoteDur(self,aNote,
			   (noteTag == MAXINT) ? YES : NO);
    cancelNoteEndMsg(self,condClass);
    /* This method doesn't free aNote if noteOnGuts returns nil (if
       the SynthPatch noteOnSelf: method returns nil). This is a potential 
       memory leak for cases where the SynthPatch aborts.  But it's a rare 
       enough case not to worry about, given the amount of trouble to clean 
       it up */
    [aNote release];
    return self;
}

-_remove:aUG
    /* Used by orch. This invalidates the integrity of the List object!. 
       A safer implementation would substitute a dummy object. */
{
    [synthElements replaceObjectAtIndex:_MKGetSynthElementSynthPatchLoc(aUG) withObject:DUMMY];
    return self;
}

-_add:aUG
    /* Private method used by Orchestra to add a unit generator to the
       receiver. */
{
    [synthElements addObject:aUG];
    _MKSetSynthElementSynthPatchLoc(aUG,[synthElements count] - 1);
    _MKSetTemplateEMemUsage(patchTemplate,[aUG _setSynthPatch:self]);
    return self;
}

-_prepareToFree:(MKSynthPatch **)headP :(MKSynthPatch **)tailP 
  /* Same as above but removes patch from deallocated list. Used by Orchestra.
     Must be method to avoid required load of SynthPatch by Orchestra. */
{
    int ix;
    id theArray;
    if (_whichList == _MK_ORCHTMPLIST) 
      return *headP;        /* Don't add it twice. */
    theArray = _MKDeallocatedSynthPatches(patchTemplate,_orchIndex);
    ix = [theArray indexOfObject:self];
    if (ix != NSNotFound) { /*sb: this ensures that only 1 instance is removed from the array, not
        all instances of the object, if they are there multiple times. Should this be so? If not, we
        may need to add the number of instances as retains, and remove them all. Hmmm. I am not
        sure what the original List behaviour was.
        */
        [self retain]; /* transfers ownership from the list below, to the headP list */
        [theArray removeObjectAtIndex:ix];
    }
    /* sb: the following should probably NOT happen if the object was not in the array, but
        I am assuming that if we got this far it must have been there anyway.
        */
    _whichList = _MK_ORCHTMPLIST;
    if (!*tailP) 
      *tailP = self;
    else (*headP)->_next = self;
    return *headP = self;
}

/* The following is for the linked list of synth patches. This is used
   for 2 different things, depending on whether the synthpatch is 
   allocated or not. If it is deallocated,
   it is used temporarily by the Orchestra
   for remembering freeable synth patches. Otherwise, it's used by
   SynthInstrument for its list of active patches.

   The following must be methods (rather than C functions) to avoid the
   undesired loading of the SynthPatch class when no SynthPatches are being
   used. */

-_freeList:(MKSynthPatch *)head
  /* Frees list of ugs. Used by orch only. */
{
    register MKSynthPatch *tmp;
    while (head) {
        tmp = head->_next;
        [head _free];
        [head release];
        head = tmp;
    }
    return nil;
}
-(void)_freeList2
  /* Frees list of ugs. Used by orch only. */
/*sb: the previous _freeList looks all wrong to me. As long as the last link is to "nil"
 * we don't need to be passed a "head", since we're the head ourselves. In any case,
 * we should be working up from the tail, not the head! it was back to front before, and
 * only released the last synthpatch in the list.
 * Remember: the calling method must release this object after calling _freeList2.
 */
{
    register MKSynthPatch *tmp;
    register MKSynthPatch *head = [self retain];
    while (head) {
        tmp = head->_next;
        [head _free];
        [head release];
        head = tmp;
    }
}      


id _MKRemoveSynthPatch(MKSynthPatch *synthP,MKSynthPatch **headP,
		       MKSynthPatch **tailP,unsigned short listFlag)
    /* Finds synthP in list and removes and returns it if found, else nil. */
/*sb: also releases the synthP. Take care to retain BEFORE calling this to ensure you don't release prematurely */
{
    register MKSynthPatch *tmp = *tailP;
    if (synthP->_whichList != listFlag)
      return nil;        
    synthP->_whichList = 0;
    if (tmp == synthP) {
	*tailP = synthP->_next;
	if (!*tailP)
	  *headP = nil;
	synthP->_next = nil;
        [synthP release];
	return synthP;
    }
    while (tmp->_next)
      if (tmp->_next == synthP) {
	  if (synthP == *headP)
	    *headP = tmp;
	  tmp->_next = synthP->_next;
	  synthP->_next = nil;
          [synthP release];
	  return synthP;
      }
      else tmp = tmp->_next;
    /* Not found. This should never happen. */
    synthP->_next = nil;  
    return nil;
}

void _MKReplaceFinishingPatch(MKSynthPatch *synthP,MKSynthPatch **headP,
			      MKSynthPatch **tailP,
			      unsigned short listFlag)
    /* Repositions SynthPatch as follows:
       The list consists of finishing patches in the order they received
       noteOff followed by running patches in the order that they received
       their noteOns. This means we have to search for the end of the 
       finishing patches before adding our patch. */
{
    [synthP retain]; /* so we don't lose it in next line before adding to list later*/
    if (!_MKRemoveSynthPatch(synthP,headP,tailP,listFlag)) {
        [synthP release];
        return;
    }
    synthP->_whichList = listFlag; 
    if (!*tailP) {        /* It's the only one in the whole list */
	*headP = synthP;
	*tailP = synthP;
    }
    else if ((*tailP)->status != MK_finishing) { /* The only finishing patch */
	synthP->_next = *tailP;
	*tailP = synthP;
    }
    else { /* Find last finishing patch */
	register MKSynthPatch *anObj;
	register MKSynthPatch *next;
	anObj = *tailP;
	next = anObj->_next;
	while (next && (next->status == MK_finishing)) {
	    anObj = next;
	    next = anObj->_next;
	}
	synthP->_next = next;
	anObj->_next = synthP;
	if (!next)
	  *headP = synthP;
    }
}


id _MKAddPatchToList(MKSynthPatch *self,MKSynthPatch **headP,MKSynthPatch **tailP,
		     unsigned short listFlag)
    /* Add receiver to end of singly-linked list. List is pointed to by
       tailP. There's also a pointer to the head of the list (last element). 
       Empty list is represented by tailP==headP==nil. Single element list is 
       represented by tailP==headP!=nil. */
/*sb: also keeps a retain of the object! */
{
    if (self->_whichList == listFlag)
      return *headP;        /* Don't add it twice. */
    self->_whichList = listFlag;
    [self retain];
    if (!*tailP) 
      *tailP = self;
    else (*headP)->_next = self;
    self->_next = nil;
    return *headP = self;
}

-(void)_setShared:aSharedKey
  /* makes object shared. If aSharedKey is nil, makes it unshared.
     Private method. */
{
    _sharedKey = aSharedKey;
}

-(void)_addSharedSynthClaim
  /* makes object shared. If aSharedKey is nil, makes it unshared.
     Private method. */
{
    _MKAddSharedSynthClaim(_sharedKey);
}

-_connectContents 
  /* Private method used by Orchestra to connect contents. */
{
    if (![self init] /*|| ![self initialize] */) { /*sb: initialise is obselete and void */
	isAllocated = NO;
	return nil;
    }
    _MKEvalTemplateConnections(patchTemplate,synthElements);
    [self noteEnd];
    return self;
}

-(void)_allocate
  /* Private */
{
    isAllocated = YES;
}

-_deallocate
  /* Private */
{
    if (!isAllocated)           /* It's already deallocated. */
      return self;
    cancelMsgs(self);           /* A noop under normal circumstances. */
    synthInstrument = nil;
    isAllocated = NO;
    [_MKDeallocatedSynthPatches(patchTemplate,_orchIndex) addObject:self];
    _MKOrchResetPreviousLosingTemplate(orchestra);
    if (_MK_ORCHTRACE(orchestra,MK_TRACEORCHALLOC))
      _MKOrchTrace(orchestra,MK_TRACEORCHALLOC,
                   "Returning %s_%p to avail pool.",[NSStringFromClass([self class]) cString],self);
    return self;
}

@end


@implementation MKSynthPatch(SynthPatchLoad)

static BOOL tryIt(NSString **filename,NSString *extension,NSString *name,int addExt,
                 NSString *dir1,NSString *dir2)
{
    if (dir1) {
        *filename = [NSString stringWithString:dir1];
	if (dir2)
            *filename = [*filename stringByAppendingPathComponent:dir2];
        *filename = [*filename stringByAppendingPathComponent:name];
    }
    else
        *filename = [NSString stringWithString:name];
    if (addExt)
        *filename = [*filename stringByAppendingPathExtension:extension];
    return [[NSFileManager defaultManager] isReadableFileAtPath:*filename];
    //open([*filename cString],O_RDONLY,PERMS); 
}

static BOOL findClass(NSString *name, NSString **filename)
    /* Returns fd or -1 if failure. Assumes name is non-NULL. */
{
    BOOL ok;
    NSString *p;
    int addExt = 0;
    if (![[name pathExtension] isEqualToString:SYNTHPATCH_EXTENSION])
      addExt = 1;
    ok = tryIt(filename,SYNTHPATCH_EXTENSION,name,addExt,nil,nil);
    if (ok) 
      return ok;
    if (![name isAbsolutePath]) { /* There's hope */
        if ((p = NSHomeDirectory())) {
            ok = tryIt(filename,SYNTHPATCH_EXTENSION,name,addExt,p,HOME_SYNTHPATCH_DIR);
	    if (ok) 
	      return ok;
	}
	
        ok = tryIt(filename,SYNTHPATCH_EXTENSION,name,addExt,LOCAL_SYNTHPATCH_DIR,nil);
	if (ok) 
	  return ok;
    }
    return ok;
}

static id getClassWithoutWarning(NSString *clname)
/* sb: checks all loaded classes to see if we have the named class. Surely NSClassFromString()
 * would do exactly the same thing? (I've tried it for a couple of examples in gdb, and appears
 * to have the desired behaviour)
 */
{
    return NSClassFromString(clname);
}

+ findSynthPatchClass:(NSString *)className
{
    /* sb: at present this just loads .o files. FIXME I need to add NSBundle support, so the
     * user can load in arbitrary bundles.
     */
    BOOL ok;
    NSString *filename;
    const char *modules[2];
    id classObj;
    classObj = getClassWithoutWarning(className);
    if (classObj)
	return classObj;
    ok = findClass(className,&filename);
    if (!ok) 
	return nil;
    modules[0] = [filename cString];
    modules[1] = '\0';
    /*sb: because of difficulties with ErrorStreams, I have removed the error reporting from
     * this function. Unfortunate, as it will be difficult to diagnose loading errors now.
     */
//    if (objc_loadModules(modules,MKErrorStream(),NULL,NULL,NULL))
    if (objc_loadModules(modules,NULL,NULL,NULL,NULL)) 
	return nil;
//    return objc_getClass(className);
    return NSClassFromString(className);
}

@end

