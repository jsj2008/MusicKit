////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Defines a structure for holding sound describing parameters.
//    This is the replacement for SndSoundStruct which is now deprecated.
//    Since there is a lot of code using SndSoundStruct, the change is gradual.
//    SndFormat differs from SndSoundStruct such that it becomes a struct just holding
//    sample format data, removing the unused info, magic and troublesome dataLocation
//    (and the crufty arrangement of data following the struct itself) fields. This will
//    still make it easier to pass around formats of sound data than having to pass each
//    parameter.
//
//  Original Author: Leigh Smith, <leigh@leighsmith.com>
//
//  Copyright (c) 2003, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDFORMAT_H__
#define __SNDFORMAT_H__

#import <MKPerformSndMIDI/PerformSound.h>

/*!
  @typedef SndFormat
  @abstract Defines a structure for holding sound describing parameters, but no sample data itself.
  @discussion This is the replacement for SndSoundStruct which is now deprecated.
  @field dataFormat The data format code of enumerated type SndSampleFormat.
  @field frameCount The number of multichannel samples in the sound. Total data size = frameCount * channelCount * SndSampleWidth(dataFormat).
  @field channelCount The number of channels.
  @field samplingRate The sampling rate in Hertz. Fractional sampling rates are supported.
 */
typedef struct {
    SndSampleFormat dataFormat;
    long frameCount;
    int channelCount;
    double sampleRate;
} SndFormat;

#endif
