#ifndef WIN32
#import <libc.h>
#else
#import <stdio.h>
#import <fcntl.h>
#import <Winsock.h>
#import <malloc.h>
#import <io.h>
#endif
#import <math.h>
#import <Foundation/Foundation.h>

#import "SndFunctions.h"
#import "SndResample.h"
#import <objc/zone.h>

#ifdef USE_MACH_MEMORY_ALLOCATION
#import <mach/mach_interface.h>
#import <mach/mach_init.h>
#endif

//#import <sound/sound.h>
#import <st.h>  // prototypes and structures from the Sox sound tools library
int ausizestyleencoding(int size, int style);  // from sox au.c 

#define SNDREADCHUNKSIZE 256*1024   // Number of LONG samples to read into a buffer.
#ifdef WIN32
#define LASTCHAR        '\\'
#else
#define LASTCHAR        '/'
#endif

int SndSampleWidth(int format)
{
	int width;
		switch (format) {
			case SND_FORMAT_MULAW_8:
			case SND_FORMAT_LINEAR_8:
				width = 1;
				break;
			case SND_FORMAT_EMPHASIZED:
			case SND_FORMAT_COMPRESSED:
			case SND_FORMAT_COMPRESSED_EMPHASIZED:
			case SND_FORMAT_DSP_DATA_16:
			case SND_FORMAT_LINEAR_16:
				width = 2;
				break;
			case SND_FORMAT_LINEAR_24:
			case SND_FORMAT_DSP_DATA_24:
				width = 3;
				break;
			case SND_FORMAT_LINEAR_32:
			case SND_FORMAT_DSP_DATA_32:
				width = 4;
				break;
			case SND_FORMAT_FLOAT:
				width = sizeof(float);
				break;
			case SND_FORMAT_DOUBLE:
				width = sizeof(double);
				break;
			default: /* just in case */
				width = 2;
				break;
		}
	return width;
}
int mcheck()
{
return NXMallocCheck();
}
int SndBytesToSamples(int byteCount, int channelCount, int dataFormat)
{
	return (int)(byteCount / (channelCount * SndSampleWidth(dataFormat)));
}
int SndSamplesToBytes(int sampleCount, int channelCount, int dataFormat)
{
	return (int)(sampleCount * channelCount * SndSampleWidth(dataFormat));
}
float SndConvertDecibelsToLinear(float db)
{
	return (float)pow(10.0, (double)db/20.0);
}

float SndConvertLinearToDecibels(float lin)
{
	return (float)(20.0 * log10((double)lin));
}

void *SndGetDataAddresses(int sample,
		const SndSoundStruct *theSound,
		int *lastSampleInBlock, /* channel independent */
		int *currentSample)     /* channel independent */
/* returns the base address of the block the sample resides in,
 * with appropriate indices for the last sample the block holds.
 * Indices count from 0 so they can be utilised directly.
 */
{
	int cc = theSound->channelCount;
	int df = theSound->dataFormat;
	int ds = theSound->dataSize;
	int numBytes;
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int i=0,count=0,oldCount = 0;
	
	if (df == SND_FORMAT_INDIRECT) df = ((SndSoundStruct *)(*((SndSoundStruct **)(theSound->dataLocation))))->dataFormat;

	numBytes = SndSampleWidth(df);
	
	if ((theSound->dataFormat) != SND_FORMAT_INDIRECT) {
		*lastSampleInBlock = ds / cc / numBytes;
		*currentSample = sample;
		return (char *)theSound + theSound->dataLocation;
	}
	ssList = (SndSoundStruct **)theSound->dataLocation;
	while ((theStruct = ssList[i++]) != NULL) {
		count += ((theStruct->dataSize) / cc / numBytes);
		if (count > sample) {
			*lastSampleInBlock = ((theStruct->dataSize) / cc / numBytes);
			*currentSample = sample - oldCount;
			return (char *)theStruct + theStruct->dataLocation;
		}
		oldCount = count;
	}
	*currentSample = -1;
	*lastSampleInBlock = -1;
	return NULL;
}

int SndSampleCount(const SndSoundStruct *sound)
{
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int count = 0, i = 0, df;

	if (!sound) return SND_ERR_NOT_SOUND;
	if (sound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    df = sound->dataFormat;
	if (df != SND_FORMAT_INDIRECT) /* simple case */
		return SndBytesToSamples(sound->dataSize,
					sound->channelCount, df);
	/* more complicated */
	ssList = (SndSoundStruct **)sound->dataLocation;
	if (ssList[0]) df = ssList[0]->dataFormat;
	else return 0; /* fragged sound with no frags! */
	while ((theStruct = ssList[i++]) != NULL)
		count += theStruct->dataSize;
	return SndBytesToSamples(count, sound->channelCount, df);
}
int SndPrintFrags(SndSoundStruct *sound)
{
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int count = 0, i = 0, df;

	if (!sound) return SND_ERR_NOT_SOUND;
	if (sound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    df = sound->dataFormat;
	if (df != SND_FORMAT_INDIRECT) {
		printf("not fragmented\n");
		return SND_ERR_NONE;
	}
	/* more complicated */
	ssList = (SndSoundStruct **)sound->dataLocation;
	df = ssList[0]->dataFormat;
	while ((theStruct = ssList[i++]) != NULL) {
		printf("**** Frag %d: starts at byte %d\n",i-1,count);
		count += theStruct->dataSize;
		printf("...ends at byte: %d\n",count-theStruct->channelCount*SndSampleWidth(df));
		printf("channels: %d sample frames: %d samples in tot: %d\n",
			theStruct->channelCount, theStruct->dataSize/theStruct->channelCount/SndSampleWidth(df),
			theStruct->dataSize/theStruct->channelCount);
		}
	return SND_ERR_NONE;
}

int SndGetDataPointer(const SndSoundStruct *sound, char **ptr, int *size, int *width)
/* only useful for non-fragmented sounds */
{
	int df;
	if (!sound) return SND_ERR_NOT_SOUND;
	if (sound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
	if ((df = sound->dataFormat) == SND_FORMAT_INDIRECT)
		return SND_ERR_BAD_FORMAT;
	*width = SndSampleWidth(df);
	*size = sound->dataSize / *width;
	*ptr = (char *)sound + sound->dataLocation;
	return SND_ERR_NONE;
}

int SndFree(SndSoundStruct *sound)
{
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int i = 0;

	if (!sound) return SND_ERR_NOT_SOUND;
	if (sound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
	/* simple case: */
	if (sound->dataFormat != SND_FORMAT_INDIRECT) {
		free(sound);
		return SND_ERR_NONE;
		}
	/* more complicated */
	ssList = (SndSoundStruct **)sound->dataLocation;
	while ((theStruct = ssList[i++]) != NULL)
		free(theStruct);
	free(ssList);
	free(sound);
	return SND_ERR_NONE;
}

int SndAlloc(SndSoundStruct **sound, int dataSize, int dataFormat,
	int samplingRate, int channelCount, int infoSize)
{
	int headerSize = 0;
	int extraInfoBytes;
	
	if (samplingRate < 0) return SND_ERR_BAD_RATE;
	if (channelCount < 1 || channelCount > 16) return SND_ERR_BAD_CHANNEL;
	if (dataSize < 0) return SND_ERR_BAD_SIZE;
	if (infoSize > 16384 || infoSize < 0) return SND_ERR_INFO_TOO_BIG;
	if (dataFormat > SND_FORMAT_DELTA_MULAW_8) return SND_ERR_BAD_FORMAT;
	
	if (infoSize < 4) infoSize = 4;
	extraInfoBytes = infoSize & 3;
	if (extraInfoBytes) extraInfoBytes = 4 - extraInfoBytes;
	headerSize = sizeof(SndSoundStruct) + infoSize + extraInfoBytes - 4;
	/* normal size of header includes 4 info bytes, so I subtract here */
	
	*sound = calloc(headerSize + dataSize, sizeof(char));
	if (!*sound) return SND_ERR_CANNOT_ALLOC;
	
	(*sound)->magic = SND_MAGIC;
	(*sound)->dataLocation = headerSize;
	(*sound)->dataSize = dataSize;
	(*sound)->dataFormat = dataFormat;
	(*sound)->samplingRate = samplingRate;
	(*sound)->channelCount = channelCount;
	return SND_ERR_NONE;
}
#if 0
/* these lifted fairly directly from the Darwin sources: */
int SndAlloc(SndSoundStruct **s,
	     int dataSize, 
	     int dataFormat,
	     int samplingRate,
	     int channelCount,
	     int infoSize)
{
    SndSoundStruct *pS;
    int size;
    
    size = sizeof(SndSoundStruct) + dataSize;
    if (infoSize > 4)
	size += ((infoSize-1) & 0xfffffffc);
    if (vm_allocate(task_self(),(pointer_t *)(&pS),size,1) != KERN_SUCCESS) {
		return SND_ERR_CANNOT_ALLOC;
    }
    pS->magic = SND_MAGIC;
    pS->dataLocation = size-dataSize;
    pS->dataSize = dataSize;
    pS->dataFormat = dataFormat;
    pS->samplingRate = samplingRate;
    pS->channelCount = channelCount;
    pS->info[0] = '\0';
    *s = pS;
#if 0 /*sb: not really necessary I don't think */
    if (dataFormat == SND_FORMAT_COMPRESSED ||
        dataFormat == SND_FORMAT_COMPRESSED_EMPHASIZED)
      return SNDSetCompressionOptions(pS, SND_CFORMAT_ATC, 0); /* default */
    else
#endif
      return SND_ERR_NONE;
}
static int calcHeaderSize(SndSoundStruct *s)
{
    int size = strlen(s->info) + 1;
    if (size < 4) size = 4;
    else size = (size + 3) & 3;
    return(sizeof(SndSoundStruct) - 4 + size);
}

int SndFree(SndSoundStruct *s)
{
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int i=0;
    int size;
    if (!s || s->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    if (s->dataFormat == SND_FORMAT_INDIRECT) {
		ssList = (SndSoundStruct **)s->dataLocation;
		while ((theStruct = ssList[i++]) != NULL)
			vm_deallocate(task_self(), (pointer_t) theStruct, theStruct->dataSize + theStruct->dataLocation);
//		if (vm_deallocate(task_self(),s->dataLocation,s->dataSize) != 
//								KERN_SUCCESS)
//	    	return SND_ERR_CANNOT_FREE;
		free((void *)s->dataLocation);
		size = calcHeaderSize(s);
		if (vm_deallocate(task_self(),(pointer_t)s,size) != KERN_SUCCESS)
	    	return SND_ERR_CANNOT_FREE;
    } else {
		size = s->dataLocation + s->dataSize;
		if (vm_deallocate(task_self(),(pointer_t)s,size) != KERN_SUCCESS)
	    	return SND_ERR_CANNOT_FREE;
    }
    return SND_ERR_NONE;
}
/* end liting from Darwin sources for SNDAlloc, SNDFree */
#endif

#if 0
int SndCompactSamples(SndSoundStruct **toSound, SndSoundStruct *fromSound)
/* There's a wee bit of a problem when compacting sounds. That is the info
 * string. When a sound is fragmented, the size of the info string is held
 * in "dataLocation" by virtue of the fact that the info will always
 * directly precede the dataLocation. When a sound is fragmented though,
 * dataLocation is taken over for use as a pointer to the list of fragments.
 * What NeXTSTEP does is to then set the dataSize of the main SNDSoundStruct
 * to 8192 -- a page of VM. Therefore, there is no longer any explicit
 * record of how long the info string was. When the sound is compacted, bytes
 * seem to be read off the main SNDSoundStruct until a NULL is reached, and
 * that is assumed to be the end of the info string.
 * Therefore I am doing things differently. In a fragmented sound, dataSize
 * will be the length of the SndSoundStruct INCLUDING the info string, and
 * adjusted to the upper 4-byte boundary.
 */
{
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int count = 0, i = 0;
	int dataLength;
	char *startLocation;
	int cc;
	int df;
	int ds;
	int sr;

	if (!fromSound) return SND_ERR_NOT_SOUND;
	if (fromSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
	cc = fromSound->channelCount;
	df = fromSound->dataFormat;
	ds = fromSound->dataSize; /*ie size of header including info string*/
	sr = fromSound->samplingRate;
	
    if (df == SND_FORMAT_INDIRECT)
		df = ((SndSoundStruct *)(*((SndSoundStruct **)
			(fromSound->dataLocation))))->dataFormat;
	else return SndCopySound(toSound,fromSound); 
	
	dataLength = SndSamplesToBytes(SndSampleCount(fromSound),cc,df);
	
	if (SndAlloc(toSound, dataLength, df, sr, cc,
			ds - sizeof(SndSoundStruct) + 4) != SND_ERR_NONE)
		return SND_ERR_CANNOT_ALLOC;
	
	memmove(&((*toSound)->info),&(fromSound->info),
		ds - sizeof(SndSoundStruct) + 4);
	
	startLocation = (char *)(*toSound) + ds;
	ssList = (SndSoundStruct **)fromSound->dataLocation;
	while ((theStruct = ssList[i++]) != NULL) {
		memmove(startLocation + count,
			(char *)theStruct + theStruct->dataLocation,
			theStruct->dataSize);
		count += theStruct->dataSize;
	}
	return SND_ERR_NONE;
}
#endif

int SndCompactSamples(SndSoundStruct **s1, SndSoundStruct *s2)
{
    SndSoundStruct *fragment, *newSound, **iBlock, *oldSound = s2;
    int format, nchan, rate, newSize, infoSize, err;
    char *src, *dst;
	if (oldSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    if (oldSound->dataFormat != SND_FORMAT_INDIRECT)
	return SND_ERR_NONE;
    iBlock = (SndSoundStruct **)oldSound->dataLocation;
    if (!*iBlock) {
		newSound = (SndSoundStruct *)0;
	} else {
		format = (*iBlock)->dataFormat;
		nchan = oldSound->channelCount;
		rate = oldSound->samplingRate;
		infoSize = oldSound->dataSize - sizeof(SndSoundStruct) + 4;
		newSize = SndSamplesToBytes(SndSampleCount(oldSound),nchan,format);
		err = SndAlloc(&newSound,newSize,format,rate,nchan,infoSize);
		if (err)
			return SND_ERR_CANNOT_ALLOC;
//		strcpy(newSound->info,oldSound->info);
		memmove(&(newSound->info),&(oldSound->info),
			infoSize);
		dst = (char *)newSound;
		dst += newSound->dataLocation;
		while(fragment = *iBlock++) {
			src = (char *)fragment;
			src += fragment->dataLocation;
			memmove(dst,src,fragment->dataSize);
			dst += fragment->dataSize;
		}
	}
    *s1 = newSound;
    return SND_ERR_NONE;
}

int SndCopySound(SndSoundStruct **toSound, const SndSoundStruct *fromSound)
{
	SndSoundStruct **ssList=NULL,**newssList=NULL;
	SndSoundStruct *theStruct;
	int i = 0,ssPointer = 0;
	int cc;
	int df;
	int ds;
	int sr;

	if (!fromSound) return SND_ERR_NOT_SOUND;
	if (fromSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
	cc = fromSound->channelCount;
	df = fromSound->dataFormat;
	ds = fromSound->dataSize; /*ie size of header including info string*/
	sr = fromSound->samplingRate;
	
    if (df == SND_FORMAT_INDIRECT) {
		df = ((SndSoundStruct *)(*((SndSoundStruct **)
			(fromSound->dataLocation))))->dataFormat;
	
		/*Copying fragged sound: */
		/* initial struct -- info and all */
		if (SndAlloc(toSound, 0, df, sr, cc,
				ds - sizeof(SndSoundStruct) + 4) != SND_ERR_NONE)
			return SND_ERR_CANNOT_ALLOC;
		
		memmove(&((*toSound)->info),&(fromSound->info),
			ds - sizeof(SndSoundStruct) + 4);
		
		ssList = (SndSoundStruct **)fromSound->dataLocation;
		while ((theStruct = ssList[i++]) != NULL);
		i--;
		/* i is the number of frags */
		newssList = malloc((i+1) * sizeof(SndSoundStruct *));
		if (!newssList) {
			free (*toSound);
			return SND_ERR_CANNOT_ALLOC;
			}
		newssList[i] = NULL; /* do the last one now... */	
		
		for (ssPointer = 0; ssPointer < i; ssPointer++) {
			if (!(newssList[ssPointer] = _SndCopyFrag(ssList[ssPointer]))) {
				free (*toSound);
				for (i = 0; i < ssPointer; i++) {
					free (newssList[i]);
					}
				return SND_ERR_CANNOT_ALLOC;
			}
		}
		(SndSoundStruct **)((*toSound)->dataLocation) = newssList;
		(*toSound)->dataSize = fromSound->dataSize;
		(*toSound)->dataFormat = SND_FORMAT_INDIRECT;
		return SND_ERR_NONE;
	}
	else {
		/* copy unfragged sound */
		if (SndAlloc(toSound, ds, df, sr, cc, fromSound->dataLocation -
				sizeof(SndSoundStruct) + 4) != SND_ERR_NONE)
			return SND_ERR_CANNOT_ALLOC;
		memmove(&((*toSound)->info),&(fromSound->info),
			fromSound->dataLocation - sizeof(SndSoundStruct) + 4);
		memmove((char *)(*toSound)   + (*toSound)->dataLocation,
				(char *)fromSound + fromSound->dataLocation, ds);
	}
	return SND_ERR_NONE;
}

int SndCopySamples(SndSoundStruct **toSound, SndSoundStruct *fromSound,
		int startSample, int sampleCount)
/*
 * what do I need to do?
 * If fromSound is non-frag, create new sound and copy appropriate samples.
 * If fragged, 
 * 		create frag header
 *		find 1st and last frag containing samples
 *		loop from 1st to last, creating new frag and copying appropriate samples
 */
{	
	SndSoundStruct **ssList = NULL,**newssList;
	SndSoundStruct *theStruct,*newStruct;
	int i = 0, ssPointer = 0;
	int cc;
	int df,originalFormat;
	int ds;
	int sr;
	int numBytes;
	int lastSample = startSample + sampleCount - 1;
	int firstFrag = -1, lastFrag = -1;
	int count = 0;
	int startOffset = 0, startLength = 0, endLength = 0;
	BOOL fromOneFrag = NO;

	if (!fromSound) return SND_ERR_NOT_SOUND;
	if (fromSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
	if (lastSample > SndSampleCount(fromSound)) return SND_ERR_BAD_SIZE;
	if (sampleCount < 1) return SND_ERR_BAD_SIZE;
	
	cc = fromSound->channelCount;
	originalFormat = df = fromSound->dataFormat;
	ds = fromSound->dataSize; /* ie size of header including info string; or data */
	sr = fromSound->samplingRate;

	if (df == SND_FORMAT_INDIRECT) { /* check to see if samples lie within 1 frag */
	/* find 1st and last frag */
		df = ((SndSoundStruct *)(*((SndSoundStruct **)
				(fromSound->dataLocation))))->dataFormat;
		numBytes = SndSampleWidth(df);
		ssList = (SndSoundStruct **)fromSound->dataLocation;
		while ((theStruct = ssList[i++]) != NULL) {
			int thisCount = (theStruct->dataSize / cc / numBytes);
			if (startSample >= count && startSample < (count + thisCount))
				{
				firstFrag = i - 1;
				startOffset = (startSample - count) * cc * numBytes;
				startLength = theStruct->dataSize - startOffset;
				}
			if (lastSample >= count && lastSample < (count + thisCount))
				{lastFrag = i - 1; endLength = (lastSample - count + 1) * cc * numBytes; }
			count += thisCount;
		}
		i--;
		if (firstFrag == lastFrag) {
			fromSound = ssList[firstFrag];
			fromOneFrag = YES;
		}
	}

	if (originalFormat != SND_FORMAT_INDIRECT || fromOneFrag) {  /* simple case... */
		if (SndAlloc(toSound, sampleCount * cc * SndSampleWidth(df),
				df, sr, cc, 4) != SND_ERR_NONE)
			return SND_ERR_CANNOT_ALLOC;
		memmove((char *)(*toSound)   + (*toSound)->dataLocation,
				(char *)fromSound + fromSound->dataLocation +
				(fromOneFrag ? startOffset : startSample * cc * SndSampleWidth(df)),
				sampleCount * cc * SndSampleWidth(df));
		return SND_ERR_NONE;
	}
	/* complicated case (fragged) */

	if (lastFrag == -1 || firstFrag == -1) return SND_ERR_BAD_SIZE; /* should not really happen I don't think */
	/* allocate main header */
	if (SndAlloc(toSound, 0, df, sr, cc, 4) != SND_ERR_NONE)
		return SND_ERR_CANNOT_ALLOC;
	(*toSound)->dataSize = sizeof(SndSoundStruct);/* we don't copy any header info */
	(*toSound)->dataFormat = SND_FORMAT_INDIRECT;
	/* allocate ssList */
	/* i is the number of frags */
	if (!(newssList = malloc((lastFrag - firstFrag + 2) * sizeof(SndSoundStruct *)))) {
		free (*toSound);
		return SND_ERR_CANNOT_ALLOC;
	}
	newssList[lastFrag - firstFrag + 1] = NULL; /* do the last one now... */	

	for (ssPointer = firstFrag; ssPointer <= lastFrag; ssPointer++) {
		int charOffset = 0, charLength;
		theStruct = ssList[ssPointer];
		charLength = theStruct->dataSize;
		if (firstFrag == lastFrag) {
			charOffset = startOffset;
			charLength = endLength - startOffset;
		}
		else if (ssPointer == firstFrag) {
			charOffset = startOffset;
			charLength = startLength;
			}
		else if (ssPointer == lastFrag) charLength = endLength;
		
		if (SndAlloc(&newStruct, charLength, theStruct->dataFormat,
				theStruct->samplingRate,theStruct->channelCount, 4)) {
			free (*toSound);
			for (i = 0; i < ssPointer; i++) {
				free (newssList[i]);
				}
			return SND_ERR_CANNOT_ALLOC;
		}
		memmove((char *)newStruct + newStruct->dataLocation,
				(char *)theStruct + theStruct->dataLocation + charOffset,
				charLength);
		newssList[ssPointer - firstFrag] = newStruct;
	}
	(SndSoundStruct **)((*toSound)->dataLocation) = newssList;
	return SND_ERR_NONE;
}

int SndInsertSamples(SndSoundStruct *toSound, const SndSoundStruct *fromSound, int startSample)
/*
 * The harder case here is when toSound is already fragmented. In this case, simply add 
 * another frag at the appropriate place in ssList (if startSample lies on frag boundary)
 * or (more likely) add frag at appropriate place in list, add SECOND frag after that one
 * containing the rest of the `sliced' frag. Then adjust the first sliced frag (realloc).
 *
 * If not fragmented already, create 2 or 3 frags. If the startSample was at pos 0
 * or after the last sample, then the 2 SndStructs just go after each other. If startSample
 * sliced the original sound, need to reslice/realloc as above.
 */
{
	SndSoundStruct **ssList = NULL,**newssList = NULL,**oldNewssList = NULL;
	SndSoundStruct *theStruct,*newStruct;
	int i = 0, ssPointer = 0;
	int cc;
	int df,ndf;
	int ds;
	int sr;
	int numBytes;
	int numFromFrags = 0, numToFrags = 0;
	int insertFrag = -1;
	int insertFragOffset = 0;
	int insertFragCounter = 0;
	int numFrags;
	int firstFragToFree = -1, firstOfCopiedListToFree = -1;

	if (!fromSound) return SND_ERR_NOT_SOUND;
	if (fromSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
	if (!toSound) return SND_ERR_NOT_SOUND;
	if (toSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
	if (startSample < 0 || startSample > SndSampleCount(toSound)) return SND_ERR_BAD_SIZE;
	
	cc = fromSound->channelCount;
	df = fromSound->dataFormat;
	ds = fromSound->dataSize; /* ie size of header including info string; or data */
	sr = fromSound->samplingRate;
	ndf = toSound->dataFormat;
	
	if (df == SND_FORMAT_INDIRECT) { /* count the num of frags in "from" sound */
		numBytes = SndSampleWidth(((SndSoundStruct *)(*((SndSoundStruct **)
				(fromSound->dataLocation))))->dataFormat);
		ssList = (SndSoundStruct **)fromSound->dataLocation;
		while ((theStruct = ssList[numFromFrags++]) != NULL);
		numFromFrags--;
		/* numFromFrags is the number of frags */
	}
	else numBytes = SndSampleWidth(df);
	if (ndf == SND_FORMAT_INDIRECT) { /* count the num of frags in "to" sound */
		oldNewssList = (SndSoundStruct **)toSound->dataLocation;
		while ((theStruct = oldNewssList[numToFrags++]) != NULL) {
			int thisCount = (theStruct->dataSize / cc / numBytes);
			if (startSample >= insertFragCounter && startSample < (insertFragCounter + thisCount)) {
				insertFrag = numToFrags - 1;
				insertFragOffset = (startSample - insertFragCounter) * cc * numBytes;
			}
			insertFragCounter += thisCount;
		}
		numToFrags--;
		if (insertFrag == -1) insertFrag = numToFrags; /* stick new data after last frag */
		/* numToFrags is the number of frags */
		/*NOW I know the frag that the insertion begins in, and the sample number within it.*/
	}
	/* need to do frag of original sound if not already fragged. Will require realloc of fromSound,
	 * creation of list etc.
	 */

	 /* In order to make this work with fragged 'toSound', I need to be able to copy
	  * the start and end portions as multi-frags, not just as flat data. Hmmm.
	  * To do this, I need to be able to split the frag that the startFrag
	  * starts and ends in.
	  */
	if (ndf != SND_FORMAT_INDIRECT) {
		if (startSample == 0) numFrags = numFromFrags ? numFromFrags + 1 : 2;
		else if (startSample == SndSampleCount(toSound) + 1)
			numFrags = numFromFrags ? numFromFrags + 1 : 2;
		else numFrags = numFromFrags ? numFromFrags + 2 : 3;
	}
	
	/* now add number of frags in toSound */
	if (ndf == SND_FORMAT_INDIRECT) {
		numFrags = numFromFrags ? numFromFrags : 1;
		if (insertFragOffset == 0 || startSample == SndSampleCount(toSound) + 1)
				numFrags += numToFrags;
		else numFrags += (numToFrags + 1);
	}
printf("numFromFrags: %d numToFrags: %d insertFragOffset %d startSample %d insertFrag %d\n",
		numFromFrags, numToFrags, insertFragOffset, startSample, insertFrag);

	if (!(newssList = malloc((numFrags + 1) * sizeof(SndSoundStruct *)))) {
		return SND_ERR_CANNOT_ALLOC;
	}
	newssList[numFrags] = NULL;
	/* stick all sound pre-insert into 1st frag... */
	if (startSample > 0 && ndf != SND_FORMAT_INDIRECT) {
		if (!(newStruct = _SndCopyFragBytes(toSound, 0, startSample * cc * numBytes))) {
			free(newssList);
			return SND_ERR_CANNOT_ALLOC;
			}
		newssList[ssPointer++] = newStruct;
	}
	if (ndf == SND_FORMAT_INDIRECT) {
		/* if insertFrag > 0, we copy pointers to all frags < insertFrag.
			* then, if insertFragOffset > 0, we copy first part of sliced frag
			*/
		for (i = 0; i<insertFrag; i++) {
			newssList[ssPointer++] = oldNewssList[i];
		}
		if (insertFragOffset > 0) {
			if (!(newStruct = _SndCopyFragBytes(oldNewssList[insertFrag],0, insertFragOffset))) {
				/* don't have to free earlier frags, as they are only pointers */
				free(newssList);
				return SND_ERR_CANNOT_ALLOC;
			}
			firstFragToFree = ssPointer;
			newssList[ssPointer++] = newStruct;
		}
	}
	/* now copy all the fromSound, or its frags if necessary */
	if (df != SND_FORMAT_INDIRECT) {
		if (!(newStruct = _SndCopyFrag(fromSound))) {
			if (ssPointer > 0) free(newssList[0]);
			free(newssList);
			return SND_ERR_CANNOT_ALLOC;
		}
		newssList[ssPointer++] = newStruct;
	}
	else {
		firstOfCopiedListToFree = ssPointer;/* remember this value so we can free if nec */
		for (i = 0; i < numFromFrags;i++){
			if (!(newStruct = _SndCopyFrag(ssList[i]))) {
				for (i = firstOfCopiedListToFree; i<ssPointer;i++) {
					free (newssList[i]);
				}
				if (firstFragToFree != -1) free(newssList[firstFragToFree]);
				free(newssList);
				return SND_ERR_CANNOT_ALLOC;
			}
			newssList[ssPointer++] = newStruct;
		}
	}
	/* now copy last bit of original sound into last frag */
	if ((startSample < SndSampleCount(toSound) + 1) && ndf != SND_FORMAT_INDIRECT) {
		if (!(newStruct = _SndCopyFragBytes(toSound, startSample * cc * numBytes,-1))) {
			for(i = 0;i<ssPointer;i++) {
					free (newssList[i]);
			}
			if (firstFragToFree != -1) free(newssList[firstFragToFree]);
			free(newssList);
			return SND_ERR_CANNOT_ALLOC;
		}
		newssList[ssPointer++] = newStruct;
	}
	if (ndf == SND_FORMAT_INDIRECT) {
		/* now copy in remainder of sliced frag (if nec), then further frags
			* from toSound into list (just pointers)
			*/
		if (insertFragOffset > 0) {
			if (!(newStruct = _SndCopyFragBytes(oldNewssList[insertFrag], insertFragOffset, -1))) {
				for (i = firstOfCopiedListToFree;i<ssPointer;i++) {
					free (newssList[i]);
				}
				if (firstFragToFree != -1) free(newssList[firstFragToFree]);
				free(newssList);
				return SND_ERR_CANNOT_ALLOC;
			}
			newssList[ssPointer++] = newStruct;
			free(oldNewssList[insertFrag]);/* this was the one that was sliced, 
											* and we have copied it, so we free */
			insertFrag++; /* step up to next complete frag to copy references to new list */
		}
		for (i = insertFrag; i<numToFrags; i++) {
			newssList[ssPointer++] = oldNewssList[i];
		}
		
	}
	if (ndf != SND_FORMAT_INDIRECT) {
		toSound = realloc(toSound,toSound->dataLocation);
		toSound->dataSize = toSound->dataLocation; /* now holds info size only */
		toSound->dataFormat = SND_FORMAT_INDIRECT;
	}
	else free(oldNewssList);
	(SndSoundStruct **)(toSound->dataLocation) = newssList;
	return SND_ERR_NONE;
}

int SndDeleteSamples(SndSoundStruct *sound, int startSample, int sampleCount)
{
	SndSoundStruct **ssList,**newssList;
	SndSoundStruct *theStruct,*newStruct;
	int i = 0, ssPointer = 0;
	int cc;
	int df,olddf=0;
	int ds;
	int sr;
	int numBytes;
	int lastSample = startSample + sampleCount - 1;
	int firstFrag = -1, lastFrag = -1;
	int numFromFrags = 0;
	int numFrags;
	int count = 0;
	int startOffset=0, startLength = 0, endLength = 0;

	if (!sound) return SND_ERR_NOT_SOUND;
	if (sound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
	if (startSample < 0 || startSample > SndSampleCount(sound)
		|| startSample + sampleCount > SndSampleCount(sound)) return SND_ERR_BAD_SIZE;
	if (!sampleCount) return SND_ERR_NONE;
	
	cc = sound->channelCount;
	df = sound->dataFormat;
	ds = sound->dataSize; /* ie size of header including info string; or data */
	sr = sound->samplingRate;

	if (df == SND_FORMAT_INDIRECT) {
		olddf = ((SndSoundStruct *)(*((SndSoundStruct **)
				(sound->dataLocation))))->dataFormat;
		numBytes = SndSampleWidth(((SndSoundStruct *)(*((SndSoundStruct **)
				(sound->dataLocation))))->dataFormat);
	}
	else numBytes = SndSampleWidth(df);
	
	if (df != SND_FORMAT_INDIRECT) {
		char *firstByteToMove = (char *)sound + sound->dataLocation + 
			(startSample + sampleCount) * cc * numBytes;
		int numBytesToMove = ds - (startSample + sampleCount) * cc * numBytes;
		char *moveToHere = (char *)sound + sound->dataLocation + startSample * cc * numBytes;
		if (numBytesToMove) memmove(moveToHere, firstByteToMove, numBytesToMove);
		sound = realloc(sound, ds + sound->dataLocation - (sampleCount * cc * numBytes));
		sound->dataSize -= (sampleCount * cc * numBytes);
		return SND_ERR_NONE;
	}
	/* find 1st and last frag containing data to be deleted */
	ssList = (SndSoundStruct **)sound->dataLocation;
	while ((theStruct = ssList[i++]) != NULL) {
		int thisCount = (theStruct->dataSize / cc / numBytes);
		if (startSample >= count && startSample < (count + thisCount)) {
			firstFrag = i - 1;
			startOffset = (startSample - count) * cc * numBytes;
			startLength = theStruct->dataSize - startOffset;
		}
		if (lastSample >= count && lastSample < (count + thisCount))
			{lastFrag = i - 1; endLength = (lastSample - count + 1) * cc * numBytes; }
		count += thisCount;
	}
	numFromFrags = i - 1;
	/* We have firstFrag and lastFrag, which may be equal.
	 * First, copy all frags before firstFrag.
	 * If startOffset == 0 and firstFrag < lastFrag, we can delete (ignore) all frags
	 * from firstFrag to lastFrag.
	 * If firstFrag == lastFrag, we must be careful to ignore only that data which is between
	 * the start and end point.
	 * Then copy all frags following endFrag.
	 */
	/* The following may overestimate the number of frags by 2, iff firstFrag == lastFrag.
	 * This does not really matter, as it's just a list of pointers, and usually not a big
	 * one at that.
	 */
	numFrags = numFromFrags - (lastFrag - firstFrag + 1) + 2;
	if (!(newssList = malloc((numFrags + 1) * sizeof(SndSoundStruct *)))) {
		return SND_ERR_CANNOT_ALLOC;
	}

	for (i = 0; i<firstFrag; i++) {
		newssList[ssPointer++] = ssList[i];
	}
	/* copy first part of 1st affected frag (the non-deleted part) */
	/* FIXME an excellent optimisation here would be to work out which part of the sound is
	 * larger (the 1st remaining part of the frag, or the last remaining part), and instead of
	 * copying it, just shuffle the data down the frag, and realloc it. This would save having to
	 * malloc a totally new block of memory. In fact, where firstFrag != lastFrag, this should
	 * be done for both halves.
	 */
	if (startOffset > 0) {
		if (!(newStruct = _SndCopyFragBytes(ssList[firstFrag], 0, startOffset))) {
			/* we don't free members of the list here, since they are still part of the
			 * original sound (i.e. we are only holding copies of the pointers)
			 */
			free(newssList);
			return SND_ERR_CANNOT_ALLOC;
		}
		newssList[ssPointer++] = newStruct;
	}
	if (endLength < ssList[lastFrag]->dataSize) {
		if (!(newStruct = _SndCopyFragBytes(ssList[lastFrag], endLength, -1))) {
			/* we don't free members of the list here, since they are still part of the
			 * original sound (i.e. we are only holding copies of the pointers
			 */
			if (startOffset > 0) free(newssList[ssPointer - 1]);
			free(newssList);
			return SND_ERR_CANNOT_ALLOC;
		}
		newssList[ssPointer++] = newStruct;
	}
	free(ssList[firstFrag]);
	if (firstFrag != lastFrag) free(ssList[lastFrag]);
	/* now we do all the rest of the list, as pointers only */
	for (i = lastFrag + 1; i<numFromFrags; i++) {
		newssList[ssPointer++] = ssList[i];
	}
	newssList[ssPointer++] = NULL;
	free(ssList); /* old list */
	if (newssList[0]) (SndSoundStruct **)(sound->dataLocation) = newssList;
	else { /* we have deleted all samples. Free new list. Check dataLocation. */
		free(newssList);
		sound->dataFormat = olddf;
		sound->dataLocation = sound->dataSize; /* size was temporarily held in dataSize */
		sound->dataSize = 0;
	}
	return SND_ERR_NONE;
}

SndSoundStruct * _SndCopyFrag(const SndSoundStruct *fromSoundFrag)
/* will not make copy of fragged sound. Info string should therefore be only 4 bytes,
 * but this takes account of longer info strings if they exist.
 */
{
	SndSoundStruct *newStruct;
	int infoSize;
	
	if (!fromSoundFrag) return NULL;
	infoSize = fromSoundFrag->dataLocation - sizeof(SndSoundStruct) + 4;
	if (fromSoundFrag->dataFormat == SND_FORMAT_INDIRECT) return NULL;
	if (SndAlloc(&newStruct, fromSoundFrag->dataSize, fromSoundFrag->dataFormat,
			fromSoundFrag->samplingRate, fromSoundFrag->channelCount, infoSize)) 
		return NULL;
	memmove(&(newStruct->info),&(fromSoundFrag->info), infoSize);
	memmove((char *)newStruct + newStruct->dataLocation,
			(char *)fromSoundFrag + fromSoundFrag->dataLocation,
			fromSoundFrag->dataSize);
	return newStruct;
}

SndSoundStruct * _SndCopyFragBytes(SndSoundStruct *fromSoundFrag, int startByte, int byteCount)
/* Does the same as _SndCopyFrag, but used for `partial' frags that occur when you insert or
 * delete data from a SndStruct.
 * If byteCount == -1, uses all data from startByte to end of frag.
 * Does not make copy of fragged sound. Info string should therefore be only 4 bytes,
 * but this takes account of longer info strings if they exist.
 */
{
	SndSoundStruct *newStruct;
	int infoSize;
	int ds;
	
	if (!fromSoundFrag) return NULL;
	ds = fromSoundFrag->dataSize;
	if (byteCount == -1) byteCount = ds - startByte;
	if (startByte + byteCount > ds) return NULL;
	infoSize = fromSoundFrag->dataLocation - sizeof(SndSoundStruct) + 4;
	if (fromSoundFrag->dataFormat == SND_FORMAT_INDIRECT) return NULL;
	if (SndAlloc(&newStruct, byteCount, fromSoundFrag->dataFormat,
			fromSoundFrag->samplingRate, fromSoundFrag->channelCount, infoSize)) 
		return NULL;
	memmove(&(newStruct->info),&(fromSoundFrag->info), infoSize);
	memmove((char *)newStruct + newStruct->dataLocation,
			(char *)fromSoundFrag + fromSoundFrag->dataLocation + startByte,
			byteCount);
	return newStruct;
}

unsigned char SndMulaw(short linearValue)
{
	return st_linear_to_ulaw(linearValue);
}

short SndiMulaw(unsigned char mulawValue)
{
	return (short)st_ulaw_to_linear(mulawValue);
}

// TODO to convert
int SndReadHeader(int fd, SndSoundStruct **sound)
{
	BOOL reverse = NO;
	SndSoundStruct *s;
	int error;
	*sound = NULL;
	if (fd == 0) return SND_ERR_CANNOT_OPEN;
	if (!(s = malloc(sizeof(SndSoundStruct)))) return SND_ERR_CANNOT_ALLOC;
	if ((error = read(fd, s, sizeof(SndSoundStruct))) < 0) return SND_ERR_CANNOT_READ;
	if (error == 0) printf("Sound contained only header!\n");
	/* now test for endianness */
	if (s->magic != SND_MAGIC)
		if (s->magic == (int)ntohl(SND_MAGIC))
			reverse = YES;
		else return SND_ERR_CANNOT_READ;
	if (reverse) {
		s->magic = ntohl(s->magic);
		s->dataLocation = ntohl(s->dataLocation);
		s->dataSize = ntohl(s->dataSize);
		s->dataFormat = ntohl(s->dataFormat);
		s->samplingRate = ntohl(s->samplingRate);
		s->channelCount = ntohl(s->channelCount);
		/* info string should be ok, if it's just chars... */
	}
	printf("Location:%d size:%d format:%d sr:%d cc:%d\n", s->dataLocation, s->dataSize, s->dataFormat, s->samplingRate, s->channelCount);
	if (s->dataLocation > sizeof(SndSoundStruct)) {
		/* read off the rest of the info string */
		s = realloc(s,s->dataLocation);
		error = read(fd,(char *)s + sizeof(SndSoundStruct),s->dataLocation - sizeof(SndSoundStruct));
		if (error <= 0) return SND_ERR_CANNOT_READ;
	}
	return SND_ERR_NONE;
}

int SndRead(FILE *fp, SndSoundStruct **sound, const char *fileTypeStr)
{
        SndSoundStruct *s;
        int lenRead;
        int samplesRead;
	int headerLen;
        struct soundstream informat;
        LONG *readBuffer;
        char *storePtr;
	int i;

        *sound = NULL;
        if (fp == NULL) 
		return SND_ERR_CANNOT_OPEN;
        informat.fp = fp;
        informat.seekable = YES;
        informat.filetype = fileTypeStr;
        informat.info.rate = 0;
        informat.info.size = -1;
        informat.info.style = -1;
        informat.info.channels = -1;
        informat.comment = NULL;
        informat.swap = 0;
        informat.filename = "input";

        gettype(&informat);

        /* Read and write starters can change their formats. */
        (* informat.h->startread)(&informat);
        checkformat(&informat);

        headerLen = sizeof(SndSoundStruct);
        if (informat.comment) {
            headerLen += strlen(informat.comment) - 4 + 1; // -4 for the 4 bytes defined with SndSoundStruct, +1 for \0
	    // if(headerLen < sizeof(SndSoundStruct))
	    // headerLen = sizeof(SndSoundStruct)
	}
        if (!(s = malloc(headerLen))) return SND_ERR_CANNOT_ALLOC;
	/* endianess is handled within startread() */
        s->magic = SND_MAGIC; // could be extended using fileTypeStr but only when we write in all formats.
        s->dataLocation = headerLen;
        s->dataFormat = ausizestyleencoding(informat.info.style, informat.info.size);
        s->samplingRate = informat.info.rate;
        s->channelCount = informat.info.channels;
        if (informat.comment) // because SndSoundStruct locates comments at a fixed location, we have to copy them in.
		strcpy(s->info, informat.comment);
	else
		s->info[0] = '\0';

	// There is a semantic mismatch between sox and the SndKit's process of managing data. .snd files provide an upfront
	// indication of sound file size in bytes, whereas sox only allows reading chunks until EOF to allow for pipe
	// operations.
	// For now, we read separate chunks and laboriously reallocate after each read. This can be slow, so the only way to
	// optimise is slightly overestimate the likely typical sound file size for initial allocation.
	// The proper solution is to properly implement a dataSize value of -1 indicating the sound is streamed.
	// Likewise, startread function should be changed to return the sound file size for the big three (aiff, wav, au)
	// so the allocation size can be closer to the real value.

        // Sox read() always returns arrays of LONG integers for each sample which the SndKit should eventually adopt
	// to enable 24 bit operation.
        // For now, we kludge it to 16 bit integers until we have sound drivers that will manage the extra precision.

	// Unfortunately there is the assumption the SndSoundStruct is always big-endian (within the MKPerformSndMIDI
	// framework and any soundStructs returned), which means we need to swap again. The correct solution is to relax
	// the big-endian requirement, introduce another format code allowing for little endian encoding, and revert the
	// MKPerformSndMIDI framework to expect native endian order.

        if((readBuffer = (LONG *) malloc(SNDREADCHUNKSIZE * sizeof(LONG))) == NULL) return SND_ERR_CANNOT_ALLOC;
        samplesRead = 0; // samplesRead represents ? excluding header.
        do {
            // punt on at least SNDREADCHUNKSIZE much then trim it at the end.
            s = realloc((char *)s, headerLen + (samplesRead + SNDREADCHUNKSIZE) * informat.info.size);
            storePtr = (char *)s + headerLen + samplesRead * informat.info.size;
            /* Read chunk of input data. */
            lenRead = (*informat.h->read)(&informat, readBuffer, (LONG) SNDREADCHUNKSIZE);
            if (lenRead <= 0)
                return SND_ERR_CANNOT_READ;
            for(i = 0; i < lenRead; i++) {
                int sample = RIGHT(readBuffer[i], (sizeof(LONG) - informat.info.size) * 8);
                *((short *) storePtr) =  htons(sample); // kludged assuming 16 bits. We always adopt big-endian format.
                storePtr += informat.info.size;
	    }
            samplesRead += lenRead;
        } while(lenRead == SNDREADCHUNKSIZE); // sound files exactly modulo SNDREADCHUNKSIZE will read 0 bytes next time thru.
        s->dataSize = samplesRead * informat.info.size;
	s = realloc((char *)s, headerLen + s->dataSize); 
	free(readBuffer);

	if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowInputFileFormat"]) {
            printf("Input file: using sample rate %lu Hz, size %s, style %s, %d %s\n",
               informat.info.rate, sizes[informat.info.size],
               styles[informat.info.style], informat.info.channels,
               (informat.info.channels > 1) ? "channels" : "channel");
            if (informat.comment)
                printf("Input file: comment \"%s\"\n", informat.comment);
            printf("Location:%d size:%d format:%d sr:%d cc:%d info:%s\n",
                s->dataLocation, s->dataSize, s->dataFormat, s->samplingRate, s->channelCount, s->info);
        }

	*sound = s;
        (* informat.h->stopread)(&informat);
	return SND_ERR_NONE;
}

/* called from util.c:fail */
void cleanup() 
{
        /* Close the input file and outputfile before exiting*/
//        if (informat.fp)
//                fclose(informat.fp);
}

int SndReadSoundfile(const char *path, SndSoundStruct **sound)
{
	int error,error2;
	FILE *fp;
	SndSoundStruct *aSound;
	const char *filetype;

        *sound = NULL;
	if (!path) return SND_ERR_BAD_FILENAME;
	if (!strlen(path)) return SND_ERR_BAD_FILENAME;
        fp = fopen(path, READBINARY);
        if (fp == NULL) return SND_ERR_CANNOT_OPEN;

        if ((filetype = strrchr(path, LASTCHAR)) != NULL)
            filetype++;
        else
            filetype = path;
        if ((filetype = strrchr(filetype, '.')) != NULL)
            filetype++;
        else /* Default to "auto" */
	    filetype = "auto";

	error = SndRead(fp, &aSound, filetype);
	error2 = fclose(fp);
	if (error2 == EOF) return SND_ERR_UNKNOWN;
	*sound = aSound;
	return error;
}

int SndWriteSoundfile(const char *path, SndSoundStruct *sound)
{
	int error,error2;
	int fd;
	if (!path) return SND_ERR_BAD_FILENAME;
	if (!strlen(path)) return SND_ERR_BAD_FILENAME;
#ifdef WIN32
        fd = open(path, O_BINARY | O_WRONLY | O_CREAT | O_TRUNC, 0644);
#else
        fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
#endif
        if (fd == -1) return SND_ERR_CANNOT_OPEN;
	error = SndWrite(fd, sound);
	error2 = close(fd);
	if (error2 == -1) return SND_ERR_UNKNOWN;
	return error;
}

int SndWriteHeader(int fd, SndSoundStruct *sound)
{
	SndSoundStruct *s;
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int headerSize;
	int df;
	int i;

	if (fd == 0) return SND_ERR_CANNOT_OPEN;
	df = sound->dataFormat;
	if (df == SND_FORMAT_INDIRECT) headerSize = sound->dataSize;
	else headerSize = sound->dataLocation;
	/* make new header with swapped bytes if nec */
	if (!(s = malloc(headerSize))) return SND_ERR_CANNOT_ALLOC;
	memmove(s,sound,headerSize);
	if (df == SND_FORMAT_INDIRECT) {
		int newCount = 0;
		i = 0;
		s->dataFormat = ((SndSoundStruct *)(*((SndSoundStruct **)
				(sound->dataLocation))))->dataFormat;
		ssList = (SndSoundStruct **)sound->dataLocation;
		while ((theStruct = ssList[i++]) != NULL)
			newCount += theStruct->dataSize;
		s->dataLocation = s->dataSize;
		s->dataSize = newCount;
	}

#ifdef __LITTLE_ENDIAN__
	s->magic = ntohl(s->magic);
	s->dataLocation = ntohl(s->dataLocation);
	s->dataSize = ntohl(s->dataSize);
	s->dataFormat = ntohl(s->dataFormat);
	s->samplingRate = ntohl(s->samplingRate);
	s->channelCount = ntohl(s->channelCount);
#endif
	if (write(fd, s, headerSize) != headerSize) { free(s); return SND_ERR_CANNOT_WRITE; }
	free(s);
	return SND_ERR_NONE;
}

int SndWrite(int fd, SndSoundStruct *sound)
{
	SndSoundStruct *s;
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int error;
	int headerSize;
	int df;
	int i,j=0;

	if (fd == 0) return SND_ERR_CANNOT_OPEN;
	df = sound->dataFormat;
	if (df == SND_FORMAT_INDIRECT) headerSize = sound->dataSize;
	else headerSize = sound->dataLocation;
	/* make new header with swapped bytes if nec */
	if (!(s = malloc(headerSize))) return SND_ERR_CANNOT_ALLOC;
	memmove(s,sound,headerSize);
	if (df == SND_FORMAT_INDIRECT) {
		int newCount = 0;
		i = 0;
		s->dataFormat = ((SndSoundStruct *)(*((SndSoundStruct **)
				(sound->dataLocation))))->dataFormat;
		ssList = (SndSoundStruct **)sound->dataLocation;
		while ((theStruct = ssList[i++]) != NULL)
			newCount += theStruct->dataSize;
		s->dataLocation = s->dataSize;
		s->dataSize = newCount;
	}

#ifdef __LITTLE_ENDIAN__
	s->magic = ntohl(s->magic);
	s->dataLocation = ntohl(s->dataLocation);
	s->dataSize = ntohl(s->dataSize);
	s->dataFormat = ntohl(s->dataFormat);
	s->samplingRate = ntohl(s->samplingRate);
	s->channelCount = ntohl(s->channelCount);
#endif
	if (write(fd, s, headerSize) != headerSize) { free(s); return SND_ERR_CANNOT_WRITE;};

	if (df != SND_FORMAT_INDIRECT) { /* simple read/write of block of data */
		error = write(fd,(char *)sound + sound->dataLocation,sound->dataSize);
		if (error <= 0) {
			free(s);
			return SND_ERR_CANNOT_WRITE;
		}
		if (error != sound->dataSize) {
			printf("File write seems to have been truncated!"
					" Wrote %d data bytes, tried %d\n",error, sound->dataSize);
		}
		free(s);
		return SND_ERR_NONE;
	}
	/* more difficult -- fragged data */

	ssList = (SndSoundStruct **)sound->dataLocation;
	free(s);
	while ((theStruct = ssList[j++]) != NULL) {
		error = write(fd,(char *)theStruct + theStruct->dataLocation, theStruct->dataSize);
		if (error <= 0) {
			return SND_ERR_CANNOT_WRITE;
		}
		if (error != theStruct->dataSize) {
			printf("File write seems to have been truncated! Wrote %d data bytes, tried %d\n",
				error, theStruct->dataSize);
		}
	}
	return SND_ERR_NONE;
}

int SndSwapSoundToHost(void *dest, void *src, int sampleCount, int channelCount, int dataFormat)
{
#ifdef __BIG_ENDIAN__
	return SND_ERR_NONE;
#else
	int numBytes = SndSampleWidth(dataFormat);
	int i;
	int samples = sampleCount * channelCount;
	if (numBytes == 1) return SND_ERR_NONE;
	if (numBytes == 2) {
		for (i = 0 ; i < samples; i++) {
			((signed short *)dest)[i] = (signed short)ntohs(((signed short *)src)[i]);
		}
		return SND_ERR_NONE;
	}
	if (dataFormat == SND_FORMAT_FLOAT) {
		for (i = 0 ; i < samples; i++) {
			SndSwappedFloat toSwap = ((SndSwappedFloat *)src)[i];
			((float *)dest)[i] = (float)SndSwapSwappedFloatToHost(toSwap);
		}
		return SND_ERR_NONE;
	}
	if (dataFormat == SND_FORMAT_DOUBLE) {
		for (i = 0 ; i < samples; i++) {
			SndSwappedDouble toSwap = ((SndSwappedDouble *)src)[i];
			((double *)dest)[i] = (double)SndSwapSwappedDoubleToHost(toSwap);
		}
		return SND_ERR_NONE;
	}
	printf("SndSoundSwap: format not currently supported, sorry.\n");
	return SND_ERR_BAD_FORMAT;
#endif 
}
int SndSwapHostToSound(void *dest, void *src, int sampleCount, int channelCount, int dataFormat)
{
#ifdef __BIG_ENDIAN__
	return SND_ERR_NONE;
#else
	int numBytes = SndSampleWidth(dataFormat);
	int i;
	int samples = sampleCount * channelCount;
	if (numBytes == 1) return SND_ERR_NONE;
	if (numBytes == 2) {
		for (i = 0 ; i < samples; i++) {
			((signed short *)dest)[i] = (signed short)htons(((signed short *)src)[i]);
		}
		return SND_ERR_NONE;
	}
	if (dataFormat == SND_FORMAT_FLOAT) {
		for (i = 0 ; i < samples; i++) {
			((SndSwappedFloat *)dest)[i] = 
				(SndSwappedFloat)SndSwapHostToSwappedFloat(((float *)src)[i]);
		}
		return SND_ERR_NONE;
	}
	if (dataFormat == SND_FORMAT_DOUBLE) {
		for (i = 0 ; i < samples; i++) {
			((SndSwappedDouble *)dest)[i] = 
				(SndSwappedDouble)SndSwapHostToSwappedDouble(((double *)src)[i]);
		}
		return SND_ERR_NONE;
	}
	printf("SndSoundSwap: format not currently supported, sorry.\n");
	return SND_ERR_BAD_FORMAT;

#endif 
}

