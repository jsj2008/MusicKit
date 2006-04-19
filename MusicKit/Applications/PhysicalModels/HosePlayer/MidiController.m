
/* Generated by Interface Builder */

#import "MidiController.h"
#import "Controller.h"
#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#import <libc.h>

    int keyTable[20] = {52,53,55,57,59,60,62,64,65,67,69,71,72,74,76,77,79,81,83,84};
    float preset[32][4] = {{ 0.015,	16470.6,	0.1,	1.000000},                            //   Lowest E
    				      { 0.014,	16470.6,	0.1,	0.833333},
    				      { 0.012,	17647.0,	0.1,	0.666666},
    				      { 0.011,	 17647.0,	0.1,	0.500000},
    				      { 0.01,	18823.5,	0.1,	0.333333},
    				      { 0.01,	18823.5, 0.1,	0.166666},
     				      { 0.01,	18823.5,	0.1,	0.000000},                           //  Lowest B Flat
    				      { 0.008,	17467.1,	0.1,	1.000000},
    				      { 0.007,	17467.1,	0.1,	0.833333},
    				      { 0.006,	16470.0,	0.1,	0.666666},
    				      { 0.006,	17467.5,	0.1,	0.500000},
    				      { 0.006,	21176.5,	0.1,	0.333333},
    				      { 0.006,	23176.5,	0.1,	0.166666},                            //   E
    				      { 0.006,	27058.5,	0.1,	0.000000},
     				      { 0.0066,	32941.0,	0.1,	0.666666},
    				      { 0.004,	24705.5,	0.1,	0.500000},
    				      { 0.003,	21176.5,	0.1,	0.333333},
    				      { 0.003,	21176.5,	0.1,	0.166666},
    				      { 0.003,	21176.5,	0.1,	0.000000},                           //   B Flat
    				      { 0.002,	20000.0,	0.1,	0.500000},
    				      { 0.002,	20000.0,	0.1,	0.333333},
    				      { 0.002,	20000.0,	0.1,	0.166666},
    				      { 0.0024,	30588.2,	0.1,	0.080000},                           //  D    Slide Adjustment here
    				      { 0.002,	28235.0,	0.1,	0.333333},
    				      { 0.0018,	28235.0,	0.1,	0.222222},
    				      { 0.0018,	31764.0,	0.1,	0.080000},                           //  F    Slide Adjustment here
    				      { 0.001,	21175.8,	0.1,	0.333333},
    				      { 0.0012,	25881.6,	0.1,	0.188888},
    				      { 0.0012,	31763.5,	0.1,	0.022222},                          //  A Flat 
    				      { 0.0009,	28234.6,	0.1,	0.188888},
    				      { 0.0009,	31764.0,	0.1,	0.100000},
    				      { 0.0009,	32940.4,	0.1,	0.500000}};

@implementation MidiController


    - (void)reset
{
    register int i;
    /* Thin continuous controllers by default */
    for (i=0; i<67; i++) {
	lastVals[i] = 0;
	minVals[i] = 2;    /* Controls how severe is the thining by value */
	lastTimes[i] = -1000.0;
	minTimes[i] = .03; /* Controls how severe is the thining by time */
	action[i] = THIN;
    }
    /* Pass discrete controllers by default */
    for (i=68; i<131; i++) {
	lastVals[i] = 0;
	minVals[i] = 0;
	lastTimes[i] = -1000.0;
	minTimes[i] = 0.0;
	action[i] = PASS;
    }
    minVals[MIDI_BALANCE] = 3;
    minVals[128] = 2048; /* pitch bend */
    minTimes[128] = .3;
    action[128] = THIN;  /* Set to STOP to block all pitch bend. */
    minVals[129] = 2;    /* aftertouch */
    minTimes[129] = .03;
    action[129] = THIN;
}

-init
    /* Sent when an instance is created. */
{    
    [super init];
    noteReceiver = [self addNoteReceiver:[[MKNoteReceiver alloc] init]];
//    noteSender = [self addNoteSender:[[NoteSender alloc] init]];
    [self reset];
    return self;
}

-realizeNote:aNote fromNoteReceiver:aNoteReceiver
    /* Here's where the work is done.
     */
{
    int i,j;
    double velocity;
    if (MKIsNoteParPresent(aNote,MK_sysRealTime)) {
	switch (MKGetNoteParAsInt(aNote,MK_sysRealTime)) {
	  case MK_sysReset: [self reset]; break;
	}
    }
    if ([aNote noteType] == MK_noteOn)	{
	if ([aNote keyNum] != lastKeyNum)	{
	    lastKeyNum = [aNote keyNum];
	    j = -1;
	    while (lastKeyNum>84) lastKeyNum -= 12;
	    while (lastKeyNum<52) lastKeyNum += 12;
	    if (![fastMode state])	{
		for (i=0;i<20;i++) if (lastKeyNum==keyTable[i]) j = i;
		if (j>=0) [[whiteKeys cellAtRow:0 column:j] performClick:self];
		else {
	             if (lastKeyNum==54) [[blackKeys1 cellAtRow:0 column:0] performClick:self];
	             if (lastKeyNum==56) [[blackKeys1 cellAtRow:0 column:1] performClick:self];
	             if (lastKeyNum==58) [[blackKeys1 cellAtRow:0 column:2] performClick:self];
	             if (lastKeyNum==61) [[blackKeys2 cellAtRow:0 column:0] performClick:self];
	             if (lastKeyNum==63) [[blackKeys2 cellAtRow:0 column:1] performClick:self];
	             if (lastKeyNum==66) [[blackKeys3 cellAtRow:0 column:0] performClick:self];
	             if (lastKeyNum==68) [[blackKeys3 cellAtRow:0 column:1] performClick:self];
	             if (lastKeyNum==70) [[blackKeys3 cellAtRow:0 column:2] performClick:self];
	             if (lastKeyNum==73) [[blackKeys4 cellAtRow:0 column:0] performClick:self];
	             if (lastKeyNum==75) [[blackKeys4 cellAtRow:0 column:1] performClick:self];
	             if (lastKeyNum==78) [[blackKeys5 cellAtRow:0 column:0] performClick:self];
	             if (lastKeyNum==80) [[blackKeys5 cellAtRow:0 column:1] performClick:self];
	             if (lastKeyNum==82) [[blackKeys5 cellAtRow:0 column:2] performClick:self];
	         }
	    }
	    else 	{
		[[lipSliders cellAtRow:0 column:0] setFloatValue:preset[lastKeyNum - 52][0]];
		[[lipSliders cellAtRow:0 column:1] setFloatValue:preset[lastKeyNum - 52][1]];
		[[lipSliders cellAtRow:0 column:2] setFloatValue:preset[lastKeyNum - 52][2]];
		[[slide cellAtRow:0 column:0] setFloatValue:preset[lastKeyNum - 52][3]];
		[[slide cellAtRow:1 column:0] setFloatValue:preset[lastKeyNum - 52][3]];
		[myHornController changeLip:lipSliders];
		[myHornController changeSlideQuick:preset[lastKeyNum - 52][3]];
	    }
	}
	velocity = [aNote parAsDouble: MK_velocity];
	[myHornController changeVelocity:velocity];
	[[ampSliders cellAtRow:0 column:0] setDoubleValue:0.22 + (0.55 * velocity / 128.0)];
	[myHornController changeAmps:ampSliders];
    }
    else if ([aNote noteType] == MK_noteOff)	{
	j = [aNote keyNum];
//	printf(" %i \n",j);
//	if (j == lastKeyNum)	{
	    [[ampSliders cellAtRow:0 column:0] setFloatValue:0.0];
	    [myHornController changeAmps:ampSliders];
//	}
    }
    else {
	static actionType act;
	static int control, value;
	if (MKIsNoteParPresent(aNote,MK_pitchBend)) {
	    act = action[control=128];
	    if (act==STOP) return self;
	    else if (act==THIN) {
		value = MKGetNoteParAsInt(aNote,MK_pitchBend);
		act = PASS;
		[[modSliders cellAtRow:0 column:0] setFloatValue:(value - 8192.0) / 8192.0];
		[self pitchWheel:[modSliders cellAtRow:0 column:0]];
	    }
	}
	else if (MKIsNoteParPresent(aNote,MK_afterTouch)) {
	    act = action[control=129];
	    if (act==STOP) return self;
	    else if (act==THIN) {
		value = MKGetNoteParAsInt(aNote,MK_afterTouch);
		act = PASS;
		[[modSliders cellAtRow:0 column:2] setFloatValue:(value - 64.0) / 64.0];
		[self volumePedal:[modSliders cellAtRow:0 column:2]];
	    }
	}
	else if (MKIsNoteParPresent(aNote,MK_controlChange)) {
	    act = action[control=MKGetNoteParAsInt(aNote,MK_controlChange)];
	    if (act==STOP) return self;
	    else if (act==THIN) {
		value = MKGetNoteParAsInt(aNote,MK_controlVal);
		act = PASS;
		[[modSliders cellAtRow:0 column:1] setFloatValue:(value - 64.0) / 64.0];
		[self modWheel:[modSliders cellAtRow:0 column:1]];
	    }
	}
	if (act==THIN) {
	    double time = MKGetTime();
	    if ((abs(value-lastVals[control])<minVals[control]) &&
		((time-lastTimes[control])<minTimes[control]))
		return self;
	    lastVals[control] = value;
	    lastTimes[control] = time;
	}
//	[noteSender sendNote:aNote];
    }
    return self;
}

- (void)center:sender
{
    [[modSliders cellAtRow:0 column:0] setFloatValue:0.0];
    [[modSliders cellAtRow:0 column:1] setFloatValue:0.0];
    [[modSliders cellAtRow:0 column:2] setFloatValue:0.0]; 
}

- (void)pitchWheel:sender
{
    double temp;
    temp = [[slide cellAtRow:0 column:0] doubleValue]; ;
    temp -= [sender doubleValue];
    if (temp<0.0) temp = 0.0;
    if (temp>1.0) temp = 1.0;
    [myHornController changeSlideQuick:temp]; 
}

- (void)modWheel:sender
{
    double temp,tempMass,tempSpring;
    temp = [sender doubleValue];
    tempMass = [[lipSliders cellAtRow:0 column:0] doubleValue];
    tempSpring = [[lipSliders cellAtRow:0 column:1] doubleValue];
    if (temp<0)	{
        tempMass -= tempMass * temp * 0.5;
        tempSpring += tempSpring * temp * 0.5;
    }
    else {
        tempMass -= tempMass * temp * 0.9;
        tempSpring += tempMass * temp * 0.9;
    }
    [myHornController changeLipQuick: tempMass : tempSpring]; 
}

- (void)volumePedal:sender
{
    double temp,tempInputAmp;
    temp = [sender doubleValue] * 0.3;
    temp += [[ampSliders cellAtRow:0 column:0] doubleValue];
    if (temp<0.0) temp = 0.0;
    if (temp>1.0) temp = 1.0;
    tempInputAmp = temp;
    temp = [[ampSliders cellAtRow:1 column:0] doubleValue];
    [myHornController changeAmpsQuick: tempInputAmp : temp]; 
}

- (void)pressKey:sender
{
    int keyNum = 0;
    if (sender==whiteKeys) keyNum = keyTable[[[sender selectedCell] tag]];
    else 
	if (sender==blackKeys1) keyNum = [[sender selectedCell] tag] * 2 + 54;
    	else 
	    if (sender==blackKeys2) keyNum = [[sender selectedCell] tag] * 2 + 61;
	    else 
	    	if (sender==blackKeys3) keyNum = [[sender selectedCell] tag] * 2 + 66;
		else 
	    	    if (sender==blackKeys4) keyNum = [[sender selectedCell] tag] * 2 + 73;
	    	    else 
			if (sender==blackKeys5) keyNum = [[sender selectedCell] tag] * 2 + 78;
//    printf("Key number = %i\n",keyNum);
    [[lipSliders cellAtRow:0 column:0] setFloatValue:preset[keyNum - 52][0]];
    [[lipSliders cellAtRow:0 column:1] setFloatValue:preset[keyNum - 52][1]];
    [[lipSliders cellAtRow:0 column:2] setFloatValue:preset[keyNum - 52][2]];
    [[slide cellAtRow:0 column:0] setFloatValue:preset[keyNum - 52][3]];
    [[slide cellAtRow:1 column:0] setFloatValue:preset[keyNum - 52][3]];
    [myHornController changeLip:lipSliders];
    [myHornController changeSlideQuick:preset[keyNum - 52][3]]; 
}


@end