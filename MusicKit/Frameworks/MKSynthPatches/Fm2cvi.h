#ifndef __MK_Fm2cvi_H___
#define __MK_Fm2cvi_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	Fm2cvi.h 

	This class is part of the Music Kit MKSynthPatch Library.
*/
#import <MusicKit/MKSynthPatch.h>
@interface Fm2cvi:MKSynthPatch
{
  double amp0, amp1, ampAtt, ampRel, freq0, freq1, freqAtt, freqRel,
         bearing, phase, portamento, svibAmp0, svibAmp1, rvibAmp,
         svibFreq0, svibFreq1, bright, cRatio,
         m1Ratio, m1Ind0, m1Ind1, m1IndAtt, m1IndRel, m1Phase,
         m2Ratio, m2Ind0, m2Ind1, m2IndAtt, m2IndRel, m2Phase,
         velocitySensitivity, panSensitivity, afterTouchSensitivity, 
         pitchbendSensitivity;
  id ampEnv, freqEnv, m1IndEnv, m2IndEnv, waveform, m1Waveform, m2Waveform;
  int wavelen, volume, velocity, pan, modulation, aftertouch, pitchbend;
  void *_ugNums;
}

+patchTemplateFor:aNote;
   

-noteOnSelf:aNote;
 

-noteUpdateSelf:aNote;

-(double)noteOffSelf:aNote;
 

-noteEndSelf;
 

@end

#endif
