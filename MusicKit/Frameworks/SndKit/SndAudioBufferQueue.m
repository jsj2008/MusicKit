////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////


#import "SndAudioBuffer.h"
#import "SndAudioBufferQueue.h"

enum {
    ABQ_noData,
    ABQ_hasData
};

#define SNDABQ_DEBUG 0   


@implementation SndAudioBufferQueue

////////////////////////////////////////////////////////////////////////////////
// audioBufferQueueWithLength:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferQueueWithLength: (int) n
{
    return [[[self alloc] initQueueWithLength: n] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    self = [self initQueueWithLength: 4];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// initQueueWithLength:
////////////////////////////////////////////////////////////////////////////////

- initQueueWithLength: (int) n
{
    self = [super init];
    if(self != nil) {
	numBuffers = n;
	if (pendingBuffersLock == nil) {
	    pendingBuffersLock   = [[NSConditionLock alloc] initWithCondition: ABQ_noData];
	    processedBuffersLock = [[NSConditionLock alloc] initWithCondition: ABQ_noData];
	    pendingBuffers       = [[NSMutableArray arrayWithCapacity: numBuffers] retain];
	    processedBuffers     = [[NSMutableArray arrayWithCapacity: numBuffers] retain];
	    
	    [processedBuffersLock lock];
	    [processedBuffersLock unlockWithCondition: ABQ_noData];
	}	
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [pendingBuffersLock release];
    pendingBuffersLock = nil;
    [processedBuffersLock release];
    processedBuffersLock = nil;
    [pendingBuffers release];
    pendingBuffers = nil;
    [processedBuffers release];
    processedBuffers = nil;
    [super dealloc];
}

- copyWithZone: (NSZone *) zone
{
    SndAudioBufferQueue *queueCopy = [[[self class] allocWithZone: zone] init];
    
    [queueCopy->pendingBuffers release];
    queueCopy->pendingBuffers = [pendingBuffers copy];
    [queueCopy->processedBuffers release];
    queueCopy->processedBuffers = [processedBuffers copy];

    return queueCopy;
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
    return [NSString stringWithFormat: @"%@ numBuffers:%i currently pending:%i, max pending:%i currently processed:%i max processed:%i",
		     [super description], numBuffers, 
		     (unsigned int) [pendingBuffers count], maximumPendingBuffers,
		     (unsigned int) [processedBuffers count], maximumProcessedBuffers];
}

////////////////////////////////////////////////////////////////////////////////
// popNextPendingBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) popNextPendingBuffer
{
    SndAudioBuffer *ab = nil;
    
    [pendingBuffersLock lockWhenCondition: ABQ_hasData];
#if SNDABQ_DEBUG    
    NSLog(@"pop pending...\n");
#endif
  // NSLog(@"[pendingBuffers objectAtIndex: 0] retainCount %d\n", [[pendingBuffers objectAtIndex: 0] retainCount]);
    if([pendingBuffers count] == 0) {
	NSLog(@"Warning: -popNextPendingBuffer attempted to pop a buffer from an empty pending queue\n");
    }
    ab = [[pendingBuffers objectAtIndex: 0] retain]; // retain so it's not released by removeObjectAtIndex: below.
						     // NSLog(@"ab %@ retainCount %d\n", ab, [ab retainCount]);
    [pendingBuffers removeObjectAtIndex: 0];
  // NSLog(@"after remove [pendingBuffers objectAtIndex: 0] retainCount %d\n", [[pendingBuffers objectAtIndex: 0] retainCount]);
    [pendingBuffersLock unlockWithCondition: ([pendingBuffers count] > 0 ? ABQ_hasData : ABQ_noData)];
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// popNextProcessedBuffer
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) popNextProcessedBuffer
{
    SndAudioBuffer *ab = nil;
    
    [processedBuffersLock lockWhenCondition: ABQ_hasData];
#if SNDABQ_DEBUG    
    NSLog(@"pop processed...\n");
#endif
    if([processedBuffers count] == 0) {
	NSLog(@"Warning: -popNextProcessedBuffer attempted to pop a buffer from an empty processed queue\n");
    }
    ab = [[processedBuffers objectAtIndex: 0] retain]; // retain so it's not released by removeObjectAtIndex: below.
    [processedBuffers removeObjectAtIndex: 0];
    [processedBuffersLock unlockWithCondition: ([processedBuffers count] > 0 ? ABQ_hasData : ABQ_noData)];
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// addPendingBuffer:
////////////////////////////////////////////////////////////////////////////////

- addPendingBuffer: (SndAudioBuffer*) audioBuffer
{
    if (audioBuffer == nil)
	NSLog(@"SndAudioBufferQueue::addPendingBuffer - audioBuffer is nil!");
    else {
	[pendingBuffersLock lock];
#if SNDABQ_DEBUG    
	NSLog(@"add pending...\n");
#endif
	[pendingBuffers addObject: audioBuffer];
	if(maximumPendingBuffers < [pendingBuffers count])
	    maximumPendingBuffers = [pendingBuffers count];
	[pendingBuffersLock unlockWithCondition: ABQ_hasData];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// addProcessedBuffer:
////////////////////////////////////////////////////////////////////////////////

- addProcessedBuffer: (SndAudioBuffer*) audioBuffer
{
    if (audioBuffer == nil)
	NSLog(@"SndAudioBufferQueue::addProcessedBuffer - audioBuffer is nil!");
    else {
	[processedBuffersLock lock];
#if SNDABQ_DEBUG    
	NSLog(@"add processed...\n");
#endif    
	[processedBuffers addObject: audioBuffer];
	if(maximumProcessedBuffers < [processedBuffers count])
	    maximumProcessedBuffers = [processedBuffers count];
	[processedBuffersLock unlockWithCondition: ABQ_hasData];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// cancelProcessedBuffers
////////////////////////////////////////////////////////////////////////////////

- (void) cancelProcessedBuffers
{
    int numOfProcessedBuffers, bufferIndex;
    
    [processedBuffersLock lock];
    numOfProcessedBuffers = [processedBuffers count];
#if SNDABQ_DEBUG
    NSLog(@"moving %d processed buffers to pending...\n", numOfProcessedBuffers);
#endif    
    for(bufferIndex = 0; bufferIndex < numOfProcessedBuffers; bufferIndex++) {
	SndAudioBuffer *processedAudioBuffer = [[processedBuffers objectAtIndex: 0] retain];
	
	[processedBuffers removeObjectAtIndex: 0];
	[self addPendingBuffer: processedAudioBuffer];
	[processedAudioBuffer release];
    }
    [processedBuffersLock unlockWithCondition: ABQ_noData];
}

////////////////////////////////////////////////////////////////////////////////
// pendingBuffersCount
////////////////////////////////////////////////////////////////////////////////

- (int) pendingBuffersCount
{
    return [pendingBuffers count];
}

////////////////////////////////////////////////////////////////////////////////
// processedBuffersCount
////////////////////////////////////////////////////////////////////////////////

- (int) processedBuffersCount
{
    return [processedBuffers count];
}

////////////////////////////////////////////////////////////////////////////////
// bufferCount
////////////////////////////////////////////////////////////////////////////////

- (int) bufferCount
{
    return numBuffers;
}

// For redefining the queue dynamically.
// TODO should enable to copy over the existing buffers.
- (void) setBufferCount: (int) newNumberOfBuffers
{
    [pendingBuffersLock lock];
    [pendingBuffers release];
    pendingBuffers = [[NSMutableArray arrayWithCapacity: newNumberOfBuffers] retain];
    [pendingBuffersLock unlockWithCondition: ABQ_noData];

    [processedBuffersLock lock];
    [processedBuffers release];
    processedBuffers = [[NSMutableArray arrayWithCapacity: newNumberOfBuffers] retain];
    [processedBuffersLock unlockWithCondition: ABQ_noData];
    numBuffers = newNumberOfBuffers;
}

////////////////////////////////////////////////////////////////////////////////
// freeBuffers
////////////////////////////////////////////////////////////////////////////////

- freeBuffers
{
    [pendingBuffers   removeAllObjects];
    [processedBuffers removeAllObjects];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// prepareQueueAsType:withBufferPrototype:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) prepareQueueAsType: (SndAudioBufferQueueType) type withBufferPrototype: (SndAudioBuffer*) buff
{
    if (buff == nil) {
	NSLog(@"SndAudioBufferQueue::prepareQueueAsType - ERROR: buff is nil!\n");
	return NO;
    }
    switch (type) {
	case audioBufferQueue_typeInput: {
	    int processedBufferIndex;
	    
	    [pendingBuffersLock lock];
	    [pendingBuffersLock unlockWithCondition: ABQ_noData];
	    [processedBuffersLock lock];
	    for (processedBufferIndex = 0; processedBufferIndex < numBuffers; processedBufferIndex++)
		[processedBuffers addObject: [buff copy]];
	    [processedBuffersLock unlockWithCondition: ABQ_hasData];
	}
	break;
	    
	case audioBufferQueue_typeOutput: {
	    int pendingBufferIndex;
	    
	    [processedBuffersLock lock];
	    [processedBuffersLock unlockWithCondition: ABQ_noData];
	    [pendingBuffersLock lock];
	    for (pendingBufferIndex = 0; pendingBufferIndex < numBuffers; pendingBufferIndex++)
		[pendingBuffers addObject: [buff copy]];
	    [pendingBuffersLock unlockWithCondition: ABQ_hasData];
	}
	break;
    }
    return YES;
}

////////////////////////////////////////////////////////////////////////////////

@end
