/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    See comments in MKNoteReceiver.h.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:

  $Log$
  Revision 1.6  2000/05/06 01:14:07  leigh
  Removed redundant ivar decls in implementation

  Revision 1.5  2000/04/22 20:14:01  leigh
  Properly typed connections returning an NSArray

  Revision 1.4  2000/04/16 04:08:49  leigh
  comment cleanup

  Revision 1.3  2000/02/07 23:49:52  leigh
  Comment corrections

  Revision 1.2  1999/07/29 01:16:38  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  09/19/89/daj - Changed _myData to type void *.
  03/13/90/daj - Moved private methods to category.
  03/21/90/daj - Added archiving.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/23/90/daj - Zone API changes
  09/06/90/daj - Fixed bug in archiving again.
*/

#import "_musickit.h"
#import <stdio.h>
#import "InstrumentPrivate.h"
#import "NoteReceiverPrivate.h"

@implementation MKNoteReceiver

/* METHOD TYPES
 * Receiving Notes
 */

-owner
  /* Gets the owner (an Instrument or NoteFilter). */
{
    return owner;
}


-(BOOL)isConnected:aNoteSender 
  /* TYPE: Querying; YES if aNoteSender is a connection.
   * Returns YES if aNoteSender is connected to the receiver.
   */
{
    return [noteSenders indexOfObject:aNoteSender] != NSNotFound; 
}

-squelch
  /* TYPE: Squelch; Turns off message-sending capability.
   * Squelches the receiver.  While a receiver is squelched it can't send
   * messages to its noteSenders.
   *
   * Note:  You can schedule a sendNote: message through
   * sendNote:atTime: or sendNote:withDelay even if the
   * receiver is squelched.
   * However, if the receiver is still squelched when the
   * sendNote: message is received, the Note isn't sent.
   *
   * Returns the receiver.
   */
{
    isSquelched = YES;
    return self;
}

-unsquelch
  /* TYPE: Squelch; Turns on message-sending capability.
   * Unsquelches and returns the receiver.
   */
{
    isSquelched = NO;
    return self;
}

-(BOOL)isSquelched
  /* TYPE: Querying; YES if the receiver is squelched.
   * Returns YES if the receiver is squelched.
   */
{
    return isSquelched;
}

-(unsigned)connectionCount
  /* TYPE: Querying; Returns the number of noteSenders.
   * Returns the number of noteSenders in the
   * receiver's connection set.
   */
{
    return [noteSenders count];
}

- (NSArray *) connections
  /* TYPE: Manipulating; Returns a copy of the List of the connections.
   * Returns a copy of the List of the receiver's noteSenders. 
   * The noteSenders themselves are not
   * copied. It is the sender's responsibility to free the List.
   */
{
    return _MKLightweightArrayCopy(noteSenders);
}

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKNoteReceiver class])
      return;
    [MKNoteReceiver setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

+new
  /* Create a new instance and sends [self init]. */
{
    self = [self allocWithZone:NSDefaultMallocZone()];
    [self init];
//    return [self autorelease]; // should new return autoreleased...probably should be renamed noteReceiver
    return self;
}


-init 
{
    [super init];
    noteSenders = [[NSMutableArray alloc] init];
    owner = nil;
    return self;
}

- (void)dealloc
  /* TYPE: Creating; Frees the receiver.
   * Frees the receiver. Illegal while the receiver is sending. Returns nil
   * Also removes the name, if any, from the name table.
   * if the receiver is freed.
   */
{
    [self disconnect];
    [noteSenders release];
    MKRemoveObjectName(self);
    [super dealloc];
}

- copyWithZone:(NSZone *)zone
  /* TYPE: Creating; Creates a new NoteReceiver as a copy of the receiver.
   * Creates, initializes, and returns a new NoteReceiver with the same noteSenders as the receiver.
   */
{
    unsigned n = [noteSenders count], i;
    MKNoteReceiver *newObj = NSCopyObject(self, 0, zone);
    newObj->noteSenders = [[NSMutableArray arrayWithCapacity: [noteSenders count]] retain];
    for (i = 0; i < n; i++)
        [newObj connect: [noteSenders objectAtIndex:i]];
    newObj->_myData = nil;
    newObj->owner = nil;
    return newObj;
}

-_connect:aNoteSender
{
    int i = [noteSenders indexOfObject:aNoteSender];
    if (i != NSNotFound)  /* Already there. */
      return nil;
    /*aNoteSender = */ [noteSenders addObject:aNoteSender];
    return self;
}

-_disconnect:aNoteSender
{
    unsigned int returnedIndex;
    if ((returnedIndex = [noteSenders indexOfObjectIdenticalTo:aNoteSender]) != NSNotFound) {
        [noteSenders removeObjectAtIndex:returnedIndex];
        return self;/* Returns aNoteSender if
                       success */

        }
/*    if ([noteSenders removeObject:aNoteSender])       return self;
 */
    return nil;
}

- disconnect:aNoteSender
  /* TYPE: Manipulating; Disconnects aNoteSender from the receiver.
   * Disconnects aNoteSender from the receiver.
   * Returns self.
   */
{
    if (!aNoteSender)
      return self;

    if ([aNoteSender _disconnect:self]) {
        [self _disconnect:aNoteSender];
    }
    return self;
}	

- disconnect
  /* TYPE: Manipulating; Disconnects all the receiver's noteSenders.
   * Disconnects all the objects connected to the receiver.
   * Returns the receiver, unless the receiver is currently sending to its
   * noteSenders, in which case does nothing and returns nil.
   */
{
    //id aList = [noteSenders copy];  // LMS originally this was _MKCopyList
    id aList = _MKLightweightArrayCopy(noteSenders);
    /* Need to copy since disconnect: modifies contents. */
    [aList makeObjectsPerformSelector:@selector(disconnect:) withObject:self];
//    [aList release];
    return self;
}

-connect:(id)aNoteSender 
  /* TYPE: Manipulating; Connects aNoteSender to the receiver.
   * Connects aNoteSender to the receiver 
   * and returns self.  
   */
{
    if (![aNoteSender isKindOfClass:[MKNoteSender class]])
      return self;
    if ([self _connect:aNoteSender])  /* Success ? */
      [aNoteSender _connect:self];    /* Make other-way link */
    return self;
}
 
-receiveNote:aNote
  /* TYPE: Receiving; Forwards note to its owner, unless squelched.
     */
{
    if (isSquelched)
      return nil;
    [owner _realizeNote:aNote fromNoteReceiver:self];
    return self;
}

-receiveNote:aNote atTime:(double)time 
    /* TYPE: Receiving; Receive Note at time specified in beats.
       Receives the specifed note at the specified time using
       the note's Conductor for time coordination. */
{
    [[aNote conductor] sel:@selector(receiveNote:) to:self atTime:time  argCount:1,aNote];
    return self;
}

-receiveNote:aNote withDelay:(double)delayTime
    /* Receives the specifed note, delayed by delayTime from the
       current time, as far as the note's conductor is concerned. 
       Uses the note's Conductor for time coordination. */
{
    [[aNote conductor] sel:@selector(receiveNote:) to:self withDelay:delayTime argCount:1,aNote];
    return self;
}

-receiveAndFreeNote:aNote withDelay:(double)delayTime
    /* Receives the specifed note, delayed by delayTime from the
       current time, as far as the note's conductor is concerned. Then
       frees the note. */
{
    [[aNote conductor] sel:@selector(receiveAndFreeNote:) to:self withDelay:delayTime argCount:1,aNote];
    return self;
}

-receiveAndFreeNote:aNote
    /* Receive note and then free it. */
{
    [self receiveNote:aNote];
    [aNote release];
    return self;
}

-receiveAndFreeNote:aNote atTime:(double)time
    /* Receive the specifed note at the specified time using
       the note's Conductor for time coordination. Then free the note. */
{
    [[aNote conductor] sel:@selector(receiveAndFreeNote:) to:self atTime:time argCount:1,aNote];
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives isSquelched. Also archives MKNoteSender List and owner using 
     NXWriteObjectReference(). */
{
    NSString *str;
    unsigned cnt = [noteSenders count], i;

    str = MKGetObjectName(self);
    [aCoder encodeValuesOfObjCTypes:"i",&cnt];
    for (i = 0; i < cnt; i++)
        [aCoder encodeConditionalObject:[noteSenders objectAtIndex:i]];
    [aCoder encodeValuesOfObjCTypes:"@c",&str,&isSquelched];
    [aCoder encodeConditionalObject:owner];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    NSString *str;
    int possibleCount,i;
    /*[super initWithCoder:aDecoder];*/ /*sb: unnecessary */
    if ([aDecoder versionForClassName:@"NoteReceiver"] == VERSION2) {
	[aDecoder decodeValuesOfObjCTypes:"i",&possibleCount];
        noteSenders = [[NSMutableArray arrayWithCapacity:possibleCount] retain];
	for (i=0; i<possibleCount; i++) 
	  [noteSenders addObject:[[aDecoder decodeObject] retain]];
	[aDecoder decodeValuesOfObjCTypes:"@c",&str,&isSquelched];
	if (str) {
	    MKNameObject(str,self);
//	    free(str);
	}
	owner = [[aDecoder decodeObject] retain];
    } 
    return self;
}

@end


@implementation MKNoteReceiver(Private)

-_setOwner:obj
  /* Sets the owner (an Instrument or NoteFilter). In most cases,
     only the owner itself sends this message. 
     */
{
    owner = obj;
    return self;
}

-(void)_setData:(void *)anObj 
  /* Facility for associating an arbitrary datum in a NoteReceiver */
{
    _myData = anObj;
}

-(void *)_getData
  /* */
{
    return _myData;
}

@end

