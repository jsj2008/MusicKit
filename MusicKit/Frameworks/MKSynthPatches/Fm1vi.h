/*!
  @header Fm1vi


<b>Fm1vi</b> is like <b>Fm1i</b>, but it includes periodic and random vibrato.
<b>Fm1v</b>(a subclass of <b>Fm1vi</b> ) is identical, but it uses a non-interpolating-oscillator (lower quality, but uses less DSP computation.).   

<img src="Images/Fm1vi.gif"> 
When using this SynthPatch in an interactive real-time context, such as playing from a MIDI keyboard, call <b>MKUseRealTimeEnvelopes()</b> before allocating the SynthPatch.

<h2>Parameter Interpretation</h2>

In addition to the parameters described in <b>Fm1i.rtf</b>, the following parameters are supported:

<b>controlChange</b> - MIDI modulation wheel (controller 1) interpolates simultaneously between <b>svibAmp0</b> and <b>svibAmp</b>, and <b>svibFreq0</b> and <b>svibFreq</b>.  The default value (127) results in svibFreq and svibAmp.  The value is given by the companion parameter controlVal. In the range 0:127.

<b>controlVal</b> - See controlChange.

<b>svibFreq</b> - Sinusoidal vibrato rate in hz.  Default is 0.0.

<b>svibAmp-</b> Sinusoidal vibrato amplitude as a percentage of the fundamental frequency.  In the range 0.0:1.0.  Default is 0.0.

<b>svibFreq0</b> - See <b>controlChange</b>.  Default is 0.0.

<b>svibAmp0</b> - See <b>controlChange.</b>  Default is 0.0.

<b>rvibAmp</b> - Random vibrato amplitude as roughly a percentage of the fundamental frequency.  In the range 0.0:1.0.  Default is 0.0.

<b>vibWaveform</b> - WaveTable object that specifies shape of vibrato.

*/
#ifndef __MK_Fm1vi_H___
#define __MK_Fm1vi_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* ------------------------------------------------------------------------ * 
 * Fm1vi is like Fm1i but adds periodic and random vibrato.
 * 
 * See Fm1i.h for a description of the non-vibrato parameters.
 * ------------------------------------------------------------------------ */

#import "Fm1i.h"

@interface Fm1vi:Fm1i
{
    /* Instance variables for the parameters to which the MKSynthPatch 
       responds. */

    MKWaveTable *vibWaveform; /* Waveform used for vibrato. */
    double svibAmp0;  /* Vibrato, on a scale of 0 to 1, when modWheel is 0. */
    double svibAmp1;  /* Vibrato, on a scale of 0 to 1, when modWheel is 127.*/
    double svibFreq0; /* Vibrato freq in Hz. when modWheel is 0. */
    double svibFreq1; /* Vibrato freq in Hz. when modWheel is 1. */
    
    double rvibAmp;   /* Random vibrato. On a scale of 0 to 1. */

    int modWheel;     /* MIDI modWheel. Controls vibrato frequency and amp */
}

/* Default parameter values, if corresponding parameter is omitted: 
   vibWaveform - sine wave
   svibAmp0 - 0.0
   svibAmp1 - 0.0
   svibFreq0 - 0.0 Hz.
   svibFreq1 - 0.0 Hz.
    
   rvibAmp - 0.0

   modWheel - vibrato amplitude of svibAmp1 and frequency of svibFreq1 (127)

*/

@end

#endif
