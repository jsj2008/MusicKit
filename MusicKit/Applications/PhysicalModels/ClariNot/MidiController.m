
/* Generated by Interface Builder */

#import "MidiController.h"
#import "Controller.h"
#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#import <libc.h>

    int keyTable[20] = {60,62,64,65,67,69,71,72,74,76,77,79,81,83,84,86,88,89};
    float preset[32][3] = {		{1.000000,	0.000000,	0},    //   Lowest C
    				      {0.909090,	0.000000,	0},
    				      {0.818181,	0.000000,	0},
    				      {0.727272,	0.000000,	0},
    				      {0.636363,	0.000000,	0},
    				      {0.545454,	0.000000,	0},    //  Lowest F
     				      {0.454545,	0.000000,	0},
    				      {0.363636,	0.000000,	0},
    				      {0.272727,	0.000000,	0},
    				      {0.181818,	0.000000,	0},
    				      {0.090909,	0.000000,	0},
    				      {0.000000,	0.000000,	0},
    				      {1.000000,	1.000000,	0},    //   C
    				      {0.909090,	1.000000,	0},
     				      {0.818181,	1.000000,	0},
    				      {0.727272,	1.000000,	0},
    				      {0.636363,	1.000000,	0},
    				      {0.545454,	1.000000,	0},    //   F
    				      {0.447600,	1.000000,	0},
    				      {1.000000,	0.100000,	1},
    				      {0.909090,	0.100000,	1},
    				      {0.818181,	0.100000,	1},
    				      {0.727272,	0.100000,	1},
    				      {0.636363,	0.100000,	1},
    				      {0.545454,	0.000000,	1},    //   C
    				      {0.454545,	0.000000,	1},
    				      {0.363636,	0.000000,	1},
    				      {0.272727,	0.000000,	1},
    				      {0.181818,	0.000000,	1}, 
    				      {0.090909,	0.000000,	1},    //  F
    				      {0.000000,	0.000000,	1},
    				      {0.090909,	0.000000,	1}};

@implementation MidiController


    -reset
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
    return self;
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
	    while (lastKeyNum>90) lastKeyNum -= 12;
	    while (lastKeyNum<60) lastKeyNum += 12;
	    if (![fastMode state])	{
		for (i=0;i<20;i++) if (lastKeyNum==keyTable[i]) j = i;
		if (j>=0) [[whiteKeys cellAt: 0 : j] performClick: self];
		else {
	             if (lastKeyNum==61) [[blackKeys1 cellAt: 0 : 0] performClick: self];
	             if (lastKeyNum==63) [[blackKeys1 cellAt: 0 : 1] performClick: self];
	             if (lastKeyNum==66) [[blackKeys2 cellAt: 0 : 0] performClick: self];
	             if (lastKeyNum==68) [[blackKeys2 cellAt: 0 : 1] performClick: self];
	             if (lastKeyNum==70) [[blackKeys2 cellAt: 0 : 2] performClick: self];
	             if (lastKeyNum==73) [[blackKeys3 cellAt: 0 : 0] performClick: self];
	             if (lastKeyNum==75) [[blackKeys3 cellAt: 0 : 1] performClick: self];
	             if (lastKeyNum==78) [[blackKeys4 cellAt: 0 : 0] performClick: self];
	             if (lastKeyNum==80) [[blackKeys4 cellAt: 0 : 1] performClick: self];
	             if (lastKeyNum==82) [[blackKeys4 cellAt: 0 : 2] performClick: self];
	             if (lastKeyNum==85) [[blackKeys5 cellAt: 0 : 0] performClick: self];
	             if (lastKeyNum==87) [[blackKeys5 cellAt: 0 : 1] performClick: self];
	         }
	    }
	    else 	{
		[slide setFloatValue: preset[lastKeyNum - 60][0]];
    		[myHornController changeSlideQuick: preset[lastKeyNum - 60][0] 
    			registerMode: (int) preset[lastKeyNum - 60][2] 
			registerHole: preset[lastKeyNum - 60][1]];
//		[embSlider setFloatValue: preset[lastKeyNum - 60][1]];
//		[myHornController changeEmbouchureQuick:  (1.0 - preset[lastKeyNum - 60][1])];
	    }
	}
	velocity = [aNote parAsDouble: MK_velocity];
	[myHornController changeVelocity: velocity];
	[[ampSliders cellAt: 0 : 0] setDoubleValue: 0.50 + (0.40 * velocity / 128.0)];
	[myHornController changeAmps: ampSliders];
    }
    else if ([aNote noteType] == MK_noteOff)	{
	j = [aNote keyNum];
//	printf(" %i \n",j);
//	if (j == lastKeyNum)	{
	    [[ampSliders cellAt: 0 : 0] setFloatValue: 0.0];
	    [myHornController changeAmps: ampSliders];
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
		[[modSliders cellAt: 0 : 0] setFloatValue: (value - 8192.0) / 8192.0];
		[self pitchWheel: [modSliders cellAt: 0 : 0]];
	    }
	}
	else if (MKIsNoteParPresent(aNote,MK_afterTouch)) {
	    act = action[control=129];
	    if (act==STOP) return self;
	    else if (act==THIN) {
		value = MKGetNoteParAsInt(aNote,MK_afterTouch);
		act = PASS;
		[[modSliders cellAt: 0 : 2] setFloatValue: (value - 64.0) / 64.0];
		[self volumePedal: [modSliders cellAt: 0 : 2]];
	    }
	}
	else if (MKIsNoteParPresent(aNote,MK_controlChange)) {
	    act = action[control=MKGetNoteParAsInt(aNote,MK_controlChange)];
	    if (act==STOP) return self;
	    else if (act==THIN) {
		value = MKGetNoteParAsInt(aNote,MK_controlVal);
		act = PASS;
		[[modSliders cellAt: 0 : 1] setFloatValue: (value - 64.0) / 64.0];
		[self modWheel1: [modSliders cellAt: 0 : 1]];
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

- center:sender
{
    [[modSliders cellAt: 0 : 0] setFloatValue: 0.0];
    [[modSliders cellAt: 0 : 1] setFloatValue: 0.0];
    [[modSliders cellAt: 0 : 2] setFloatValue: 0.0];
    [[modSliders cellAt: 0 : 3] setFloatValue: 0.0];
    return self;
}

- pitchWheel:sender
{
    double temp;
    temp = [[slide cellAt: 0 : 0] doubleValue];;
    temp -= [sender doubleValue];
    if (temp<0.0) temp = 0.0;
    if (temp>1.0) temp = 1.0;
    [myHornController changeSlideQuick: temp 
    			registerMode: (int) preset[lastKeyNum - 60][2] 
			registerHole: preset[lastKeyNum - 60][1]];
    return self;
}

- modWheel1:sender
{
    double temp=0.0;
    temp = [regSlider doubleValue];
    temp += [sender doubleValue];
    if (temp<0.0) temp = 0.0;
    if (temp>1.0) temp = 1.0;
    [myHornController changeSlideQuick: preset[lastKeyNum - 60][0] 
    		registerMode: (int) preset[lastKeyNum - 60][2] 
		registerHole: temp];
    return self;
}

- volumePedal:sender
{
    double temp,tempInputAmp;
    temp = [sender doubleValue] * 0.3;
    temp += [[ampSliders cellAt: 0  : 0] doubleValue];
    if (temp<0.0) temp = 0.0;
    if (temp>1.0) temp = 1.0;
    tempInputAmp = temp;
    temp = [[ampSliders cellAt: 1  : 0] doubleValue];
    [myHornController changeAmpsQuick: tempInputAmp : temp];
    return self;
}

- pressKey:sender
{
    int keyNum = 0;
    if (sender==whiteKeys) keyNum = keyTable[[[sender selectedCell] tag]];
    else 
	if (sender==blackKeys1) keyNum = [[sender selectedCell] tag] * 2 + 61;
    	else 
	    if (sender==blackKeys2) keyNum = [[sender selectedCell] tag] * 2 + 66;
	    else 
	    	if (sender==blackKeys3) keyNum = [[sender selectedCell] tag] * 2 + 73;
		else 
	    	    if (sender==blackKeys4) keyNum = [[sender selectedCell] tag] * 2 + 78;
	    	    else 
			if (sender==blackKeys5) keyNum = [[sender selectedCell] tag] * 2 + 85;
//    printf("Key number = %i\n",keyNum);
    [slide setFloatValue: preset[keyNum - 60][0]];
    [regMode selectCellAt: preset[keyNum - 60][2] : 0];
    [regSlider setFloatValue: preset[keyNum - 60][1]];
    [myHornController changeSlideQuick: preset[keyNum - 60][0] 
    			registerMode: (int) preset[keyNum - 60][2] 
			registerHole: preset[keyNum - 60][1]];
    return self;
}


@end
