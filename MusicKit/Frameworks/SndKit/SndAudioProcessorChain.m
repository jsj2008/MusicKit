////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorChain.m
//  SndKit
//
//  Created by skot on Tue Mar 27 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
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
    [postFader setAudioProcessorChain:self];
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

- addAudioProcessor: (SndAudioProcessor*) proc
{
    [audioProcessorArray addObject: proc];
    [proc setAudioProcessorChain:self];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// removeAudioProcessor
////////////////////////////////////////////////////////////////////////////////

- removeAudioProcessor: (SndAudioProcessor*) proc
{
    [audioProcessorArray removeObject: proc];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processorAtIndex
////////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessor*) processorAtIndex: (int) index
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

- processBuffer: (SndAudioBuffer*) buff forTime: (double) t
{
    if (bBypass)
        return self;

    nowTime = t;
    // TODO: make sure temp buffer is in same format and size as buff too.

    if (tempBuffer == nil) {
        tempBuffer = [SndAudioBuffer audioBufferWithFormat: [buff format] data: NULL];
        [tempBuffer retain];
    }
    {
        int i, c = [audioProcessorArray count];

        for (i=0;i<c;i++) {
            SndAudioProcessor *proc = [audioProcessorArray objectAtIndex: i];
            if ([proc processReplacingInputBuffer: buff
                                     outputBuffer: tempBuffer]) {
                [buff copyData: tempBuffer];
            }
        }
        if ([postFader processReplacingInputBuffer: buff
                                      outputBuffer: tempBuffer]) {
            [buff copyData: tempBuffer];
        }
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
// @postFader
////////////////////////////////////////////////////////////////////////////////

- (SndAudioFader *) postFader
{
  return [[(id)postFader retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// @nowTime
////////////////////////////////////////////////////////////////////////////////

- (double) nowTime
{
    return nowTime;
}

////////////////////////////////////////////////////////////////////////////////

@end
