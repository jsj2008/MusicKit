/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    (See discussion below)

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.7  2005/05/14 03:23:05  leighsmith
  Clean up of parameter names to correct doxygen warnings

  Revision 1.6  2005/05/09 15:27:44  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.5  2001/11/16 20:37:51  leighsmith
  Made images use musickit.org URL since it will be too difficult to place the image into the generated class documentation directory and too location specific to specify relative URLs to images

  Revision 1.4  2001/09/10 17:38:28  leighsmith
  Added abstracts from IntroSynthPatches.rtf

  Revision 1.3  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
//  classgroup Virtual Acoustics (a.k.a. Physical Modeling or Waveguide) Synthesis
/*!
  @class Pluck
  @brief Plucked string synthesis.
  
  

Pluck implements a Plucked string with fine-tuning of pitch and dynamics, as described in Jaffe/Smith, and Karplus/Strong, "The Music Machine", MIT Press, 1989.  This is a type of "virtual acoustic" synthesis (also called "physical modeling" or "waveguide synthesis".)

Pluck creates a sound suggesting a struck or plucked string.  It uses a delay line to represent the string.  The lower the pitch, the more delay memory it needs.  The implication is that a passage with many low notes may have problems running out of DSP memory.  Pluck does dynamic allocation of its delay memory.  This may result in some loss of memory over time due to DSP memory fragmentation.  

Keep in mind that the highest frequency that Pluck can play is only 1300 Hz. for a sampling rate of 22050 and 2600 Hz for a sampling rate of 44100.  (For the curious, this annoying limitation could be lifted if the SynthPatch were redesigned to be one giant UnitGenerator.  The limitation comes in the pipeline delay, which is the tick size 16 samples.)

<img src="Images/Pluck.png"> 

<h2>Parameter Interpretation</h2>

<b>amp</b> - Amplitude.  In the range 0.0:1.0.  amp1 is a synonym for amp.  Default is 0.1.  Note that this parameter applies only to the initial pluck.  Attempts to change the amplitude after the pluck have no effect.  Also, note that the resultant amplitude may be lower than a comparable setting in other SynthPatches, due to the indeterminate nature of the noise used for the attack.  Default is 0.1.

<b>ampRel</b> - Time in seconds at end of note (after noteOff) for string to damp to -60dB of original amplitude.  Default is 0.15.

<b>bearing</b> - Left/right panning of signal.  In range -45.0:45.0.  -45.0 is far left.  Default is 0.0.

<b>bright</b> -  Brightness of the pluck.  In range 0.0:1.0.  1.0 is very bright.  Default is 0.5.

<b>controlChange</b> - This parameter is the MIDI controller number to be affected.  It is used in conjunction with the parameter <b>controlVal</b>, which provides the value the controller is set to.  This SynthPatch uses MIDI volume (controller 7) to adjust output volume as an attenuation of the final output signal.  The default for MIDI volume is 127.

<b>controlVal</b> - See controlChange.

<b>decay</b> - Time constant of additional decay beyond the natural decay of the string.  A value of 0.0 indicates no additional decay.  This value is given in units of t60.  (t60 is the time for a note to decay to -60dB of its original amplitude.) Default is 0.0.

<b>freq</b> - Frequency in Hz.  freq1 is a synonym for freq.  Default is A440.

<b>keyNum</b> - The MIDI key number, an alternative to freq.  If both freq and keyNum are present, freq, takes precedence.  In the range 0:127.

<b>lowestFreq</b> - This parameter is used to warn the synthpatch what the lowest freq that may appear in the phrase will be so that it can allocate an appropriate amount of delay memory.  It is only used in the first note of a phrase.  Note that very low pitches use an awful lot of memory and may exceed the capacity of the DSP.

<b>pickNoise</b> - In seconds (duration of initial pick noise).  Default is a period of time equal to one period at the fundamental frequency.

<b>pitchBend</b> - Modifies frequency (or keyNum) as a 14 bit integer.  A value of MIDI_ZEROBEND (defined as 0x2000 in &lt;mididriver/midi_spec.h&gt;) gives no  bend.  0 is maximum negative bend.  0x3fff is maximum positive bend.  See TuningSystem class for details.  May give unexpected results when combined with frequency envelopes.  Default is MIDI_ZEROBEND.

<b>pitchBendSensitivity</b> - A value of 0.0 means pitchBend has no effect.  A value of 1.0 means pitch bend corresponds to plus or minus a semitone.  Larger values give larger pitch deviation.  Default is 3.0.

<b>sustain</b> - In range 0.0:1.0.  1 means "sustain forever".  0 is the default and gives a moderate sustain.

<b>velocity</b> - A MIDI parameter.  In range 0:127.  The default is 64.  Velocity scales amplitude by an amount deteremined by velocitySensitivity.  Note that Pluck uses this parameter to scale brightness as well as amplitude.  In range 0:127.  Default is 64.

<b>velocitySensitivity</b> - In range 0.0:1.0.  Default is 0.5.  When velocitySensitivity is 0, velocity has no effect.
*/
#ifndef __MK_Pluck_H___
#define __MK_Pluck_H___

#import <MusicKit/MKSynthPatch.h>

@interface Pluck:MKSynthPatch
{
    /* Here are the parameters. */
    double freq;                  /* Frequency.   */
    double sustain;               /* Sustain parameter value */
    double ampRel;                /* AmpRel parameter value.*/
    double decay;                 /* Decay parameter value. */
    double bright;                /* Brightness parameter value */
    double amp;                   /* Amplitude parameter value.   */
    double bearing;               /* Bearing parameter value. */
    double baseFreq;              /* Frequency, not including pitch bend  */
    int pitchBend;                /* Modifies freq. */
    double pitchBendSensitivity;  /* How much effect pitch bend has. */
    double velocitySensitivity;   /* How much effect velocity has. */
    int velocity;                 /* Velocity scales bright. */
    int volume;                   /* Midi volume pedal */
    id _reservedPluck1;
    id _reservedPluck2;
    int _reservedPluck3;
    void * _reservedPluck4;
}


/*!
  @param  aNote is an id.
  @return Returns an id.
  @brief Returns a default template.

  <i>aNote </i>is ignored.
*/
+patchTemplateFor:currentNote;
-init;

/*!
  @param  aNote is an id.
  @return Returns an id.
  @brief <i>aNote</i> is assumed to be a noteOn or noteDur.

  This method triggers (or retriggers) the MKNote's envelopes, if any.  If this is a new phrase, all instance variables are set to default values, then the values are read from the MKNote.  
*/
-noteOnSelf: (MKNote *) aNote;

/*!
  @param  aNote is an id.
  @return Returns an id.
  @brief <i>aNote</i> is assumed to be a noteUpdate and the receiver is assumed to be currently playing a MKNote.

  Sets parameters as specified in <i>aNote.</i>
*/
-noteUpdateSelf: (MKNote *) aNote;

/*!
  @param  aNote is an id.
  @return Returns a double.
  @brief <i>aNote</i> is assumed to be a noteOff.

  This method causes the MKNote's envelopes (if any) to begin its release portion and returns the time for the envelopes to finish.  Also sets any parameters present in <i>aNote.</i>
*/
-(double)noteOffSelf: (MKNote *) aNote;

/*!
  @return Returns an id.
  @brief Resest instance variables to default values.

  
*/
-noteEndSelf;

/*!
  @param  aNote is an id.
  @return Returns an id.
  @brief Preempts envelope, if any.

  
*/
-preemptFor: (MKNote *) aNote;

@end

#endif
