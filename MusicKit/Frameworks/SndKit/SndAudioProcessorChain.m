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
#import "SndAudioFader.h"
#import "SndAudioProcessor.h"
#import "SndAudioProcessorChain.h"

@implementation SndAudioProcessorChain

////////////////////////////////////////////////////////////////////////////////
// audioProcessorChain
////////////////////////////////////////////////////////////////////////////////

+ audioProcessorChain
{
    SndAudioProcessorChain *pSAPC = [[SndAudioProcessorChain alloc] init];
    return [pSAPC autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    [super init];
    if (audioProcessorArray == nil)
        audioProcessorArray = [[NSMutableArray arrayWithCapacity: 2] retain];
    bBypass = FALSE;
    nowTime = 0.0;
    postFader = [[SndAudioFader alloc] init];
    [postFader setActive: YES]; // By default, our post effects fader is active.
    [postFader setAudioProcessorChain: self];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc;
{
    [audioProcessorArray release];
    [tempBuffer release];
    [postFader release];
    [super dealloc];
}


- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ audioProcessors: %@, postFader %@ %@\n", 
	[super description], audioProcessorArray, postFader, bBypass ? @"(bypassed)" : @"(active)"];
}

////////////////////////////////////////////////////////////////////////////////
// bypassProcessors
////////////////////////////////////////////////////////////////////////////////

- bypassProcessors: (BOOL) b
{
    bBypass = b;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// addAudioProcessor
////////////////////////////////////////////////////////////////////////////////

- addAudioProcessor: (SndAudioProcessor *) proc
{
    [audioProcessorArray addObject: proc];
    [proc setAudioProcessorChain: self];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// insertAudioProcessor:atIndex:
////////////////////////////////////////////////////////////////////////////////

- insertAudioProcessor: (SndAudioProcessor *) proc
	       atIndex: (int) processorIndex
{
    [audioProcessorArray insertObject: proc atIndex: processorIndex];
    [proc setAudioProcessorChain: self];
    return self;    
}


////////////////////////////////////////////////////////////////////////////////
// removeAudioProcessor
////////////////////////////////////////////////////////////////////////////////

- removeAudioProcessor: (SndAudioProcessor *) proc
{
    [audioProcessorArray removeObject: proc];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// removeAudioProcessorAtIndex:
////////////////////////////////////////////////////////////////////////////////

- removeAudioProcessorAtIndex: (int) index
{
    [audioProcessorArray removeObjectAtIndex: index];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processorAtIndex
////////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessor *) processorAtIndex: (int) index
{
    return [audioProcessorArray objectAtIndex: index];
}

////////////////////////////////////////////////////////////////////////////////
// removeAllProcessors
////////////////////////////////////////////////////////////////////////////////

- removeAllProcessors
{
    [audioProcessorArray removeAllObjects];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processBuffer:forTime:
////////////////////////////////////////////////////////////////////////////////

- processBuffer: (SndAudioBuffer *) buff forTime: (double) t
{
    int audioProcessorIndex, audioProcessorCount = [audioProcessorArray count];
    if (bBypass)
        return self;

    nowTime = t;
    // TODO: make sure temp buffer is in same format and size as buff too.

    if (tempBuffer == nil) {
        tempBuffer = [[SndAudioBuffer alloc] initWithBuffer: buff];
    }
    for (audioProcessorIndex = 0; audioProcessorIndex < audioProcessorCount; audioProcessorIndex++) {
	SndAudioProcessor *proc = [audioProcessorArray objectAtIndex: audioProcessorIndex];
	if ([proc isActive]) {
	    if ([proc processReplacingInputBuffer: buff
				     outputBuffer: tempBuffer]) {
		// NSLog(@"buff %@\n", buff);
		[buff copyData: tempBuffer];
		// NSLog(@"after buff %@\n", buff);
	    }
	}
    }
    if ([postFader isActive]) {
	if ([postFader processReplacingInputBuffer: buff
				      outputBuffer: tempBuffer]) {
	    [buff copyData: tempBuffer];
	}
	// NSLog(@"fader after buff %@\n", buff);
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processorCount
////////////////////////////////////////////////////////////////////////////////

- (int) processorCount
{
    return [audioProcessorArray count];
}

////////////////////////////////////////////////////////////////////////////////
// processorArray
////////////////////////////////////////////////////////////////////////////////

- (NSArray*) processorArray
{
    return audioProcessorArray;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isBypassingFX
{
  return bBypass;
}

////////////////////////////////////////////////////////////////////////////////
// setBypass
////////////////////////////////////////////////////////////////////////////////

- (void) setBypass: (BOOL) b
{
  bBypass = b;
}

////////////////////////////////////////////////////////////////////////////////
// postFader
////////////////////////////////////////////////////////////////////////////////

- (SndAudioFader *) postFader
{
  return [[(id)postFader retain] autorelease];
}

- (void) setPostFader: (SndAudioFader *) newPostFader
{
    [postFader release];
    postFader = [newPostFader retain];
}

////////////////////////////////////////////////////////////////////////////////
// nowTime
////////////////////////////////////////////////////////////////////////////////

- (double) nowTime
{
    return nowTime;
}

////////////////////////////////////////////////////////////////////////////////

@end
