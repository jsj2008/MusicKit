/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import "SndAudioBuffer.h"
#import "SndPlayer.h"
#import "SndStreamManager.h"
#import "SndPerformance.h"

////////////////////////////////////////////////////////////////////////////////
//  SndPlayer
////////////////////////////////////////////////////////////////////////////////

static SndPlayer *defaultSndPlayer;


@implementation SndPlayer

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

+ player
{
    SndPlayer *sp = [SndPlayer new];
    return [sp autorelease];
}

+ (SndPlayer*) defaultSndPlayer
{
  if (defaultSndPlayer == nil) {
    Snd *s = [Snd new];
    defaultSndPlayer = [SndPlayer new]; 
    [s release];
  }
  return [[defaultSndPlayer retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- init
{
    [super init];
    bRemainConnectedToManager = TRUE;
    if (toBePlayed  == nil)
        toBePlayed  = [[NSMutableArray arrayWithCapacity: 10] retain];
    if (playing     == nil)
        playing     = [[NSMutableArray arrayWithCapacity: 10] retain];
    if (playingLock == nil)
        playingLock = [[NSLock alloc] init];  // controls adding and removing sounds from the playing list.
    [self setClientName: @"SndPlayer"];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [toBePlayed release];
    [playing release];
    [playingLock release];
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
    NSString *description;
    [playingLock lock];
    description = [NSString stringWithFormat: @"SndPlayer to be played %@, playing %@", toBePlayed, playing];
    [playingLock unlock];
    return description;
}

// Start the given performance immediately by adding it to the playing list and firing off the delegate.
// We assume that any method calling this is doing the locking itself, hence this should not be used
// outside this class.
- _startPerformance: (SndPerformance *) performance
{
    Snd *snd = [performance snd];
    [playing addObject: performance];
    // The delay between receiving this delegate and when the audio is actually played 
    // is an extra buffer, therefore: delay == buffLength/sampleRate after the delegate 
    // message has been received.
    
    [snd _setStatus:SND_SoundPlaying]; 
//    [[performance snd] tellDelegate: @selector(willPlay:duringPerformance:)
//                  duringPerformance: performance];
    [manager sendMessageInMainThreadToTarget: snd
                                         sel: @selector(tellDelegateString:duringPerformance:)
                                        arg1: @"willPlay:duringPerformance:"
                                        arg2: performance];
    return self;
}

- stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds
{
    double whenToStop;
    double beginPlayTime;
    long stopAtSample;

    if(![self isActive]) {
        [[SndStreamManager defaultStreamManager] addClient: self];
    }
    [playingLock lock];
    whenToStop = [self streamTime] + inSeconds;
    beginPlayTime = [performance playTime]; // in seconds
    if(whenToStop < beginPlayTime) {
        // stop before we even begin, delete the performance from the toBePlayed queue
        [toBePlayed removeObject: performance];
    }
    else {
        stopAtSample = (whenToStop - beginPlayTime) * [[performance snd] samplingRate];
        // NSLog(@"stopping at sample %ld\n", stopAtSample);
        // check stopAtSample since it could be beyond the length of the sound. 
        // If so, leave it stop at the end of the sound.
        if(stopAtSample < [[performance snd] sampleCount])
            [performance setEndAtIndex: stopAtSample];
    }
    [playingLock unlock];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:withTimeOffset:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s withTimeOffset: (double) dt 
{
//    fprintf(stderr,"PlaySnd: withTimeOffset: %f\n",dt);
    return [self playSnd: s withTimeOffset: dt beginAtIndex: 0 endAtIndex: -1];
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:withTimeOffset:endAtIndex:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s
              withTimeOffset: (double) dt
                beginAtIndex: (long) beginAtIndex
                  endAtIndex: (long) endAtIndex
{
    double playT;
    
    if(![self isActive])
        [[SndStreamManager defaultStreamManager] addClient: self];
        
    if (dt < 0.0)
        playT = 0.0;
    else
        playT = [self streamTime] + dt;
     
//    fprintf(stderr,"SndPlayer: timeOffset:%f playT:%f clientNowTime:%f begin:%li end:%li\n", dt, playT,clientNowTime,beginAtIndex,endAtIndex);
    {
      SndPerformance *perf = [self playSnd: s
                           atTimeInSeconds: playT
                              beginAtIndex: beginAtIndex
                                endAtIndex: endAtIndex]; 
//      NSLog([perf description]);
      return perf;
    }
} 

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s atTimeInSeconds: (double) t withDurationInSeconds: (double) d
{
    long endIndex = -1;

    if (d > 0)
        endIndex =  d * [s samplingRate]; 
 
//    NSLog(@"SndPlayer::play:atTimeInSeconds: %f", t);
       
    return [self playSnd: s
         atTimeInSeconds: t
            beginAtIndex: 0
              endAtIndex: endIndex];  
}  


- (SndPerformance *) playSnd: (Snd *) s
             atTimeInSeconds: (double) playT
                beginAtIndex: (long) beginAtIndex
                  endAtIndex: (long) endAtIndex
{
    if(endAtIndex > [s sampleCount]) {
        endAtIndex = [s sampleCount];	// Ensure the end of play can't exceed the sound data
    }
    if(endAtIndex == -1) {
        endAtIndex = [s sampleCount];	// Ensure the end of play can't exceed the sound data
    }
    if (beginAtIndex > endAtIndex) {
//      NSLog(@"SndPlayer::playSnd:atTimeInSeconds:beginAtIndex:endAtIndex: - WARNING: beginAtIndex > endAtIndex - ignoring play cmd");
      return nil;
    }
    if(beginAtIndex < 0) {
        beginAtIndex = 0;	// Ensure the end of play can't exceed the sound data
    }
    if(![self isActive]) {
        [[SndStreamManager defaultStreamManager] addClient: self];
    }

//    fprintf(stderr,"PlaySnd:atStreamTime:%f beginAtIndex:%li endAtIndex:%li clientTime:%f streamTime:%f\n", 
//            playT, beginAtIndex, endAtIndex, clientNowTime, [manager nowTime]);

    if (playT <= clientNowTime) {  // play now!
        SndPerformance *nowPerformance;
        nowPerformance = [SndPerformance performanceOfSnd: s 
                                            playingAtTime: [self streamTime]
                                             beginAtIndex: beginAtIndex
                                               endAtIndex: endAtIndex];

        [playingLock lock];
        [self _startPerformance: nowPerformance];    
        [playingLock unlock];
        return nowPerformance;
    }		
    else {            // play later!
        int i;
        int numToBePlayed;
        int insertIndex;
        SndPerformance *laterPerformance;
        
        laterPerformance = [SndPerformance performanceOfSnd: s
                                              playingAtTime: playT
                                               beginAtIndex: beginAtIndex
                                                 endAtIndex: endAtIndex];

        [playingLock lock];
        numToBePlayed = [toBePlayed count];
        insertIndex = numToBePlayed;
        for (i = 0; i < numToBePlayed; i++) {
            SndPerformance *this = [toBePlayed objectAtIndex: i];
            if ([this playTime] > playT) {
                insertIndex = i;
                break;
            }
        }
        [toBePlayed insertObject: laterPerformance atIndex: i];
        [playingLock unlock];
        return laterPerformance;
    }
}

////////////////////////////////////////////////////////////////////////////////
// playSnd:
////////////////////////////////////////////////////////////////////////////////

- (SndPerformance *) playSnd: (Snd *) s
{
    return [self playSnd: s withTimeOffset: 0.0];
}

// stop all performances of the sound, at some point in the future.
- stopSnd: (Snd *) s withTimeOffset: (double) inSeconds
{
    NSArray *performancesToStop = [self performancesOfSnd: s];
    int performanceIndex;

    for(performanceIndex = 0; performanceIndex < [performancesToStop count]; performanceIndex++) {
        [self stopPerformance: [performancesToStop objectAtIndex: performanceIndex] inFuture: inSeconds];
    }
    return self;
}

// stop all performances of the sound immediately.
- stopSnd: (Snd *) s
{
    return [self stopSnd: s withTimeOffset: 0.0];
}

// Return an array of the performances of a given sound.
- (NSArray *) performancesOfSnd: (Snd *) snd
{
    int performanceIndex;
    NSMutableArray *performances = [NSMutableArray arrayWithCapacity: 10];
    SndPerformance *aPerformance;
    int count;

    // extract out from our playing/toBePlayed lists those with Snds matching snd
    [playingLock lock];
    count = [playing count];
    for (performanceIndex = 0; performanceIndex < count; performanceIndex++) {
        aPerformance = [playing objectAtIndex: performanceIndex];
        if([snd isEqual: [aPerformance snd]]) {
            [performances addObject: aPerformance];
        }
    }
    count = [toBePlayed count];
    for (performanceIndex = 0; performanceIndex < count; performanceIndex++) {
        aPerformance = [toBePlayed objectAtIndex: performanceIndex];
        if([snd isEqual: [aPerformance snd]]) {
            [performances addObject: aPerformance];
        }
    }
    [playingLock unlock];
    return performances;
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
// nowTime must be the CLIENT now time as this is a process-head capable
// thread - our client's synthesis sense of time is ahead of the manager's
// closer-to-absolute sense of time.
////////////////////////////////////////////////////////////////////////////////
 
- (void) processBuffers  
{
    SndAudioBuffer* ab   = [self synthOutputBuffer];
    double       bufferDur     = [ab duration];
//    double       sampleRate    = [ab samplingRate];
    double       bufferEndTime = [self synthesisTime] + bufferDur;
    int numberToBePlayed;
    int numberPlaying;
    int buffLength = [ab lengthInSamples];
    int i;
    NSMutableArray *removalArray = [NSMutableArray arrayWithCapacity: 10];

    [playingLock lock];
    // Are any of the 'toBePlayed' samples gonna fire off during this buffer?
    // If so, add 'em to the play array
    numberToBePlayed = [toBePlayed count];
    for (i = 0; i < numberToBePlayed; i++) {
        SndPerformance *performance = [toBePlayed objectAtIndex: i];
        if ([performance playTime] < bufferEndTime) {
            [removalArray addObject: performance];
            [performance setPlayIndex: - [[performance snd] samplingRate] * ([performance playTime] - [self synthesisTime])];
            [self _startPerformance: performance];
        }
    }
    [toBePlayed removeObjectsInArray: removalArray];
    [removalArray removeAllObjects];
    
    //*The plan*
    //
    // Create a temporary wrapper buffer around each audio segment we are mixing.

    numberPlaying = [playing count];
    for (i = 0; i < numberPlaying; i++) {
        SndPerformance *performance = [playing objectAtIndex: i];
        Snd    *snd          = [performance snd];
        long    startIndex   = [performance playIndex];
        long    endAtIndex   = [performance endAtIndex];  // allows us to play a sub-section of a sound.
        NSRange playRegion   = {startIndex, buffLength};
        
        if (buffLength + startIndex > endAtIndex)
            buffLength = endAtIndex - startIndex;
        playRegion.length = buffLength;

        if (startIndex < 0) {
            playRegion.length += startIndex;
            playRegion.location = 0;
        }

        //NSLog(@"SYNTH THREAD: startIndex = %ld, endAtIndex = %ld, location = %d, length = %d\n", startIndex, endAtIndex, playRegion.location, playRegion.length);
        // Negative buffer length means the endAtIndex was moved before the current playIndex, so we should skip any mixing and stop.
        if(buffLength > 0) {      
            int start = 0, end = buffLength;
            SndAudioBuffer *temp = [SndAudioBuffer audioBufferWithSndSeg: snd range: playRegion];
    
            if (startIndex < 0)
                start = -startIndex;
            if (end + startIndex > endAtIndex)
                end = endAtIndex - startIndex;

            // NSLog(@"SYNTH THREAD: calling mixWithBuffer from SndPlayer processBuffers start = %ld, end = %ld\n", start, end);
            [ab mixWithBuffer: temp fromStart: start toEnd: end];
	    //NSLog(@"\nSndPlayer: mixing buffer from %d to %d, playregion %d for %d, val at start = %f\n",
	    // start, end, playRegion.location, playRegion.length, (((short *)[snd data])[playRegion.location])/(float)32768);

            [performance setPlayIndex: startIndex + buffLength];
        }
        
        // When at the end of sounds, signal the delegate and remove the performance.
        
        if ([performance playIndex] >= endAtIndex) {
            int count;
            int performanceIndex;
            SndPerformance *aPerformance;
            
            [removalArray addObject: performance];
  // SKoT: Dangerous - what if we have multiple performances of a single sound? Comment out for now.       
 //           [[performance snd] _setStatus: SND_SoundStopped];
 //           [[performance snd] tellDelegate: @selector(didPlay:duringPerformance:)
 //                        duringPerformance: performance];

/* sbrandon Nov 2001: now check thru all performances, and if this one was the last
 * one using this snd, we set the snd to SND_SoundStopped
 */
            count = [playing count];
            for (performanceIndex = 0; performanceIndex < count; performanceIndex++) {
                aPerformance = [playing objectAtIndex: performanceIndex];
                if([snd isEqual: [aPerformance snd]] && performance != aPerformance) {
                    performanceIndex = -1;
                    break;
                }
            }
            if (performanceIndex != -1) {
                [snd _setStatus: SND_SoundStopped];
            }

/* sbrandon Nov 2001: re-instated delegate messaging, but fixed it up for multithreaded
 * use. Note that the arguments HAVE to be objects - hence arg1 here is not a SEL as one
 * would expect but an NSString, and we convert to a SEL in the Snd object.
 * Note also that the messages received in the main thread are asynchronous, being
 * received in the NSRunLoop in the same way that keyboard, mouse or GUI actions are
 * received.
 */
            [manager sendMessageInMainThreadToTarget: snd
                                                 sel: @selector(tellDelegateString:duringPerformance:)
                                                arg1: @"didPlay:duringPerformance:"
                                                arg2: performance];

        }
    }

    // NSLog(@"SYNTH THREAD: playing %d sounds", [playing count]);
    if ([removalArray count] > 0) {
        [playing removeObjectsInArray: removalArray];
        if (!bRemainConnectedToManager &&
            [toBePlayed count] == 0 && 
            [playing count] == 0) 
        {
            active = FALSE;
            // NSLog(@"SYNTH THREAD: Setting active false\n");
        }
    }
    [playingLock unlock];    
}

- setRemainConnectedToManager: (BOOL) b
{
  bRemainConnectedToManager = b;
  return self;
}

@end
