////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Heavily inspired by Steinberg's VST effects plugins for the moment
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

#import <MKPerformSndMIDI/SndStruct.h>
#import "SndFunctions.h"
#import "SndAudioBuffer.h"
#import "SndAudioProcessorRecorder.h"

////////////////////////////////////////////////////////////////////////////////
// Debug defines
////////////////////////////////////////////////////////////////////////////////

#define SNDAUDIOPROCRECORDER_DEBUG 0

@implementation SndAudioProcessorRecorder

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super initWithParamCount: recorder_kNumParams name: @"Recorder"];
  fStartTriggerThreshold = 0.002f;
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (recordBuffer != nil)
    [recordBuffer release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// isRecording
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isRecording
{
  return isRecording;
}

////////////////////////////////////////////////////////////////////////////////
// setRecordBuffer:
////////////////////////////////////////////////////////////////////////////////

- setRecordBuffer: (SndAudioBuffer*) buffer
{
  if (recordBuffer != nil)
    [recordBuffer release];
  recordBuffer = [buffer retain];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// bytesRecorded
////////////////////////////////////////////////////////////////////////////////

- (long) bytesRecorded
{
  return bytesRecorded;
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer:outputBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB;
{
#if SNDAUDIOPROCRECORDER_DEBUG > 1
  fprintf(stderr,"SndAudioProcessor::processReplacing: Entering...\n");
#endif
  if (stopSignal) {
#if SNDAUDIOPROCRECORDER_DEBUG > 1
    fprintf(stderr,"SndAudioProcessor::processReplacing: Finished recording BBB\n");        
#endif    
    if (bytesRecorded == 0 && position == 0)
      return FALSE;
  }
  {
    float *recData             = (float*) [recordBuffer bytes];
    float *inputData           = (float*) [inB bytes]; 
    long inBuffLengthInBytes  = [inB lengthInBytes];
    long recBuffLengthInBytes = [recordBuffer lengthInBytes];
    long remainder            = 0;
    long length               = 0, i;
    
    if (bStartTrigger) { // whoop! haven't started recording - look thru buffer
      long inBuffLengthInSams   = [inB lengthInSampleFrames];
      float *finB = (float*) [inB bytes];
      long skip = [inB channelCount];
      
      for (i = skip ; i < inBuffLengthInSams; i += skip) {
        if (fabs(finB[i]) > fStartTriggerThreshold) {
          bStartTrigger = FALSE;
          inputData           += (i-skip);
          inBuffLengthInBytes -= (i-skip);
          break;
        }
      }
    }
    
    if (!bStartTrigger) { // do NOT make this an 'else' with the above 'if'!
    // work out how much of the incoming buffer we can dump in the
    // record buffer...
      if (inBuffLengthInBytes + position > recBuffLengthInBytes) {
        remainder = (inBuffLengthInBytes + position) - recBuffLengthInBytes;
        length    = recBuffLengthInBytes - position;
      }
      else {
        length = inBuffLengthInBytes;
      }
      // transfer the incoming data...
      memcpy(((void*)recData) + position, inputData, length);
      position += length;    
      
      // have we filled a record buffer?
      if (position == recBuffLengthInBytes) {      
    
        if (recordFile != NULL) { // we are streaming to a file, and need to write to disk!
          [self streamToDiskData: recData length: recBuffLengthInBytes];
#if SNDAUDIOPROCRECORDER_DEBUG
          fprintf(stderr,"SndAudioProcessor::processReplacing: Processing... (pos: %li / %li  length: %li inlength: %li)\n",position,recBuffLengthInBytes,bytesRecorded,[inB lengthInBytes]);
#endif
        }
        else {
          bytesRecorded += length;
          isRecording = FALSE;
        }
        position = 0;
      }        
      if (remainder) {
#if SNDAUDIOPROCRECORDER_DEBUG
        fprintf(stderr,"SndAudioProcessor::processReplacing: memcpy... (position: %li length: %li remainder: %li recData: %p inputData:%p inLength:%li)\n",
                position, length, remainder,recData,inputData,[inB lengthInBytes]);
#endif
        memcpy(recData, ((void*)inputData) + length, remainder);
        position += remainder;
      }    
    
      if (stopSignal) { // If so, shut down stuff.
        if (recordFile != NULL) {
          if (position > 0)  // flush out partial record buffer to disk
            [self streamToDiskData: recData length: position];
        
          [self closeRecordFile];
#if SNDAUDIOPROCRECORDER_DEBUG  
        fprintf(stderr,"SndAudioProcessor::processReplacing: closed record file\n");
#endif
        }      
      }
    }
  } // end of isRecording
#if SNDAUDIOPROCRECORDER_DEBUG > 1
  fprintf(stderr,"SndAudioProcessor::processReplacing: Leaving...\n");
#endif
  return FALSE;
}

////////////////////////////////////////////////////////////////////////////////
// prepareToRecordForDuration:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) prepareToRecordForDuration: (double) time
                     withDataFormat: (int) dataFormat
                       channelCount: (int) chanChan
                       samplingRate: (int) samRate
{
  BOOL r = FALSE;
  
  if (isRecording) {
#if SNDAUDIOPROCRECORDER_DEBUG  
    fprintf(stderr,"SndAudioProcessorRecorder::prepareToRecordForDuration - Error: already recording!\n");
#endif
  }
  else {
    // This ain't an optimal situation - recorder shouldn't even HAVE an output buffer.
    // However, it is the only way at present to get format info from manager 
    // Ideally, we would like the recorder to connect to the stream manager itself
    if (recordBuffer != nil)
      [recordBuffer release];

    recordBuffer = [SndAudioBuffer audioBufferWithFormat: dataFormat
                                            channelCount: chanChan
                                            samplingRate: samRate
                                                duration: time];
    if (recordBuffer == nil) {
#if SNDAUDIOPROCRECORDER_DEBUG
      fprintf(stderr,"SndAudioProcessorRecorder::prepareToRecordForDuration - Error: record buffer is nil.\n");
#endif
    }
    else {
      [recordBuffer retain];
      r = TRUE;
    }
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// startRecording
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecording
{
  BOOL r = FALSE;
  
  if (recordBuffer == nil) {
#if SNDAUDIOPROCRECORDER_DEBUG  
    fprintf(stderr,"SndAudioProcessorRecorder::startRecording - Error: recordBuffer is nil.\n");
#endif
  }
  else if (isRecording) {  
#if SNDAUDIOPROCRECORDER_DEBUG  
    fprintf(stderr,"SndAudioProcessorRecorder::startRecording - Error: already recording!\n");
#endif
  }
  else {
    position    = 0;
    isRecording = TRUE;	
    r           = TRUE;
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// setUpRecordFile:
////////////////////////////////////////////////////////////////////////////////

void writeWavFormatHeader(int format, int channelCount, int samplingRate,
                          FILE* f, unsigned long dataLengthInBytes)
{
  unsigned long dw;
  unsigned short w;
  
  fwrite("RIFF", 4, 1, f);  
  fwrite(SndSwap_Convert32BitNative2LittleEndian(dataLengthInBytes + 38), 4, 1, f); // file length
  fwrite("WAVE", 4, 1, f);  
  fwrite("fmt ", 4, 1, f);  
  fwrite(SndSwap_Convert32BitNative2LittleEndian(18), 4, 1, f);                    // chunk length
  fwrite(SndSwap_Convert16BitNative2LittleEndian(1),  2, 1, f);                    // file format 1 = linear wav
  fwrite(SndSwap_Convert16BitNative2LittleEndian(channelCount),  2, 1, f); // channels
  fwrite(SndSwap_Convert32BitNative2LittleEndian(samplingRate), 4, 1, f);  // chunk length
  dw = samplingRate * channelCount * sizeof(short);
  fwrite(SndSwap_Convert32BitNative2LittleEndian(dw), 4, 1, f);                    // bytes per second
  w = channelCount * sizeof(short);
  fwrite(SndSwap_Convert16BitNative2LittleEndian(w),  2, 1, f);                    // frame size
  fwrite(SndSwap_Convert16BitNative2LittleEndian(16),  2, 1, f);                   // bit resolution
  fwrite(SndSwap_Convert16BitNative2LittleEndian(0),  2, 1, f);                    // extra bytes
  fwrite("data", 4, 1, f);  
  fwrite(SndSwap_Convert32BitNative2LittleEndian(dataLengthInBytes), 4, 1, f);     // data chunk length
}

////////////////////////////////////////////////////////////////////////////////
// setUpRecordFile:withFormat:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) setUpRecordFile: (NSString*) filename
          withDataFormat: (int) dataFormat
            channelCount: (int) channelCount
            samplingRate: (int) samplingRate
{
  if ((recordFile = fopen([filename fileSystemRepresentation],"wb")) == NULL) {
#if SNDAUDIOPROCRECORDER_DEBUG  
    fprintf(stderr, "SndAudioProcessorRecorder::setupRecordFile - Error opening file '%s' for recording.\n",[filename cString]);
#endif
  }
  else  {
    writeWavFormatHeader(dataFormat, channelCount, samplingRate,
                         recordFile, 0);
    if (recordFileName != nil)
      [recordFileName release];
    recordFileName = [filename copy];
    return TRUE;
  }
  return FALSE;
}

////////////////////////////////////////////////////////////////////////////////
// closeRecordFile:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) closeRecordFile
{
  // We have to seek back to the beginning of the recorded file to rewrite the
  // file header so that it contains the size of the recorded data, and the
  // file-stream format  
  fseek(recordFile, 0, SEEK_SET);
  writeWavFormatHeader([recordBuffer dataFormat], [recordBuffer channelCount],
                       [recordBuffer samplingRate], recordFile, bytesRecorded);
  fclose(recordFile);
  recordFile    = NULL;
  bytesRecorded = 0;
  stopSignal = FALSE;

#if SNDAUDIOPROCRECORDER_DEBUG
  fprintf(stderr,"SndAudioProcessor::closeRecordFile - closed\n");
#endif
  
  return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// startRecordingToFile:
//
// Set up an snd file for storage.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecordingToFile: (NSString*) filename
               withDataFormat: (int) dataFormat
                 channelCount: (int) channelCount
                 samplingRate: (int) samplingRate
{
  BOOL b = FALSE;
  
  if (![self prepareToRecordForDuration: 1.0
                         withDataFormat: dataFormat
                           channelCount: channelCount
                           samplingRate: samplingRate]) {
#if SNDAUDIOPROCRECORDER_DEBUG  
    fprintf(stderr,"SndAudioProcessorRecorder::startRecordingToFile - Error in prepareTorecordForDuration.\n");
#endif
  }
  else  if (![self setUpRecordFile: filename
                    withDataFormat: dataFormat
                      channelCount: channelCount
                      samplingRate: samplingRate]) {
#if SNDAUDIOPROCRECORDER_DEBUG  
    fprintf(stderr,"SndAudioProcessorRecorder::startRecordingToFile - Error in setUpRecordFile\n");
#endif
  }
  else if (recordBuffer == nil) {
#if SNDAUDIOPROCRECORDER_DEBUG  
    fprintf(stderr,"SndAudioProcessorRecorder::startRecordingToFile - Error: recordBuffer is nil.\n");
#endif
  }
  else {
    long size = sizeof(short) * [recordBuffer lengthInSampleFrames] * [recordBuffer channelCount];
    if ((conversionBuffer = (short*) malloc(size)) == NULL) {
#if SNDAUDIOPROCRECORDER_DEBUG  
      fprintf(stderr,"SndAudioProcessorRecorder::startRecordingToFile - Error: bad malloc for conversionBuffer\n");
#endif
    }
    else
    {
      position      = 0;
      bytesRecorded = 0;
      isRecording   = TRUE;
      b             = TRUE;
      stopSignal    = FALSE;
    }
  }
  return b;
}

////////////////////////////////////////////////////////////////////////////////
// stopRecording
////////////////////////////////////////////////////////////////////////////////

- stopRecording
{
  stopSignal = TRUE; // signal to recording thread that we wanna stop.
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// stopRecordingWait:
////////////////////////////////////////////////////////////////////////////////

- stopRecordingWait: (BOOL) bWait disconnectFromStream: (BOOL) bDisconnectFromStream
{
  float timeWaiting = 0.0;
  stopSignal = TRUE; // signal to recording thread that we want to stop.
  
  if (bWait) {
    while (recordFile != NULL && timeWaiting < 3.0) {
      [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
      timeWaiting += 0.1;
    }
  }
#if SNDAUDIOPROCRECORDER_DEBUG
  fprintf(stderr,"SndAudioProcessor::stopRecordingWait:disconnectFromStream: \n");
#endif
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
////////////////////////////////////////////////////////////////////////////////

- (void) streamToDiskData: (void*) recData length: (long) bytesToRecord
{
    float *f = (float*) recData; 
    int    i, samsToConvert = bytesToRecord / sizeof(float);

    for (i = 0; i < samsToConvert; i++) {
        char *p = (char*)(conversionBuffer + i); 
        short s = (short)(f[i] * 32767.0f);
        p[0] = (char) (s & 0x00FF);
        p[1] = (char) ((s & 0xFF00) >> 8);
    }              
    fwrite(conversionBuffer, samsToConvert, sizeof(short), recordFile);
    bytesRecorded += samsToConvert * sizeof(short);    
}

////////////////////////////////////////////////////////////////////////////////
// primeStartTrigger
////////////////////////////////////////////////////////////////////////////////

- primeStartTrigger
{
  bStartTrigger = TRUE;
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// setStartTriggerThreshold:
////////////////////////////////////////////////////////////////////////////////

- setStartTriggerThreshold: (float) f
{
  fStartTriggerThreshold = f;
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// paramObjectForIndex:
////////////////////////////////////////////////////////////////////////////////

- (id) paramObjectForIndex: (const int) i
{
  id obj;
  switch (i) {
    case recorder_kRecordFile: if (recordFileName != nil) obj = recordFileName; else obj = @""; break;
    default:
      obj = [super paramObjectForIndex: i];
  }
  return obj;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue:
////////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (const int) index
{
  float f = 0.0f;
  switch (index) {
    case recorder_kStartTriggerThreshold: f = fStartTriggerThreshold; break;
  }
  return f;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramName: (const int) index
{
  NSString *r = nil;
  switch (index) {
    case recorder_kStartTriggerThreshold: r = @"StartTriggerThreshold"; break;
    case recorder_kRecordFile:            r = @"RecordFileName";        break;
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////

@end
