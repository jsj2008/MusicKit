////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
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

#ifndef __SNDKIT_SNDAUDIOPROCESSORTONEGENERATOR_H__
#define __SNDKIT_SNDAUDIOPROCESSORTONEGENERATOR_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

/*!
 @brief SndToneGenParam Parameter keys
 @constant toneGen_kFreq  Frequency 
 @constant toneGen_kAmp  Amplitude
 @constant toneGen_kPhase  Phase offset
 @constant toneGen_kWave  Waveform 
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
@brief A tone generator processor

  To come
*/
@interface SndAudioProcessorToneGenerator : SndAudioProcessor
{
/*! freq This is a dodgey one at the moment - range [0,1] logarithmically maps to [55,880] Hz*/
  float freq;
/*! amp  Yuckky linear scale [0,1] for the moment - be nice to have in dB */
  float amp;
/*! phase Phase offset */
  float phase;
/*! waveform  (not currently used). */
  int   waveform;
  
@private
/*! t */
  double t;
}

@end

//////////////////////////////////////////////////////////////////////////////

#endif
