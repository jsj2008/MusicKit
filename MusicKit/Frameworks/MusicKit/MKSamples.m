/*
  $Id$
  Defined In: The MusicKit

  Description:
    The MKSamples object allows you to use a Snd as data in DSP synthesis.
    The most common use is as a wavetable table for an oscillator.
    You may set the sound from a Snd object or from a sound file using
    setSound: or readSoundfile:.

    Access to the data, is provided by the superclass, MKWaveTable.
    MKSamples currently does not provide resampling functionality.
    Hence, it is an error to ask for an array length other than the
    length of the original Snd passed to the object.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.10  2003/08/04 21:23:22  leighsmith
  Changed typing of several variables and parameters to avoid warnings of mixing comparisons between signed and unsigned values. Removed use of NSSound, now only uses Snd class

  Revision 1.9  2003/06/20 20:27:08  leighsmith
  Changed Snd -sampleCount to lengthInSampleFrames

  Revision 1.8  2002/04/15 14:22:35  sbrandon
  - set a couple of ivars to nil after releasing, in -init
  - added -hash and -isEqual: methods to aid in situations where object is
    used as a key in dictionaries or maptables.

  Revision 1.7  2002/04/03 03:59:41  skotmcdonald
  Bulk = NULL after free type paranoia, lots of ensuring pointers are not nil before freeing, lots of self = [super init] style init action

  Revision 1.6  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.5  2001/08/07 16:16:11  leighsmith
  Corrected class name during decode to match latest MK prefixed name

  Revision 1.4  2000/04/20 21:33:12  leigh
  Added extra methods to allow processing regions of samples

  Revision 1.3  2000/03/11 01:22:19  leigh
  Now using NSSound to replace Snd. This means removing functionality until NSSound is full-featured

  Revision 1.2  1999/07/29 01:16:42  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  12/4/89 /daj - Fixed normalization in fillTableLength:scale:.
   3/19/90/daj - Added MKGet/SetSamplesClass().
  03/21/90/daj - Added archiving.
  03/21/90/daj - Small changes to quiet -W compiler warnings.
  08/27/90/daj - Changed to zone API.
  07/25/91/daj - Fixed bug in _writeScorefileStream:. Was writing wrong for
                 ASCII scorefile.
  05/31/92/daj - Changed invocation of newFromSoundfile: to initFromSoundFile:
                 for 3.0
   12/11/93/daj - Added byte swapping for Intel hardware.
   1/27/96/daj - Plugged leak in readSoundfile:
*/
#import "_musickit.h"
#import "_scorefile.h"
#import "_error.h"
#import "MKSamples.h"

@implementation MKSamples

static id theSubclass = nil;

BOOL MKSetSamplesClass(id aClass)
{
    if (!_MKInheritsFrom(aClass,[MKSamples class]))
      return NO;
    theSubclass = aClass;
    return YES;
}

id MKGetSamplesClass(void)
{
    if (!theSubclass)
      theSubclass = [MKSamples class];
    return theSubclass;
}

#define VERSION2 2

+ (void)initialize
{
/* Changed by Nick 8/11/95 */
/*    if (self != [MKEnvelope class]) */
    if (self == [MKEnvelope class])  
      return;
    [MKSamples setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

-  init
  /* This method is ordinarily invoked only by the superclass when an 
     instance is created. You may send this message to reset the object. */ 

{
    [super init];
    /*sound = */
    if (sound) [sound release];/*sb: used to be sound free*/
    if (soundfile) [soundfile release];
    sound  = nil;
    soundfile = nil;

    tableType = MK_oscTable;
    return self;
}

- (unsigned) hash
{
//trivial hash
  return [sound hash] + 256 * tableType + 23 * curLoc + 32767 * amplitude
    + 512 * startSampleLoc + 1024 * lastSampleLoc + [soundfile length];
}

- (BOOL) isEqual: (MKSamples *)anObject
{
    if (!anObject)                           return NO;
    if (self == anObject)                    return YES;
    if ([self class] != [anObject class])    return NO;
    if ([self hash] != [anObject hash])      return NO;
    if (![soundfile isEqual:[anObject soundfile]])     return NO;
    if (sound != [anObject sound])           return NO;
    if (startSampleLoc != [anObject processingStartSample]) return NO;
    if (lastSampleLoc != [anObject processingEndSample])   return NO;

    return [super isEqual:anObject];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeValuesOfObjCTypes: "@@", &sound, &soundfile];/* sb was @* */
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ([aDecoder versionForClassName: @"MKSamples"] >= VERSION2) 
      [aDecoder decodeValuesOfObjCTypes: "@@", &sound, &soundfile];/* sb was @* */
    return self;
}

- (void)dealloc
  /* Frees object and Sound. */
{
    if (sound) [sound release];
    if (soundfile) [soundfile release];
    [super dealloc];
}

- copyWithZone:(NSZone *)zone
  /* Copies receiver. Copies the Sound as well. */
{
    MKSamples *newObj = [super copyWithZone:zone];
    newObj->soundfile = [soundfile copyWithZone:zone];
    newObj->sound     = [sound copyWithZone:zone];
    return newObj;
}

- (BOOL) readSoundfile: (NSString *) aSoundfile 
/* Creates a sound object from the specified file and initializes the
   receiver from the data in that file. Implemented in terms of 
   setSound:. This method creates a Sound object which is owned
   by the receiver. You should not free the Sound. 
   
   Returns self or nil if there's an error. */
{
    Snd *aTmpSound = [[Snd alloc] initFromSoundfile: aSoundfile];

    if (!aTmpSound)
      return NO;
    if (![self setSound: aTmpSound]) {
	[aTmpSound release];
	if (soundfile)
	    [soundfile release];
	return NO;
    }
    if (soundfile)
	[soundfile autorelease]; /* gets rid of old one! */
    soundfile = [aSoundfile copy];
    [aTmpSound release]; /* It's copied by setSound: */
    return YES; //sb: was self
}

/* Sets the Sound of the MKSamples object to be aSoundObj.
   aSoundObj must be in 16-bit linear mono format. If not, setSound: returns
   nil. aSoundObj is copied.
*/
- (BOOL) setSound: (Snd *) aSoundObj //sb: originally returned self/nil -- now BOOL.
{
    if (!aSoundObj)
      return FALSE;
    if (sound)
	[sound autorelease];/*sb: gets rid of old one*/
    length = 0; /* This ensures that the superclass recomputes cached buffers. */ 
    sound = [aSoundObj copy];
    [sound convertToFormat: SND_FORMAT_LINEAR_16
              samplingRate: [sound samplingRate]
              channelCount: 1];
    curLoc = 0;
    return TRUE;
}

- _writeScorefileStream:(NSMutableData *)aStream binary:(BOOL)isBinary
{
    NSString* tempSoundFile;
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (isBinary)
      _MKWriteChar(aStream,'\1'); /* Marks it as Sample rather than MKPartials */
    if (!soundfile) {
	/* Generate file name and write samples. */  
	int i = 0;
        BOOL error = NO;

        tempSoundFile = @"samples.snd";
	for (; ;) {                         /* Keep trying until success */
            if([manager fileExistsAtPath: tempSoundFile] != YES)
                break;                       /* File doesn't exist. */
            tempSoundFile = [NSString stringWithFormat: @"samples%d.snd", (++i)];
        }
        [soundfile autorelease];
        soundfile = [tempSoundFile copy];
        error = [sound writeSoundfile:soundfile];
        if (error) { 
            [soundfile release];
	    soundfile = nil;
	    /*** FIXME Print sound error code here. ***/ 
	    if (isBinary)
	        _MKWriteString(aStream,"/dev/null");
	    else
                [aStream appendData:[@"{\"/dev/null\"}" dataUsingEncoding:NSNEXTSTEPStringEncoding]];      /* Not very good */
	    return nil;
	}
    }
    if (isBinary)
	_MKWriteNSString(aStream,soundfile);
    else
        [aStream appendData: [[NSString stringWithFormat: @"{\"%@\"}", soundfile] 
                 dataUsingEncoding: NSNEXTSTEPStringEncoding]];
    return self;
}

/* This method is used by the Music Kit to reference the receiver in 
   a scorefile. There are two cases, depending whether the Sound was set
   with readSoundfile: or setSound:.

   If the data was set with readSoundfile, just writes the file name in the
   scorefile. 

   If the data was set with setSound:, generates a new soundfile name of 
   the form "samples<number>.snd",
   writes that soundfile name to the scorefile, and writes a
   soundfile with the auto-generated name on the current directory.
   The soundfile name is guaranteed to be unique on the current directory.
   Also remembers that the file's been written and what its name is so that 
   future references to the MKSamples object use the same name and don't 
   rewrite the file.

   */
- writeScorefileStream:(NSMutableData *)aStream
{
    return [self _writeScorefileStream:aStream binary:NO];
}

- _writeBinaryScorefileStream:(NSMutableData *)aStream
{
    return [self _writeScorefileStream:aStream binary:YES];
}

- (Snd *) sound
/* Returns the Snd object. */
{
    return sound;
}

-(NSString *) soundfile
/* Returns the name of the soundfile from which the data was 
   obtained, if any. The receiver should not alter this string. 
   If the data was obtained using setSound:,
   returns a nil. 
   */
{
    return soundfile;
}

// Methods for setting and using processing sub-regions

- (void) setProcessingStartSample: (unsigned int) sampleNum
{
    startSampleLoc = sampleNum;
}

- (unsigned int) processingStartSample
{
    return startSampleLoc;
}

- (void) setProcessingEndSample: (unsigned int) sampleNum
{
    lastSampleLoc = sampleNum;
}

- (unsigned int) processingEndSample
{
    return lastSampleLoc;
}

- (unsigned int) currentSample
{
    return curLoc;
}

- (void) setCurrentSample: (unsigned int) sampleNum
{
    curLoc = sampleNum;
}

- (double) amplitude
    /* returns the amplitude scaling */
{
    return amplitude;
}

- (void) setAmplitude: (double) newAmp;
    /* assigns an amplitude scaling */
{
    amplitude = newAmp;
}

/* 

I favor left shifting because there is a truncation of 8 bits
when going to the dacs.  If you are going straight through and don't
left shift, you lose the 8 bits.  I think it is better to assume that
no scaling is going to take place.

As for leaving headroom, I prefer to deal with scaling down when
necessary, rather than scaling up.  This means you are generally
always working in the high order bits by default, leading to naturally
better S/N on output.

Probably we should make it optional (with shifting as the default).
- Mike Mcnabb

It should not be necessary to left-shift 8 bits to convert 16 to 24.  We
download 16-bit data by really writing two bytes per word.  If it really
will be treated as 24 bits, then you have your choice.  Left-shifting is
reasonable (maxamp in 16 => maxamp in 24) but it leaves you no dynamic
range for growth.  If you don't left-shift, you do have to sign extend.
- Julius Smith

Since the MKSamples object has a scale factor argument in its
fileTableLength:scale: method, you can always 'get there from here'.
Therefore, we can pick one or the other method and anyone can get the
desired effect by scaling. So it's a flip of a coin. I'm currently
doing the shift so this is how I'm leaving it, unless I get argued out
of it.
- David Jaffe

*/

- _fillTableLength:(int)aLength scale:(double)aScaling 
  /* Private method that supports both osc and excitation tables */
{
    /*** FIXME Eventually allow double and other format Sounds and avoid
      losing precision in this case. ***/
    int originalLength, inc;
    short *data,*end;
    DSPDatum  *newData;
    if (!sound)
      return nil;
    originalLength = [sound lengthInSampleFrames];
    if (aLength == 0)
      aLength = originalLength;
    if (tableType == MK_oscTable) {
	inc = originalLength/aLength;
	if (inc * aLength != originalLength) 
	  return _MKErrorf(MK_samplesNoResampleErr);
    } else inc = 1;

    /* The above allows us to down-sample a waveform. If the Sound's size is an
       multiple of the desired length, we can do cheap sampling rate 
       conversion. */

    if (dataDSP) {
      free(dataDSP);
      dataDSP = NULL;
    }
    _MK_MALLOC(dataDSP, DSPDatum, aLength);
    if (dataDouble) {
      free(dataDouble);
      dataDouble = NULL;
    }
    length = aLength;
    scaling = aScaling;
    data = (short *)[sound data]; 
    if (tableType == MK_oscTable)
      end = data + originalLength;
    else 
      end = data + MIN(aLength,originalLength);
    /* We only compute dataDouble here if scaling is not 1.0. The point is
       that if we have to do scaling, we might as well compute dataDouble
       while we're at it, since we have to do mutliplies anyway.  On the
       other hand, if scaling is 1.0, we don't bother with dataDouble here
       and only create it in superclass on demand. */
    if (scaling == 1.0) {
	short wd;
	newData = dataDSP;
	while (data < end) {
	  wd = NSSwapBigShortToHost(*data);
	  *newData++ = (((int) wd) << 8); /* Coercion to int does sign
						extension. */
	  data += inc;
	}
	while (newData < dataDSP+aLength)  /* This can happen when lengthening */
	  *newData++ = 0;
    }
    else {
	double scaler;
	short val;
	register double *dbl;
	newData = dataDSP;
    	if (aScaling == 0.0) {
	    /* if normalizing, find the maximum amplitude. */
	    short maxval;
    	    maxval = 0;   
    	    while (data < end) {
		val = NSSwapBigShortToHost(*data);
	        val = (val < 0) ? -val : val;        /* Abs value */
		data += inc;
    	        if (val > maxval) 
		  maxval = val; 
	    }	
	    if (maxval > 24573) {  /* Don't bother if we're close */
		/* 24573 is (0x7fff * .75) */
	        data = (short *)[sound data]; 
		while (data < end) {         /* Same as above. */
		    val = NSSwapBigShortToHost(*data);
		    *newData++ = (((int) val) << 8); 
		    data += inc;
		}
		while (newData < dataDSP+aLength)  /* Happens when lengthening */
		  *newData++ = 0;
		return self;
	    }
    	    scaler = (1.0 / (double)maxval);  
	}
        else scaler = scaling / (double)(0x7fff); 

	/* This should be rewritten to use fixed point arithmetic and to not
	   fill dataDouble. FIXME */
    	data = (short *)[sound data];
	_MK_MALLOC(dataDouble, double, aLength);
	dbl = dataDouble;
        while (data < end) {
	    val = NSSwapBigShortToHost(*data);
	    *dbl = val * scaler; 
	    data += inc;
    	    *newData++ = _MKDoubleToFix24(*dbl++);
	}
	while (newData < dataDSP+aLength) { /* This can happen when lengthening */
	    *newData++ = 0;
	    *dbl++ = 0.0;
	}
    }
    return self;
}

-(int)tableType
{
    return tableType;
}

@end

@implementation MKSamples(OscTable)

- fillTableLength:(int)aLength scale:(double)aScaling 
/* Default version returns table as oscTable.

   It is currently an error to ask for a length other than an integral
   division of the original data length. If the requested length is an
   integral division, the appropriate number of samples are skipped when
   copying the data into the data buffer.
   Returns self or nil if there's a problem. */
{
    tableType = MK_oscTable;
    return [self _fillTableLength:aLength scale:aScaling];
}

- fillOscTableLength:(int)aLength scale:(double)aScaling 
{
    return [self fillTableLength:aLength scale:aScaling];
}

- (DSPDatum *) dataDSPAsOscTableLength:(int)aLength;
{
    return [self dataDSPLength:aLength];
}
 
- (double *)dataDoubleAsOscTableLength:(int)aLength;
{
    return [self dataDoubleLength:aLength];
}

- (DSPDatum *) dataDSPAsOscTableScale:(double)aScaling;
{
    return [self dataDSPScale:aScaling];
}
 
- (double *)dataDoubleAsOscTableScale:(double)aScaling;
{
    return [self dataDoubleScale:aScaling];
}

- (double *) dataDoubleAsOscTable
{
    return [self dataDouble];
}

- (DSPDatum *) dataDSPAsOscTable
{
    return [self dataDSP];
}

@end

@implementation MKSamples(ExcitationTable)

- fillExcitationTableLength:(int)aLength scale:(double)aScaling 
/* Default version returns table as oscTable.

   It is currently an error to ask for a length other than an integral
   division of the original data length. If the requested length is an
   integral division, the appropriate number of samples are skipped when
   copying the data into the data buffer.
   Returns self or nil if there's a problem. */
{
    tableType = MK_excitationTable;
    return [self _fillTableLength:aLength scale:aScaling];
}

- (DSPDatum *) dataDSPAsExcitationTableLength: (unsigned int) aLength scale: (double) aScaling
{
   if ((tableType != MK_excitationTable) || 
       (length != aLength) || (scaling != aScaling) || (length == 0))
     if (![self fillExcitationTableLength:aLength scale:aScaling])
       return NULL;
   if (!dataDSP && dataDouble) {
       _MK_MALLOC(dataDSP, DSPDatum, length);
       if (!dataDSP) return NULL;
       _MKDoubleToFix24Array(dataDouble, dataDSP, length);
   } 
   return dataDSP;
}

- (double *) dataDoubleAsExcitationTableLength: (unsigned int) aLength scale: (double) aScaling
{  
   if ((tableType != MK_excitationTable) || 
       (length != aLength) || (scaling != aScaling) || (length == 0))
     if (![self fillExcitationTableLength:aLength scale:aScaling])
       return NULL;
   if (!dataDouble && dataDSP) {
       _MK_MALLOC (dataDouble, double, length);
       if (!dataDouble) return NULL;
       _MKFix24ToDoubleArray (dataDSP, dataDouble, length);
   } 
   return dataDouble;
}

- (DSPDatum *)dataDSPAsExcitationTable
{
    return [self dataDSPAsExcitationTableLength:length scale:scaling];
}

- (double *)dataDoubleAsExcitationTable
{
    return [self dataDoubleAsExcitationTableLength:length scale:scaling];
}

- (DSPDatum *)dataDSPAsExcitationTableLength:(int)aLength
{
    return [self dataDSPAsExcitationTableLength:aLength scale:scaling];
}

- (double *)dataDoubleAsExcitationTableLength:(int)aLength
{
    return [self dataDoubleAsExcitationTableLength:aLength scale:scaling];
}

- (DSPDatum *)dataDSPAsExcitationTableScale:(double)aScaling
{
    return [self dataDSPAsExcitationTableLength:length scale:aScaling];
}

- (double *)dataDoubleAsExcitationTableScale:(double)aScaling
{
    return [self dataDoubleAsExcitationTableLength:length scale:aScaling];
}

@end
