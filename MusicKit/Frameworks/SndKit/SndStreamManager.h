/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
#ifndef __SNDSTREAMMANAGER_H__
#define __SNDSTREAMMANAGER_H__

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

@class SndAudioBuffer;
@class SndStreamClient;
@class SndStreamMixer;

#define SSM_VERSION 1 

/*!
    @class      SndStreamManager
    @abstract   Provides client connection and stream mixing services, and acts as 
                the gateway to the lowlevel MKPerformSndMIDI C functions
    @discussion To come
*/
@interface SndStreamManager : NSObject
{ 
/*! @var            mixer A stream client mixer*/
    SndStreamMixer *mixer;
/*! @var            active Stores the streaming state of the manager. */
    BOOL            active;
/*! @var            format SndSoundStruct containing stream format information. */
    SndSoundStruct  format;
/*! @var            nowTime Manager's conception of time, in seconds. */
    double          nowTime;
} 

/*!
    @method initialize
    @abstract Class initialization method
    @discussion Creates the default stream manager
    @result void.
*/
+ (void) initialize;

/*!
    @method   defaultStreamManager
    @abstract   Accessor to the default stream manager created upon class initialization.
    @discussion SndStreamClients will usually connect to the default stream manager, unless
                the user wishes to explicitly create their own manager.  
    @result     Returns the default manager
*/
+ (SndStreamManager*) defaultStreamManager;

/*!
    @method   dealloc
    @abstract   Destructor
*/
- (void) dealloc;

/*!
    @method   description
    @abstract   Returns an NSString with description of SndStreamManager
    @discussion 
    @result     Returns an NSString with description of SndStreamManager
*/
- (NSString*) description;

/*!
    @method   startStreaming
    @abstract   Starts streaming.
    @discussion You should never need to call this. Streaming is started automatically
                whene the first client connects to the manager.   
    @result     TRUE if streaming was successfully started
*/
- (BOOL) startStreaming;

/*!
    @method   stopStreaming
    @abstract   Stops streaming.
    @discussion You should never need to call this. Streaming is stopped automatically
                whene the last client disconnects from the manager.   
    @result     TRUE if streaming was successfully stopped.
*/
- (BOOL) stopStreaming;

/*!
    @method   addClient: 
    @abstract   Adds an SndStreamClient to the manager's mixer
    @discussion If the SndStreamClient is already a client of the mixer, it 
                is NOT added again. If the client is the first connected to
                the manager, the manager will automatically start streaming.
    @param      client
    @result     TRUE if client was successfully added
*/
- (BOOL) addClient: (SndStreamClient*) client;

/*!
    @method   removeClient: 
    @abstract   Removes the SndStreamClient from the manager's mixer
    @discussion If the removed client was the last client connected to the
                manager, streaming will be automatically shut down.
    @param      client The client to be disconnected from the manager.
    @result     TRUE if the client was successfully removed.
*/
- (BOOL) removeClient: (SndStreamClient*) client;

/*!
    @method   processStreamAtTime:input:output:
    @abstract   Passes new input and output buffers from the underlaying API to the
                mixer.
    @discussion Do not call this method - it is part of the audio callback handler.
    @param      sampleCount Time in samples
    @param      inB inputBuffer
    @param      outB
*/
- (void) processStreamAtTime: (double) sampleCount
                       input: (SNDStreamBuffer*) inB
                      output: (SNDStreamBuffer*) outB;

/*!
    @method   setFormat:
    @abstract   Sets the format to be used during streaming
    @discussion Do not call this method - it is called as part of the start-streaming
                process. The stream format used is the native format coming up from 
                the devices below.
    @param      f
    @result     self
*/
- setFormat: (SndSoundStruct*) f;

/*!
    @method   nowTime
    @abstract   Return the current time as understood by the SndStreamManager
    @discussion 
    @result     nowTime as a double 
*/
- (double) nowTime;

/*!
    @method   mixer
    @abstract   Mixer member accessor method
    @result     The internal SndStreamMixer
*/
- (SndStreamMixer*) mixer;

/*!
    @method   isActive
    @abstract   indicates whether streaming is happening (active) 
    @discussion 
    @result     TRUE if streaming is active
*/
- (BOOL) isActive;

@end

#endif