////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description: An object containing raw audio data, and doing audio 
//               operations on that data
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

#ifndef __SNDAUDIOBUFFER_H__
#define __SNDAUDIOBUFFER_H__

#import <Foundation/Foundation.h>
#import <MKPerformSndMIDI/PerformSound.h>
#import "Snd.h"
#import "SndFunctions.h"

/*!
  @class SndAudioBuffer
  @abstract   Audio Buffer
  @discussion A SndAudioBuffer represents sound data in memory. As distinct from a Snd class, it may hold small
	      chunks of sound data ready for signal processing or performance. Using classes such as SndAudioBufferQueue
              enables a fragmented arrangement of buffers across memory, typically for processing constraints. SndAudioBuffers
              are the closest SndKit match to the underlying audio hardware buffer. In addition to holding the sample data,
              SndAudioBuffer encapsulates sampling rate, number of channels and the format of the sample data.
*/
@interface SndAudioBuffer : NSObject
{
/*! @var byteCount  */
  unsigned int byteCount;
/*! @var maxByteCount  */
  unsigned int maxByteCount;
/*! @var samplingRate  */
  double samplingRate;
/*! @var dataFormat */
  int    dataFormat;
/*! @var channelCount  */
  int    channelCount;
/*! @var data */
  NSMutableData *data;
}

/*!
  @method     audioBufferWithFormat:duration:
  @abstract   Factory method
  @discussion
  @param      format
  @param      timeInSec
  @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndSoundStruct*) format duration: (double) timeInSec;

/*!
  @method     audioBufferWithFormat:channelCount:samplingRate:duration:
  @abstract   Factory method
  @discussion
  @param      dataFormat
  @param      chanCount
  @param      samRate
  @param      duration
  @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (int) dataFormat
           channelCount: (int) chanCount
           samplingRate: (double) samRate
               duration: (double) time;

/*!
    @method     audioBufferWithFormat:data:
    @abstract   Factory method
    @discussion The dataLength member of format MUST be set to the length of d (in bytes)!
    @param      format
    @param      d
    @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndSoundStruct*) format data: (void*) d;

/*!
    @method     audioBufferWrapperAroundSNDStreamBuffer:
    @abstract   Factory method
    @discussion
    @param      cBuff
    @result     An SndAudioBuffer
*/
+ audioBufferWrapperAroundSNDStreamBuffer: (SNDStreamBuffer*) cBuff;

/*!
    @method     audioBufferWithSndSeg:range:
    @abstract   Factory method
    @discussion
    @param      snd 
    @param      r
    @result     An SndAudioBuffer 
*/
+ audioBufferWithSndSeg: (Snd*) snd range: (NSRange) r;

/*!
  @method     initWithFormat:data:
  @abstract   Initialization method
  @discussion
  @param      f
  @param      d
  @result     self.
*/
- initWithFormat: (SndSoundStruct*) f data: (void*) d;

/*!
  @method     initWithBuffer:
  @abstract   Initialize a buffer with a matching format to the supplied buffer
  @discussion Creates a duplicated buffer (with a shallow copy, the data is referenced)
  @param      b is a SndAudioBuffer.
  @result     self.
*/
- initWithBuffer: (SndAudioBuffer*) b;
/*!
  @method     initWithBuffer:range:
  @abstract   Initialize a buffer with a matching format to the supplied buffer method
  @discussion
  @param      b
  @param      r
  @result     self.
*/
- initWithBuffer: (SndAudioBuffer*) b
           range: (NSRange) r;

/*!
  @method     initWithFormat:channelCount:samplingRate:duration:
  @abstract   Initialization method
  @discussion
  @param      dataFormat
  @param      channelCount
  @param      samplingRate
  @param      time
  @result     An SndAudioBuffer
*/
- initWithFormat: (int) dataFormat
    channelCount: (int) channelCount
    samplingRate: (double) samplingRate
        duration: (double) time;

/*!
  @method     mixWithBuffer:fromStart:toEnd:
  @abstract   Initialization method
  @discussion
  @param      buff
  @param      start
  @param      end
  @param      exp if TRUE, receiver is allowed to expand <i>buff</i> in place
                  if required to change format before mixing.
  @result     self.
*/
- mixWithBuffer: (SndAudioBuffer*) buff
      fromStart: (long) start
          toEnd: (long) end
      canExpand: (BOOL) exp;

/*!
  @method   mixWithBuffer:
  @abstract
  @discussion
  @param      buff
  @result     self.
*/
- mixWithBuffer: (SndAudioBuffer*) buff;

/*!
  @method     copy
  @abstract
  @discussion
  @result     A duplicate SndAudioBuffer with its own, identical data.
*/
- copy;

/*!
  @method     copyData:
  @abstract
  @discussion
  @param      ab
  @result     self.
*/
- copyData: (SndAudioBuffer*) ab;

/*!
  @method     copyBytes:count:format:
  @abstract   copies bytes from the char* array given
  @discussion grows the internal NSMutableData object as necessary
  @param      bytes the char* array to copy from
  @param      count the number of bytes to copy from the array
  @param      format pointer to a SndSoundStruct containing valid channelCount,
              samplingRate and dataFormat variables.
  @result     self.
*/
- copyBytes: (char*) bytes count:(unsigned int)count format: (SndSoundStruct *) f;

/*!
  @method     copyBytes:intoRange:format:
  @abstract   copies bytes from the char* array given into a sub region of the buffer.
  @discussion grows the internal NSMutableData object as necessary
  @param      bytes The char* array to copy from.
  @param      range The start location and number of bytes to copy from the array.
  @param      format pointer to a SndSoundStruct containing valid channelCount,
              samplingRate and dataFormat variables.
  @result     self.
 */
- copyBytes: (char*) bytes intoRange: (NSRange) range format: (SndSoundStruct *) f;

/*!
  @method     copyFromBuffer:intoRange:
  @abstract   Copies from the start of the given buffer into a sub region of the receiving buffer.
  @discussion Grows the internal NSMutableData object as necessary
  @param      fromBuffer The audio buffer to copy from.
  @param      range The start location and number of samples to copy to the receiving buffer.
  @result     self.
 */
- copyFromBuffer: (SndAudioBuffer *) sourceBuffer intoRange: (NSRange) rangeInSamples;

/*!
  @method     lengthInSamples
  @abstract
  @discussion
  @result     buffer length in sample frames
*/
- (long) lengthInSampleFrames;
/*!
  @method     setLengthInSampleFrames
  @abstract   Changes the length of the buffer to <I>newSampleFrameCount</I> sample frames.
*/
- setLengthInSampleFrames: (long) newSampleFrameCount;
/*!
  @method     lengthInBytes
  @abstract
  @discussion
  @result     buffer length in bytes
*/
- (long) lengthInBytes;

/*!
  @method     duration
  @abstract
  @discussion
  @result     Duration in seconds (as determined by format sampling rate)
*/
- (double) duration;

/*!
  @method     samplingRate
  @abstract
  @discussion
  @result     sampling rate
*/
- (double) samplingRate;
/*!
  @method     channelCount
  @abstract
  @discussion
  @result     Number of channels
*/
- (int) channelCount;

/*!
  @method     dataFormat
  @abstract
  @discussion
  @result     Data format identifier
*/
- (int) dataFormat;

/*!
  @method     bytes
  @abstract
  @discussion
  @result     pointer to NSData object contaiing the audio data
*/
- (void*) bytes;

/*!
  @method     hasSameFormatAsBuffer:
  @abstract   compares the data format and length of this buffer to a second buffer
  @param      buff The SndAudioBuffer to compare to.
  @result     YES if the buffers have the same format and length, NO if there are
              any differences in format between buffers.
*/
- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer*) buff;

/*!
    @method     zero
    @abstract   Sets data to zero
    @discussion
    @result     self
*/
- zero;

/*!
    @method     zeroForeignBuffer
    @abstract   Sets buffer data to zero, regardless of whether the buffer is owned by the SndAudioBuffer or not.
    @discussion Same as zero, but skips a buffer ownership test.
    @result     self
*/
- (void) zeroForeignBuffer;

/*!
    @method     frameSizeInBytes
    @abstract
    @discussion
    @result     Integer size of sample frame (channels * sample size in bytes)
*/
- (int) frameSizeInBytes;

/*!
    @method     description
    @abstract    
    @discussion 
    @result     Integer size of sample frame (channels * sample size in bytes)
*/
- (NSString*) description;


+ (void) resampleByLinearInterpolation: (SndAudioBuffer*) aBuffer
                                  dest: (SndAudioBuffer*) tempBuffer
                                factor: (double) deltaTime
                                offset: (double) offset;

- (void) findMin:(float*) pMin max:(float*) pMax;

@end

////////////////////////////////////////////////////////////////////////////////

@interface SndAudioBuffer(SampleConversion)

/*!
  @method convertToFormat:
  @abstract Converts the sample data to the given format.
  @discussion Only the format is changed, the number of channels and sampling rate are preserved.
  @param  sndFormatCode  An integer representing different sample data formats.
  @result Returns self if conversion was successful, nil if conversion was not possible, such as due to incompatible channel counts.
 */
- convertToFormat: (int) sndFormatCode;

/*!
  @method dataConvertedToFormat:
  @abstract Converts the sample data to the given format.
  @discussion Only the format is changed, the number of channels and sampling rate are preserved.
  @param  newDataFormat An integer representing different sample data formats.
  @result Returns an autoreleased NSData instance with the new sample data.
 */
- (NSMutableData *) dataConvertedToFormat: (int) newDataFormat;

/*!
  @method convertBytes:intoRange:fromFormat:channels:samplingRate:
  @abstract Converts from a data pointer described by the given data format, channel count and sampling rate to the current buffer format.
  @discussion Checks the range does not exceed the bounds of the buffer.
  @param fromDataPtr      A pointer to raw sample data.
  @param bufferByteRange  Indicates the region of the buffer which will be converted.
  @param fromDataFormat   An integer representing different sample data formats.
  @param fromChannelCount The old number of channels in the raw sample data.
  @param fromSamplingRate The old sampling rate in the raw sample data.
  @result Returns self if conversion was successful, nil if conversion was not possible, such as due to incompatible channel counts.
 */
- convertBytes: (void *) fromDataPtr
     intoRange: (NSRange) bufferByteRange
    fromFormat: (int) fromDataFormat
      channels: (int) fromChannelCount
  samplingRate: (double) fromSamplingRate;

/*!
  @method convertToFormat:channelCount:
  @abstract Converts the sample data to the given format and channel count.
  @discussion Reallocates sample data if necessary for channel count changes.
  @param toDataFormat   An integer representing different sample data formats.
  @param toChannelCount Number of channels for the new sound. If less than the current number, channels are averaged,
                        if more, channels are duplicated.
  @result Returns self if conversion was successful, nil if conversion was not possible, such as due to incompatible channel counts.
 */
- convertToFormat: (int) toDataFormat
     channelCount: (int) toChannelCount;

/*!
  @method convertToFormat:channelCount:samplingRate:useLargeFilter:interpolateFilter:useFastInterpolation:
  @abstract Converts the sample data to the given format, channel count and sampling rate.
  @discussion The parameter fields useLargeFilter: interpolateFilter:  and useFastInterpolation: control the
              particular resampling methods used.
  @param toDataFormat    An integer representing different sample data formats.
  @param toChannelCount
  @param toSampleRate
  @param largeFilter
  @param interpFilter
  @param fastInterpolation
  @result Returns self if conversion was successful, nil if conversion was not possible, such as due to incompatible channel counts.
 */
- convertToFormat: (int) toDataFormat
     channelCount: (int) toChannelCount
     samplingRate: (double) toSampleRate
   useLargeFilter: (BOOL) largeFilter
interpolateFilter: (BOOL) interpFilter
useFastInterpolation: (BOOL) fastInterpolation;

/*!
 @function SndConvertSound
 @abstract Convert from one sound struct format to another.
 @discussion Converts from one sound struct to another, where toSound defines the format the data is to be
             converted to and provides the location for the converted sound data.
 @param fromSound Defines the sound data to be converted.
 @param toSound Defines the format the data is to be converted to and provides the location
                for the converted sound data.
 @param allocate Allocate the memory to use for the resulting converted sound, freeing the toSound passed in.
 @param largeFilter Use a large filter for better quality resampling.
 @param interpFilter Use interpolated filter for conversion for better quality resampling.
 @param fast Do the conversion fast, without filtering, low quality resampling.
 @result Returns various SND_ERR constants, or SND_ERR_NONE if the conversion worked.
 */
SNDKIT_API int SndConvertSound(const SndSoundStruct *fromSound,
				    SndSoundStruct **toSound,
				BOOL allocate,
				BOOL largeFilter,
				BOOL interpFilter,
				BOOL fast);

/*!
  @function SndChangeSampleType
  @abstract Does an conversion from one sample type to another.
  @discussion If fromPtr and toPtr are the same it does the conversion inplace.
           The buffer must be long enough to hold the increased number
           of bytes if the conversion calls for it. Data must be in host
           endian order. Currently knows about ulaw, char, short, int,
           float and double data types, represented by the data format
           parameters (prefixed SND_FORMAT_).
  @param fromPtr Pointer to the byte buffer to read data from.
  @param toPtr Pointer to the byte buffer to write data to.
  @param dfFrom The data format to convert from.
  @param dfTo The data format to convert to.
  @param outCount Length in samples of the original buffer, counting number of channels, that is duration in samples * number of channels.
  @result Returns error code.
 */
SNDKIT_API int SndChangeSampleType (void *fromPtr, void *toPtr, int dfFrom, int dfTo, unsigned int outCount);

/*!
  @function SndChangeSampleRate
  @abstract Resamples an input buffer into an output buffer, effectively
            changing the sampling rate.
  @discussion Internal function which uses the "resample" routine to resample
           an input buffer into an output buffer. Various boolean flags
           control the speed and accuracy of the conversion. The output is
           always 16 bit, but the input routine can read ulaw, char, short,
           int, float and double types, of any number of channels. The old
           and new sample rates are determined by fromSound>samplingRate
           and toSound>samplingRate, respectively. Data must be in host
           endian order.
  @param fromSound Holds header information about the input sound, and
                  optionally the input sound data itself (see also
		    "alternativeInput" below). The fromSound may hold fragmented
                  SndSoundStruct data.
  @param toSound Holds header information about the target sound
  @param factor Ratio of new_sample_rate / old_sample_rate
  @param largeFilter TRUE means use 65tap FIR filter, with higher quality.
  @param interpFilter When not in "fast" mode, controls whether or not the
                     filter coefficients are interpolated (disregarded in fast mode).
  @param fast if TRUE, uses a fast, noninterpolating resample routine.
  @param alternativeInput If nonnull, points to a contiguous buffer of input
                         data to be used instead of any data pointed to by
                         fromSound.
                         If null, the "fromSound" structure hold the
                         input data.
  @param outPtr pointer to a buffer big enough to hold the output data
  @result void
 */
SNDKIT_API void SndChangeSampleRate(const SndSoundStruct *fromSound,
				    SndSoundStruct *toSound,
				    BOOL largeFilter, BOOL interpFilter,
				    BOOL fast,
				    void *alternativeInput,
				    short *outPtr);

/*!
  @function    SndChannelIncrease
  @abstract   Increases the number of channels in the buffer, in place.
  @discussion Endian-agnostic. Only sensible conversions are accepted (1
 	      to anything, 2 to 4, 8 etc, 4 to 8, 16 etc). Buffer must have
              enough memory allocated to hold the increased data.
  @param inPtr
  @param outPtr
  @param frames
  @param oldNumChannels
  @param newNumChannels
  @param df   data format of buffer
  @result does not return error code.
 */

SNDKIT_API void SndChannelIncrease (void *inPtr,
				    void *outPtr,
				    int frames,
				    int oldNumChannels,
				    int newNumChannels,
				    int df );


/*!
  @function SndChannelDecrease
  @abstract Decreases the number of channels in the buffer, in place.
  @discussion Because samples are read and averaged, must be hostendian. Only
           exact divisors are supported (anything to 1, even numbers to even numbers)
  @param inPtr
  @param outPtr
  @param frames
  @param oldNumChannels
  @param newNumChannels
  @param df data format of buffer
  @result does not return error code.
*/

SNDKIT_API void SndChannelDecrease (void *inPtr,
				    void *outPtr,
				    int frames,
				    int oldNumChannels,
				    int newNumChannels,
				    int df );

@end

#endif
