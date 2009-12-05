/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    (See discussion below)

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2005, The MusicKit Project.
*/
/*!
  @class Fm2pnvi
  @ingroup FrequencyModulationSynthesis
  @brief Like <b>Fm2pvi</b>, but with an additional noise modulator.

<b>Fm2pnvi</b> is a parallel-modulator frequency modulation SynthPatch, with an interpolating-oscillator as a carrier and a noise source modulating the frequency of the two wavetable modulators.  It provides for envelopes on amplitude, frequency, and a separate envelope on each modulator's FM index, as well as an envvelope on the noise source.  It also supports vibrato.   Although it does not inherit from <b>Fm2pvi</b>, it implements the same parameters, plus some of its own. 

<img src="http://www.musickit.org/Frameworks/MKSynthPatches/Images/FM2pnvi.png"> 

When using this SynthPatch in an interactive real-time context, such as playing from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the SynthPatch.

<h2>Parameter Interpretation</h2>

In addition to the parameters described in <b>Fm2pvi.rtfd</b>, the following parameters are supported:

<b>breathSensitivity</b> - Controls how much affect the breath controller has.  Default is 0.5.

<b>controlChange</b> -  MIDI breath controller (controller 2) attenuates the output of  the noise modulator.  The value is obtained from companion parameter, controlVal.  The range is 0:127 and the default is 127, indicating no attenuation.  The effect of this parameter depends on the parameter breathSensitivity.

<b>controlVal</b> - See controlChange

<b>noiseAmp</b> - Amplitude of noise modulator.  If a noise amplitude envelope is provided, this is the amplitude of the noise when the envelope is 1.  noiseAmp1 is a synonym for the parameter noiseAmp.  Default is 0.007.

<b>noiseAmpEnv</b> - Noise amplitude envelope.  Default is a constant value of 1.0.

<b>noiseAmp0</b> - Noise amplitude when noise envelope is at 0.0.  noiseAmp is the value when the noise envelope is at 1.0.  Default is 0.0.

<b>noiseAmpAtt</b> - Time of attack portion of noise envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.

<b>noiseAmpRel</b> - Time of release portion of noise envelope in seconds.  If this parameter is not present, the times in the envelope are used verbatim.
*/
#ifndef __MK_Fm2pnvi_H___
#define __MK_Fm2pnvi_H___

#import <MusicKit/MKSynthPatch.h>

@interface Fm2pnvi:MKSynthPatch
{
  double amp0, amp1, ampAtt, ampRel, freq0, freq1, freqAtt, freqRel,
         bearing, phase, portamento, svibAmp0, svibAmp1, rvibAmp,
         svibFreq0, svibFreq1, bright, cRatio,
         m1Ratio, m1Ind0, m1Ind1, m1IndAtt, m1IndRel, m1Phase,
         m2Ratio, m2Ind0, m2Ind1, m2IndAtt, m2IndRel, m2Phase,
         noise0, noise1, noiseAtt, noiseRel,
         velocitySensitivity, breathSensitivity,
         balanceSensitivity, panSensitivity, afterTouchSensitivity, 
         pitchbendSensitivity;
  id ampEnv, freqEnv, m1IndEnv, m2IndEnv, noiseEnv,
     waveform, m1Waveform, m2Waveform;
  int wavelen, volume, velocity, pan, modulation, breath, aftertouch, 
      balance, pitchbend;
  void *_ugNums;
}

/*!
  @param aNote is an id.
  @return Returns an id.
  @brief Returns a template.

  A non-zero for <b>svibAmp</b> and <b>rvibAmp</b> determines
  whether vibrato resources are allocated. 
*/
+patchTemplateFor: (MKNote *) aNote;
   
/*!
  @param aNote is an id.
  @return Returns an id.
  @brief <i>aNote</i> is assumed to be a noteOn or noteDur.

  This method triggers (or retriggers) the MKNote's envelopes, if any.  If this is a new phrase, all instance variables are set to default values, then the values are read from the MKNote.  
*/
-noteOnSelf: (MKNote *) aNote;
 
/*!
  @param aNote is an id.
  @return Returns an id.
  @brief <i>aNote</i> is assumed to be a noteUpdate and the receiver is assumed to be currently playing a MKNote.

  Sets parameters as specified in <i>aNote.</i>
*/
-noteUpdateSelf: (MKNote *) aNote;

/*!
  @param aNote is an id.
  @return Returns a double.
  @brief <i>aNote</i> is assumed to be a noteOff.

  This method causes the MKNote's envelopes (if any) to begin its release portion and returns the time for the envelopes to finish.  Also sets any parameters present in <i>aNote.</i>
*/
-(double)noteOffSelf: (MKNote *) aNote;
 
/*!
  @return Returns an id.
  @brief Resest instance variables to default values.

  
*/
-noteEndSelf;
 

@end

#endif
