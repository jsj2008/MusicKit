////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and non-
//  commercial purposes so long as the author attribution and copyright messages
//  remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndStreamManager.h"
#import "SndAudioFader.h"
#ifndef M_PI
#define M_PI            3.14159265358979323846  /* pi */
#endif

static id ENVCLASS=nil;

static SEL bpBeforeOrEqualSel;
static SEL bpAfterSel;
static SEL flagsForBpSel;
static SEL yForBpSel;
static SEL yForXSel;
static SEL xForBpSel;

@interface SndAudioFader (SKPrivate)

- (BOOL) _rampEnvelope: (id <SndEnveloping, NSObject>) theEnv
                  from: (float) startRampLevel
                    to: (float) endRampLevel
             startTime: (double) startRampTime
               endTime: (double) endRampTime;
- (void) _setStaticPointInEnvelope: (id <SndEnveloping, NSObject>) theEnv
                              yVal: (float) yVal
                              xVal: (double) atTime;
@end


@implementation SndAudioFader

/* forward decl */
static float lookupEnvForX(SndAudioFader *saf, id <SndEnveloping, NSObject> anEnvelope, double theX);

+ (void)setEnvelopeClass:(id)aClass
{
  ENVCLASS = aClass;
}

+ (id) envelopeClass
{
  return ENVCLASS;
}

- (void) setEnvelopeClass: (id) aClass
{
  envClass = aClass;
  bpBeforeOrEqual = (BpBeforeOrEqualIMP) [envClass instanceMethodForSelector: bpBeforeOrEqualSel];
  bpAfter = (BpAfterIMP) [envClass instanceMethodForSelector: bpAfterSel];
  flagsForBp = (FlagsForBpIMP) [envClass instanceMethodForSelector: flagsForBpSel];
  yForBp = (YForBpIMP) [envClass instanceMethodForSelector: yForBpSel];
  yForX = (YForXIMP) [envClass instanceMethodForSelector: yForXSel];
  xForBp = (XForBpIMP) [envClass instanceMethodForSelector: xForBpSel];
}

- (id) envelopeClass
{
  return envClass;
}

+ (void) initialize
{
  if (self == [SndAudioFader class]) {
    [SndAudioFader setVersion:1];
  }
  ENVCLASS = [SndEnvelope class]; /* default envelope */

  bpBeforeOrEqualSel = @selector(breakpointIndexBeforeOrEqualToX:);
  bpAfterSel = @selector(breakpointIndexAfterX:);
  flagsForBpSel = @selector(lookupFlagsForBreakpoint:);
  yForBpSel = @selector(lookupYForBreakpoint:);
  yForXSel = @selector(lookupYForX:);
  xForBpSel = @selector(lookupXForBreakpoint:);
}

// initWithParamCount:name: is the designated initializer for SndAudioProcessor.
- initWithParamCount: (const int) paramCount name: (NSString *) faderName
{
    self = [super initWithParamCount: faderNumParams name: @"Fader"];
    if (self) {
	envelopesLock  = [NSLock new];
	balanceEnvLock = [NSLock new];
	ampEnvLock     = [NSLock new];
	ampEnv         = nil;
	staticAmp      = 1;
	balanceEnv     = nil;
	staticBalance  = 0;
	[self setEnvelopeClass: ENVCLASS];
	uee = NULL;
    }
    return self;
}

/*
 * "instantaneous" getting and setting; applies from start of buffer
 */
- setBalance: (float) balance clearingEnvelope: (BOOL) clear
{
  double nowTime;
  if (clear) {
    if (balanceEnv) {
      [balanceEnvLock lock];
      [balanceEnv release];
      balanceEnv = nil;
      [balanceEnvLock unlock];
    }
    staticBalance = balance;
    return self;
  }
  /* if there's an envelope there, keep it and insert new value */
  if (balanceEnv) {
    nowTime = [(SndStreamManager *) [SndStreamManager defaultStreamManager] nowTime];
    [self setBalance: balance atTime: nowTime];
  }
  staticBalance = balance;
  return self;
}

- (float) getBalance
{
  double nowTime;
  float yVal;
  if (balanceEnv == nil) {
    return staticBalance;
  }
  nowTime = [(SndStreamManager *)[SndStreamManager defaultStreamManager] nowTime];
  [balanceEnvLock lock];
  yVal = lookupEnvForX(self, balanceEnv, nowTime);
  [balanceEnvLock unlock];
  return yVal;
}

- setAmp: (float) amp clearingEnvelope: (BOOL) clear
{
  double nowTime;
  if (clear) {
    [ampEnvLock lock];
    if (ampEnv) {
      [ampEnv release];
      ampEnv = nil;
    }
    [ampEnvLock unlock];
    staticAmp = amp;
    return self;
  }
  /* if there's an envelope there, keep it and insert new value */
  if (ampEnv) {
    nowTime = [(SndStreamManager *)[SndStreamManager defaultStreamManager] nowTime];
    [self setAmp: amp atTime: nowTime];
  }
  staticAmp = amp;
  return self;
}

- (float) getAmp
{
  double nowTime;
  float yVal;
  if (!ampEnv) {
    return staticAmp;
  }
  nowTime = [(SndStreamManager *)[SndStreamManager defaultStreamManager] nowTime];
  [ampEnvLock lock];
  yVal = lookupEnvForX(self, ampEnv, nowTime);
  [ampEnvLock unlock];
  return yVal;
}

BOOL middleOfMovement(SndAudioFader *saf, double xVal, id <SndEnveloping,NSObject> anEnvelope)
{
  int prevBreakpoint = saf->bpBeforeOrEqual(anEnvelope, bpBeforeOrEqualSel, xVal);
  if (prevBreakpoint == BP_NOT_FOUND) {
    return NO;
  }
  if (saf->flagsForBp(anEnvelope, flagsForBpSel, prevBreakpoint) &
      SND_FADER_ATTACH_RAMP_RIGHT) {
    return YES;
  }
  return NO;
}

/* Official "future movement" API - moves faders about at arbitrary times in
* the future.
*/
- (BOOL) _rampEnvelope: (id <SndEnveloping, NSObject>) theEnv
                  from: (float) startRampLevel
                    to: (float) endRampLevel
             startTime: (double) startRampTime
               endTime: (double) endRampTime
{
  /* Need to watch for the following problems:
  * 1 locking
  * 2 sticking this movement in the middle of another movement, or spanning
  *   several other breakpoints
  *   - if our new ramp spans any breakpoints, then they will be deleted.
  *     However, any ramp leading into or out of our new ramp will be preserved
  *     by calculating the point where they would have bisected our new ramp,
  *     and inserting a new end point/start point as necessary.
  */
  BOOL dissectsAtStart, dissectsAtEnd;
  int newStartIndex;

  dissectsAtStart = middleOfMovement(self, startRampTime, theEnv);
  dissectsAtEnd = middleOfMovement(self, endRampTime, theEnv);

  if (dissectsAtStart || dissectsAtEnd) {
    float   endPrecedingRampLevel    = 0.0f;
    float   startSucceedingRampLevel = 0.0f;
    int i;
    // do we span any breakpoints, which we will need to delete?
    int index1 = [theEnv breakpointIndexBeforeOrEqualToX: startRampTime];
    int index2 = [theEnv breakpointIndexAfterX: endRampTime];
    // If index1 == BP_NOT_FOUND, that means that there must be an end dissection,
    // and bp[0] is definitely to be deleted
    // If index2 == BP_NOT_FOUND, that means that our new end point lies beyond the
    // rightmost bp.
    if (index2 == BP_NOT_FOUND) index2 = [theEnv breakpointCount];

    // calculate a new end point and/or start point for the enclosing
    // envelope(s). The flags for these will be SND_FADER_ATTACH_RAMP_LEFT
    // and SND_FADER_ATTACH_RAMP_RIGHT, respectively.

    if (dissectsAtStart) {
      endPrecedingRampLevel = lookupEnvForX(self, theEnv, startRampTime);
    }
    if (dissectsAtEnd) {
      startSucceedingRampLevel = lookupEnvForX(self, theEnv, endRampTime);
    }

    // do the deletion, backwards
    for (i = index2 - 1; i > index1; i--) {
      [theEnv removeBreakpoint: i];
    }
    // stick in our new preceding/succeeding ramps, if necessary
    if (dissectsAtStart) {
      // we know at which bp this should be inserted
      [theEnv insertXValue: startRampTime
                    yValue: endPrecedingRampLevel
                     flags: SND_FADER_ATTACH_RAMP_LEFT
              atBreakpoint: index1 + 1];
    }
    if (dissectsAtEnd) {
      [theEnv insertXValue: endRampTime
                    yValue: endPrecedingRampLevel
                     flags: SND_FADER_ATTACH_RAMP_RIGHT
              atBreakpoint: index1 + dissectsAtStart ? 2 : 1];
    }
  }
  // finally, put in new ramp.
  // Note that if there are already breakpoints at the same X value,
  // the new bp is inserted after the last one.
  newStartIndex = [theEnv insertXValue: startRampTime
                                yValue: startRampLevel
                                 flags: SND_FADER_ATTACH_RAMP_RIGHT];
  //    NSLog(@"newStartIndex %d, startramptime %f, startRampLevel %f\n",
  //         newStartIndex,startRampTime,startRampLevel);
  [theEnv insertXValue: endRampTime
                yValue: endRampLevel
                 flags: SND_FADER_ATTACH_RAMP_LEFT
          atBreakpoint: newStartIndex + 1];

  return YES;
}

- (BOOL) rampAmpFrom: (float) startRampLevel
                  to: (float) endRampLevel
           startTime: (double) startRampTime
             endTime: (double) endRampTime
{
  BOOL ret;
  [ampEnvLock lock];
  if (!ampEnv) {
    ampEnv = [[envClass alloc] init];
  }
  ret = [self _rampEnvelope: ampEnv
                       from: startRampLevel
                         to: endRampLevel
                  startTime: startRampTime
                    endTime: endRampTime];
  [ampEnvLock unlock];
  return ret;
}

- (BOOL) rampBalanceFrom: (float) startRampLevel
                      to: (float) endRampLevel
               startTime: (double) startRampTime
                 endTime: (double) endRampTime;
{
  BOOL ret;
  [balanceEnvLock lock];
  if (!balanceEnv) {
    balanceEnv = [[envClass alloc] init];
  }
  ret = [self _rampEnvelope: balanceEnv
                       from: startRampLevel
                         to: endRampLevel
                  startTime: startRampTime
                    endTime: endRampTime];
  [balanceEnvLock unlock];
  return ret;
}

/*
 * "future" getting and setting; transparently reads and writes
 * from/to the envelope object(s)
 */
- (void) _setStaticPointInEnvelope: (id <SndEnveloping, NSObject>) theEnv
                              yVal: (float) yVal
                              xVal: (double) atTime
{
  BOOL isRamping;
  /* if there's a following ramp end, delete it.
  * also give the new point an end-of-ramp status
  */
  isRamping = middleOfMovement(self, atTime, theEnv);
  if (!isRamping) {
    [theEnv insertXValue:atTime yValue: yVal flags: 0];
  }
  else {
    int endBp = [theEnv breakpointIndexAfterX: atTime];
    if (endBp == BP_NOT_FOUND) {
      /* A ramp was started but not finished. Just set the
      * new bp, and change the status of the previous bp
      * to static (flag 0)
      */
      int precedingBpIndex =
      [theEnv breakpointIndexBeforeOrEqualToX: atTime];
      double newX  = [theEnv lookupXForBreakpoint: precedingBpIndex];
      float  newY  = [theEnv lookupYForBreakpoint: precedingBpIndex];
      int    flags = [theEnv lookupFlagsForBreakpoint: precedingBpIndex];
      flags = flags & SND_FADER_ATTACH_RAMP_LEFT;
      [theEnv replaceXValue: newX
                     yValue: newY
                      flags: flags
               atBreakpoint: precedingBpIndex];
      [theEnv insertXValue: atTime yValue: yVal flags: 0];
    }
    else {
      /* We need to create a new end-of-ramp along the same trajectory
      * as was there before, then switch immediately to the new static
      * bp
      */
      float newEndY = [theEnv lookupYForX:atTime];
      [theEnv removeBreakpoint:endBp];
      [theEnv insertXValue: atTime
                    yValue: yVal
                     flags: 0
              atBreakpoint: endBp];
      [theEnv insertXValue: atTime
                    yValue: newEndY
                     flags: SND_FADER_ATTACH_RAMP_LEFT
              atBreakpoint: endBp];

    }
  }
}

- setBalance: (float) balance atTime: (double) atTime
{
  [balanceEnvLock lock];
  if (!balanceEnv) {
    balanceEnv = [[envClass alloc] init];
  }

  [self _setStaticPointInEnvelope:balanceEnv
                             yVal:balance
                             xVal:atTime];
  [balanceEnvLock unlock];
  return self;
}

- (float) getBalanceAtTime: (double) atTime
{
  double yVal;
  if (!balanceEnv) return staticBalance;
  [balanceEnvLock lock];
  yVal = lookupEnvForX(self,balanceEnv, atTime);
  [balanceEnvLock unlock];
  return yVal;
}

- setAmp: (float) amp atTime: (double) atTime
{
  [ampEnvLock lock];
  if (!ampEnv) {
    ampEnv = [[envClass alloc] init];
  }
  [self _setStaticPointInEnvelope:ampEnv
                             yVal:amp
                             xVal:atTime];
  [ampEnvLock unlock];
  return self;
}

- (float) getAmpAtTime: (double) atTime
{
  double yVal;
  if (!ampEnv) return staticAmp;
  [ampEnvLock lock];
  yVal = lookupEnvForX(self, ampEnv, atTime);
  [ampEnvLock unlock];
  return yVal;
}

- (void) dealloc
{
    if (uee)
	free(uee);
    [envelopesLock release];
    envelopesLock = nil;
    [ampEnvLock release];
    ampEnvLock = nil;
    [balanceEnvLock release];
    balanceEnvLock = nil;
    [ampEnv release];
    [balanceEnv release];
    [super dealloc];
}

- (float) paramValue: (const int) paramIndex
{
    float r = 0.0f;
    
    switch (paramIndex) {
    case faderAmp:
	r = [self getAmp];
	break;
    case faderBalance:
	r = [self getBalance];
	break;
    }
    return r;
}

- (NSString *) paramName: (const int) paramIndex
{
    NSString *paramName = nil;
    
    switch (paramIndex) {
    case faderAmp:
	paramName = @"Amplitude";
	break;
    case faderBalance:
	paramName = @"Balance";
	break;
    }
    return paramName;  
}

- (void) setParam: (const int) paramIndex toValue: (const float) v
{
    switch (paramIndex) {
    case faderAmp:   
	[self setAmp: v > 1.0 ? 1.0 : (v < 0.0 ? 0.0 : v) clearingEnvelope: NO];
	break;
    case faderBalance: 
	[self setBalance: v > 1.0 ? 1.0 : (v < -1.0 ? -1.0 : v) clearingEnvelope: NO];
	break;
    }
}

static float lookupEnvForX(SndAudioFader *saf, id <SndEnveloping, NSObject> anEnvelope, double theX)
{
  //    int prevBreakpoint = [anEnvelope breakpointIndexBeforeOrEqualToX:theX];
  int prevBreakpoint = saf->bpBeforeOrEqual(anEnvelope,bpBeforeOrEqualSel,theX);
  if (prevBreakpoint == BP_NOT_FOUND) {
    return 0;
  }
  /* it was a static breakpoint: take last y val and don't interpolate */
  //    if (!([anEnvelope lookupFlagsForBreakpoint:prevBreakpoint] & SND_FADER_ATTACH_RAMP_RIGHT))
  if (!(saf->flagsForBp(anEnvelope,flagsForBpSel,prevBreakpoint) &
        SND_FADER_ATTACH_RAMP_RIGHT)) {
    //        return [anEnvelope lookupYForBreakpoint:prevBreakpoint];
    return saf->yForBp(anEnvelope,yForBpSel,prevBreakpoint);
  }
  /* let the envelope object do its interpolation */
  //    return [anEnvelope lookupYForX:theX];
  return saf->yForX(anEnvelope,yForXSel,theX);

}

static inline int processBalance(int xPtr,
                            SndUnifiedEnvelopeEntry *uee,
                            double tempXVal,
                            float tempAmpY,
                            float tempBalanceY,
                            int tempAmpFlags,
                            int tempBalanceFlags)
{
  /* this will insert an additional uee entry iff the balance crossed over the 0
  * line during the last segment. This is because the balance curve is not linear
  * and the subsegments (on either side of the 0 crossing) need to be processed
  * differently.
  * Returns an incremented xPtr if a new point has been added.
  */
  float tempBalanceL,tempBalanceR;
  double lastXVal,xOverPoint;
  SndUnifiedEnvelopeEntry *oldUee = uee - 1;
  float lastBalanceY = oldUee->balanceY;
  if (tempBalanceY >= 0) {
    tempBalanceR = 1;
    tempBalanceL = 1 - tempBalanceY;
  }
  else {
    tempBalanceR = 1 + tempBalanceY;
    tempBalanceL = 1;
  }
  if ((lastBalanceY < 0 && tempBalanceY > 0) ||
      (lastBalanceY > 0 && tempBalanceY < 0)) {
    float proportion;
    /* insert new point here */
    lastXVal = oldUee->xVal;
    proportion = (float)-lastBalanceY/(float)(tempBalanceY - lastBalanceY);
    xOverPoint = lastXVal + proportion * (tempXVal - lastXVal);
    uee->xVal = xOverPoint;
    uee->balanceY = oldUee->balanceY + proportion * (tempBalanceY - oldUee->balanceY);
    uee->ampFlags = (oldUee->ampFlags & SND_FADER_ATTACH_RAMP_RIGHT) ?
      SND_FADER_ATTACH_RAMP_RIGHT | SND_FADER_ATTACH_RAMP_LEFT : 0;
    uee->balanceFlags = (oldUee->balanceFlags & SND_FADER_ATTACH_RAMP_RIGHT) ?
      SND_FADER_ATTACH_RAMP_RIGHT | SND_FADER_ATTACH_RAMP_LEFT : 0;
    uee->ampY = oldUee->ampY + proportion * (tempAmpY - oldUee->ampY);
    uee->balanceL = 1;
    uee->balanceR = 1;
    xPtr++;
    uee++;
  }
  uee->xVal = tempXVal;
  uee->ampFlags = tempAmpFlags;
  uee->balanceFlags = tempBalanceFlags;
  uee->ampY = tempAmpY;
  uee->balanceR = tempBalanceR;
  uee->balanceL = tempBalanceL;
  uee->balanceY = tempBalanceY; /* don't need for final scaling, but for this calc */
  return xPtr;
}

- (void) staticMixIntoBuffer: (SndAudioBuffer *) inB
{
    float *samples = (float *) [inB bytes];
    int channelCount = [inB channelCount];
    long lengthInSamples = [inB lengthInSampleFrames] * channelCount;
    long sampleIndex;

    if (staticBalance == 0) {
        for (sampleIndex = 0; sampleIndex < lengthInSamples; sampleIndex += channelCount) {
            int channelIndex;
            
            for(channelIndex = 0; channelIndex < channelCount; channelIndex++)
                samples[sampleIndex + channelIndex] *= staticAmp;
        }
    }
    else {
        double leftAmpD  = (staticBalance <= 0) ? staticAmp : staticAmp * (1 - staticBalance);
        double rightAmpD = (staticBalance >= 0) ? staticAmp : staticAmp * (1 + staticBalance);
        // Left channel in 0th element, Right channel in 1st element.
        // [anAudioBuffer stereoChannels]
        short stereoChannels[2] = { 0, 1 };

        // TODO Currently this balance routine generates the balance between two nominated stereo channels.
        // We should extend this so that multiple channels such as L/R surround channels are also balanced.
        // This can get tricky with centre channels, rear and LFE channels, so we need to determine speaker placement.
        for (sampleIndex = 0; sampleIndex < lengthInSamples; sampleIndex += channelCount) {
            samples[sampleIndex + stereoChannels[0]] *= leftAmpD;
            samples[sampleIndex + stereoChannels[1]] *= rightAmpD;
        }
    }
}

//- (void) envelopeMix
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB
                        outputBuffer: (SndAudioBuffer *) outB
{
    double nowTime;

    /* bypass if possible */
    if (ampEnv == nil && staticAmp == 1 && balanceEnv == nil && staticBalance == 0) {
        return NO;
    }

    nowTime = [[self audioProcessorChain] nowTime];

    [envelopesLock lock];

    if (ampEnv == nil && balanceEnv == nil) {
        [self staticMixIntoBuffer: inB];
    }
    else {  // Mix using envelopes.
        if ([inB dataFormat] == SND_FORMAT_FLOAT && [inB channelCount] == 2) {
            long lengthInFrames  = [inB lengthInSampleFrames];
            double x = nowTime;
            double maxX = x + [inB duration];
            int xPtr = 0;
            double ampX = x;
            double nextAmpX, nextBalanceX;
            int nextAmpIndx, nextBalanceIndx;
            int countAmp;
            int countBalance;
            long i;
            int j;
            int nextAmpFlags = 0, nextBalanceFlags = 0;
            int currentAmpFlags = 0, currentBalanceFlags = 0;
        
            double tempXVal;
            int tempBalanceFlags;
            int tempAmpFlags;
            float tempAmpY;
            float tempBalanceY;

            if (balanceEnv == nil && ampEnv == nil) {
                [envelopesLock unlock];
                return NO;
            }
            [ampEnvLock lock];
            [balanceEnvLock lock];
        
            countAmp = ampEnv ? [ampEnv breakpointCount] : 0;
            countBalance = balanceEnv ? [balanceEnv breakpointCount] : 0;
        
            if (!uee) 
                uee = calloc(256, sizeof(SndUnifiedEnvelopeEntry));
            if (!uee)
                [[NSException exceptionWithName: NSMallocException
                                         reason: @"SndAudioFader envelope"
                                       userInfo: nil] raise];
        
            /* prime the loop */
            nextAmpIndx = ampEnv ? [ampEnv breakpointIndexAfterX: nowTime] : BP_NOT_FOUND;
            nextBalanceIndx = balanceEnv ? [balanceEnv breakpointIndexAfterX: nowTime] : BP_NOT_FOUND;
            if (nextAmpIndx != BP_NOT_FOUND) {
                // nextAmpX = [ampEnv lookupXForBreakpoint:nextAmpIndx];
                // nextAmpFlags = [ampEnv lookupFlagsForBreakpoint:nextAmpIndx];
                nextAmpX = xForBp(ampEnv, xForBpSel, nextAmpIndx);
                nextAmpFlags = flagsForBp(ampEnv, flagsForBpSel, nextAmpIndx);
            }
            else {
                nextAmpX = maxX + 1;
            }
            if (nextBalanceIndx != BP_NOT_FOUND) {
                // nextBalanceX = [balanceEnv lookupXForBreakpoint:nextBalanceIndx];
                // nextBalanceFlags = [balanceEnv lookupFlagsForBreakpoint:nextBalanceIndx];
                nextBalanceX = xForBp(balanceEnv, xForBpSel, nextBalanceIndx);
                nextBalanceFlags = flagsForBp(balanceEnv, flagsForBpSel, nextBalanceIndx);
            }
            else {
                nextBalanceX = maxX + 1;
            }

            /* last chance to bypass: if the first amp and balance envelope points
             * are beyond the end of the buffer, we eject.
             */
            if ((nextBalanceIndx == 0 && (nextBalanceX > maxX)) && (nextAmpIndx == 0 && (nextAmpX > maxX))) {
                [balanceEnvLock unlock];
                [ampEnvLock unlock];
                [envelopesLock unlock];
                return NO;
            }
            /* always include start of buffer as 1st bp*/
            /* grab some values pertaining to start of envelope */
            // primeStartOfEnvelope(uee)
            {
                // int b4AmpIndx = [ampEnv breakpointIndexBeforeOrEqualToX:nowTime];
                // int b4BalanceIndx = [balanceEnv breakpointIndexBeforeOrEqualToX:nowTime];
                int b4AmpIndx = ampEnv ? bpBeforeOrEqual(ampEnv, bpBeforeOrEqualSel, nowTime) : BP_NOT_FOUND;
                int b4BalanceIndx = balanceEnv ? bpBeforeOrEqual(balanceEnv, bpBeforeOrEqualSel, nowTime) : BP_NOT_FOUND;

                if (b4AmpIndx != BP_NOT_FOUND) {
                    // uee[xPtr].ampFlags = [ampEnv lookupFlagsForBreakpoint:b4AmpIndx];
                    uee[xPtr].ampFlags = flagsForBp(ampEnv, flagsForBpSel, b4AmpIndx);
                    uee[xPtr].ampY = lookupEnvForX(self, ampEnv, ampX);
                }
                else {
                    uee[xPtr].ampFlags = 0;
                    uee[xPtr].ampY = staticAmp;
                }
                if (b4BalanceIndx != BP_NOT_FOUND) {
                    // uee[xPtr].balanceFlags = [balanceEnv lookupFlagsForBreakpoint: b4BalanceIndx];
                    uee[xPtr].balanceFlags = flagsForBp(balanceEnv, flagsForBpSel, b4BalanceIndx);
                    uee[xPtr].balanceY = lookupEnvForX(self, balanceEnv, ampX);
                }
                else {
                    uee[xPtr].balanceFlags = 0;
                    uee[xPtr].balanceY = staticBalance;
                }
                if (uee[xPtr].balanceY >= 0) {
                    uee[xPtr].balanceR = 1;
                    uee[xPtr].balanceL = 1 - uee[xPtr].balanceY;
                }
                else {
                    uee[xPtr].balanceR = 1 + uee[xPtr].balanceY;
                    uee[xPtr].balanceL = 1;
                }
            }
            uee[xPtr].xVal = ampX;
            xPtr++;
        
            /* do the loop to get all relevant x values within our relevant
             * time period
             */
            while ((nextAmpX < maxX) || (nextBalanceX < maxX)) {
                if (nextAmpX <= nextBalanceX) {
                    tempXVal = nextAmpX;
                    tempBalanceFlags = 0;
                    tempAmpFlags = nextAmpFlags;
                    //[ampEnv lookupYForBreakpoint:nextAmpIndx];
                    tempAmpY = ampEnv ?
                        yForBp(ampEnv,yForBpSel,nextAmpIndx) : staticAmp;
                    tempBalanceY = balanceEnv ?
                        lookupEnvForX(self, balanceEnv, nextAmpX) : staticBalance;
            
                    /* since we're slotting in an unexpected bp as far as the balance env
                        * is concerned, make sure we tell the new bp to ramp on both sides,
                        * if it needs to
                        */
                    if ((currentBalanceFlags & SND_FADER_ATTACH_RAMP_RIGHT) ||
                        (nextBalanceFlags & SND_FADER_ATTACH_RAMP_LEFT)) {
                        tempBalanceFlags = SND_FADER_ATTACH_RAMP_RIGHT | SND_FADER_ATTACH_RAMP_LEFT;
                    }
                    else {
                        tempBalanceFlags = 0;
                    }
                    xPtr = processBalance( xPtr, uee+xPtr,
                                            tempXVal, tempAmpY,
                                            tempBalanceY,
                                            tempAmpFlags,
                                            tempBalanceFlags);
                    xPtr++;
                    nextAmpIndx++;
                    if (nextAmpIndx < countAmp) {
                        //                    nextAmpX = [ampEnv lookupXForBreakpoint:nextAmpIndx];
                        nextAmpX = xForBp(ampEnv,xForBpSel,nextAmpIndx);
                        currentAmpFlags = nextAmpFlags;
                        //                    nextAmpFlags = [ampEnv lookupFlagsForBreakpoint:nextAmpIndx];
                        nextAmpFlags = flagsForBp(ampEnv,flagsForBpSel,nextAmpIndx);
                    }
                    else {
                        nextAmpX = maxX + 1;
                        currentAmpFlags = nextAmpFlags;
                        nextAmpFlags = 0;
                    }
                }
                else {
                    tempXVal = nextBalanceX;
                    tempBalanceFlags = nextBalanceFlags;
                    tempAmpFlags = 0;
                    //[balanceEnv lookupYForBreakpoint:nextBalanceIndx]
                    tempAmpY = ampEnv ?
                        lookupEnvForX(self, ampEnv,nextBalanceX) : staticAmp;
                    tempBalanceY = balanceEnv ?
                        yForBp(balanceEnv,yForBpSel,nextBalanceIndx) : staticBalance;
            
                    /* since we're slotting in an unexpected bp as far as the amp env
                        * is concerned, make sure we tell the new bp to ramp on both sides,
                        * if it needs to
                        */
                    if ((currentAmpFlags & SND_FADER_ATTACH_RAMP_RIGHT) ||
                        (nextAmpFlags & SND_FADER_ATTACH_RAMP_LEFT)) {
                        tempAmpFlags = SND_FADER_ATTACH_RAMP_RIGHT | SND_FADER_ATTACH_RAMP_LEFT;
                    }
                    else {
                        tempAmpFlags = 0;
                    }
                    xPtr = processBalance( xPtr, uee+xPtr,
                                            tempXVal, tempAmpY,
                                            tempBalanceY,
                                            tempAmpFlags,
                                            tempBalanceFlags);
                    xPtr++;
                    nextBalanceIndx++;
                    if ((nextBalanceIndx != BP_NOT_FOUND) &&
                        (nextBalanceIndx < countBalance)) {
                        //                    nextBalanceX = [balanceEnv lookupXForBreakpoint:nextBalanceIndx];
                        nextBalanceX = xForBp(balanceEnv,xForBpSel,nextBalanceIndx);
                        currentBalanceFlags = nextBalanceFlags;
                        //                    nextBalanceFlags = [balanceEnv lookupFlagsForBreakpoint:nextBalanceIndx];
                        nextBalanceFlags = flagsForBp(balanceEnv,flagsForBpSel,nextBalanceIndx);
                    }
                    else {
                        nextBalanceX = maxX + 1;
                        currentBalanceFlags = nextBalanceFlags;
                        nextBalanceFlags = 0;
                    }
                }
            } /* end while */
            /* always include end of buffer as last bp */
            tempXVal = maxX;
            tempAmpFlags = nextAmpFlags;
            tempBalanceFlags = nextBalanceFlags;
            tempAmpY = ampEnv ? lookupEnvForX(self, ampEnv, maxX) : staticAmp;
            tempBalanceY = balanceEnv ? lookupEnvForX(self, balanceEnv, maxX) : staticBalance;
            xPtr = processBalance( xPtr, uee+xPtr,
                                    tempXVal, tempAmpY,
                                    tempBalanceY,
                                    tempAmpFlags,
                                    tempBalanceFlags);
            xPtr++;
        
            /* finished with ampEnv and balanceEnv now */
            [balanceEnvLock unlock];
            [ampEnvLock unlock];
        
#if 0
            /* log 'em */
            //NSLog(@"time diff: %f at %f\n",GSTimeNow()-t,nowTime);
            NSLog(@"number of points: %d\n",xPtr);
            for (i = 0 ; i < xPtr ; i++) {
                NSLog(@"xVal %f ampFlag %d, ampY %f, balanceFlag %d, balanceY %f, balL %f, balR %f\n",
                uee[i].xVal,
                uee[i].ampFlags,
                uee[i].ampY,
                uee[i].balanceFlags,
                uee[i].balanceY,
                uee[i].balanceL,
                uee[i].balanceR );
            }
#endif

            /* use 'em */
            //  For R channel, scaler will go from rStartAmp to rEndAmp (at x1 the scaling
            //  is rStartAmp; at x2, rEndAmp). Given iterator i (0 to x2-x1) the scaling
            //  at each sample is (rStartAmp + i/(x2-x1) * (rEndAmp-rStartAmp))
            // define as method -amplitudeScalingOfBuffer: inB unifiedEnvelopeEntry: uee
            { 
                /* new block so I can define variables */
                SndUnifiedEnvelopeEntry *startUee;
                SndUnifiedEnvelopeEntry *endUee;
                float *inD  = (float*) [inB bytes];
                int currSample,lastSample;
                int timeDiff;
                float lDiff,rDiff;
                float lEndAmp, rEndAmp, lStartAmp, rStartAmp;
                float lScaler, rScaler;
                float ampMult, balanceMultL, balanceMultR;
                double sr = [inB samplingRate];
                float proportion;
        
                //NSLog(@"("before  : %f (nowTime %f) %f %f %f %f\n",GSTimeNow() - t, nowTime,inD[0],inD[1],inD[1022],inD[1023]);
                for (i = 0 ; i < xPtr - 1 ; i++) {
                    startUee = &(uee[i]);
                    endUee = &(uee[i+1]);
        
                    /* there are some 0-length sections created when envelopes
                    * collide
                    */
                    if (startUee->xVal == endUee->xVal) {
                        continue;
                    }
        
                    currSample = (startUee->xVal - nowTime) * sr; //frames
                    lastSample = (endUee->xVal - nowTime) * sr;
                    //easy way of ensuring we don't scale the same sample twice...
                    if (i < xPtr - 2) {
                        lastSample--;
                    }
        
                    currSample *= 2;
                    if (lastSample >= lengthInFrames) {
                        lastSample = lengthInFrames - 1;
                    }
                    lastSample *= 2;
                    timeDiff = lastSample - currSample;
        
        
                    ampMult = ((startUee->ampFlags & SND_FADER_ATTACH_RAMP_RIGHT) ?
                                endUee->ampY : startUee->ampY);
                    //            balanceMult = ((startUee->balanceFlags & SND_FADER_ATTACH_RAMP_RIGHT) ?
                    //                    endUee->balanceY : startUee->balanceY);
                    if (startUee->balanceFlags & SND_FADER_ATTACH_RAMP_RIGHT) {
                        balanceMultL = endUee->balanceL;
                        balanceMultR = endUee->balanceR;
                    }
                    else {
                        balanceMultL = startUee->balanceL;
                        balanceMultR = startUee->balanceR;
                    }
        
                    //            lStartAmp = startUee->ampY * (startUee->balanceY - 45.0) / -90.0;
                    //            rStartAmp = startUee->ampY * (startUee->balanceY + 45.0) / 90.0;
                    //            lEndAmp = ampMult * (balanceMult - 45.0) / -90.0;
                    //            rEndAmp = ampMult * (balanceMult + 45.0) / 90.0;
                    lStartAmp = startUee->ampY * startUee->balanceL;
                    rStartAmp = startUee->ampY * startUee->balanceR;
                    lEndAmp = ampMult * balanceMultL;
                    rEndAmp = ampMult * balanceMultR;
        
                    lDiff = lEndAmp - lStartAmp; /* how much we have to scale l from start to end */
                    rDiff = rEndAmp - rStartAmp;
                    //NSLog(@"curr sample %d last sample %d nowTime %f lstart %f lend %f rstart %f rend %f\n",
                    //    currSample,lastSample,nowTime,lStartAmp,lEndAmp,rStartAmp,rEndAmp);
        
                    if (timeDiff == 0.0F) {
                        inD[currSample] *= lStartAmp;
                        inD[currSample + 1] *= rStartAmp;
                    }
                    else if ((lDiff != 0.0F) && (rDiff != 0.0F)) {
                        for (j = currSample; j <= lastSample; j += 2) {
                            proportion = (float) j / (float) timeDiff;
                            lScaler = lStartAmp + lDiff * proportion;
                            rScaler = rStartAmp + rDiff * proportion;
                            inD[j] *= lScaler;
                            inD[j+1] *= rScaler;
                        }
                    }
                    else if (lDiff == 0.0F) {
                        for (j = currSample; j <= lastSample; j += 2) {
                            proportion = (float) j / (float) timeDiff;
                            rScaler = rStartAmp + rDiff * proportion;
                            inD[j] *= lStartAmp;
                            inD[j+1] *= rScaler;
                        }
                    }
                    else if (rDiff == 0.0F) {
                        for (j = currSample; j <= lastSample; j += 2) {
                            proportion = (float) j / (float) timeDiff;
                            lScaler = lStartAmp + lDiff * proportion;
                            inD[j] *= lScaler;
                            inD[j + 1] *= rStartAmp;
                        }
                    }
                    else {
                        for (j = currSample; j <= lastSample; j += 2) {
                            inD[j] *= lStartAmp;
                            inD[j + 1] *= rStartAmp;
                        }
                    }
                }
                // NSLog(@"tot time: %f (nowTime %f) %f %f %f %f\n",GSTimeNow() - t, nowTime,inD[0],inD[1],inD[1022],inD[1023]);
            } /*end block */
        }
        else {
            NSLog(@"SndAudioFader::processReplacingInputBuffer:outputBuffer: Bad buffer format (not stereo, float): %d channels, %@\n",
                [inB channelCount], SndFormatName([inB dataFormat], NO));
        }
    }

    [envelopesLock unlock];

    return NO; /* we've written the results in place */
}

@end

