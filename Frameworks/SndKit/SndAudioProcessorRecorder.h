////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    See the headerdoc below.
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

#ifndef __SNDKIT_SNDAUDIOPROCESSORRECORDER_H__
#define __SNDKIT_SNDAUDIOPROCESSORRECORDER_H__

/* We #include this file regardless of the setting of
   HAVE_CONFIG_H so that other applications compiling against this
   header don't have to define it. If you are seeing errors for
   SndKitConfig.h not found when compiling the MusicKit, you haven't
   run ./configure 
*/
#import "SndKitConfig.h"

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

#if HAVE_LIBSNDFILE
# import <sndfile.h>
#else
#define SNDFILE void
#endif

@class SndAudioBuffer;
@class SndAudioBufferQueue;

/*!
 @enum SndRecorderParam
 @brief Parameter keys
 @constant recorder_StartTriggerThreshold  Start trigger threshold
 @constant recorder_RecordFile  Record filename
 @constant recorder_NumParams  Number of parameters
*/
enum SndRecorderParam {
    recorder_StartTriggerThreshold = 0,
    recorder_RecordFile            = 1,
    recorder_NumParams             = 2
};

//////////////////////////////////////////////////////////////////////////////

/*!
  @class SndAudioProcessorRecorder
  @brief Records the FX audio stream to disk.
  
  A threshold can be set to prevent silence being recorded prior to the sound. An automatic shutoff
  after a specifiable period of silence is also possible.
*/
@interface SndAudioProcessorRecorder : SndAudioProcessor {

@protected
    /*! A queue of buffers copied from those received by processReplacingInputBuffer: ready for writing. */
    SndAudioBufferQueue *writingQueue;
    /*! The format of the data to be stored in the file. */
    SndFormat fileFormat;
    /*! Indicates if recording is currently active. */
    BOOL isRecording;
    /*! Holds the file handle used in writing. */
    NSFileHandle *writingFileHandle;
    /*! Number of sample frames written */
    unsigned long framesRecorded;  
    /*! The libsndfile handle referring to the open file. NULL if not open. */
    SNDFILE *recordFile;
    /*! Full pathname of the file being or about to be written. */
    NSString *recordFileName;
    /*! Indicates if a minimum threshold or time trigger has passed and recording has begun. */
    BOOL startedRecording;
    /*! A normalised absolute value threshold to begin the recording of sound. */
    float startTriggerThreshold;
    /*! A boolean variable to indicate that recording should stop and the file should be closed. */
    BOOL stopSignal;
}

/*!
  @brief   Returns whether the receiver is currently recording.
  @return  YES if currently recording.
*/
- (BOOL) isRecording;

/*!
  @brief Sets the buffer used for recording.
  @return YES if able to prepare correctly, NO if there was a problem.
 */
- (BOOL) prepareToRecordForDuration: (double) recordDuration;

/*!
  @brief YES if recording started ok.
  @return YES if recording started ok.
*/
- (BOOL) startRecording;

/*!
  @brief Sets up recording of the file in the given format.
  
  This method is not normally called, use startRecordingToFile:withDataFormat:channelCount:samplingRate:
  instead. This method, setUpRecordFile:withFormat: is defined here in order to facilitate overriding
  in subclasses.
  @return Returns YES if able to open the file for writing, NO if there is an error.
 */
- (BOOL) setUpRecordFile: (NSString *) filename
	      withFormat: (SndFormat) format;

/*!
  @brief   Begins recording to the given format in the given format.
  @return  Returns YES if able to open the file for writing, NO if there is an error.
*/
- (BOOL) startRecordingToFile: (NSString*) filename
               withDataFormat: (SndSampleFormat) dataFormat
                 channelCount: (int) chanChan
                 samplingRate: (int) samRate;

/*!
  @brief Stops the recording of the stream to file.
  @return Returns self.
*/
- stopRecording;

/*!
  @brief TODO remove this, redundant, always wait until the queue clears.
  @return Returns self.
*/
- stopRecordingWait: (BOOL) wait;

/*!
  @brief Returns the number of frames recorded.
  @return The number of frames recorded.
*/
- (long) framesRecorded;

/*!
  @brief Sets the linear amplitude the stream must rise above before recording begins.
*/
- (void) setStartTriggerThreshold: (float) f;

- copyWithZone: (NSZone *) zone;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
