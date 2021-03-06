/*
  $Id$

  Description:
    Defines the C entry points to the Sound Library for portaudio.

    These routines emulate an internal SoundKit module.
    This is intended to hide all the operating system evil behind a banal C function interface.
    However, it is intended that developers will use the higher level 
    Objective C SndKit interface rather this one...

  Original Author: Leigh M. Smith, <leigh@leighsmith.com>

  10 July 1999, Copyright (c) 1999 The MusicKit Project.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import <Foundation/Foundation.h>
#include "PerformSoundPrivate.h"
#if HAVE_PORTAUDIO_H
# include <portaudio.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif 


#define SQUAREWAVE_DEBUG 0
#define DEBUG_VENDBUFFER 0

#define DEFAULT_SAMPLE_RATE     (44100)
#define DEFAULT_OUT_CHANNELS    (2)
#define DEFAULT_IN_CHANNELS     (2)
/* Note: if changing the default buffer size, ensure it is exactly
 * divisible by BYTES_PER_FRAME (which is 8 for stereo, 4 byte
 * floats).
 */
#define DEFAULT_BUFFER_SIZE      (512)  // in Frames
#define DEFAULT_DATA_FORMAT      (SND_FORMAT_FLOAT)
#define BYTES_PER_FRAME          (sizeof(float) * DEFAULT_OUT_CHANNELS)

// "class variables" 
static BOOL             initialised = FALSE;
static const char       **outputDeviceList;
static const char       **inputDeviceList;
static unsigned int     outputDeviceIndex = 0;
static unsigned int     inputDeviceIndex = 0;
static char             **speakerConfigurationList;

static int              numOfDevices;
static BOOL             inputInit = FALSE;

// portaudio specific variables
static long             bufferSizeInFrames = DEFAULT_BUFFER_SIZE;
static PaStream         *stream = NULL; // init to NULL to catch unused case.
static BOOL             isMuted = FALSE;
static BOOL             useNativeBufferSize = TRUE;

// Stream processing data.
static SNDStreamProcessor streamProcessor;
static void *streamUserData;
static PaTime firstSampleTime = -1.0; // indicates this has not been assigned.
static float *lastRecvdInputBuffer = NULL;


static const char **retrieveDriverList(BOOL forOutputDevices)
{
    int driverIndex = 0;
    numOfDevices = Pa_GetDeviceCount();
    char **driverList;

    // NSLog(@"Number of portaudio devices %d\n", numOfDevices);
    if(numOfDevices < 0) { // Error getting devices.
        NSLog(@"PortAudio Error retrieving number of devices %s\n", Pa_GetErrorText(numOfDevices));
        return NULL;
    }
    if((driverList = (char **) malloc(sizeof(char *) * (numOfDevices + 1))) == NULL) {
          NSLog(@"Unable to malloc driver list for %d devices\n", numOfDevices);
          return NULL;
    }
    driverIndex = 0;
    while (driverIndex < numOfDevices) {
	const PaDeviceInfo *deviceInfo = Pa_GetDeviceInfo(driverIndex);
        const char *name = deviceInfo->name;
        char *deviceName;

#if 0
	NSLog(@"%s max input channels %d, max output channels %d\n", name, deviceInfo->maxInputChannels, deviceInfo->maxOutputChannels);
	NSLog(@"input latency %lf -> %lf\n", deviceInfo->defaultLowInputLatency, deviceInfo->defaultHighInputLatency);
	NSLog(@"output latency %lf -> %lf\n", deviceInfo->defaultLowOutputLatency, deviceInfo->defaultHighOutputLatency);
#endif

	if((forOutputDevices && deviceInfo->maxOutputChannels > 0) ||
	   (!forOutputDevices && deviceInfo->maxInputChannels > 0)) {
	    if((deviceName = (char *) malloc((strlen(name) + 1) * sizeof(char))) == NULL) {
		NSLog(@"Unable to malloc deviceName string\n");
		return NULL;
	    }
	    strcpy(deviceName, name);
	    driverList[driverIndex] = deviceName;
	    driverIndex++;
	}
    }
    driverList[driverIndex] = NULL;
    return (const char **) driverList;
}

BOOL SNDSetBufferSizeInBytes(long newBufferSizeInBytes, BOOL forOutputDevices)
{
    long newBufferSizeInFrames = newBufferSizeInBytes / BYTES_PER_FRAME;

    // We allow changes to occur while the streaming is active since the changes only
    // occur when streaming is started anyway, in portaudio.
    if ((float)newBufferSizeInBytes /(float) BYTES_PER_FRAME != newBufferSizeInFrames) {
        NSLog(@"output device - error setting buffer size. Buffer must be multiple of %d\n", BYTES_PER_FRAME);
        return FALSE;
    }
    bufferSizeInFrames = newBufferSizeInFrames;
    // if we set the size, we force the streaming to use it, not the native size.
    useNativeBufferSize = FALSE;  
    return TRUE;
}

long SNDGetBufferSizeInBytes(BOOL forOutputDevices)
{
    // TODO Pa_getBufferSize())
    return useNativeBufferSize ? 0 : bufferSizeInFrames * BYTES_PER_FRAME;
}

////////////////////////////////////////////////////////////////////////////////
// vendBuffersToStreamManagerIOProc
//
// We vend the output and input buffers in their native format to avoid 
// redundant conversions. This allows postponing the conversion to the last 
// possible moment. The SndConvertFormat() function in the SndKit makes for an 
// easy way to do the conversion without anyone writing their own converter.
////////////////////////////////////////////////////////////////////////////////

static int vendBuffersToStreamManagerIOProc(const void *inputBuffer,
                                            void *outputBuffer,
                                   unsigned long framesPerBuffer,
				   const PaStreamCallbackTimeInfo *timeInfo,
                                     PaStreamCallbackFlags statusFlags,
                                            void *userData)
{
    SNDStreamBuffer inStream, outStream;
    unsigned long vendBufferSizeInBytes = framesPerBuffer * BYTES_PER_FRAME;

    // TODO We modify the saved buffer size here, before
    // SNDStreamNativeFormat() is called.
    // bufferSizeInFrames = framesPerBuffer; 
#if DEBUG_VENDBUFFER
    NSLog(@"framesPerBuffer now %ld\n", framesPerBuffer);
#endif
//    if(statusFlags) {
//        NSLog(@"Problem in callback: %x\n", statusFlags);
//    }
    if(firstSampleTime == -1.0) {
        firstSampleTime = timeInfo->outputBufferDacTime; /* I assume this will be 0, but interesting to find out. */
    }

    // to tell the client the format it is receiving.

    if (inputInit) {
        memcpy(lastRecvdInputBuffer, inputBuffer, vendBufferSizeInBytes);
    }

    // to tell the client the format it should send.
        
    SNDStreamNativeFormat(&outStream, YES);
    SNDStreamNativeFormat(&inStream, NO);

    inStream.streamData  = lastRecvdInputBuffer;
    outStream.streamData = outputBuffer;
        
    // hand over the stream buffers to the processor/stream manager.
    // the output time goes out as a relative time, noted from the 
    // first sample time we first receive.

#ifdef GNUSTEP
    // If we are using a GNUstep system, the thread of the callback
    // hasn't yet been registered with GNUstep which it must be before
    // we can create NSAutoreleasePools.
    GSRegisterCurrentThread();
#endif
    (*streamProcessor)(timeInfo->outputBufferDacTime - firstSampleTime, 
                       &inStream, &outStream, streamUserData);
    if (isMuted) {
        memset(outputBuffer, 0, vendBufferSizeInBytes);
    }

    return paContinue; // returning 1 stops the stream
}


// Takes a parameter indicating whether to guess the device to select.
// This allows us to hard code devices or use heuristics to prevent the user
// having to always select the best device to use.
// If we guess or not, we still do get a driver initialised.
PERFORM_API BOOL SNDInit(BOOL useDefaultDevice)
{
    PaError err = Pa_Initialize();

    if (err != paNoError) {
        NSLog(@"SNDInit: PortAudio initialisation error: %s\n", Pa_GetErrorText(err));
        return FALSE;
    }

    // Debugging
#if 0
    { 
	const PaHostApiInfo *hostAPIInfo;
	NSLog(@"Default Host API index %d\n", Pa_GetDefaultHostApi());
	
	hostAPIInfo = Pa_GetHostApiInfo(Pa_GetDefaultHostApi());
	NSLog(@"Host API named: %s\n", hostAPIInfo->name);
    }
#endif

    if((outputDeviceList = retrieveDriverList(TRUE)) == NULL)
        return FALSE;

    if((inputDeviceList = retrieveDriverList(FALSE)) == NULL)
        return FALSE;

    if(!initialised)
        initialised = TRUE;   // SNDSetDriverIndex() needs to think we're initialised.
    inputInit = TRUE;

    // If we guess the device, then we retrieve the buffer size of the 
    // default device and use that, rather than using the buffer size
    // defined in DEFAULT_BUFFER_SIZE.
    if(useDefaultDevice) {
#if 0
         err = Pa_OpenDefaultStream(
 				   &stream,                         /* passes back stream pointer */
 				   DEFAULT_IN_CHANNELS,          /* stereo input */
 				   DEFAULT_OUT_CHANNELS,         /* stereo output */
 				   paFloat32,                       /* 32 bit floating point output paFloat32 */
                                          /*  note: this value instructs portaudio
                                           *  what sample size to expect, which
                                           *  is a different constant to that used
                                           *  to talk to the SndKit (SND_FORMAT_*)
                                           */
 	DEFAULT_SAMPLE_RATE,          /* sample rate */
         paFramesPerBufferUnspecified, /* frames per buffer */
         vendBuffersToStreamManagerIOProc, /* specify our custom callback */
         NULL);        /* pass our data through to callback */

 	Pa_CloseStream(stream);
	useNativeBufferSize = TRUE;
#else
	outputDeviceIndex = Pa_GetDefaultOutputDevice();
	inputDeviceIndex = Pa_GetDefaultInputDevice();
	useNativeBufferSize = FALSE;
#endif
    }
    return TRUE;
}

// Returns an array of strings listing the available drivers.
// Returns NULL if the driver names were unobtainable.
// The client application should not attempt to free the pointers.
// TODO return driverIndex by reference
PERFORM_API const char **SNDGetAvailableDriverNames(BOOL forOutputDevices)
{
    // We need the initialisation to retrieve the driver list.
    if(!initialised)
        SNDInit(TRUE);

    return forOutputDevices ? outputDeviceList : inputDeviceList;
}


// Match the driverDescription against the outputDeviceList
PERFORM_API BOOL SNDSetDriverIndex(unsigned int selectedIndex, BOOL forOutputDevices)
{
    // This needs to be called after initialising.
    if(initialised && selectedIndex >= 0 && selectedIndex < numOfDevices) {
	if(forOutputDevices)
	    outputDeviceIndex = selectedIndex;
	else
	    inputDeviceIndex = selectedIndex;
	return TRUE;
    }
    return FALSE;
}

// Match the driverDescription against the outputDeviceList
PERFORM_API unsigned int SNDGetAssignedDriverIndex(BOOL forOutputDevices)
{
    return forOutputDevices ? outputDeviceIndex : inputDeviceIndex;
}

PERFORM_API BOOL SNDIsMuted(void)
{
    return isMuted;
}

PERFORM_API void SNDSetMute(BOOL aFlag)
{
    isMuted = aFlag;
}

PERFORM_API float SNDGetLatency(BOOL forOutputDevices)
{
    if(stream) {
	const PaStreamInfo *streamInfo = Pa_GetStreamInfo(stream);

	// NSLog(@"output latency = %lf seconds, input latency = %lf sample rate = %lf\n",
	//       streamInfo->outputLatency, streamInfo->inputLatency, streamInfo->sampleRate);
	return forOutputDevices ? streamInfo->outputLatency : streamInfo->inputLatency;
    }
    else
	return 0.0;
}

////////////////////////////////////////////////////////////////////////////////
// SNDStreamStart
//
// Routine to begin playback/recording of a stream.
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDStreamStart(SNDStreamProcessor newStreamProcessor,
                                              void *newUserData)
{
    PaError err;
    int data = 0;
    BOOL streamStartedOK = TRUE;
    PaStreamParameters inputStreamParameters;
    PaStreamParameters outputStreamParameters;

    if(!initialised)
        return FALSE;  // invalid sound structure.

    // indicate the first absolute sample time received from the call back needs to be marked as a
    // datum to use to convert subsequent absolute sample times to a relative time.
    firstSampleTime = -1.0;  

    streamProcessor = newStreamProcessor;
    streamUserData  = newUserData;

    inputStreamParameters.device = inputDeviceIndex;
    inputStreamParameters.channelCount = DEFAULT_IN_CHANNELS;
    /* 32 bit floating point output paFloat32. */
    /* note: this value instructs portaudio what sample size to expect, which
       is a different constant to that used to talk to the SndKit (SND_FORMAT_*)
     */
    inputStreamParameters.sampleFormat = paFloat32;
    inputStreamParameters.suggestedLatency = 0; /* These values are probably wrong */
    inputStreamParameters.hostApiSpecificStreamInfo = NULL;

    outputStreamParameters.device = outputDeviceIndex;
    outputStreamParameters.channelCount = DEFAULT_OUT_CHANNELS;
    outputStreamParameters.sampleFormat = paFloat32;
    outputStreamParameters.suggestedLatency = 0; /* These values are probably wrong */
    outputStreamParameters.hostApiSpecificStreamInfo = NULL;
	
    err = Pa_OpenStream(&stream,		/* passes back stream pointer */
			&inputStreamParameters,
			&outputStreamParameters,
			DEFAULT_SAMPLE_RATE,	/* sample rate */
			useNativeBufferSize ? paFramesPerBufferUnspecified : bufferSizeInFrames, /* frames per buffer */
			paNoFlag,			  /* stream flags */
			vendBuffersToStreamManagerIOProc, /* specify our custom callback */
			&data);				  /* pass our data through to callback */
    if(err != paNoError) {
        NSLog(@"SNDStreamStart: PortAudio Pa_OpenStream error: %s\n", Pa_GetErrorText(err));
        return FALSE;
    }

#if 0
    NSLog(@"inputStreamParameters.suggestedLatency = %lf\n", inputStreamParameters.suggestedLatency);
    NSLog(@"outputStreamParameters.suggestedLatency = %lf\n", outputStreamParameters.suggestedLatency);
    NSLog(@"useNativeBufferSize %d bufferSizeInFrames %d\n", useNativeBufferSize, useNativeBufferSize ? paFramesPerBufferUnspecified : bufferSizeInFrames);
#endif

    if (inputInit) {
        long bufferSizeInBytes = bufferSizeInFrames * DEFAULT_IN_CHANNELS * sizeof(float);

        if ((lastRecvdInputBuffer = (float *) malloc(bufferSizeInBytes)) == NULL)
            return FALSE;
        memset(lastRecvdInputBuffer, 0, bufferSizeInBytes);
    }
 
    err = Pa_StartStream(stream);
    if(err != paNoError) {
        NSLog(@"SNDStreamStart: PortAudio Pa_StartStream error: %s\n", Pa_GetErrorText(err));
        streamStartedOK = FALSE;
    }

    return streamStartedOK;
}

////////////////////////////////////////////////////////////////////////////////
// SNDStreamStop
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDStreamStop(void)
{
    BOOL streamStoppedOK = TRUE;
    PaError err = Pa_StopStream(stream);

    if( err != paNoError ) {
        NSLog(@"PortAudio Pa_StopStream error: %s\n", Pa_GetErrorText( err ) );
        streamStoppedOK = FALSE;
    }

    err = Pa_CloseStream(stream);
    if( err != paNoError ) {
        NSLog(@"PortAudio Pa_CloseStream error: %s\n", Pa_GetErrorText( err ) );
        streamStoppedOK = FALSE;
    }

    if (inputInit) {
        free(lastRecvdInputBuffer);
        lastRecvdInputBuffer = NULL;
    }
    // NSLog(@"SNDStreamStopped %d\n", streamStoppedOK);
    return streamStoppedOK;
}


////////////////////////////////////////////////////////////////////////////////
// SndStreamNativeFormat
////////////////////////////////////////////////////////////////////////////////

// Return in the stream buffer the format of the sound data preferred by
// the operating system.
PERFORM_API void SNDStreamNativeFormat(SNDStreamBuffer *streamFormat, BOOL isOutputStream)
{
    if (!initialised)
	SNDInit(TRUE);

    /* The bytes per frame is implicitly set by the dataFormat value. */
    streamFormat->frameCount   = bufferSizeInFrames;
    streamFormat->dataFormat   = DEFAULT_DATA_FORMAT;
    streamFormat->sampleRate   = DEFAULT_SAMPLE_RATE;
    streamFormat->channelCount = isOutputStream ? DEFAULT_OUT_CHANNELS : DEFAULT_IN_CHANNELS;
}

PERFORM_API BOOL SNDTerminate(void)
{
    PaError err = Pa_Terminate();

    if (err != paNoError) {
        NSLog(@"PortAudio Pa_StartStream error: %s\n", Pa_GetErrorText(err));
	return FALSE;
    }
    return TRUE;
}

// Returns an array of character pointers listing the names of each channel.
// There will be channel count number of strings returned, with a NULL terminated
// The naming is system dependent, but is guaranteed to have two
// channels named "Left" and "Right" to ensure that stereo can always be used.
PERFORM_API const char **SNDSpeakerConfiguration(void)
{
    speakerConfigurationList[0] = "Left";
    speakerConfigurationList[1] = "Right";
    speakerConfigurationList[2] = NULL;

    return (const char **) speakerConfigurationList;
}

#ifdef __cplusplus
}
#endif
