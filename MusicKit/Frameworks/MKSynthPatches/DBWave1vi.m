/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/* 
  Modification history:

  04/23/90/daj - Made this a subclass of Wave1vi.
  04/25/90/daj - Changed timbre string handling to use NoCopy string func
  08/28/90/daj - Changed initialize to init.
  07/09/91/daj - Changed to use Timbre.

*/

#import <MusicKit/MusicKit.h>
#import <MusicKit/midi_spec.h>
#import <objc/HashTable.h>
//#import <MusicKit/unitgenerators/unitgenerators.h>
#import <unitgenerators/unitgenerators.h>
//#import <appkit/nextstd.h>
#import "DBWave1vi.h"
/* Database of analyzed timbres */
#import "partialsDB.h"
#import "_synthPatchInclude.h"
#define  NX_MALLOC(VAR, TYPE, NUM)  \
    ((VAR) = (TYPE *) malloc((unsigned)(NUM)*sizeof(TYPE)))
#define  NX_REALLOC(VAR, TYPE, NUM)  \
    ((VAR) = (TYPE *) realloc((VAR), (unsigned)(NUM)*sizeof(TYPE)))
#define NX_FREE(PTR)    free((PTR));

#import "_Wave1i.h"
@implementation DBWave1vi


+(void)initialize
{
    [MKTimbre initialize];
    return;
}


-controllerValues:controllers
  /* Initializes controller variables to current controller values when
     synthpatch is set up. */
{
  if ([controllers isKey:(const void *)MIDI_MAINVOLUME])
    volume = (int)[controllers valueForKey:(const void *)MIDI_MAINVOLUME];
  if ([controllers isKey:(const void *)MIDI_MODWHEEL])
    modWheel = (int)[controllers valueForKey:(const void *)MIDI_MODWHEEL];
  if ([controllers isKey:(const void *)MIDI_BALANCE])
    balance = (int)[controllers valueForKey:(const void *)MIDI_BALANCE];
  if ([controllers isKey:(const void *)MIDI_PAN])
    pan = (int)[controllers valueForKey:(const void *)MIDI_PAN];
  return self;
}

-_setDefaults
  /* Set the static global variables to reasonable values. */
{
    [super _setDefaults];
    waveform0 = nil;
    waveform1 = nil;
    balance   = 127;
    pan       = MAXINT;
    panSensitivity = 1.0;
    balanceSensitivity = 1.0;
    table = NULL;
    return self;
  }

-init
  /* Sent by this class on object creation and reset. */
{
  [super init];
  NX_MALLOC(_localTable,DSPDatum,512);
  return self;
}

-freeSelf
{
  NX_FREE(_localTable);
  return self;
}

-_setWaveform:(BOOL)newPhrase str0:(NSString *)waveStr0 str1:(NSString *)waveStr1
{
  int interp = balance;
  if sValid(waveStr0) 
      waveform0 = MKWaveTableForTimbreKey(waveStr0,freq0,freq1);
  if sValid(waveStr1) 
      waveform1 = MKWaveTableForTimbreKey(waveStr1,freq0,freq1);
  if ((waveform0 && !waveform1) || (waveform0==waveform1)) {
    waveform = waveform0;
    table = [waveform0 dataDSPLength: wavelen];
  }
  else if (waveform1 && !waveform0) {
    waveform = waveform1;
    table = [waveform1 dataDSPLength: wavelen];
  }
  else if (waveform0 && waveform1) {
    interp = balance * balanceSensitivity;
    if (interp==0) {
      waveform = waveform0;
      table = [waveform0 dataDSPLength: wavelen];
    }
    else if (interp==127) {
      waveform = waveform1;
      table = [waveform1 dataDSPLength: wavelen];
    }
    else {
      register DSPDatum *t0, *t1, *end;
      int x0, x1;
      double tmp = (double)interp/127.0;
      t0 = [waveform0 dataDSPLength: wavelen];
      t1 = [waveform1 dataDSPLength: wavelen];
      table = _localTable;
      end = table + wavelen;
      while (table<end) { 
	x0 = *t0++;
	x1 = *t1++;
	if (x0 &  0x800000) x0 |= 0xFF000000;
	if (x1 &  0x800000) x1 |= 0xFF000000;
	*table++ = (x0 + (int)((double)(x1-x0)*tmp)) & 0xFFFFFF;
      }
      table = _localTable;
    }
  }
  if (!table || (!waveform0 && waveform1) || (waveform0 && !waveform1) ||
      (interp==0) || (interp==127))
    [WAVEUG(oscUG) setTable:waveform length:wavelen defaultToSineROM:newPhrase];
  else {
    if (_synthData && ([_synthData length]!=wavelen)) {
      [orchestra dealloc:_synthData];
      _synthData = nil;
    }
    if (!_synthData) 
      _synthData = [orchestra allocSynthData:MK_yData length:wavelen];
    if (_synthData)
      [_synthData setData:table length:wavelen offset:0];
    else if (MKIsTraced(MK_TRACEUNITGENERATOR))
      fprintf(stderr,"Insufficient wavetable memory at time %.3f. \n",MKGetTime());
    [WAVEUG(oscUG) setTable:_synthData length:wavelen defaultToSineROM:newPhrase];
  }
  return self;
}

-_updateParameters:aNote
    /* Updates the MKSynthPatch according to the information in the note and
   * the note's relationship to a possible ongoing phrase. 
   */
{
    BOOL newPhrase, setWaveform, setOutput,
         setRandomVib, setVibWaveform, setVibFreq,
         setVibAmp, setPhase, setAmpEnv, setFreqEnv;
    void *state; /* For parameter iteration below */
    int par;     
    MKPhraseStatus phraseStatus = [self phraseStatus];
    NSString *waveStr0 = @"";
    NSString *waveStr1 = @"";

    /* Initialize booleans based on phrase status -------------------------- */
    switch (phraseStatus) {
      case MK_phraseOn:          /* New phrase. */
      case MK_phraseOnPreempt:   /* New phrase but using preempted patch. */
        newPhrase = setWaveform =  setOutput = setRandomVib =  
	  setVibWaveform = setVibFreq = setVibAmp = setPhase = setAmpEnv = 
	    setFreqEnv = YES;  /* Set everything for new phrase */
	break;
      case MK_phraseRearticulate: /* NoteOn rearticulation within phrase. */
	newPhrase = setWaveform = setOutput = setRandomVib = 
	    setVibWaveform = setVibFreq = setVibAmp = setPhase = NO;
	setAmpEnv = setFreqEnv = YES; /* Just restart envelopes */
	break;
      case MK_phraseUpdate:       /* NoteUpdate to running phrase. */
      case MK_phraseOff:          /* NoteOff to running phrase. */
      case MK_phraseOffUpdate:    /* NoteUpdate to finishing phrase. */
      default: 
	newPhrase = setWaveform = setOutput = setRandomVib = 
	    setVibWaveform = setVibFreq = setVibAmp = setPhase = setAmpEnv = 
	      setFreqEnv = NO;  /* Only set what's in Note */
	break;
      }

    /* Since this MKSynthPatch supports so many parameters, it would be 
     * inefficient to check each one with Note's isParPresent: method, as
     * we did in Simplicity and Envy. Instead, we iterate over the parameters 
     * in aNote. */

    state = MKInitParameterIteration(aNote);
    while (par = MKNextParameter(aNote, state))  
      switch (par) {          /* Parameters in (roughly) alphabetical order. */
	case MK_ampEnv:
	  ampEnv = MKGetNoteParAsEnvelope(aNote,MK_ampEnv);
	  setAmpEnv = YES;
	  break;
	case MK_ampAtt:
	  ampAtt = MKGetNoteParAsDouble(aNote,MK_ampAtt);
	  setAmpEnv = YES;
	  break;
	case MK_ampRel:
	  ampRel = MKGetNoteParAsDouble(aNote,MK_ampRel);
	  setAmpEnv = YES;
	  break;
	case MK_amp0:
	  amp0 = MKGetNoteParAsDouble(aNote,MK_amp0);
	  setAmpEnv = YES;
	  break;
	case MK_amp1: /* MK_amp is synonym */
	  amp1 = MKGetNoteParAsDouble(aNote,MK_amp1);
	  setAmpEnv = YES;
	  break;
	case MK_bearing:
	  bearing = MKGetNoteParAsDouble(aNote,MK_bearing);
	  setOutput = YES;
	  break;
	case MK_panSensitivity:
	  panSensitivity = MKGetNoteParAsDouble(aNote,MK_panSensitivity);
	  setOutput = YES;
	  break;
	case MK_balanceSensitivity:
	  balanceSensitivity = MKGetNoteParAsDouble(aNote,MK_balanceSensitivity);
	  setWaveform = YES;
	  break;
	case MK_controlChange: {
	    int controller = MKGetNoteParAsInt(aNote,MK_controlChange);
	    if (controller == MIDI_MAINVOLUME) {
		volume = MKGetNoteParAsInt(aNote,MK_controlVal);
		setOutput = YES; 
	    } 
	    else if (controller == MIDI_MODWHEEL) {
		modWheel = MKGetNoteParAsInt(aNote,MK_controlVal);
		setVibFreq = setVibAmp = YES;
	    }
	    else if (controller == MIDI_PAN) {
		pan = MKGetNoteParAsInt(aNote,MK_controlVal);
		setOutput = YES;
	    }
	    else if (controller == MIDI_BALANCE) {
		balance = MKGetNoteParAsInt(aNote,MK_controlVal);
		setWaveform = YES;
	    }
	    break;
	}
	case MK_freqEnv:
	  freqEnv = MKGetNoteParAsEnvelope(aNote,MK_freqEnv);
	  setFreqEnv = YES;
	  break;
	case MK_freqAtt:
	  freqAtt = MKGetNoteParAsDouble(aNote,MK_freqAtt);
	  setFreqEnv = YES;
	  break;
	case MK_freqRel:
	  freqRel = MKGetNoteParAsDouble(aNote,MK_freqRel);
	  setFreqEnv = YES;
	  break;
	case MK_freq:
	case MK_keyNum:
	  freq1 = [aNote freq]; /* A special method (see <MusicKit/Note.h>) */
	  setFreqEnv = YES;
	  break;
	case MK_freq0:
	  freq0 = MKGetNoteParAsDouble(aNote,MK_freq0);
	  setFreqEnv = YES;
	  break;
	case MK_phase:
	  phase = MKGetNoteParAsDouble(aNote,MK_phase);
	  /* To avoid clicks, we don't allow phase to be set except at the 
	     start of a phrase. Therefore, we don't set setPhase. */
	  break;
	case MK_pitchBendSensitivity:
	  pitchbendSensitivity = 
	    MKGetNoteParAsDouble(aNote,MK_pitchBendSensitivity);
	  setFreqEnv = YES;
	  break;
	case MK_pitchBend:
	  pitchbend = MKGetNoteParAsInt(aNote,MK_pitchBend);
	  setFreqEnv = YES;
	  break;
	case MK_portamento:
	  portamento = MKGetNoteParAsDouble(aNote,MK_portamento);
	  setAmpEnv = YES;
	  break;
	case MK_rvibAmp:
	  rvibAmp = MKGetNoteParAsDouble(aNote,MK_rvibAmp);
	  setRandomVib = YES;
	  break;
	case MK_svibFreq0:
	  svibFreq0 = MKGetNoteParAsDouble(aNote,MK_svibFreq0);
	  setVibFreq = YES;
	  break;
	case MK_svibFreq1:
	  svibFreq1 = MKGetNoteParAsDouble(aNote,MK_svibFreq1);
	  setVibFreq = YES;
	  break;
	case MK_svibAmp0:
	  svibAmp0 = MKGetNoteParAsDouble(aNote,MK_svibAmp0);
	  setVibAmp = YES;
	  break;
	case MK_svibAmp1:
	  svibAmp1 = MKGetNoteParAsDouble(aNote,MK_svibAmp1);
	  setVibAmp = YES;
	  break;
	case MK_vibWaveform:
	  vibWaveform = MKGetNoteParAsWaveTable(aNote,MK_vibWaveform);
	  setVibWaveform = YES;
	  break;
	case MK_velocity:
	  velocity = MKGetNoteParAsDouble(aNote,MK_velocity);
	  setAmpEnv = YES;
	  break;
	case MK_velocitySensitivity:
	  velocitySensitivity = 
	    MKGetNoteParAsDouble(aNote,MK_velocitySensitivity);
	  setAmpEnv = YES;
	  break;
	case MK_waveform0:
	  waveform0 = MKGetNoteParAsWaveTable(aNote,MK_waveform0);
	  if (waveform0==nil)
	    waveStr0 = MKGetNoteParAsStringNoCopy(aNote,MK_waveform0);
	  setWaveform = YES;
	  break;
	case MK_waveform1:
	  waveform1 = MKGetNoteParAsWaveTable(aNote,MK_waveform1);
	  if (waveform1==nil)
	    waveStr1 = MKGetNoteParAsStringNoCopy(aNote,MK_waveform1);
	  setWaveform = YES;
	  break;
	case MK_waveLen:
	  wavelen = MKGetNoteParAsInt(aNote,MK_waveLen);
	  setWaveform = YES; 
	  break;
	default: /* Skip unrecognized parameters */
	  break;
      } /* End of parameter loop. */

	/* -------------------------------- Waveforms --------------------- */
    if (setWaveform)
      [self _setWaveform:newPhrase str0:waveStr0 str1:waveStr1];

	/* ------------------------------- Phases -------------------------- */
    if (setPhase)
      [WAVEUG(oscUG) setPhase:phase];

    /* ------------------------------ Envelopes ------------------------ */
    if (setAmpEnv) 
      MKUpdateAsymp(WAVEUG(ampUG),ampEnv,amp0,
		    amp1 * 
		    MKMidiToAmpWithSensitivity(velocity,velocitySensitivity),
		    ampAtt,ampRel,portamento,phraseStatus);
    if (setFreqEnv) {
	double fr0, fr1;
	fr0 = MKAdjustFreqWithPitchBend(freq0,pitchbend,pitchbendSensitivity);
	fr1 = MKAdjustFreqWithPitchBend(freq1,pitchbend,pitchbendSensitivity);
	MKUpdateAsymp(WAVEUG(incUG),freqEnv,
		      [WAVEUG(oscUG) incAtFreq:fr0], /* Convert to osc increment */
		      [WAVEUG(oscUG) incAtFreq:fr1], 
		      freqAtt,freqRel,portamento,phraseStatus);
    }

    if (WAVENUM(svibUG)>=0) {
      double modPc = (double)modWheel/127.0;
      if (setVibWaveform)
	[WAVEUG(svibUG) setTable:vibWaveform length:128 defaultToSineROM:YES];
      else if (newPhrase)
	[WAVEUG(svibUG) setTableToSineROM];
      if (setVibFreq)
	[WAVEUG(svibUG) setFreq:svibFreq0+(svibFreq1-svibFreq0)*modPc];
      if (setVibAmp)
	[WAVEUG(svibUG) setAmp:svibAmp0+(svibAmp1-svibAmp0)*modPc];
    }
    if ((WAVENUM(nvibUG)>=0) && (setRandomVib || newPhrase)) {
      [WAVEUG(onepUG) setB0:.004*rvibAmp];
      [WAVEUG(onepUG) clear];
      if (newPhrase) {
	[WAVEUG(onepUG) setA1:-.9999];
	[WAVEUG(nvibUG) anySeed];
      }
    }

    /* ------------------- Bearing, volume and after touch -------------- */
    if (setOutput) {
      if (iValid(pan)) bearing = panSensitivity * 45.0 * (double)(pan-64)/64.0;
      [WAVEUG(outUG) setBearing:bearing scale:MKMidiToAmpAttenuation(volume)];
    }
    return self;
}    

-noteEndSelf
  /* Sent when patch goes from finalDecay to idle. */
{
    [super noteEndSelf];
    if (_synthData) [orchestra dealloc:_synthData];
    _synthData = nil;
    return self;
}

@end

