/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    A pseudo-recorder that does its work by managing a set of MKPartRecorders.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2005, The MusicKit Project.
*/
/* Modification History prior to commit to CVS repository:

   03/13/90/daj - Minor changes for new private category scheme.
   03/17/90/daj - Added settable PartRecorderClass
   04/21/90/daj - Small mods to get rid of -W compiler warnings.
   08/27/90/daj - API changes to support zones
   06/06/92/daj - Changed -freePartRecorders to refuse to do so if the
                  MKScoreRecorder is in performance.
   01/13/96/daj - Added init of partRecorders in copyFromZone: 
*/

#import "_musickit.h"

#import "ConductorPrivate.h"
#import "PartRecorderPrivate.h"
#import "ScoreRecorderPrivate.h"

@implementation MKScoreRecorder(Private)

- (void) _firstNote: (MKNote *) aNote
{
    if (!_noteSeen) {
	[MKConductor _afterPerformanceSel: @selector(_afterPerformance) to: self argCount: 0];
	[self firstNote: aNote];
	_noteSeen = YES;
    }
}

- _afterPerformance
  /* Sent by conductor at end of performance. Private */
{
    [self afterPerformance];
    _noteSeen = NO;
    return self;
}

@end

@implementation MKScoreRecorder

- init
{
    self = [super init];
    if(self != nil) {
	timeUnit = MK_second;
	partRecorders = [[NSMutableArray array] retain];
	partRecorderClass = [MKPartRecorder class];	
    }
    return self;
}

#define VERSION2 2
#define VERSION3 3 /* Changed Nov 7, 1992 */

+ (void) initialize
{
    if (self != [MKScoreRecorder class])
        return;
    [MKScoreRecorder setVersion: VERSION3]; //sb: suggested by Stone conversion guide (replaced self)
    return;
}

- (void) encodeWithCoder: (NSCoder *) aCoder
  /* TYPE: Archiving; Writes object.
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives partRecorders, timeUnit and partRecorderClass.
     Also optionally archives score using NXWriteObjectReference().
     */
{
    /*[super encodeWithCoder:aCoder];*/ /*sb: unnec */
    NSAssert((sizeof(MKTimeUnit) == sizeof(int)), @"write: method error.");
    [aCoder encodeObject: partRecorders];
    [aCoder encodeConditionalObject: score];
    [aCoder encodeValuesOfObjCTypes: "i#", &timeUnit, &partRecorderClass];
    [aCoder encodeValuesOfObjCTypes: "c", &compensatesDeltaT];
}

- (id) initWithCoder: (NSCoder *) aDecoder
  /* TYPE: Archiving; Reads object.
     You never send this message directly.  
     Should be invoked with NXReadObject(). 
     */
{
    int version;
    
    version = [aDecoder versionForClassName: @"MKScoreRecorder"];
    if (version >= VERSION2) {
	partRecorders = [[aDecoder decodeObject] retain];
	score = [[aDecoder decodeObject] retain];
	[aDecoder decodeValuesOfObjCTypes: "i#", &timeUnit, &partRecorderClass];
    }
    if (version >= VERSION3) {
	[aDecoder decodeValuesOfObjCTypes: "c", &compensatesDeltaT];
    }
    return self;
}

// reset all the partRecorders of the MKScoreRecorder to nil, release the score and set it's value nil
static void unsetPartRecorders(MKScoreRecorder *self)
{
    unsigned n = [self->partRecorders count], i;
    for (i = 0; i < n; i++)
        _MKSetScoreRecorderOfPartRecorder([self->partRecorders objectAtIndex: i], nil);
    if(self->score != nil)
        [self->score release];
    self->score = nil;
}

- setScore: (MKScore *) aScore
  /* Sets score over which we will sequence and creates MKPartRecorders for
     each MKPart in the MKScore. Note that any MKParts added to aScore after
     the setScore: call will not appear in the performance. */
{
    NSMutableArray *aListOfParts;
    MKPart *part;
    MKPartRecorder *newPartRecorder;
    unsigned n, i;
    
    if (aScore == score)
        return self;
    if ([self inPerformance])
        return nil;
    unsetPartRecorders(self);
    [partRecorders release];
    partRecorders = [[NSMutableArray array] retain];
    score = aScore;
    if (aScore == nil)
        return self;  // early out if resetting the score to nil
    [score retain];
    aListOfParts = [score parts];
    n = [aListOfParts count];
    for (i = 0; i < n; i++) {
        part = [aListOfParts objectAtIndex:i];
        newPartRecorder = [partRecorderClass new];
        [newPartRecorder setPart: part];
        _MKSetScoreRecorderOfPartRecorder(newPartRecorder, self);
       	[partRecorders addObject: newPartRecorder];
        [newPartRecorder release]; /* since +new will retain */
    }
    return self;
}

- (MKScore *) score
  /* Returns current score. */
{
    return score;
}

- copyWithZone: (NSZone *) zone
  /* Copies object. This involves copying firstTimeTag and lastTimeTag. 
     The score of the new object is set with setScore:, creating a new set 
     of partRecorders.
     */
{
//    MKScoreRecorder *newObj = [super copyWithZone:zone];
    MKScoreRecorder *newObj = [[MKScoreRecorder allocWithZone:[self zone]] init];
    newObj->timeUnit = timeUnit;/* sb */
    newObj->partRecorderClass = partRecorderClass;
    [newObj->partRecorders autorelease]; /* sb: unfortunate duplication of array creation must be undone */
    newObj->partRecorders = [[NSMutableArray alloc] init]; /* 1/13/96 DAJ */
    [newObj setScore:score];
    return newObj;
}

- removePartRecorders
  /* Sets score to nil (in unsetPartRecorders) and removes all PartRecorders, but doesn't free them.
     Returns self.
     */
{
    unsetPartRecorders(self);
    [partRecorders removeAllObjects];
    return self;
}

- (void) dealloc
  /* Frees contained PartRecorders and self. */
{
    /*sb: FIXME!!! This is not the right place to decide whether or not to dealloc.
     * maybe need to put self in a global list of non-dealloced objects for later cleanup */
    if ([self inPerformance])
	return;
    unsetPartRecorders(self);
    [partRecorders release];
    [super dealloc];
}

- setDeltaTCompensation:(BOOL)yesOrNo /* default is NO */
{
    unsigned n, i;
    if ([self inPerformance] && (yesOrNo  != compensatesDeltaT))
	return nil;
    n = [partRecorders count];
    for (i = 0; i < n; i++)
        [[partRecorders objectAtIndex: i] setDeltaTCompensation: yesOrNo];

    compensatesDeltaT = yesOrNo;
    return self;
}

- (BOOL) compensatesDeltaT
{
    return compensatesDeltaT;
}

- (MKTimeUnit) timeUnit
  /* TYPE: Querying; Returns the receiver's recording mode.
   * Returns YES if the receiver is set to do post-tempo recording.
   */
{
    return timeUnit;
}

- setTimeUnit: (MKTimeUnit) aTimeUnit
{
    unsigned n = [partRecorders count], i;
    
    if ([self inPerformance] && (timeUnit != aTimeUnit))
	return nil;
    for (i = 0; i < n; i++)
        [[partRecorders objectAtIndex: i] setTimeUnit: aTimeUnit];
    timeUnit = aTimeUnit;
    return self;
}

- (NSArray *) partRecorders
  /* TYPE: Processing
   * Returns a copy of the NSArray of the receiver's MKPartRecorder collection.
   * The PartRecorders themselves are not copied. It is the sender's
   * responsibility to free the NSArray.
   */
{
    return _MKLightweightArrayCopy(partRecorders);
}

- (BOOL) inPerformance
  /* YES if the receiver has received notes for realization during
     the current performance. */
{
    return (_noteSeen);
}    

- firstNote: (MKNote *) aNote
  /* You receive this message when the first note is received in a given
     performance session, before the realizeNote:fromNoteReceiver: 
     message is sent. You may override this method to do whatever
     you like, but you should send [super firstNote:aNote]. 
     The default implementation returns self. */
{
    return self;
}

- afterPerformance 
  /* You may implement this to do any cleanup behavior, but you should
     send [super afterPerformance]. Default implementation
     does nothing. It is sent once after the performance. */
{
    return self;
}

/* The MKNoteReceivers themselves are not copied. */
- (NSArray *) noteReceivers
{
    // this functionality is now embodied in _MKLightweigthArrayCopy()
    // return [[NSMutableArray arrayWithArray:partRecorders] retain];
    return _MKLightweightArrayCopy(partRecorders);
}

- (MKPartRecorder *) partRecorderForPart: (MKPart *) aPart
  /* Returns the MKPartRecorder for aPart, if found. */
{
    unsigned n = [partRecorders count], partRecorderIndex;
    for (partRecorderIndex = 0; partRecorderIndex < n; partRecorderIndex++) {
	MKPartRecorder *partRecorderCandidate = [partRecorders objectAtIndex: partRecorderIndex];
	
        if ([partRecorderCandidate part] == aPart)
	    return partRecorderCandidate;
    }
    return nil;
}

- setPartRecorderClass: (Class) aPartRecorderSubclass
{
    if (!_MKInheritsFrom(aPartRecorderSubclass, [MKPartRecorder class]))
	return nil;
    partRecorderClass = aPartRecorderSubclass;
    return self;
}

- (Class) partRecorderClass
{
    return partRecorderClass;
}

@end


