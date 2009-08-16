/*
  $Id$
  Defined In: The MusicKit

  Description: 
    See MKInstrument.h

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/
/* Modification history prior to committing to CVS:

  03/13/90/daj - Changes to support category for private methods.
  03/21/90/daj - Added archiving.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/23/90/daj - Changed to zone API.
  09/26/90/daj & lbj - Added check for [owner inPerformance] in 
                       addNoteReceiver and check for noteSeen in 
		       freeNoteReceivers.
  02/25/91/daj - Added removeFromPerformance and disconnectNoteReceivers.
                 Also flushed class description comment.
  10/7/93/daj - Added check in addNoteReceiver for existance of MKNoteReceivers list.
*/

#import "_musickit.h"

#import "ConductorPrivate.h"
#import "InstrumentPrivate.h"

@implementation MKInstrument

#define VERSION2 2

+ (void) initialize
{
    if (self != [MKInstrument class])
	return;
    _MKCheckInit();
    [MKInstrument setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
}

- init
  /* TYPE: Creating; Initializes the receiver.
   * Initializes the receiver.
   * You never invoke this method directly,
   * it's sent by the superclass when the receiver is created.
   * An overriding subclass method should send [super\ init]
   * before setting its own defaults. 
   */
{
    noteReceivers = [[NSMutableArray alloc] init];
    return self;
}

- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
  /* TYPE: Performing; Realizes aNote.
   * Realizes aNote in the manner defined by the subclass.  
   * You never send this message; it's sent to an MKInstrument
   * as its MKNoteReceivers receive MKNote objects.
   */
{
    return self;
}


- firstNote: (MKNote *) aNote
  /* TYPE: Performing; Received just before the first MKNote is realized.
   * You never invoke this method directly; it's sent by the receiver to 
   * itself just before it realizes its first MKNote.
   * You can subclass the method to perform pre-realization initialization.
   * aNote, the MKNote that the MKInstrument is about to realize,
   * is provided as a convenience and can be ignored in a subclass 
   * implementation.  The MKInstrument isn't considered to be in performance 
   * until after this method returns.
   * The default implementation does nothing and returns the receiver.
   */
{
    return self;
}

- (NSArray *) noteReceivers	
  /* TYPE: Querying; Returns a copy of the Array of MKNoteReceivers.
   * Returns a copy of the Array of MKNoteReceivers. The MKNoteReceivers themselves
   * are not copied.	
   */
{
    return _MKLightweightArrayCopy(noteReceivers);
    // return [_MKLightweightArrayCopy(noteReceivers) autorelease];
}

- (int) indexOfNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    return [noteReceivers indexOfObject: aNoteReceiver];
}

- (BOOL) isNoteReceiverPresent: (MKNoteReceiver *) aNoteReceiver
  /* TYPE: Querying; Returns YES if aNoteReceiver is present.
   * Returns YES if aNoteReceiver is a member of the receiver's 
   * MKNoteReceiver collection.  Otherwise returns NO.
   */
{
    return ([self indexOfNoteReceiver: aNoteReceiver] == -1) ? NO : YES;
}

- addNoteReceiver: (MKNoteReceiver *) aNoteReceiver
   /* TYPE: Modifying; Adds aNoteReceiver to the receiver.
    * Removes aNoteReceiver from its current owner and adds it to the 
    * receiver. 
    * You can't add a MKNoteReceiver to an MKInstrument that's in performance.
    * If the receiver is in a performance, this message is ignored and nil is
    * returned. Otherwise aNoteReceiver is returned.
    */
{
    id owner = [aNoteReceiver owner];
    
    if (noteSeen ||  /* in performance */
	(owner && (![owner removeNoteReceiver: aNoteReceiver]))) /* owner might be in performance */
	return nil;
    if (!noteReceivers) /* Just in case init wasn't called */
	noteReceivers = [[NSMutableArray alloc] init];
    [noteReceivers addObject: aNoteReceiver];
    [aNoteReceiver _setOwner: self];
    return aNoteReceiver;
}

- removeNoteReceiver: (MKNoteReceiver *) aNoteReceiver
  /* TYPE: Modifying; Removes aNoteReceiver from the receiver.
   * Removes aNoteReceiver from the receiver and returns it
   * (the MKNoteReceiver) or nil if it wasn't owned by the receiver.
   * You can't remove a MKNoteReceiver from an MKInstrument that's in
   * performance. Returns nil in this case.
   */ 
{
    if ([aNoteReceiver owner] != self)
	return nil;
    if (noteSeen)
	return nil;
    [aNoteReceiver _setOwner: nil];
    [noteReceivers removeObject: aNoteReceiver];
    return aNoteReceiver;
}

/* TYPE: Creating; Releases the receiver and its MKNoteReceivers.
 * Removes and releases the receiver's MKNoteReceivers and then releases the receiver itself.  
 * The MKNoteReceiver's connections are severed.
 * If the receiving instance is in a performance, we don't release the noteReceivers
 * ivars although this a leak and is probably the wrong thing to do.
 */
- (void) dealloc
{
    if (!noteSeen) {
	// TODO is this necessary to create a copy of the array?
	NSMutableArray *aList = _MKLightweightArrayCopy(noteReceivers);
	
	[self disconnectNoteReceivers];
	[self removeNoteReceivers];
	[aList removeAllObjects];  // Split this up because elements may try
				   // and remove themselves from noteReceivers when they are freed.
	// [aList release]; // don't release as aList is autoreleased.
	[noteReceivers release];
	noteReceivers = nil;
	[super dealloc];
    }
    else {
	NSLog(@"Assertion failed %@ -dealloc while still in performance!\n", self);
    }
}

/* Broadcasts "disconnect" to MKNoteReceivers. */ 
- disconnectNoteReceivers
{
    [noteReceivers makeObjectsPerformSelector: @selector(disconnect)];
    return self;
}

- removeFromPerformance
    /* Invokes [self disconnectNoteReceivers].  If the receiver is 
       in performance, also sends [self _afterPerformance] */
{
    if (!noteSeen) 
	return nil;
    [self disconnectNoteReceivers];	
    MKCancelMsgRequest(_afterPerfMsgPtr);
    [self _afterPerformance];
    return self;
}

- removeNoteReceivers
  /* Empties noteReceivers by repeatedly sending removeNoteSender:
     with each element of the collection as the argument. */
{
    /* Need to use seq because we may be modifying the List. */
    unsigned i;
    if (!noteReceivers)
      return self;
    i = [noteReceivers count]; 
    while (i--) 
      [self removeNoteReceiver: [noteReceivers objectAtIndex: i]];
    return self;
}

- (BOOL) inPerformance
  /* TYPE: Querying; Returns YES if first MKNote has been seen.
   * Returns NO if the receiver has yet to receive a MKNote object.
   * Otherwise returns YES.
   */
{
    return (noteSeen);
}    

- afterPerformance 
  /* TYPE: Performing; Sent after performance is finished.
   * You never invoke this method; it's automatically
   * invoked when the performance is finished.
   * A subclass can implement this method to do post-performance
   * cleanup.  The default implementation does nothing and
   * returns the receiver.
   */
{
    return self;
}

- copyWithZone: (NSZone *) zone
  /* TYPE: Creating; Creates and returns a copy of the receiver.
   * Creates and returns a new MKInstrument as a copy of the receiver.  
   * The new object has its own MKNoteReceiver collection that contains
   * copies of the receiver's MKNoteReceivers.  The new MKNoteReceivers'
   * connections (see the PerfLink class) are copied from 
   * those in the receiver.
   */
{
    MKNoteReceiver *el, *el_copy;
    int noteReceiverIndex;
    int count;
    MKInstrument *newObj = [[[self class] allocWithZone: zone] init];
    
    newObj->noteSeen = NO;
    newObj->noteReceivers = [[NSMutableArray alloc] initWithCapacity: [noteReceivers count]];
    
    count = [noteReceivers count];
    for (noteReceiverIndex = 0; noteReceiverIndex < count; noteReceiverIndex++) {
	el = [noteReceivers objectAtIndex: noteReceiverIndex];
	el_copy = [el copy];
	[newObj addNoteReceiver: el_copy];
	[el_copy release]; /* since we held retain from the -copy */
    }
    return newObj;
}

- (MKNoteReceiver *) noteReceiver
  /* TYPE: Querying; Returns the receiver's first MKNoteReceiver.
   * Returns the first MKNoteReceiver in the receiver's Array.
   * This is particularly useful for Instruments that have only
   * one MKNoteReceiver.
   */
{
    if ([noteReceivers count] == 0)
        [self addNoteReceiver: [[MKNoteReceiver alloc] init]];
    return [noteReceivers objectAtIndex: 0];
}

- (void) encodeWithCoder: (NSCoder *) aCoder
{    
    // Check if decoding a newer keyed coding archive
    if([aCoder allowsKeyedCoding]) {
	[aCoder encodeObject: noteReceivers forKey: @"MKInstrument_noteReceivers"];
    }
    else {
	[aCoder encodeObject: noteReceivers];	
    }
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    // Check if decoding a newer keyed coding archive
    if([aDecoder allowsKeyedCoding]) {
	[noteReceivers release];
	noteReceivers = [[aDecoder decodeObjectForKey: @"MKInstrument_noteReceivers"] retain];
    }
    else {
	if ([aDecoder versionForClassName: @"MKInstrument"] == VERSION2) 
	    noteReceivers = [[aDecoder decodeObject] retain];	
    }
    return self;
}

// Immediately stops playing any sounding notes. The default is to do nothing.
- allNotesOff
{
    return self;
}

@end

@implementation MKInstrument(Private)

- _realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    if (!noteSeen) {
	// Note this will put the instrument on the after performance queue which implies it will be retained until
	// the end of the MKConductor's performance, which could be forever, i.e it won't actually be released.
	_afterPerfMsgPtr = [MKConductor _afterPerformanceSel: @selector(_afterPerformance) 
							  to: self
						    argCount: 0];
	[self firstNote: aNote];
	noteSeen = YES;
    }
    return [self realizeNote: aNote fromNoteReceiver: aNoteReceiver];
}

- _afterPerformance
  /* Sent by conductor at end of performance. Private */
{
    [self afterPerformance];
    noteSeen = NO;
    return self;
}

@end

