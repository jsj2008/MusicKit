//////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorToneGenerator.h
//  SndKit
//
//  Created by SKoT McDonald on Mon Dec 31 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORTONEGENERATOR_H__
#define __SNDKIT_SNDAUDIOPROCESSORTONEGENERATOR_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

/*!
 @enum SndToneGenParam
 @abstract Parameter keys
 @constant toneGen_kFreq       Frequency 
 @constant toneGen_kAmp        Amplitude
 @constant toneGen_kPhase      Phase offset
 @constant toneGen_kWave       Waveform 
 @constant toneGen_kNumParams  Number of parameters
 */
enum {
  toneGen_kFreq      = 0,
  toneGen_kAmp       = 1,
  toneGen_kPhase     = 2,
  toneGen_kWave      = 3,
  toneGen_kNumParams = 4
};

@class SndAudioBuffer;

//////////////////////////////////////////////////////////////////////////////

/*!
@class SndAudioProcessorToneGenerator
@abstract A tone generator processor
@discussion To come
*/
@interface SndAudioProcessorToneGenerator : SndAudioProcessor {
/*! @var   freq This is a dodgey one at the moment - range [0,1] logarithmically maps to [55,880] Hz*/
  float freq;
/*! @var   amp  Yuckky linear scale [0,1] for the moment - be nice to have in dB */
  float amp;
/*! @var   phase Phase offset */
  float phase;
/*! @var   waveform  (not currently used)*/
  int   waveform;
  
@private
/*! @var   t */
  double t;
}

@end

//////////////////////////////////////////////////////////////////////////////

#endif