
#import "Controller.h"
#ifdef WIN32
# import <Foundation/NSPathUtilities.h>
# import <AppKit/NSSound.h>
#endif

/* number of seconds of sound to display */
#define SECONDS 0.2
#define TWOPI 6.28318530718
#define SAMPLING_RATE 44100
#define SINWAVE(srate,freq,amp,pos) (amp * sin(freq * TWOPI * pos/srate))
#define COSWAVE(srate,freq,amp,pos) (amp * cos(freq * TWOPI * pos/srate))
#define SQUAREWAVE(srate,freq,amp,pos) ((pos%(int)(srate / freq) < (srate/freq/2)) ? amp : 0-amp)
#define SAWTOOTH(srate,freq,amp,pos) (2 * amp * (pos%(int)(srate / freq)) / (srate/freq) - amp)
#define REVSAWTOOTH(srate,freq,amp,pos) (-(2 * amp * (pos%(int)(srate / freq)) / (srate/freq) - amp))
#define TRIANGLE(srate,freq,amp,pos) ((pos%(int)(srate / freq) < (srate/freq/2)) ? \
                                      (2 * amp * (pos%(int)(srate / freq)) / (srate/freq/2) - amp) :\
                                      (-(2 * amp * (pos%(int)(srate / freq)) / (srate/freq/2) - 3 * amp)))

static BOOL clipping = NO;

@implementation Controller

- init
{
	return [super init];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    float redFact;
	NSRect theFrame;
#ifdef WIN32
        playsound = nil;
        tempfile = nil;
#endif
	theFrame = [sound1 frame];
	[sound1 setAutoscale:YES];
	[sound2 setAutoscale:YES];
        [sound3 setAutoscale:YES];
        [sound1 setEditable:NO];
        [sound2 setEditable:NO];
        [sound3 setEditable:NO];
        [sound1 setDisplayMode:NX_SOUNDVIEW_WAVE];
        [sound2 setDisplayMode:NX_SOUNDVIEW_WAVE];
        [sound3 setDisplayMode:NX_SOUNDVIEW_WAVE];
        [sound1 setOptimizedForSpeed:NO];
        [sound2 setOptimizedForSpeed:NO];
        [sound3 setOptimizedForSpeed:NO];

        soundLength = [sLength floatValue];
	if (soundLength < 0 || soundLength > 20) {
		soundLength = 6;
		[sLength setFloatValue:soundLength];
		}
	type1 = 0;
	type2 = 0;
        theSound1 = [[Snd alloc] init] ;
        theSound2 = [[Snd alloc] init] ;
        theSound3 = [[Snd alloc] init] ;
        newSound = [[Snd alloc] init] ;
        [theSound1 setDataSize:SAMPLING_RATE * 2 * SECONDS 
		dataFormat:SND_FORMAT_LINEAR_16
                                samplingRate:SAMPLING_RATE 
		channelCount:1 
		infoSize:0];
        [theSound2 setDataSize:SAMPLING_RATE * 2 * SECONDS 
		dataFormat:SND_FORMAT_LINEAR_16
                                samplingRate:SAMPLING_RATE 
		channelCount:1 
		infoSize:0];
        [theSound3 setDataSize:SAMPLING_RATE * 2 * SECONDS 
		dataFormat:SND_FORMAT_LINEAR_16
                                samplingRate:SAMPLING_RATE 
		channelCount:1 
		infoSize:0];
        newSound = nil;
        redFact = SAMPLING_RATE * SECONDS / theFrame.size.width;
	[sound1 setReductionFactor:redFact];
	[sound2 setReductionFactor:redFact];
	[sound3 setReductionFactor:redFact];
	[(SndView *)sound1 setSound:theSound1];
        [(SndView *)sound2 setSound:theSound2];
        [(SndView *)sound3 setSound:theSound3];
	[self calcSound1];
	[self calcSound2];
	[self calcSound3];

        [sound1 invalidateCacheStartPixel:0 end:-1];
        [sound2 invalidateCacheStartPixel:0 end:-1];
        [sound3 invalidateCacheStartPixel:0 end:-1];
	[sound1 display];
	[sound2 display];
	[sound3 display];
	somethingChanged = YES;
}

void doCalc(int type, short *pointer, float theFreq, float theAmp)
{
	int i;
	switch (type) {
		case 0: /*sine*/
		default:
                    for (i = 0;i<SECONDS * SAMPLING_RATE;i++) {
                        pointer[i] = SINWAVE(SAMPLING_RATE,theFreq, theAmp,i);
			}
			break;
		case 1:  /*cosine*/
                    for (i = 0;i<SECONDS * SAMPLING_RATE;i++) {
                        pointer[i] = COSWAVE(SAMPLING_RATE,theFreq, theAmp,i);
			}
			break;
		case 2:  /*square*/
                    for (i = 0;i<SECONDS * SAMPLING_RATE;i++) {
                        pointer[i] = SQUAREWAVE(SAMPLING_RATE,theFreq, theAmp,i);
			}
			break;
		case 3:  /*sawtooth*/
                    for (i = 0;i<SECONDS * SAMPLING_RATE;i++) {
                        pointer[i] = SAWTOOTH(SAMPLING_RATE,theFreq, theAmp,i);
			}
			break;
		case 4:  /*rev sawtooth*/
                    for (i = 0;i<SECONDS * SAMPLING_RATE;i++) {
                        pointer[i] = REVSAWTOOTH(SAMPLING_RATE,theFreq, theAmp,i);
			}
			break;
		case 5:  /*triangle*/
                    for (i = 0;i<SECONDS * SAMPLING_RATE;i++) {
                        pointer[i] = TRIANGLE(SAMPLING_RATE,theFreq, theAmp,i);
			}
			break;
	}
        SndSwapHostToSound(pointer, pointer, SECONDS * SAMPLING_RATE, 1,SND_FORMAT_LINEAR_16);
}

- calcSound1
{
	float theFreq,theAmp;
	short *pointer = (short *)[(Snd *)[sound1 sound] data];
	theAmp = [volNum1 floatValue] * 32768 / 10;
	theFreq = [freqNum1 floatValue];
	doCalc(type1, pointer, theFreq, theAmp);
	return self;
}

- calcSound2
{
	float theFreq,theAmp;
    short *pointer = (short *)[(Snd *)[sound2 sound] data];
	theFreq = [freqNum2 floatValue];
	theAmp = [volNum2 floatValue] * 32768 / 10;
	doCalc(type2, pointer, theFreq, theAmp);
	return self;
}

- calcSound3
{
	int i,newVal;
    short *pointer1 = (short *)[(Snd *)[sound1 sound] data];
    short *pointer2 = (short *)[(Snd *)[sound2 sound] data];
    short *pointer3 = (short *)[(Snd *)[sound3 sound] data];
        for (i = 0;i<SECONDS * SAMPLING_RATE;i++) {
            newVal = (signed short)NSSwapBigShortToHost(pointer1[i]) + (signed short)NSSwapBigShortToHost(pointer2[i]);
            if (newVal > 32768 || newVal < -32767) clipping = YES;
            pointer3[i] = newVal;
            }
        SndSwapHostToSound(pointer3, pointer3, SECONDS * SAMPLING_RATE, 1,SND_FORMAT_LINEAR_16);
        if (clipping) {
            clipping = NO;
            [mesgBox setString:@"Combined amplitudes of sounds are too high and are causing clipping. Reduce amplitudes of one or both."];
        }
        else [mesgBox setString:@""];
        [mesgBox display];
	return self;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[theSound1 release];
	[theSound2 release];
	[theSound3 release];
	[newSound release];
#ifdef WIN32
        if (playsound)
            [playsound release];
        if (tempfile) {
            [[NSFileManager defaultManager] removeFileAtPath:tempfile handler:nil];
            [tempfile release];
        }
#endif
}

- (void)dealloc
{
        [super dealloc];
}

- playA:sender
{ /* 3 seconds */
    short *pointer;
    Snd *newSoundA = [[Snd alloc] init];
    int i;
    float amp1,freq1;
    [newSoundA setDataSize:SAMPLING_RATE * 3 * 2 
                dataFormat:SND_FORMAT_LINEAR_16
              samplingRate:SAMPLING_RATE 
              channelCount:1 
                  infoSize:0];

    amp1 = [volNum1 floatValue] * 32768 / 10;
    freq1 = [freqNum1 floatValue];
    pointer = (short *)[newSoundA data];
        for (i = 0;i<3*SAMPLING_RATE;i++) {
                    float num1;
                    switch (type1) {
                            case 0:
                            default:
                                num1 = (float)SINWAVE(SAMPLING_RATE,freq1,amp1,i);
                                break;
                            case 1:
                                num1 = (float)COSWAVE(SAMPLING_RATE,freq1,amp1,i);
                                break;
                            case 2:
                                num1 = (float)SQUAREWAVE(SAMPLING_RATE,freq1,amp1,i);
                                break;
                            case 3:
                                num1 = (float)SAWTOOTH(SAMPLING_RATE,freq1,amp1,i);
                                break;
                            case 4:
                                num1 = (float)REVSAWTOOTH(SAMPLING_RATE,freq1,amp1,i);
                                break;
                            case 5:
                                num1 = (float)TRIANGLE(SAMPLING_RATE,freq1,amp1,i);
                    }
                    pointer[i] = NSSwapHostShortToBig(num1);
            }
#ifdef WIN32
{
    id tempfileA;
    tempfileA = [NSTemporaryDirectory() stringByAppendingPathComponent:@"sptempa.snd"];
    [newSoundA writeSoundfile:tempfileA];
    [playsoundA release];
    playsoundA = [[NSSound alloc] initWithContentsOfFile:tempfileA byReference:NO];
    [[NSFileManager defaultManager] removeFileAtPath:tempfileA handler:nil];
    [playsoundA setDelegate:self];
    [(NSSound *)playsoundA play];
}
#endif
        return self;
}
- playB:sender
{ /* 3 seconds */
    short *pointer;
    Snd *newSoundB = [[Snd alloc] init];
    int i;
    float amp1,freq1;
    [newSoundB setDataSize:SAMPLING_RATE * 3 * 2 
                dataFormat:SND_FORMAT_LINEAR_16
              samplingRate:SAMPLING_RATE 
              channelCount:1 
                  infoSize:0];

    amp1 = [volNum2 floatValue] * 32768 / 10;
    freq1 = [freqNum2 floatValue];
    pointer = (short *)[newSoundB data];
        for (i = 0;i<3*SAMPLING_RATE;i++) {
                    float num1;
                    switch (type2) {
                            case 0:
                            default:
                                num1 = (float)SINWAVE(SAMPLING_RATE,freq1,amp1,i);
                                break;
                            case 1:
                                num1 = (float)COSWAVE(SAMPLING_RATE,freq1,amp1,i);
                                break;
                            case 2:
                                num1 = (float)SQUAREWAVE(SAMPLING_RATE,freq1,amp1,i);
                                break;
                            case 3:
                                num1 = (float)SAWTOOTH(SAMPLING_RATE,freq1,amp1,i);
                                break;
                            case 4:
                                num1 = (float)REVSAWTOOTH(SAMPLING_RATE,freq1,amp1,i);
                                break;
                            case 5:
                                num1 = (float)TRIANGLE(SAMPLING_RATE,freq1,amp1,i);
                    }
                    pointer[i] = NSSwapHostShortToBig(num1);
            }
#ifdef WIN32
{
    id tempfileB;
    tempfileB = [NSTemporaryDirectory() stringByAppendingPathComponent:@"sptempb.snd"];
    [newSoundB writeSoundfile:tempfileB];
    [playsoundB release];
    playsoundB = [[NSSound alloc] initWithContentsOfFile:tempfileB byReference:NO];
    [[NSFileManager defaultManager] removeFileAtPath:tempfileB handler:nil];
    [playsoundB setDelegate:self];
    [(NSSound *)playsoundB play];
}
#endif
        return self;
}

- play:sender
{
	short *pointer;
	int i;
	float amp1,amp2,freq1,freq2;
        float theLength = [sLength floatValue];
	amp1 = [volNum1 floatValue] * 32768 / 10;
	amp2 = [volNum2 floatValue] * 32768 / 10;
	freq1 = [freqNum1 floatValue];
	freq2 = [freqNum2 floatValue];
        [newSound release];
        newSound = [[Snd alloc] init];
        [newSound setDataSize:SAMPLING_RATE * 2 * theLength 
                dataFormat:SND_FORMAT_LINEAR_16
                               samplingRate:SAMPLING_RATE 
                channelCount:1 
                infoSize:0];

	pointer = (short *)[newSound data];
	if (somethingChanged) {
            for (i = 0;i<theLength*SAMPLING_RATE;i++) {
			float num1,num2;
			switch (type1) {
				case 0:
				default:
                                    num1 = (float)SINWAVE(SAMPLING_RATE,freq1,amp1,i);
                                    break;
				case 1:
                                    num1 = (float)COSWAVE(SAMPLING_RATE,freq1,amp1,i);
                                    break;
				case 2:
                                    num1 = (float)SQUAREWAVE(SAMPLING_RATE,freq1,amp1,i);
                                    break;
				case 3:
                                    num1 = (float)SAWTOOTH(SAMPLING_RATE,freq1,amp1,i);
                                    break;
				case 4:
                                    num1 = (float)REVSAWTOOTH(SAMPLING_RATE,freq1,amp1,i);
                                    break;
				case 5:
                                    num1 = (float)TRIANGLE(SAMPLING_RATE,freq1,amp1,i);
			}
			switch (type2) {
				case 0:
				default:
                                    num2 = (float)SINWAVE(SAMPLING_RATE,freq2,amp2,i);
                                    break;
				case 1:
                                    num2 = (float)COSWAVE(SAMPLING_RATE, freq2, amp2,i);
                                    break;
                                case 2:
                                    num2 = (float)SQUAREWAVE(SAMPLING_RATE, freq2, amp2,i);
                                    break;
                                case 3:
                                    num2 = (float)SAWTOOTH(SAMPLING_RATE, freq2, amp2,i);
                                    break;
				case 4:
                                    num2 = (float)REVSAWTOOTH(SAMPLING_RATE, freq2, amp2,i);
                                    break;
				case 5:
                                    num2 = (float)TRIANGLE(SAMPLING_RATE, freq2, amp2,i);
			}
                        pointer[i] = NSSwapHostShortToBig(num1 + num2);
		}
#ifdef WIN32
            {
                [tempfile release];
                tempfile = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"spectrotemp.snd"] retain];
                [newSound writeSoundfile:tempfile];
                [playsound release];
                playsound = [[NSSound alloc] initWithContentsOfFile:tempfile byReference:NO];
                [playsound setDelegate:self];
            }
#endif
	}
	somethingChanged = NO;
#ifdef WIN32
        [(NSSound *)playsound play];
#else
	[(Snd *)newSound play];
#endif
	return self;
}

- updateNums:sender
{
    double a,b;
    a = pow(10,[freqSlide1 floatValue]);
    b = pow(10,[freqSlide2 floatValue]);

    somethingChanged = YES;
    [freqNum1 setIntValue:a];
    [freqNum2 setIntValue:b];
    
    [volNum1 setFloatValue:0.01 * (int)([volSlide1 floatValue] * 100)];
    [volNum2 setFloatValue:0.01 * (int)([volSlide2 floatValue] * 100)];
    if (sender == volSlide1 || sender == freqSlide1) {
        [self calcSound1];
        [sound1 invalidateCacheStartPixel:0 end:-1];
        [sound1 display];
        }
    else if (sender == volSlide2 || sender == freqSlide2) {
        [self calcSound2];
        [sound2 invalidateCacheStartPixel:0 end:-1];
        [sound2 display];
        }
    [self calcSound3];
    [sound3 invalidateCacheStartPixel:0 end:-1];
    [sound3 display];
    return self;
}

- updateSliders:sender
{
	somethingChanged = YES;
	[freqSlide1 setFloatValue:log10([freqNum1 floatValue])];
        [freqSlide2 setFloatValue:log10([freqNum2 floatValue])];
	[volSlide1 setFloatValue:[volNum1 floatValue]];
	[volSlide2 setFloatValue:[volNum2 floatValue]];
        if ([sender selectedCell] == volNum1 || [sender selectedCell] == freqNum1) {
		[self calcSound1];
                [sound1 invalidateCacheStartPixel:0 end:-1];
		[sound1 display];
		}
        else if ([sender selectedCell] == volNum2 || [sender selectedCell] == freqNum2) {
		[self calcSound2];
                [sound2 invalidateCacheStartPixel:0 end:-1];
		[sound2 display];
	}
	[self calcSound3];
        [sound3 invalidateCacheStartPixel:0 end:-1];
	[sound3 display];
    return self;
}

- waveChanged:sender
{
	somethingChanged = YES;
	if (sender == waveType1) {
		type1 = [sender selectedRow];
		[self calcSound1];
                [sound1 invalidateCacheStartPixel:0 end:-1];
		[sound1 display];
	}
	if (sender == waveType2) {
		type2 = [sender selectedRow];
		[self calcSound2];
                [sound2 invalidateCacheStartPixel:0 end:-1];
		[sound2 display];
	}		
	[self calcSound3];
        [sound3 invalidateCacheStartPixel:0 end:-1];
	[sound3 display];
    return self;
}

- changeLength:sender
{
    somethingChanged = YES;
    return self;
}

- recalc
{

	return self;
}
@end
