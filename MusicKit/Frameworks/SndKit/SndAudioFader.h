////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDAUDIOFADER_H__
#define __SNDAUDIOFADER_H__

#import <Foundation/Foundation.h>

#import "SndEnvelope.h"
#import "SndAudioProcessor.h"
@class SndStreamManager;
@class SndStreamMixer;
@class SndAudioProcessor;
@class SndAudioBuffer;

#define SND_FADER_ATTACH_RAMP_RIGHT 1
#define SND_FADER_ATTACH_RAMP_LEFT  2

/* this value limits the number of envelope points that can be held
 * in the unified (amp + balance) envelope. Unless providing for almost
 * sample-level enveloping, the specified figure will be more than enough.
 */
#define MAX_ENV_POINTS_PER_BUFFER 256

typedef struct _UEE {
    double          xVal;
    int             ampFlags;
    int             balanceFlags;
    float           ampY;
    float           balanceY;
    float           balanceL;
    float           balanceR;
} SndUnifiedEnvelopeEntry;

/* Squeeze the last drop of performance out of this class by caching IMPs.
 * See also +initialize and -init for the initialization of selectors, which
 * are static "class" variables.
 * To use, cache the following:
 *  bpBeforeOrEqual = [ENVCLASS instanceMethodForSelector:bpBeforeOrAfterSel];
 * then use like this:
 *  y = bpbeforeOrEqual(myEnv,bpBeforeOrAfterSel,myX);
 */
typedef int (*BpBeforeOrEqualIMP)(id, SEL, double);
typedef int (*BpAfterIMP)(id, SEL, double);
typedef int (*FlagsForBpIMP)(id, SEL, int);
typedef float (*YForBpIMP)(id, SEL, int);
typedef float (*YForXIMP)(id, SEL, double);
typedef float (*XForBpIMP)(id, SEL, int);

/*!
@class SndAudioFader
@abstract An object providing basic amplitude and balance controls on
                incoming audio buffers. "Fader" movements can be scheduled
                for arbitrary times in the future.
    @discussion

<P>
SndAudioFader objects can be inserted into SndAudioProcessorChains at arbitrary
points. In addition, all SndAudioProcessorChains have a SndAudioFader which is run
after any other user defined processors.</P>
<P>
Because both SndStreamMixer and SndStreamClient have processor chains, both the
overall output and the individual clients (respectively) can have faders.</P>
<P>
SndAudioFader is built to be as efficient as possible. If it does not have to do
any processing on the incoming stream, it does not.</P>
<P>
SndAudioFader keeps track of amplitude and/or balance settings in two ways: via a
static setting, and via an envelope system for scheduling future movements. This
process is largely transparent to the user.</P>
<P>
For computational ease, interpolation between breakpoints in the scheduled amplitude
fader movements is linear. For stereo balance, the situation is similar, as the
balance calculations are <b>not</b> adjusted for equal power. This is because balance
is a different art to pan, where a mono sound is panned into a stereo sound field.
The balance calculations mimic the traditional analog balance implementation with
a twin gang potentiometer. That is, at every balance position left of centre, the
left channel is on full power, and the right channel loses power linearly, proportional
to the distance left of centre. The same applies to positions right of centre (the
right channel is on full power, and the left channel drops off). One advantage of
doing it this way is that at the centre position, both channels are at full power.
Most panning implementations scale to root 2 (0.707) at the centre position.</P>
<P>
One limitation of the faders is that the "postfader" copies (in SndStreamMixer and
SndStreamClient) are only created once the audio streams have started to play. Thus
the user cannot pre-load the faders with future movements. To pre-load faders before
a stream starts to play, create a SndAudioFader programmatically, send it the fader
movements, then insert it into the SndAudioProcessorChain later.</P>
*/

@interface SndAudioFader : SndAudioProcessor
{
  /*! @var envClass Class object used in initialising new envelopes*/  
  id     envClass; 
  /*! @var ampEnv */  
  id     <SndEnveloping, NSObject> ampEnv;
  /*! @var staticAmp */  
  float  staticAmp;
  /*! @var balanceEnv */  
  id     <SndEnveloping,NSObject> balanceEnv;
  /*! @var staticBalance */  
  float  staticBalance;

  /*! @var uee Unified Envelope Entry */  
  SndUnifiedEnvelopeEntry *uee;
  
  /*! @var envelopesLock Locks changes to both the envelope objects (?) */
  NSLock *envelopesLock;
  /*! @var balanceEnvLock */  
  NSLock *balanceEnvLock;
  /*! @var ampEnvLock */
  NSLock *ampEnvLock;

@public
  /*! @var bpBeforeOrEqual */
  BpBeforeOrEqualIMP  bpBeforeOrEqual;
  /*! @var bpAfter */
  BpAfterIMP          bpAfter;
  /*! @var flagsForBp */
  FlagsForBpIMP       flagsForBp;
  /*! @var yForBp */
  YForBpIMP           yForBp;
  /*! @var yForX */
  YForXIMP            yForX;
  /*! @var xForBp */
  XForBpIMP           xForBp;
}

/*!
    @method setEnvelopeClass:
    @abstract Sets the class object used for the internal amplitude and balance envelopes.
    @discussion If you wish to develop your own high performance envelopes, perhaps with improved
    interpolation, ensure that they conform to the SndEnveloping protocol, then call this
    method with [MyNewEnvelopeClass class] before doing any audio output for the first time.
    All future envelope objects created by SndAudioFader will use the new class.
    @param aClass The alternative class to set.
    @result void
*/
+ (void)setEnvelopeClass:(id)aClass;

/*!
    @method envelopeClass
    @abstract Returns the class of the internal envelope objects.
    @discussion Defaults to SndEnvelope. Note that this method does not check the class of its
    envelopes directly, but returns the stored class object used for creating future envelopes.
    @result <SndEnveloping> (a class conforming to the SndEnveloping protocol)
*/
+ (id)envelopeClass;

/*!
    @method setEnvelopeClass:
    @abstract Sets the class object used for the internal amplitude and balance envelopes.
    @discussion If you wish to develop your own high performance envelopes, perhaps with improved
    interpolation, ensure that they conform to the SndEnveloping protocol, then call this
    method with [MyNewEnvelopeClass class] before doing any audio output for the first time.
    Note that sending this message to an instance of SndAudioFader will affect ONLY this instance.
    See also +(void)setEnvelopeClass:(id)aClass
    @param aClass The alternative class to set.
    @result void
*/
- (void)setEnvelopeClass:(id)aClass;

/*!
    @method envelopeClass
    @abstract Returns the class of the internal envelope objects.
    @discussion Defaults to SndEnvelope. Note that this method does not check the class of its
    envelopes directly, but returns the stored class object used for creating future envelopes.
    @result <SndEnveloping> (a class conforming to the SndEnveloping protocol)
*/
- (id)envelopeClass;

/*
 * "instantaneous" getting and setting; applies from start of buffer
 */

/*!
    @method setBalance:clearingEnvelope:
    @abstract Sets the instantaneous balance value between stereo (2) channels, optionally clearing future scheduled events
    @discussion The balance value takes effect from the next buffer to pass through the processor
    chain.
    The parameter <i>newBalance</i> must be a floating-point number between -1.0 (left) 0.0 (centre) and 1.0 (right).
    If successful, returns <b>self</b>; otherwise returns <b>nil</b>.
    For greater than 2 channel sound, balance must be defined as between
    two lateral planes of outputs. So a 5.1 surround system should map balance
    between the combined left front and left surround speaker vs. the right front
    and right surround speaker. This needs further description as to how stereo panning
    should map onto other multichannel formats and in the most general sense, i.e even is left,
    odd is right.
    @param balance is a float (-1.0 to +1.0)
    @param clear If TRUE, discard any future scheduled balance events.
    @result Returns self.
*/
- setBalance: (float) newBalance clearingEnvelope: (BOOL) clear;

/*!
    @method getBalance
    @abstract Returns the balance value as of the start of the currently running, or next buffer.
    @discussion Returns the position between stereo channels as a floating-point
                number between -1.0 (left) and 1.0 (right).
    @result float (usually -1.0 to +1.0)
*/
- (float) getBalance;

/*!
    @method setAmp:clearingEnvelope:
    @abstract Sets the instantaneous amplitude value, optionally clearing future scheduled events
    @discussion The amplitude value takes effect from the next buffer to pass through the processor
    chain.
    @param amp A floating point value normally between 0.0 (minimum, silence) and +1.0 (maximum, full volume) inclusive.
               This parameter is the scaling factor for all channels. Negative values will invert the audio stream.
               There is no checking done for overload.
    @param clear If TRUE, discard any future scheduled amp events.
    @result self
*/
- setAmp: (float) amp clearingEnvelope:(BOOL)clear;

/*!
    @method getAmp
    @abstract Returns the amplitude value of all channels as of the start of the currently running, or next buffer.
    @result float (usually 0.0 to +1.0)
*/
- (float) getAmp;

/*
 * "future" getting and setting; transparently reads and writes
 * from/to the envelope object(s)
 */
/*!
    @method setBalance:atTime:
    @abstract Sets the balance value at the given future time
    @discussion The balance value is scheduled for the given time. If the specified time bisects
    an already scheduled ramp, the first part of the old ramp is maintained at its existing
    trajectory until the time of the new point, then the new balance point is inserted.
    Subsequent ramps are unaffected.
    @param balance (-1.0 to +1.0)
    @param atTime (double) the time at which to insert the new balance value
    @result self
*/
- setBalance:(float)balance atTime:(double)atTime;

/*!
    @method getBalanceAtTime:
    @abstract Returns the scheduled balance value for the given time
    @discussion If the time given bisects a scheduled ramp, the value is linearly interpolated.
    @param atTime (double) the time for which to return the balance value
    @result float (usually -1.0 to +1.0)
*/
- (float)getBalanceAtTime:(double)atTime;

/*!
    @method setAmp:atTime:
    @abstract Sets the amp value at the given future time
    @discussion The amp value is scheduled for the given time. If the specified time bisects
    an already scheduled ramp, the first part of the old ramp is maintained at its existing
    trajectory until the time of the new point, then the new amp point is inserted.
    Subsequent ramps are unaffected.
    @param amp any valid amplitude multiplier (usually 0.0 to 1.0)
    @param atTime (double) the time at which to insert the new amp value
    @result self
*/
- setAmp:(float)amp atTime:(double)atTime;

/*!
    @method getAmpAtTime:
    @abstract Returns the scheduled amp value for the given time
    @discussion If the given time bisects a scheduled ramp, the value is linearly interpolated.
    @param atTime (double) the time for which to return the amp value
    @result float any valid amplitude multiplier (usually 0.0 to 1.0)
*/
- (float)getAmpAtTime:(double)atTime;

/*!
    @method rampAmpFrom:to:startTime:endTime:
    @abstract Creates an amplitude ramp for a given time in the future
    @discussion The amp value is scheduled for the given time. If the start time
    of the new ramp bisects an already scheduled ramp, the first part of the old
    ramp is maintained at its existing trajectory until the time of the onset of
    the new ramp, then the new ramp is inserted. Subsequent ramps are unaffected.
    @param startRampLevel the level at the start of the ramp
    @param endRampLevel the level at the end of the ramp
    @param startRampTime (double) the time at which to start the new ramp
    @param endRampTime (double) the time at which to end the new ramp
    @result self
*/
- (BOOL) rampAmpFrom:(float)startRampLevel
                  to:(float)endRampLevel
           startTime:(double)startRampTime
             endTime:(double)endRampTime;

/*!
    @method rampBalanceFrom:to:startTime:endTime:
    @abstract Creates a balance ramp for a given time in the future
    @discussion The balance value is scheduled for the given time. If the start
    time of the new ramp bisects an already scheduled ramp, the first part of
    the old ramp is maintained at its existing trajectory until the time of the
    onset of the new ramp, then the new ramp is inserted. Subsequent ramps are
    unaffected.
    @param startRampLevel the balance at the start of the ramp
    @param endRampLevel the balance at the end of the ramp
    @param startRampTime (double) the time at which to start the new ramp
    @param endRampTime (double) the time at which to end the new ramp
    @result self
*/
- (BOOL) rampBalanceFrom:(float)startRampLevel
                      to:(float)endRampLevel
               startTime:(double)startRampTime
                 endTime:(double)endRampTime;

- (int) paramCount;
- (float) paramValue: (const int) index;
- (NSString*) paramName: (const int) index;
- setParam: (const int) index toValue: (const float) v;

/*!
    @method processReplacingInputBuffer:outputBuffer:
    @abstract Processes the input buffer according to the amplitude and balance settings. 
    @discussion This method currently only works with stereo float buffers. Not to be called directly. This method is called by
    SndAudioProcessorChain with buffers destined for audio output.
    @param inB the audio buffer with input to the processor
    @param endB unused
    @result Always returns NO since SndAudioFader processes audio in place, in inB.
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB
                        outputBuffer: (SndAudioBuffer *) outB;

@end

#endif
