/******************************************************************************
$Id$

Description: Main class defining a sound object.

Original Author: Stephen Brandon

LEGAL:
This framework and all source code supplied with it, except where specified,
are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free
to use the source code for any purpose, including commercial applications, as
long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be
error free.  Further, we will not be liable to you if the Software is not fit
for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES
OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our
negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR
POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED
DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND
CONDITIONS OF THIS AGREEMENT.

Additions Copyright (c) 2001, The MusicKit Project.  All rights reserved.

******************************************************************************/
/* HISTORY
 * ..is now contained in the cvs log.
 * pre cvs:
 * 20/6/99 sb: added check to -compactSamples to ensure sound needs it
 */

#ifdef WIN32
#include <windows.h>
#else
# ifndef GNUSTEP
#  include <libc.h>
# endif
#endif

#include <stdlib.h>
#include <stdio.h>
#include <string.h> /* for memmove() */
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSApplication.h>

#import "Snd.h"
#import "SndError.h"
#import "SndFunctions.h"
#import "SndPlayer.h"

// TODO this needs upgrading
#ifndef USE_NEXTSTEP_SOUND_IO
NSString *NXSoundPboardType = @"NXSoundPboardType";
#endif

#define USE_STREAMING 1  // 0 will use the older monophonic sound API, 1 uses the newer SndPlayer API

@implementation Snd

#if !USE_STREAMING
static NSMutableDictionary *playRecTable = nil;
static int ioTags = 1000;
#endif

+ (void) initialize
{
}

+ (NSString*) defaultFileExtension
{
    return @"snd"; // TODO this should probably be determined at run time.
}

+ soundNamed:(NSString *)aName
{
  return [[SndTable defaultSndTable] soundNamed: aName];
}

+ findSoundFor:(NSString *)aName
{
  return [[SndTable defaultSndTable] findSoundFor: aName];
}

+ addName:(NSString *)aname sound:aSnd
{
  return [[SndTable defaultSndTable] addName: aname sound:aSnd];
}

+ addName:(NSString *)aname fromSoundfile:(NSString *)filename
{
  return [[SndTable defaultSndTable] addName: aname fromSoundfile: filename];
}

+ addName:(NSString *)aname fromSection:(NSString *)sectionName
{
  return [[SndTable defaultSndTable] addName: aname fromSection: sectionName];
}

+ addName:(NSString *)aName fromBundle:(NSBundle *)aBundle
{
  return [[SndTable defaultSndTable] addName: aName fromBundle: aBundle];
}

+ (void)removeSoundForName: (NSString *) aname
{
  return [[SndTable defaultSndTable] removeSoundForName: aname];
}

+ (void) removeAllSounds
{
  return [[SndTable defaultSndTable] removeAllSounds];
}


+ (BOOL)isMuted
{
    return SNDIsMuted();
}

+ setMute:(BOOL)aFlag
{
    SNDSetMute(aFlag);
    return self;
}

- init
{
    name = nil;
    conversionQuality = SndConvertLowQuality;
    delegate = nil;
    status = SND_SoundInitialized;

    currentError = 0;
    _scratchSnd = NULL;
    _scratchSize = 0;
    tag = 0;

    if (performancesArray == nil) {
      performancesArray     = [NSMutableArray new];
      performancesArrayLock = [NSLock new];
    }
    else
      [performancesArray removeAllObjects];

    // initialize loop points to legal values
    loopWhenPlaying = NO;
    loopStartIndex = 0;
    loopEndIndex = 0;

    // initialize the priming volume and balance for playback.
    allChannelsVolume = 1.0;  // full volume,
    balance = 0.0;            // center panning.
    
    return [super init];
}

- initWithFormat: (int) format
	channels: (int) channels
	  frames: (int) frames
    samplingRate: (float) samplingRate
{
  self = [self init];
  if (soundStruct == NULL)
    if (!(soundStruct = malloc(sizeof(SndSoundStruct))))
      [[NSException exceptionWithName:@"Sound Error"
                               reason:@"Can't allocate memory for Snd class"
                             userInfo:nil] raise];

  // TODO _why_ do we still have file format specific data in Snd???? History is the only reason,
  // it should eventually be removed now we use Sox for File I/O.
  soundStruct->magic        = SND_MAGIC;
  soundStruct->dataLocation = 0; 
  soundStruct->dataSize     = 0;
  soundStruct->dataFormat   = format;
  soundStruct->samplingRate = (int) samplingRate;
  soundStruct->channelCount = channels;

  [self setDataSize: SndFramesToBytes(frames, channels, format)
         dataFormat: format
       samplingRate: (int) samplingRate
       channelCount: channels
           infoSize: 0];

  return self;
}

- initWithAudioBuffer: (SndAudioBuffer*) aBuffer
{
  self = [self init];
  if (soundStruct == NULL)
    if (!(soundStruct = malloc(sizeof(SndSoundStruct))))
      [[NSException exceptionWithName:@"Sound Error"
                               reason:@"Can't allocate memory for Snd class"
                             userInfo:nil] raise];

  soundStruct->magic        = SND_MAGIC; // _why_ do we still have bloody file format specific data in Snd???? Grrrr.
  soundStruct->dataLocation = 0;
  soundStruct->dataSize     = 0;
  soundStruct->dataFormat   = [aBuffer dataFormat];
  soundStruct->samplingRate = [aBuffer samplingRate];
  soundStruct->channelCount = [aBuffer channelCount];

  [self setDataSize: [aBuffer lengthInBytes]
         dataFormat: [aBuffer dataFormat]
       samplingRate: [aBuffer samplingRate]
       channelCount: [aBuffer channelCount]
           infoSize: 0];

  memcpy([self data], [aBuffer bytes], [aBuffer lengthInBytes]);  
  return self;
}


- initFromSoundfile:(NSString *)filename
{
  self = [self init];
  if (self != nil) {
    if ([self readSoundfile: filename] != SND_ERR_NONE) {
      [self release];
      return nil;
    }
  }
  return self;
}

- initFromSection:(NSString *)sectionName
{
    printf("Snd: -initFromSection:(NSString *)sectionName obsolete, not implemented\n");
    return nil;
}

- initFromSoundURL: (NSURL *) url
{
  self = [self init];
  if (self != nil) {
    if ([self readSoundfile: [url path]] != SND_ERR_NONE) {
      [self release];
      return nil;
    }
  }
  return self;
}

- (unsigned) hash
{
  unsigned ss = 0;
  if (soundStruct) {
    // take into account all basic metadata, including size, formate, rate, channels
    ss = ((unsigned *)soundStruct)[0] + ((unsigned *)soundStruct)[1] + 
         ((unsigned *)soundStruct)[2] + ((unsigned *)soundStruct)[3] +
	 ((unsigned *)soundStruct)[4] + ((unsigned *)soundStruct)[5] +
         ((unsigned *)soundStruct)[6] + ((unsigned *)soundStruct)[7];
  }
  return [name length] * 256 + 512 * tag + ss + 1023 *soundStructSize;

}

// return the file extensions supported by sox.
+ (NSArray *) soundFileExtensions
{
    return SndFileExtensions();
}

+ (BOOL) isPathForSoundFile: (NSString *) path
{
    NSArray *exts = [[self class] soundFileExtensions];
    NSString *ext  = [path pathExtension];
    int extensionIndex, extensionCount = [exts count];
    
    for (extensionIndex = 0; extensionIndex < extensionCount; extensionIndex++) {
	NSString *anExt = [exts objectAtIndex: extensionIndex];
	if ([ext compare: anExt options: NSCaseInsensitiveSearch] == NSOrderedSame)
	    return YES;
    }
    return NO;
}

- (void) dealloc
{
    if (name) {
        if ([[SndTable defaultSndTable] soundNamed: name] == self)
            [[SndTable defaultSndTable] removeSoundForName: name];
        [name release];
    }
    if (soundStruct) SndFree(soundStruct);
    if (_scratchSnd) SndFree(_scratchSnd);
    [performancesArray release];
    performancesArray = nil;
    [performancesArrayLock release];
    performancesArrayLock = nil;
    [super dealloc];
}

// for debugging
- (NSString *) description
{
    if(soundStruct != NULL)
        return [NSString stringWithFormat: @"%@ (%@)", [super description], SndStructDescription(soundStruct)];
    else
        return name;
}

- readSoundFromStream:(NSData *)stream
{
    SndSoundStruct *s;
    int finalSize;

    [name release];
    priority = 0;

    if (soundStruct) SndFree(soundStruct);
    if (!(s = malloc(sizeof(SndSoundStruct))))
        [[NSException exceptionWithName:@"Sound Error"
                                 reason:@"Can't allocate memory for Snd class"
                               userInfo:nil] raise];
    [stream getBytes:s length:sizeof(SndSoundStruct)];/* only gets 1st 4 bytes of info string */
#ifdef __LITTLE_ENDIAN__
    s->magic = NSSwapBigLongToHost(s->magic);
    s->dataLocation = NSSwapBigLongToHost(s->dataLocation);
    s->dataSize = NSSwapBigLongToHost(s->dataSize);
    s->dataFormat = NSSwapBigLongToHost(s->dataFormat);
    s->samplingRate = NSSwapBigLongToHost(s->samplingRate);
    s->channelCount = NSSwapBigLongToHost(s->channelCount);
#endif

    // SndPrintStruct(s);
    finalSize = s->dataSize + s->dataLocation;

    s = realloc((char *)s,finalSize);
    [stream getBytes:(char *)s + sizeof(SndSoundStruct)
               range:NSMakeRange(sizeof(SndSoundStruct),finalSize - sizeof(SndSoundStruct))];

    soundStruct = s;
    status = SND_SoundInitialized;
    return SND_ERR_NONE;
}

- writeSoundToStream:(NSMutableData *)stream
{
    SndSoundStruct *s;
    SndSoundStruct **ssList;
    SndSoundStruct *theStruct;
    int headerSize;
    int df;
    int i,j=0;

    df = soundStruct->dataFormat;
    if (df == SND_FORMAT_INDIRECT) headerSize = soundStruct->dataSize;
    else headerSize = soundStruct->dataLocation;
    /* make new header with swapped bytes if nec */
    if (!(s = malloc(headerSize))) [[NSException exceptionWithName:@"Sound Error"
                                                          reason:@"Can't allocate memory for Snd class"
                                                          userInfo:nil] raise];
    memmove(s, soundStruct,headerSize);
    if (df == SND_FORMAT_INDIRECT) {
        int newCount = 0;
        i = 0;
        s->dataFormat = ((SndSoundStruct *)(*((SndSoundStruct **)
                        (soundStruct->dataLocation))))->dataFormat;
        ssList = (SndSoundStruct **)soundStruct->dataLocation;
        while ((theStruct = ssList[i++]) != NULL)
                newCount += theStruct->dataSize;
        s->dataLocation = s->dataSize;
        s->dataSize = newCount;
    }

#ifdef __LITTLE_ENDIAN__
    s->magic = NSSwapHostIntToBig(s->magic);
    s->dataLocation = NSSwapHostIntToBig(s->dataLocation);
    s->dataSize = NSSwapHostIntToBig(s->dataSize);
    s->dataFormat = NSSwapHostIntToBig(s->dataFormat);
    s->samplingRate = NSSwapHostIntToBig(s->samplingRate);
    s->channelCount = NSSwapHostIntToBig(s->channelCount);
#endif

    [stream appendBytes:s length:headerSize];
    if (df != SND_FORMAT_INDIRECT) { /* simple read/write of block of data */
        [stream appendBytes:(char *)soundStruct + soundStruct->dataLocation length:soundStruct->dataSize];
        free(s);
        return SND_ERR_NONE;
    }

    ssList = (SndSoundStruct **)soundStruct->dataLocation;
    free(s);
    while ((theStruct = ssList[j++]) != NULL) {
        [stream appendBytes:(char *)theStruct + theStruct->dataLocation length:theStruct->dataSize];
    }
    return SND_ERR_NONE;
}

- (void) swapHostToSnd
{
    void *d = [self data];
    SndSwapHostToSound(d,d,[self lengthInSampleFrames],[self channelCount],[self dataFormat]);
}

- (void) swapSndToHost
{
    void *d = [self data];
    SndSwapSoundToHost(d,d,[self lengthInSampleFrames],[self channelCount],[self dataFormat]);
}

- (void)encodeWithCoder:(NSCoder *)aCoder
/* Here I archive data to coder as CHAR rather than exact data
 * type. Why? Well, I don't want it swapping data for me! I always want the
 * internal data representation to be big endian.
 */
{
    SndSoundStruct *s;
    SndSoundStruct **ssList;
    SndSoundStruct *theStruct;
    int headerSize;
    int df;
    int i,j=0;

    [aCoder encodeConditionalObject:delegate];
    [aCoder encodeObject:name];

    df = soundStruct->dataFormat;
    if (df == SND_FORMAT_INDIRECT) headerSize = soundStruct->dataSize;
    else headerSize = soundStruct->dataLocation;
    /* make new header with swapped bytes if nec */
    if (!(s = malloc(headerSize))) [[NSException exceptionWithName:@"Sound Error"
                                                          reason:@"Can't allocate memory for Snd class"
                                                          userInfo:nil] raise];
    memmove(s, soundStruct,headerSize);
    if (df == SND_FORMAT_INDIRECT) {
        int newCount = 0;
        i = 0;
        s->dataFormat = ((SndSoundStruct *)(*((SndSoundStruct **)
                        (soundStruct->dataLocation))))->dataFormat;
        ssList = (SndSoundStruct **)soundStruct->dataLocation;
        while ((theStruct = ssList[i++]) != NULL)
            newCount += theStruct->dataSize;
        s->dataLocation = s->dataSize;
        s->dataSize = newCount;
    }

    /* no need to swap data in the header, because coders take care
    * of endian issues for us.
    */
    [aCoder encodeValuesOfObjCTypes:"iiiiii", s->magic, s->dataLocation, s->dataSize,
            s->dataFormat, s->samplingRate,s->channelCount];
    [aCoder encodeArrayOfObjCType:"c" count:headerSize - sizeof(SndSoundStruct) + 4 at:s->info];

    if (df != SND_FORMAT_INDIRECT) { /* simple read/write of block of data */
        [aCoder encodeArrayOfObjCType:"s"
                                count:soundStruct->dataSize
                                   at:(char *)soundStruct + soundStruct->dataLocation];
        free(s);
    }

    ssList = (SndSoundStruct **)soundStruct->dataLocation;
    free(s);
    while ((theStruct = ssList[j++]) != NULL) {
            [aCoder encodeArrayOfObjCType:"c"
                                    count:theStruct->dataSize
                                       at:(char *)theStruct + theStruct->dataLocation];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    SndSoundStruct *s;
    int finalSize;

    delegate = [[aDecoder decodeObject] retain];
    name = [[aDecoder decodeObject] retain];

    if (soundStruct) SndFree(soundStruct);
    if (!(s = malloc(sizeof(SndSoundStruct))))
        [[NSException exceptionWithName:@"Sound Error"
                                 reason:@"Can't allocate memory for Snd class"
                               userInfo:nil] raise];

    [aDecoder decodeValuesOfObjCTypes:"iiiiii", &(s->magic), &(s->dataLocation), &(s->dataSize),
            &(s->dataFormat), &(s->samplingRate), &(s->channelCount)];
    s = realloc((char *)s, s->dataLocation + 1); /* allocate enough room for info string */
    [aDecoder decodeArrayOfObjCType:"c" count:s->dataLocation - sizeof(SndSoundStruct) + 4 at:s->info];

    // SndPrintStruct(s);

    finalSize = s->dataSize + s->dataLocation;

    s = realloc((char *)s,finalSize);
    if (s->dataLocation > sizeof(SndSoundStruct)) {
            /* read off the rest of the info string */
        [aDecoder decodeArrayOfObjCType: "c"
                                  count: s->dataLocation - sizeof(SndSoundStruct)
                                     at: (char *)s + sizeof(SndSoundStruct)];
    }
    [aDecoder decodeArrayOfObjCType: "c" count: s->dataSize at: (char *)s + s->dataLocation];

    soundStruct = s;
    return SND_ERR_NONE;
}

- awakeAfterUsingCoder: (NSCoder *) aDecoder
{
    status = SND_SoundInitialized;
    conversionQuality = SndConvertLowQuality;
    return self; /* what to do here??? Doesn't seem to be anything pressing... */
}

- (NSString *) name
{
    return name;
}

- setName: (NSString *) theName
/* this needs to interface with an object-wide name table
 * to identify sounds by name. At the moment multiple sound
 * objects may share the same name, which is not right.
 * Second Thoughts: many sounds MAY share the same name, as
 * they do not have to register with the central name table.
 * The central name table though can only register one sound
 * with any unique name.
 */
{
    if (name) {
        [name release];
        name = nil;
    }
    if (!theName) return self;
    if (![theName length]) return self;
    name = [theName copy];
    return self;
}

- delegate
{
    return delegate;
}

- (void) setDelegate: (id) anObject
{
    delegate = anObject;
}

- (double) samplingRate
{
    if (!soundStruct) return 0;
    return (double)(soundStruct->samplingRate);
}

- (long) lengthInSampleFrames
{
    if (!soundStruct) return 0;
    return SndFrameCount(soundStruct);
}

- (double) duration
{
    if (!soundStruct) return 0.0;
    if ((double)(soundStruct->samplingRate) == 0) return 0.0; /* cop-out */
    return (double)[self lengthInSampleFrames] / (double)(soundStruct->samplingRate);
}

- (int) channelCount
{
    if (!soundStruct) return 0;
    return soundStruct->channelCount;
}

- (NSString *) info
{
    if (!soundStruct)
	return nil;
    return [NSString stringWithCString: (char *)(soundStruct->info)];
}

#if !USE_STREAMING
// Since these two functions come in from the cold, they need warm and snug autorelease pools...
int beginFun(SndSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    theSnd = [playRecTable objectForKey: [NSNumber numberWithInt: tag]];
    // NSLog(@"beginFun theSnd = %x, err = %d tag = %d\n", theSnd, err, tag);
    if (err) {
        [theSnd _setStatus:SND_SoundStopped];
        [theSnd tellDelegate:@selector(hadError:)];
    }
    else {
        [theSnd _setStatus:SND_SoundPlaying];
        [theSnd tellDelegate:@selector(willPlay:)];
    }
    [pool release];
    return 0;
}

int endFun(SndSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSNumber *tagNumber = [NSNumber numberWithInt: tag];

    theSnd = [playRecTable objectForKey: tagNumber];
    // NSLog(@"endFun theSnd = %x, err = %d tag = %d\n", theSnd, err, tag);
    [theSnd _setStatus:SND_SoundStopped];
    if (err == SND_ERR_ABORTED) err = SND_ERR_NONE;
    if (err) [theSnd tellDelegate:@selector(hadError:)];
    else [theSnd tellDelegate:@selector(didPlay:)];
    [playRecTable removeObjectForKey: tagNumber];
    /* bug fix for SoundKit: if DSP was used, its access is not
     * released as it should be. So I just automatically release it
     * here, whether or not it was used. Generally it's used for real-time
     * rate conversion for playback. (maybe recording etc too???)
     */
    err = SNDUnreserve(3);
    if(err) {
        NSLog(@"Unreserving error %d\n", err);
    }
    // NSLog(@"theSnd = %x, err = %d\n", theSnd, err);
    ((Snd *)theSnd)->tag = 0;
    [pool release];
    return 0;
}

int beginRecFun(SndSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;
    theSnd = [playRecTable objectForKey: [NSNumber numberWithInt: tag]];
    if (err) {
        [theSnd _setStatus:SND_SoundStopped];
        [theSnd tellDelegate:@selector(hadError:)];
    }
    else {
        [theSnd _setStatus:SND_SoundRecording];
        [theSnd tellDelegate:@selector(willRecord:)];
    }
    return 0;
}

int endRecFun(SndSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;
    NSNumber *tagNumber = [NSNumber numberWithInt: tag];

    theSnd = [playRecTable objectForKey: tagNumber];
    [theSnd _setStatus:SND_SoundStopped];
    printf("End recording error: %d\n",err);
    if (err == SND_ERR_ABORTED) err = SND_ERR_NONE;
    if (err) [theSnd tellDelegate:@selector(hadError:)];
    else [(Snd *)theSnd tellDelegate:@selector(didRecord:)];
    [playRecTable removeObjectForKey: tagNumber];
    ((Snd *)theSnd)->tag = 0;
    return 0;
}
#endif

// Begin the playback of the sound at some future time, specified in seconds, over a region of the sound.
// All other play methods are convenience wrappers around this.
- (SndPerformance *) playInFuture: (double) inSeconds 
                      beginSample: (int) begin
                      sampleCount: (int) count 
{
    int playBegin = begin;
    int playEnd = begin + count;
    
    if (playBegin > [self lengthInSampleFrames] || playBegin < 0)
        playBegin = 0;
    
    if (playEnd > [self lengthInSampleFrames] || playEnd < playBegin)
        playEnd = [self lengthInSampleFrames];

//    if (!soundStruct)
//        return nil;
    status = SND_SoundPlayingPending;
    
    return [[SndPlayer defaultSndPlayer] playSnd: self 
                                  withTimeOffset: inSeconds 
                                    beginAtIndex: playBegin 
                                      endAtIndex: playEnd];
}

- (SndPerformance *) playInFuture: (double) inSeconds
           startPositionInSeconds: (double) startPos
                durationInSeconds: (double) d
{
  double sr = [self samplingRate];
  return [self playInFuture: inSeconds
                beginSample: startPos * sr
                sampleCount: d * sr];
}

// TODO See if we can make this use self playInFuture so all use of looping
// is done in playInFuture:beginSample:sampleCount:
- (SndPerformance *) playAtTimeInSeconds: (double) t withDurationInSeconds: (double) d
{
//  NSLog(@"Snd::playAtTimeInSeconds: %f", t);
  return [[SndPlayer defaultSndPlayer] playSnd: self
                               atTimeInSeconds: t
                        startPositionInSeconds: 0
                             durationInSeconds: d];  
}

- (SndPerformance *) playInFuture: (double) inSeconds 
{
    return [self playInFuture: inSeconds 
                  beginSample: 0
                  sampleCount: [self lengthInSampleFrames]];
}

- (SndPerformance *) playAtDate: (NSDate *) date
{
    return [self playInFuture: [date timeIntervalSinceNow]];
}

// Legacy method for SoundKit compatability
- play:(id) sender beginSample:(int) begin sampleCount: (int) count 
{
    // do something with sender?
    [self playInFuture: 0.0
           beginSample: begin
           sampleCount: count];
    return self;
}

// Legacy method for SoundKit compatability
- play:sender
{
#if !USE_STREAMING
    int err;
    if (!soundStruct)
        return self;
    status = SND_SoundPlayingPending;
    if (!playRecTable) {
        playRecTable = [NSMutableDictionary dictionaryWithCapacity: 20];
        [playRecTable retain];
    }
    
    tag = ioTags;
    // the same soundStruct is used every time the sound is played, so we use the tag to differentiate.
    // We use an NSDictionary rather than a HashTable for strict OpenStep support.
    [playRecTable setObject: self forKey: [NSNumber numberWithInt: tag]];
    err = SNDUnreserve(3);
    if(err) {
        NSLog(@"Unreserving error %d\n", err);
    }
    err = SNDStartPlaying((SndSoundStruct *)soundStruct,
            ioTags++ /*	int tag			*/,
            1 /*	int priority	*/,
            0 /*	int preempt		*/, 
            (SNDNotificationFun) beginFun,
            (SNDNotificationFun) endFun);
    if (err) {
        NSLog(@"Playback error %d\n",err);
        return nil;
    }
    return self;
#else
    // do something with sender?
    [self playInFuture: 0.0];
    return self;
#endif
}

// Legacy method for SoundKit compatability
- (int) play
{
    [self play:self];
    return SND_ERR_NONE;
}

- record:sender
{
#if !USE_STREAMING
    int err;
    if (!playRecTable) {
        playRecTable = [NSMutableDictionary dictionaryWithCapacity: 20];
        [playRecTable retain];
    }

    if (soundStruct) {
        err = SndAlloc(&soundStruct,
                (int)((float)SND_RATE_CODEC*600.0 + 1),
                SND_FORMAT_MULAW_8,
                SND_RATE_CODEC,1,4);
        if (err) return nil;
    }
    tag = ioTags;
    [playRecTable setObject: self forKey: [NSNumber numberWithInt: tag]];
    status = SND_SoundRecordingPending;
    err = SNDStartRecording((SndSoundStruct *)soundStruct,
            ioTags++, /*	int tag			*/
            9, /*	int priority	*/
            1, /*	int preempt		*/
            (SNDNotificationFun) beginRecFun,
            (SNDNotificationFun) endRecFun);
    return self;
#else
    NSLog(@"Not yet implemented!\n");
    return self;
#endif
}

- (int) record
{
    [self record: self];
    return SND_ERR_NONE;
}

- (int) samplesProcessed
{
#if !USE_STREAMING
    return (tag == 0) ? -1 : SNDSamplesProcessed(tag);
#else
    // what to do, when samplesProcessed only makes sense if you know only one performance of this
    // snd is occuring? For now, we erroneously return the first performance.
    return [[performancesArray objectAtIndex: 0] playIndex];
#endif
}

- (int) status
{
    return status;
}

- (void) _setStatus: (int) newStatus
/* for use in the beginFunc and endFunc routines and the SndPlayer */
{
    status = newStatus;
}

- (int) waitUntilStopped
{
    return SND_ERR_NOT_IMPLEMENTED;
}

// stop the performance
+ (void) stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds
{
    [[SndPlayer defaultSndPlayer] stopPerformance: performance inFuture: inSeconds];
}

- (void) stopInFuture: (double) inSeconds
{
    if (status == SND_SoundRecording || status == SND_SoundRecordingPaused) {
        status = SND_SoundStopped;
        [self tellDelegate: @selector(didRecord:)];	
    }
  // SKoT: I commented this out as the player may have PENDING performances to
  // deal with as well - in wich case the SND won't have a playing status.
  // Basically yet another reason to move playing status stuff out of the snd obj.
//    if (status == SND_SoundPlaying || status == SND_SoundPlayingPaused) {
        [[SndPlayer defaultSndPlayer] stopSnd: self withTimeOffset: inSeconds];
//    }
}

- (void) stop: (id) sender
{
#if !USE_STREAMING
    NSNumber *tagNumber = [NSNumber numberWithInt: tag];

    if (tag) {
        SNDStop(tag);
    }
    if (status == SND_SoundRecording || status == SND_SoundRecordingPaused) {
        [playRecTable removeObjectForKey: tagNumber];
        status = SND_SoundStopped;
        [self tellDelegate:@selector(didRecord:)];      
    }
    if (status == SND_SoundPlaying || status == SND_SoundPlayingPaused) {
        [playRecTable removeObjectForKey: tagNumber];
        status = SND_SoundStopped;
        [self tellDelegate:@selector(didPlay:)];        
    }
    if(tag) {
        tag = 0;
    }
#else
    [self stopInFuture: 0.0];
#endif
}

- (int) stop
{
    [self stop: self];
    return SND_ERR_NONE;
}

- pause: sender
{
  [performancesArrayLock lock];
  [performancesArray makeObjectsPerformSelector: @selector(pause)];
  [performancesArrayLock unlock];
  return self;
}

- (int) pause
{
  [self pause: self];
  return SND_ERR_NONE;
}

- resume: sender
{
  [performancesArrayLock lock];
  [performancesArray makeObjectsPerformSelector: @selector(resume)];
  [performancesArrayLock unlock];
  return self;
}

- (int) resume;
{
  [self resume:self];
  return SND_ERR_NONE;
}

- (int) readSoundfile: (NSString *) filename
{
    int err;
    NSDictionary *fileAttributeDictionary;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (soundStruct)
        SndFree(soundStruct);

    [name release];
    name = nil;

    if (![[NSFileManager defaultManager] fileExistsAtPath: filename]) {
//      NSLog(@"Snd::readSoundfile: sound file %@ doesn't exist",filename);
      return SND_ERR_CANNOT_OPEN;
    }

    // check its seekable, by checking its POSIX regular.
    fileAttributeDictionary = [fileManager fileAttributesAtPath: filename
					           traverseLink: YES];

    if([fileAttributeDictionary objectForKey: NSFileType] != NSFileTypeRegular)
        return SND_ERR_CANNOT_OPEN;

    err = SndReadSoundfile(filename, &soundStruct);

    // SndPrintStruct(soundStruct);
    if (!err) {
        soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
        // This is probably a bit kludgy but it will do for now.
        loopEndIndex = [self lengthInSampleFrames] - 1;
    }
    return err;
}

- (int) writeSoundfile: (NSString *) filename
{
    // compaction ideally should not be necessary, but SoX saving requires it for now
    [self compactSamples]; 
    return SndWriteSoundfile(filename, soundStruct);
    //return SndWriteSoundfile([filename fileSystemRepresentation], soundStruct);
}

- (void) writeToPasteboard: (NSPasteboard *) thePboard
{
/* here I provide data straight away. Ideally, a non-freeing object
 * should be given the data to hold, and it should implement the "provideData"
 * method.
 * If I could guarantee that the Snd Class object itself wold not be freed
 * (for instance when the app is terminated) then one could specify the class
 * object. Cunning, eh. Maybe I'll do that anyway, and use a static variable to
 * hold the data...
 */
/* an alternative method of providing the data here is to NOT compact,
 * but to write the data to a stream (  NXStream *ts ) and send the stream to 
 * the pasteboard. I'll leave it like it is for now.
 */
/* here I assume that the header will be in host form, and the sound data
 * will be in "sound" (ie big endian) format. This is ok if we aren't trying
 * to share the pasteboard between dissimilar machines...
 */
    BOOL ret;
    NSMutableData *ts = [NSMutableData dataWithCapacity:soundStructSize];

//	[self compactSamples];
    [self writeSoundToStream:ts];
    [thePboard declareTypes:[NSArray arrayWithObject:NXSoundPboardType] owner:nil];	

    ret = [thePboard setData:ts forType:NXSoundPboardType];
    if (!ret) {
        printf("Sound paste error\n");
    }
}

- initFromPasteboard: (NSPasteboard *) thePboard
{
    NSData *ts;
    ts = [thePboard dataForType:NXSoundPboardType];
    [self init];
    [self readSoundFromStream:ts];

    return self;
}

- (BOOL) isEmpty
{
    if (![self isEditable]) return NO;
    if (!soundStruct) return YES;
    if (![self dataSize]) return YES;
    return NO;
}

- (BOOL) isEditable
{
    int df;
    if (!soundStruct) return YES; /* empty sound can be played! */
    if ((df = soundStruct->dataFormat) == SND_FORMAT_INDIRECT)
        df =  ((SndSoundStruct *)(*((SndSoundStruct **)
                (soundStruct->dataLocation))))->dataFormat;
    switch (df) {
        case SND_FORMAT_MULAW_8:
        case SND_FORMAT_LINEAR_8:
        case SND_FORMAT_LINEAR_16:
        case SND_FORMAT_LINEAR_24:
        case SND_FORMAT_LINEAR_32:
        case SND_FORMAT_FLOAT:
        case SND_FORMAT_DOUBLE:
                return YES;
        default:
                break;
    }
    return NO;
}

- (BOOL) compatibleWith: (Snd *) aSound
{
    SndSoundStruct *aStruct;
    if (!soundStruct) return YES;
    if (!aSound) return YES;
    if (!(aStruct = [aSound soundStruct])) return YES;
    if (soundStruct->samplingRate == aStruct->samplingRate
          && soundStruct->channelCount == aStruct->channelCount
          && [self dataFormat] == [aSound dataFormat]) return YES;
    return NO;
}

- (BOOL) isPlayable
{
    int df,cc,sr;
    if (!soundStruct) return YES; /* empty sound can be played! */
    if ((df = soundStruct->dataFormat) == SND_FORMAT_INDIRECT)
        df =  ((SndSoundStruct *)(*((SndSoundStruct **)
                    (soundStruct->dataLocation))))->dataFormat;
    cc = soundStruct->channelCount;
    if (cc < 1 || cc > 2) return NO;
    sr = soundStruct->samplingRate;
    if (sr < 4000 || sr > 48000) return NO; /* need to check hardware here */
    switch (df) {
    case SND_FORMAT_MULAW_8:
    case SND_FORMAT_LINEAR_8:
    case SND_FORMAT_LINEAR_16:
    case SND_FORMAT_LINEAR_32:
    case SND_FORMAT_FLOAT:
    case SND_FORMAT_DOUBLE:
        return YES;
    default:
        break;
    }
    return NO;
}
	
- (int) convertToFormat: (int) toFormat
	   samplingRate: (double) toRate
	   channelCount: (int) toChannelCount
{
    NSRange wholeSound = { 0, [self lengthInSampleFrames] };
    SndAudioBuffer *bufferToConvert;
    SndAudioBuffer *error;

    if([self dataFormat] == toFormat && [self samplingRate] == toRate && [self channelCount] == toChannelCount)
	return SND_ERR_NONE;

    bufferToConvert = [SndAudioBuffer audioBufferWithSnd: self inRange: wholeSound];
    switch (conversionQuality) {
    case SndConvertLowQuality:
    default:
	/* fastest conversion, non-interpolated */
	error = [bufferToConvert convertToFormat: toFormat
			            channelCount: toChannelCount
			            samplingRate: toRate
		                  useLargeFilter: NO
		               interpolateFilter: NO
		          useLinearInterpolation: YES];
	    
	break;
    case SndConvertMediumQuality:
	/* medium conversion, small filter, uses interpolation */
	error = [bufferToConvert convertToFormat: toFormat
				    channelCount: toChannelCount
				    samplingRate: toRate
				  useLargeFilter: NO
			       interpolateFilter: YES
			  useLinearInterpolation: NO];
        break;
    case SndConvertHighQuality:
	/* slow, accurate conversion, large filter, uses interpolation */
	error = [bufferToConvert convertToFormat: toFormat
				    channelCount: toChannelCount
				    samplingRate: toRate
				  useLargeFilter: YES
			       interpolateFilter: YES
			  useLinearInterpolation: NO];
    }
    if (error != nil) {
	double stretchFactor = toRate / [self samplingRate];
	SndSoundStruct *toSound;
	int err = SndAlloc(&toSound, [bufferToConvert lengthInBytes], toFormat, toRate, toChannelCount, 4);

	if (err != SND_ERR_NONE)
	    return err;
	
        SndFree(soundStruct);
	// We need to copy the buffer sample data back into the soundStruct. In the future, post-soundStruct,
	// we should just be able to use the buffer directly.
	memcpy((void *) toSound + toSound->dataLocation, [bufferToConvert bytes], [bufferToConvert lengthInBytes]);
	soundStruct = toSound;
        soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
	loopStartIndex *= stretchFactor;  // adjust the loop pointers if the sound was resampled.
	loopEndIndex *= stretchFactor;
	return SND_ERR_NONE;
    }
    return SND_ERR_UNKNOWN;
}

- (int) convertToFormat: (int) aFormat
{
    return [self convertToFormat: aFormat
                    samplingRate: soundStruct->samplingRate
                    channelCount: soundStruct->channelCount];
}

- (int) convertToNativeFormat
{
    SndSoundStruct nativeFormat;

    SNDStreamNativeFormat(&nativeFormat);
    return [self convertToFormat: nativeFormat.dataFormat
                    samplingRate: nativeFormat.samplingRate
                    channelCount: nativeFormat.channelCount];
}

- (int) deleteSamples
{
    return [self deleteSamplesAt: 0 count: [self lengthInSampleFrames]];
}

- (int) deleteSamplesAt: (int) startSample count: (int) sampleCount
{
    int err = SndDeleteSamples(soundStruct, startSample, sampleCount);
    
    if (!err) {
        if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
            soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
        else
	    soundStructSize = soundStruct->dataSize;		
    }
    return err;
}

- (int) insertSamples: (Snd *) aSnd at: (int) startSample
{
    int err;
    SndSoundStruct *fromSound;
    
    if (!aSnd)
        return SND_ERR_NONE;
    if (!(fromSound = [aSnd soundStruct]))
        return SND_ERR_NONE;
    err = SndInsertSamples(soundStruct, fromSound, startSample);
    if (!err) {
        if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
            soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
        else
            soundStructSize = soundStruct->dataSize;		
    }
    return err;
}

- (id) copyWithZone: (NSZone *) zone
{
    id newSound = [[[self class] allocWithZone: zone] init];
    
    [newSound copySound:self];
    return newSound;
}

- (int) copySound: (Snd *) aSnd
{
    int err;
    SndSoundStruct *fromSound;
    
    status = SND_SoundInitialized;
    if (aSnd)
        if (soundStruct == [aSnd soundStruct]) return SND_ERR_NONE;
    if (soundStruct) {
        err = SndFree(soundStruct);
        soundStruct = NULL;
        soundStructSize = 0;
        if (err) return err;
    }
    if (!aSnd) {
        return SND_ERR_NONE;
    }

    if (!(fromSound = [aSnd soundStruct])) {
        return SND_ERR_NONE;
    }
    err = SndCopySound(&soundStruct,fromSound);
    if (!err) {
        if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
            soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
        else
            soundStructSize = soundStruct->dataSize;		
    }
    return err;
}

- (int) copySamples: (Snd *) aSnd at: (int) startSample count: (int) sampleCount
{
    int err;
    
    status = SND_SoundInitialized;
    if (!aSnd) {
        if (soundStruct) {
            err = SndFree(soundStruct);
            soundStruct = NULL;
            soundStructSize = 0;
            return err;
        }
        return SND_ERR_NONE;
    }
    if (soundStruct) {
        if (![self isEditable]) return SND_ERR_CANNOT_EDIT;
// following condition not in the original! Therefore removed.
//		if (![aSnd compatibleWith:self]) return SND_ERR_CANNOT_COPY;
        SndFree(soundStruct);
        soundStruct = NULL;
        soundStructSize = 0;
    }
    err = SndCopySamples(&soundStruct, [aSnd soundStruct],
            startSample, sampleCount);
    if (!err) {
        if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
                soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
        else soundStructSize = soundStruct->dataSize;		
    }
    return err;
}

- (int) compactSamples
{
    SndSoundStruct *newStruct;
    int err;
    
    if (![self isEditable]) return SND_ERR_CANNOT_EDIT;
    if (!soundStruct) return SND_ERR_NOT_SOUND;
    if (soundStruct->dataFormat != SND_FORMAT_INDIRECT) return SND_ERR_NONE;
    if ((err = SndCompactSamples(&newStruct, soundStruct))) return err;
    if ((err = SndFree(soundStruct))) return err;
    soundStruct = newStruct;
    soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
    return SND_ERR_NONE;
}

- (BOOL) needsCompacting
{
    if (!soundStruct) return NO;
    return (soundStruct->dataFormat == SND_FORMAT_INDIRECT);
}

- (unsigned char *) data
{
  if (!soundStruct) return NULL;
  if (soundStruct->dataFormat == SND_FORMAT_INDIRECT)
    return (char *)soundStruct->dataLocation;
  return (char *)soundStruct + soundStruct->dataLocation;
}

- (int) dataSize
/* This looks after fragged sounds ok, as the docs say that for a
 * fragged sound, this should return the length of the main SndSoundStruct
 * (not including data); otherwise, should return num of bytes of data,
 * not including the structure.
 */
{
    if (!soundStruct) return 0;
    return soundStruct->dataSize; 
}

- (int) dataFormat
{
    int df;
    if (!soundStruct) return 0;
    if ((df = soundStruct->dataFormat) == SND_FORMAT_INDIRECT)
        return ((SndSoundStruct *)(*((SndSoundStruct **)
                    (soundStruct->dataLocation))))->dataFormat;
    return df;
}

- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer*) buff
{
    if (buff == nil)
	return FALSE;
    else
	return (soundStruct->dataFormat   == [buff dataFormat]  ) &&
	       (soundStruct->channelCount == [buff channelCount]) &&
	       (soundStruct->samplingRate == [buff samplingRate]);
}

- (int) setDataSize: (int) newDataSize
         dataFormat: (int) newDataFormat
       samplingRate: (double) newSamplingRate
       channelCount: (int) newChannelCount
           infoSize: (int) newInfoSize
{
    if (soundStruct) SndFree(soundStruct);
    return SndAlloc(&soundStruct, newDataSize, newDataFormat,
            newSamplingRate, newChannelCount, newInfoSize);
}

- (SndSoundStruct *) soundStruct
{
    return soundStruct;
}

/* if the sound is fragmented, returns only the size of the FIRST fragment */
- (int) soundStructSize
{
    if (!soundStruct) return 0;
    if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
        return soundStruct->dataSize + soundStruct->dataLocation;
    else
        return soundStruct->dataSize; /* see SndFunctions.h */
}

- setSoundStruct: (SndSoundStruct *) aStruct soundStructSize: (int) aSize
{
    if (status != SND_SoundInitialized && status != SND_SoundStopped)
            return nil;
    if (soundStruct && soundStruct != aStruct) SndFree(soundStruct);
    soundStruct = aStruct;
    soundStructSize = aSize;
    return self;
}

/* when we implement i/o, need to return different */
- (SndSoundStruct *) soundStructBeingProcessed
{
    return soundStruct;
}

- (int) processingError
{
    return currentError;
}

/* default implementation. Provided for subclassing */
- soundBeingProcessed
{
    return self;
}

// delegations which are not nominated per performance.
- (void) tellDelegate: (SEL) theMessage
{
    if (delegate) {
        if ([delegate respondsToSelector:theMessage]) {
            [delegate performSelector:theMessage withObject:self];
        }
    }
}

// delegations which are nominated per performance.
- (void) tellDelegate: (SEL) theMessage duringPerformance: (SndPerformance *) performance
{
    if (delegate) {
        if ([delegate respondsToSelector:theMessage]) {
            [delegate performSelector:theMessage withObject: self withObject: performance];
        }
    }
}

// Convenience function for when using NSInvocations to send messages. NSInvocations don't like
// dealing with SEL types, so we use a NSString on the other end, and convert to SEL here.
- (void) tellDelegateString: (NSString *) theMessage duringPerformance: (SndPerformance *) performance
{
    [self tellDelegate: NSSelectorFromString(theMessage) duringPerformance: performance];
}

- (void) setConversionQuality: (SndConversionQuality) quality
{
    conversionQuality = quality;
}

- (SndConversionQuality) conversionQuality
{
    return conversionQuality;
}

- (NSArray*) performances
{
  return performancesArray;
}

- addPerformance: (SndPerformance*) p
{
  [performancesArrayLock lock];
  [performancesArray addObject: p];
  [performancesArrayLock unlock];
  return self;
}

- removePerformance: (SndPerformance*) p
{
  [performancesArrayLock lock];
  [performancesArray removeObject: p];
  [performancesArrayLock unlock];
  return self;
}

- (int) performanceCount
{
  return [performancesArray count];
}

- (SndAudioBuffer*) audioBufferForSamplesInRange: (NSRange) r
{
  SndAudioBuffer *ab  = [SndAudioBuffer alloc];
  int   samSize       = SndFrameSize(soundStruct);
  void* dataPtr       = [self data] + samSize * r.location;
  int   lengthInBytes = r.length * samSize;
  SndSoundStruct s;

  memcpy(&s, soundStruct, sizeof(SndSoundStruct));
  s.dataSize = lengthInBytes;
  [ab initWithFormat: &s data: dataPtr];

  return [ab autorelease];
}

- (long) insertIntoAudioBuffer: (SndAudioBuffer *) buff
		intoFrameRange: (NSRange) bufferFrameRange
	        samplesInRange: (NSRange) sndFrameRange
{
    void  *sndDataPtr = [self data] + sndFrameRange.location * SndFrameSize(soundStruct);
    double stretchFactor = [buff samplingRate] / [self samplingRate];

    //NSLog(@"bufferFrameRange [%ld, %ld] sndFrameRange [%ld,%ld]\n",
    //	  bufferFrameRange.location, bufferFrameRange.location + bufferFrameRange.length,
    //	  sndFrameRange.location, sndFrameRange.location + sndFrameRange.length);
    
    // Check if the number of frames to fill into the buffer will exceed the number of frames in the sound
    // remaining to be played (including when downsampling). If so, reduce the number to fill into the buffer,
    // pad the remainder of the buffer range with zeros. This will only occur at the end of a sound.

    if((bufferFrameRange.length / stretchFactor) > sndFrameRange.length) {
	long originalBufferFrameLength = bufferFrameRange.length;
	NSRange toZero;
	
	bufferFrameRange.length = sndFrameRange.length * stretchFactor;
	//NSLog(@"shortened buffer length to %ld\n", bufferFrameRange.length);
	toZero.location = bufferFrameRange.length;
	toZero.length = originalBufferFrameLength - bufferFrameRange.length;
	[buff zeroFrameRange: toZero];
    }
    
    if(![self hasSameFormatAsBuffer: buff]) { // If not the same, do a data conversion.
	// The number of frames returned as read could be more or less than bufferFrameRange.length if resampling occurs.
	long framesRead = [buff convertBytes: sndDataPtr
			      intoFrameRange: bufferFrameRange
			          fromFormat: [self dataFormat]
			            channels: [self channelCount]
			        samplingRate: [self samplingRate]];
	
	//NSLog(@"buffer to fill %@ mismatched to %@, converted, read %ld\n", buff, self, framesRead);
	return framesRead;  // framesRead depends on resampling.
    }
    else {
	// Matching sound buffer formats, so we can just do a copy.
	int buffFrameSize = [buff frameSizeInBytes];
	NSRange bufferByteRange = { bufferFrameRange.location * buffFrameSize, bufferFrameRange.length * buffFrameSize };
	
	// NSLog(@"channel count of sound = %d, of buffer = %d\n", soundStruct->channelCount, [buff channelCount]);
	[buff copyBytes: sndDataPtr intoRange: bufferByteRange format: soundStruct];
	return bufferFrameRange.length;
    }
}

- (long) fillAudioBuffer: (SndAudioBuffer *) buff
		toLength: (long) fillLength
          samplesInRange: (NSRange) readFromSndSample
{
    NSRange bufferRange;

    bufferRange.location = 0;
    bufferRange.length = fillLength; // TODO this may become [buff lengthInSamples] if we remove toLength: parameter.
    
    return [self insertIntoAudioBuffer: buff
			intoFrameRange: bufferRange
		        samplesInRange: readFromSndSample];
}

- (void) setUseVolumeWhenPlaying: (BOOL) yesOrNo
{
    useVolumeWhenPlaying = yesOrNo;
}

- (BOOL) useVolumeWhenPlaying
{
    return useVolumeWhenPlaying;
}

- (void) setUseBalanceWhenPlaying: (BOOL) yesOrNo
{
    useBalanceWhenPlaying = yesOrNo;
}

- (BOOL) useBalanceWhenPlaying
{
    return useBalanceWhenPlaying;
}

- (void) setLoopWhenPlaying: (BOOL) yesOrNo
{
    loopWhenPlaying = yesOrNo;
}

- (BOOL) loopWhenPlaying
{
    return loopWhenPlaying;
}

- (void) setLoopStartIndex: (long) newLoopStartIndex
{
    loopStartIndex = newLoopStartIndex;
}

- (long) loopStartIndex
{
    return loopStartIndex;
}

- (void) setLoopEndIndex: (long) newLoopEndIndex
{
    loopEndIndex = newLoopEndIndex;
}

- (long) loopEndIndex
{
    return loopEndIndex;
}

- (float) getAllChannelsVolume
{
    return allChannelsVolume;
}

- (BOOL) isPlaying
{
    // if any performances are currently playing, return YES.
    int performanceIndex;
    int performanceCount = [performancesArray count];

    for(performanceIndex = 0; performanceIndex < performanceCount; performanceIndex++) {
	if([[performancesArray objectAtIndex: performanceIndex] isPlaying])
	    return YES;
    }
    // 
    // performancesArrayLock
    return NO;
}

- setAllChannelsVolume: (float) newAllChannelsVolume
{
    // TODO Check to see if this sound is playing, if so, update the volume of the performance
    //[self isPlaying]
    // Can we hide this within [self performance] setAllChannelsVolume: 
    //[[[self performance] audioProcessorChain] postFader] setAmp
    // Regardless of the sound performance, update the priming sound value.
    allChannelsVolume = newAllChannelsVolume;
    return [self class];
}

- (float) balance
{
    return balance;
}

- setBalance: (float) newBalance
{
    // TODO Check to see if this sound is playing, if so, update the balance of the performance
    //[self isPlaying]
    // Regardless of the sound performance, update the priming sound value.
    balance = newBalance;
    return [self class];
}

@end
