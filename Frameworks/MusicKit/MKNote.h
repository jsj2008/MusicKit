/*
  $Id$
  Defined In: The MusicKit

  Description:   
    A MKNote object represents a musical sound or event by describing its
    attributes.  This information falls into three categories:
   
    * parameters
    * timing information
    * type information.
   
    Most of the information in a MKNote is in its parameters; a MKNote can
    have any number of parameters.  A parameter consists of an identifier,
    a string name, and a value.  The identifier is a unique integer used
    to catalog the parameter within the MKNote; the MusicKit defines a
    number of parameter identifiers such as MK_freq (for frequency) and
    MK_amp (for amplitude).  The string name is used to identify the
    parameter in a scorefile.  The string names for the MusicKit
    parameters are the same as the identifier names, but without the "MK_"
    prefix.  You can create your own parameter identifiers by passing a
    name to the parTagForName: class method.  This method returns the identifier
    associated with the parameter name, creating it if it doesn't already
    exit.
   
    A parameter's value can be a double, int, NSString object, an MKEnvelope object,
    MKWaveTable object, or other (non-MusicKit) object.  These six
    parameter value types are represented by the following MKDataType
    constants:
   
    * MK_double
    * MK_int
    * MK_string
    * MK_envelope
    * MK_waveTable
    * MK_object
   
    The method you invoke to set a parameter value depends on the type of
    the value.  To set a double value, for example, you would invoke the
    setPar:toDouble: method.  Analogous methods exist for the other data
    types.
   
    You can retrieve the value of a parameter as any of the parameter data
    types.  For instance, the parAsInt: method returns an integer
    regardless of the parameter value's actual type.  The exceptions are
    in retrieving object information: The parAsEnvelope:, parAsWaveTable:,
    and parAsObject: messages return nil if the parameter value isn't the
    specified type.
   
    A MKNote's parameters are significant only if an object that processes
    the MKNote (such as an instance of a subclass of MKPerformer, MKNoteFilter,
    MKInstrument, or MKSynthPatch) accesses and uses the information.
   
    Timing information is used to perform the MKNote at the proper time and
    for the proper duration.  This information is called the MKNote's
    timeTag and duration, respectively.  A single MKNote can have only one
    timeTag and one duration.  Setting a MKNote's duration automatically
    changes its noteType to MK_noteDur, as described below.  TimeTag and
    duration are measured in beats.
   
    A MKNote has two pieces of type information, a noteType and a noteTag.
    A MKNote's noteType establishes its nature; there are six noteTypes:
   
    * A noteDur represents an entire musical note (a note with a duration).
    * A noteOn establishes the beginning of a note.
    * A noteOff establishes the end of a note.
    * A noteUpdate represents the middle of a note (it updates a sounding note).
    * A mute makes no sound.
   
    These are represented by MKNoteType constants:
   
    * MK_noteDur
    * MK_noteOn
    * MK_noteOff
    * MK_noteUpdate
    * MK_mute
   
    The default is MK_mute.
   
    NoteTags are integers used to identify MKNote objects that are part of
    the same musical sound or event; in particular, matching noteTags are
    used to create noteOn/noteOff pairs and to associate noteUpdates with
    other MKNotes.  (A noteUpdate without a noteTag updates all the MKNotes in
    its MKPart.)
  
    The C function MKNoteTag() is provided to generate noteTag values that
    are guaranteed to be unique across your entire application -- you
    should never create a new noteTag except through this function.  The
    actual integer value of a noteTag has no significance (the range of
    noteTag values extends from 0 to 2^BITS_PER_INT).
   
    Mutes can't have noteTags; if you set the noteTag of such a MKNote, it
    automatically becomes a noteUpdate.
   
    MKNotes are typically added to MKPart objects.  A MKPart is a time-ordered
    collection of MKNotes.
  
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/

@class MKPart;
@class MKPerformer;

/*!
  @class MKNote
  @brief A MKNote object represents a musical sound or event by describing its attributes. 

MKNote objects are containers of musical information.  The amount and
type of information that a MKNote can hold is practically unlimited;
however, you should keep in mind that MKNotes haven't the ability to
act on this information, but merely store it.  It's left to other
objects to read and process the information in a MKNote.  Most of the
other MusicKit classes are designed around MKNote objects, treating
them as common currency.  For example, MKPart objects store MKNotes,
MKPerformers acquire them and pass them to MKInstruments,
MKInstruments read the contents of MKNotes and apply the information
therein to particular styles of realization, and so on.

The information that comprises a MKNote defines the attributes of a
particular musical event.  Typically, an object that uses MKNotes
plucks from them just those bits of information in which it's
interested.  Thus you can create MKNotes that are meaningful in more
than one application.  For example, a MKNote object that's realized as
synthesis on the DSP would contain many particles of information that
are used to drive the synthesis machinery; however, this doesn't mean
that the MKNote can't also contain graphical information, such as how
the MKNote would be rendered when drawn on the screen.  The objects
that provide the DSP synthesis realization (MKSynthPatch objects, as
defined by the MusicKit) are designed to read just those bits of
information that have to do with synthesis, and ignore anything else
the MKNote contains.  Likewise, a notation application would read the
attributes that tell it how to render the MKNote graphically, and
ignore all else.  Of course, some information, such as the pitch and
duration of the MKNote, would most likely be read and applied in both
applications.

Most of the methods defined by the MKNote class are designed to let
you set and retrieve information in the form of <i>parameters</i>.  A
parameter consists of a tag, a name, a value, and a data type:

<ul>
<li> A parameter tag is a unique integer used to catalog the
parameter within the MKNote; the MusicKit defines a number of
parameter tags such as MK_freq (for frequency) and MK_amp (for
amplitude).
</li>

<li>The parameter's name is used primarily to identify the
parameter in a scorefile.  The names of the MusicKit parameters are
the same as the tag constants, but without the "MK_" prefix.
You can also use a parameter's name to retrieve its tag, by passing
the name to MKNote's <b>parTagForName:</b> class method.  (As
explained in its descriptions below, it's through this method that you
create your own parameter tags.)  Similarly, you can get a name from a
tag with MKNote's <b>parNameForTag:</b> class method.
</li>

<li> A parameter's value can be a <b>double</b>, <b>int</b>, string
(<b>char *</b>), or an object (<b>id</b>).  The method you invoke to
set a parameter value depends on the type of the value.  To set a
<b>double</b> value, for example, you would invoke the
<b>setPar:toDouble:</b> method.  Analogous methods exist for the other
types.  You can retrieve the value of a <b>double</b>-, <b>int</b>-,
or string-valued parameter as any of these three types, regardless of
the actual type of the value.  For example, you can set the frequency
of a MKNote as a <b>double</b>, thus:
	
	<tt>[aNote setPar: MK_freq toDouble: 440.0]</tt>

and then retrieve it as an <b>int</b>:
	
	<tt>int freq = [aNote parAsInt: MK_freq]</tt>

The type conversion is done automatically.  

Object-valued parameters are treated differently from the other value types.
The only MusicKit objects that are designed to be used as parameter values
are MKEnvelopes and MKWaveTables (and the MKWaveTable descendants MKPartials
and MKSamples).  Special methods are provided for setting and retrieving
these objects.  Other objects, most specifically, objects of your own classes,
are set through the <b>setPar:toObject:</b> method.  While an instance of any
class may be set as a parameter's value through this method, you should note
well that only those objects that respond to the <b>writeASCIIStream:</b> and
<b>readASCIIstream:</b> messages can be written to and read from a scorefile. 
None of the MusicKit classes implement these methods and so their instances
can't be written to a scorefile as parameter values (MKEnvelopes and
MKWaveTables are written and read through a different mechanism).
</li>

<li> The parameter's data type is set when the parameter's value is
set; thus the data type is either a <b>double</b>, <b>int</b>, string,
MKEnvelope, MKWaveTable, or (other) object.  These are represented by
constants, as given in the description of <b>parType:</b>, the method
that retrieves a parameter's data type.</li>
</ul>

A parameter is said to be present within a MKNote once its value has
been set.  You can determine whether a parameter is present in one of
four ways:

<ul>
<li>The easiest way is to invoke the boolean method <b>isParPresent:</b>,
passing the parameter tag as the argument.  An
equivalent C function, <b>MKIsNoteParPresent()</b> is also provided
for greater efficiency.</li>

<li> At a lower lever, you can invoke the <b>parVector:</b> method
to retrieve one of a MKNote's &ldquo;parameter bit vectors&rdquo;,
integers that the MKNote uses internally to indicate which parameters
are present.  You query a parameter bit vector by masking it with the
parameter's tag:
	
<pre>
// A MKNote may have more then one bit vector to accommodate all
// its parameters.

int parVector = [aNote parVector: (MK_amp / 32)];
	
// If MK_amp is present, the predicate will be true.
if (parVector &amp; (1 &lt;&lt; (MK_amp \% 32)))
</pre>
</li>
 
<li> If you plan on retrieving the value of the parameter after
you've checked for the parameter's presence, then it's generally more
efficient to go ahead and retrieve the value and <i>then</i> determine
if the parameter is actually set by comparing its value to the
appropriate parameter-not-set value, as given below:
	
<table border=1 cellspacing=2 cellpadding=0 align=center>
<tr>
<td align=left>Retrieval type</td>
<td align=left>No-set value</td>
</tr>
<tr>
<td align=left>int</td>
<td align=left>MAXINT</td>
</tr>
<tr>
<td align=left>double</td>
<td align=left>MK_NODVAL (but see below)</td>
</tr>
<tr>
<td align=left>NSString</td>
<td align=left>\@&ldquo;&rdquo;</td>
</tr>
<tr>
<td align=left>id</td>
<td align=left><b>nil</b></td>
</tr>
</table>

Unfortunately, you can't use MK_NODVAL in a simple comparison
predicate. To check for this return value, you must call the 
in-line function <b>MKIsNoDVal()</b>; the function returns 0 if
its argument is MK_NODVAL and nonzero if not:
	
<pre>
// Retrieve the value of the amplitude parameter.
double amp = [aNote parAsDouble: MK_amp];
	
// Test for the parameter's existence.
if (!MKIsNoDVal(amp))
  ... // do something with the parameter
</pre>
</li>
 
<li> 
If you're looking for and processing a large number of
parameters in one block, then you should make calls to the
<b>MKNextParameter()</b> C function, which returns the values of a
MKNote's extant parameters only.  See the function's description in
Chapter 2 for more details.
</li>
</ul>

A MKNote has two special timing attributes:  A MKNote's time tag
corresponds, conceptually, to the time during a performance that the
MKNote is performed.  Time tags are set through the
<b>setTimeTag:</b> method.  The other timing attribute is the MKNote's
duration, a value that indicates how long the MKNote will endure once
it has been struck. It's set through <b>setDur:</b>. A single MKNote
can have only one time tag and one duration.  Keep in mind, however,
that not all MKNotes need a time tag and a duration.  For example, if
you realize a MKNote by sending it directly to an MKInstrument, then
the MKNote's time tag - indeed, whether it even has a time tag - is
of no consequence; the MKNote's performance time is determined by
when the MKInstrument receives it (although see the
MKScorefileWriter, MKScoreRecorder, and MKPartRecorder class
descriptions for alternatives to this edict).  Similarly, a MKNote
that merely initiates an event, relying on a subsequent MKNote to
halt the festivities, as described in the discussion of <i>note
types</i>, below, doesn't need and actually mustn't be given a
duration value.

During a performance, time tag and duration values are measured in
time units called <i>beats</i>. The size of a beat is
determined by the tempo of the MKNote's MKConductor.  You can set the
MKNote's conductor directory with the method <b>setConductor:</b>.
However, if  the MKNote is in the process of being sent by a
MKPerformer (or MKMidi), the MKPerformer's MKConductor is used
instead.  Hence, MKNote's <b>conductor</b> method returns the
MKPerformer's MKConductor if the MKNote is in the process of being
sent by a MKPerformer, or the MKNote's conductor otherwise.  If no
MKConductor is set, then its MKConductor is the
<i>defaultConductor</i>, which has a default (but not immutable)
tempo of 60.0 beats per minute.

Keep in mind that if you send a MKNote directly to an MKInstrument, then
the MKNote's time tag is (usually) ignored, as described above, but
its duration may be considered and employed by the MKInstrument.

A MKNote has a <i>note type</i> that casts it into one of five roles: 

<ul>
<li>	A noteDur represents an entire musical note (a note with a duration).</li>
<li>	A noteOn establishes the beginning of a note.</li>
<li>	A noteOff establishes the end of a note.</li>
<li>	A noteUpdate represents the middle of a note (it updates a sounding note).</li>
<li>	A mute makes no sound.</li>
</ul>

Only noteDurs may have duration values; the very act of setting a
MKNote's duration changes it to a noteDur.

You match the two MKNotes in a noteOn/noteOff pair by giving them the
same <i>note tag</i> value; a note tag is an integer that identifies
two or more MKNotes as part of the same musical event or phrase.  In
addition to coining noteOn/noteOff pairs, note tags are used to
associate a noteUpdate with a noteDur or noteOn that's in the process
of being performed.  The C function <b>MKNoteTag()</b> is provided to
generate note tag values that are guaranteed to be unique across your
entire application - you should never create a new note tag except
through this function. 

Instead of or in addition to being actively realized, a MKNote object
can be stored.  In a running application, MKNotes are stored within
MKPart objects through the <b>addToPart:</b> method.  A MKNote can
only be added to one MKPart at a time; adding it to a MKPart
automatically removes it from its previous MKPart.  Within a MKPart
object, MKNotes are sorted according to their time tag values.

For long-term storage, MKNotes can be written to a scorefile.  There
are two "safe" ways to write a scorefile: You can add a
MKNote-filled MKPart to a MKScore and then write the MKScore to a
scorefile, or you can send MKNotes during a performance to a
MKScorefileWriter MKInstrument.  The former of these two methods is
generally easier and more flexible since it's done statically and
allows random access to the MKNotes within a MKPart.  The latter
allows MKNote objects to be reused since the file is written
dynamically; it also lets you record interactive performances.

You can also write individual MKNotes in scorefile format to an open
stream by sending <b>writeScorefileStream:</b> to the MKNotes.  This
can be convenient while debugging, but keep in mind, however, that the
method is designed primarily for use by MKScore and MKScorefileWriter
objects; if you write MKNotes directly to a stream that's open to a
file, the  file isn't guaranteed to be recognized by methods that
read scorefiles, such as MKScore's <b>readScorefile:</b>.

MKNote are automatically created by the MusicKit in a number of
circumstances, such as when reading a MKScorefile.  The function
<b>MKSetNoteClass()</b> allows you to specify that your own subclass
of MKNote be used when MKNotes are automatically created.  You
retrieve the MKNote class with <b>MKGetNoteClass()</b>.

*/
#ifndef __MK_Note_H___
#define __MK_Note_H___

#import <Foundation/Foundation.h>
#import <Foundation/NSObject.h>
#import "MKConductor.h"
#import "params.h"

#define BITS_PER_INT 32
#define MK_MKPARBITVECTS ((((int)MK_appPars-1)/ BITS_PER_INT)+1)

/*! 
  @file MKNote.h
 */

/*!
  @brief This enumeration defines the types of MKNote objects.  The types are as follows.
 */
typedef enum _MKNoteType {
    /*! A MKNote with a duration. Can have a noteTag. */
    MK_noteDur = 257,
    /*! The start of a musical note. Must have a noteTag. */
    MK_noteOn,
    /*! The onset of the ending portion of a musical note. Must have a noteTag. */
    MK_noteOff,
    /*! An update to an already-playing musical note.  Can have a noteTag. */
    MK_noteUpdate,
    /*! A MKNote that makes no sound.  May not have a noteTag. */
    MK_mute
} MKNoteType;

/*!
  @brief This enumeration defines the types of parameters in MKNote objects. 
*/
typedef enum _MKDataType {
    /*! Invalid type. */
    MK_noType = ((int)MK_sysReset + 1),
    /*! C Double value. */
    MK_double,  
    /*! Character string value. */
    MK_string,
    /*! C int value. */
    MK_int,
    /*! Generic object value.  Object must implement scorefile object protocol. */
    MK_object,
    /*! MKEnvelope object value.  Object must implement MKEnvelope protocol. */
    MK_envelope, 
    /*! MKWaveTable object value.  Object must implement MKWaveTable protocol. */
    MK_waveTable
} MKDataType;

@interface MKNote: NSObject
{
/*! The MKNote's noteType. */
    MKNoteType noteType;
/*! The MKNote's noteTag. */
    int noteTag;
/*! MKPerformer object that's currently sending the MKNote in performance, if any. */
    MKPerformer *performer;   
/*! The MKPart that this MKNote is a member of, if any. */
    MKPart *part;
/*! Time tag, if any, else MK_ENDOFTIME. */
    double timeTag;
/*! MKConductor to use if performer is nil. If performer is not nil, uses [performer conductor]. */
    MKConductor *conductor;  

@private
    NSHashTable *_parameters;       /* Set of parameter values. */
    unsigned _mkPars[MK_MKPARBITVECTS]; /* Bit vectors specifying presence of MusicKit parameters. */
    unsigned *_appPars; /* Bit-vector for application-defined parameters. */
    unsigned short _highAppPar; /* Highest bit in _appPars (0 if none). */
    /* _orderTag disambiguates simultaneous notes. If it's negative,
       it means that the MKNote is actually slated for deletion. In this case,
       the ordering is the absolute value of _orderTag. */
    int _orderTag;
} 

/*!
  @param  aTimeTag is a double in seconds.
  @brief Sets timeTag as specified and sets type to mute.

  If aTimeTag is MK_ENDOFTIME, the timeTag isn't set.
  Subclasses should send [super initWithTimeTag:aTimeTag] if it overrides 
  this method. 
*/ 
- initWithTimeTag:(double) aTimeTag;

/*!
  @return Returns <b>self</b>.
  @brief Initializes a MKNote that was created through <b>allocFromZone:</b>.
 
  For example:
  	
  <tt>id aNote = [MKNote allocFromZone:aZone];
  [aNote init];</tt>
  
  A newly initialized MKNote's note type is mute.

  Same as [self initWithTimeTag:MK_ENDOFTIME].
  @see  -<b>init:</b>
*/
- init;

/*!
  @brief Removes the receiver from its MKPart, if any, and then frees the
  receiver and its contents.

  The contents of object-valued,
  envelope-valued and wavetable-valued parameters aren't
  freed.  
*/
- (void) dealloc; 

/*! 
  @param  zone is an NSZone.
  @brief Creates and returns a new MKNote object as a copy of the receiver.

  The receiver's parameters, timing information, noteType, and noteTag are
  copied into the new MKNote.  Object-valued parameters are shared by the
  two MKNotes.  The new MKNote's MKPart is set to nil.  
*/
- copyWithZone: (NSZone *) zone; 

/*!
  @brief This method splits a noteDur into a noteOn/noteOff pair, as
  described below.

  The new MKNotes are returned by reference in the
  arguments.  The noteDur itself is left unchanged.  If the receiving
  MKNote isn't a noteDur, this does nothing and returns <b>nil</b>,
  otherwise it returns <b>self</b>. 
  
  The receiving MKNote's MK_relVelocity parameter, if
  present, is copied into the noteOff.  All other
  parameters are copied into (or, in the case of
  object-valued parameters, referenced by) the noteOn.
  The noteOn takes the receiving MKNote's time tag value;
  the noteOff's time tag is that of the MKNote plus its
  duration.  If the receiving MKNote has a note tag, it's
  copied into the noteOn and noteOff; otherwise a new note
  tag is generated for them.  The new MKNotes are added to
  the receiving MKNote's MKPart, if any.
  
  Keep in mind that if while this method replicates the
  noteDur within the noteOn/noteOff pair, it doesn't
  replace the former with the latter.  To do this, you
  must free the noteDur yourself.

  The new MKNotes are returned as retained objects (ie you must
  release them yourself as they are not autoreleased). 
  @param  aNoteOn is an id *.
  @param  aNoteOff is an id *.
  @return Returns an id.
 */
- split: (id *) aNoteOn : (id *) aNoteOff; 

/*!
  @return Returns an MKPerformer instance.
  @brief Returns the MKPerformer that most recently performed the MKNote.

  This is provided, primarily, as part of the implementation of the
  <b>conductor</b> method. 
  
  @see -<b>conductor</b>
*/
- (MKPerformer *) performer; 

/*!
  @return Returns an MKPart instance.
  @brief Returns the MKPart that contains the MKNote, or <b>nil</b> if none.

  By default, a MKNote isn't contained in a MKPart.
  
  @see -<b>addToPart:</b>, -<b>removeFromPart</b>
*/
- (MKPart *) part; 

/*!
  @return Returns an MKConductor instance.
  @brief If the MKNote is being sent by a MKPerformer (or MKMidi), returns the
  MKPerformer's MKConductor.

  Otherwise, if conductor was set with
  <b>setConductor:</b>, returns the <i>conductor</i> instance
  variable.  Otherwise returns the <i>defaultConductor</i>.  A
  MKNote's MKConductor is used, primarily, by MKInstrument objects that
  split noteDurs into noteOn/noteOff pairs; performance of the noteOff
  is scheduled with the MKConductor that's returned by this method.
  
  @see -<b>performer</b>
*/
- (MKConductor *) conductor; 

/*!
  @param  newConductor is an MKConductor instance.
  @brief Sets <i>conductor</i> instance variable.

  Note that <i>newConductor</i> is not archived, nor is it saved when a MKNote 
  is added to a MKPart - it is used only in performance.   Note that -<b>setConductor:</b>
  is called implicitly when a MKNote is copied with the <b>copy</b>
  method. Be careful not to release a MKConductor while leaving a
  dangling reference to it in a MKNote!
  
  @see  -<b>conductor</b>
*/
- (void) setConductor: (MKConductor *) newConductor; 

/*!
  @param  aPart is an id.
  @return Returns the receiver's old MKPart, if any.
  @brief Removes the MKNote from the MKPart that it's currently a member of and adds it to
  <i>aPart</i>.

  This method is equivalent to MKPart's <b>addNote:</b> method.
  
  @see -<b>part</b>, -<b>removeFromPart</b>
*/
- (MKPart *) addToPart: (MKPart *) aPart; 

/*!
  @return Returns a double.
  @brief Returns the MKNote's time tag.

  If the time tag isn't set, MK_ENDOFTIME is returned.
  Time tag values are used to sort the MKNotes within a MKPart.
  
  @see -<b>setTimeTag:</b>
*/
- (double) timeTag; 

/*!
  @param  newTimeTag is a double.
  @return Returns a double.
  @brief Sets the MKNote's time tag to <i>newTimeTag</i> or 0.0, whichever is
  greater (a time tag can't be negative).

  The old time tag value is returned; a return value of MK_ENDOFTIME indicates that the
  time tag hadn't been set. If newTimeTag is negative, it is clipped to 0.0.  Time tags
  are used to sort the MKNotes within a MKPart; if you change the time tag of a MKNote
  that's been added to a MKPart, the MKNote is automatically resorted.
  
  @see -<b>timeTag</b>, -<b>addToPart:</b>, -<b>sort</b> (MKPart)
*/
- (double) setTimeTag: (double) newTimeTag; 

/*!
  @param newTimeTag
  @brief Sets the receiver's timeTag to newTimeTag and returns the old timeTag, or MK_ENDOFTIME if none.
  
  If newTimeTag is negative, it's clipped to 0.0. If newTimeTag is greater than the endTime,
  it is clipped to endTime.

  If the receiver is a member of a MKPart, it's first removed from the
  MKPart, its timeTag is set, and then it's re-added to the MKPart.  This
  ensures that the receiver's position within its MKPart is correct.

  Duration is changed to preserve the endTime of the note

  Note: ONLY works for MK_noteDur type notes! MK_NODVAL returned otherwise.
 */
- (double) setTimeTagPreserveEndTime: (double) newTimeTag;

/*!
  @brief Removes the MKNote from its MKPart.
  @return Returns the MKPart, or <b>nil</b> if none.
  @see  -<b>addToPart:</b>, -<b>part</b>
*/
- (MKPart *) removeFromPart; 

/*!
  @brief Returns a value that indicates which of the receiving MKNote and the
  argument MKNote would appear first if the two MKNotes were sorted
  into the same MKPart.
  
  The values returned are:
 
  <ul>
  <li>	-1 indicates that the receiving MKNote is first.</li>
  <li>	1 means that the argument, <i>aNote</i>, is first.</li>
  <li>	0 is returned if the receiving MKNote and <i>aNote</i> are the same object.</li>
  </ul>
  
  If the timeTags are equal, the comparison is by order in the part.
   
  Keep in mind that the two MKNotes needn't actually be
  members of the same MKPart, nor must they be members of
  MKParts at all.  Naturally, the comparison is judged
  first on the relative values of the two MKNotes' time
  tags; changing one or both of the MKNotes' time tags
  invalidates the result of a previous invocation of this
  method.
  @param  aNote is an MKNote instance.
  @return Returns an int.
*/
-(int) compare: (MKNote *) aNote; 
 /* 
  * If the MKNotes are both not in parts or are in different parts, the
  * result is indeterminate.
  */


/*!
  @return Returns a MKNoteType.
  @brief Returns the MKNote's note type, one of MK_noteDur, MK_noteOn,
  MK_noteOff, MK_noteUpdate, or MK_mute.

  The note type describes the
  character of the MKNote, whether it represents an entire musical
  note (or event), the beginning, middle, or end of a note, or no note
  (no sound). A newly created MKNote is a mute.  A MKNote's note type
  can be set through <b>setNoteType:</b>, although <b>setDur:</b> and
  <b>setNoteTag:</b> may also change it as a side effect.
  
  @see  -<b>setNoteType:</b>, -<b>setDur:</b>, -<b>setNoteTag:</b>
*/
- (MKNoteType) noteType; 

/*!
  @param  newNoteType is a MKNoteType.
  @return Returns <b>self</b>, or <b>nil</b> if <i>newNoteType</i> isn't a valid note type.
  @brief Sets the MKNote's note type to <i>newNoteType</i>.
 
  The note type can be one of:
  
  <ul>
  <li>	MK_noteDur; represents an entire musical note.</li>
  <li>	MK_noteOn; represents the beginning of a note.</li> 
  <li>	MK_noteOff; represents the end of a note.</li> 
  <li>	MK_noteUpdate; represents the middle of a note.</li> 
  <li>	MK_mute; makes no sound.</li>
  </ul>
  
  You should keep in mind that the <b>setDur:</b> method
  automatically sets a MKNote's note type to MK_noteDur;
  <b>setNoteTag:</b> changes mutes into noteUpdates.
  
  @see -<b>noteType</b>, -<b>setNoteTag:</b>, -<b>setDur:</b> 
*/
- setNoteType: (MKNoteType) newNoteType; 

/*!
  @param  value is a double.
  @return Returns a double.
  @brief Sets the MKNote's duration to <i>value</i> beats and sets its note
  type to MK_noteDur.

  If <i>value</i> is negative the duration isn't
  set, the note type isn't changed, and MK_NODVAL is returned (use the
  function <b>MKIsNoDVal()</b> to check for MK_NODVAL); otherwise
  returns <i>value</i>.
  
  @see  -<b>dur</b>, -<b>conductor</b>
*/
- (double) setDur: (double) value;

/*!
  @return Returns a double.
  @brief If the MKNote has a duration, returns the duration, or MK_NODVAL if
  it isn't set (use the function <b>MKIsNoDVal()</b> to check for
  MK_NODVAL).

  This method always returns MK_NODVAL for noteOn,
  noteOff and noteUpdate MKNotes.  It returns a valid dur (if one has
  been set) for noteDur MKNotes.  For mute MKNotes, it returns a valid
  value if the MKNote has an <b>MK_restDur</b> parameter, otherwise it
  returns MK_NODVAL.  This allows you to specify rests with
  durations.
  
  @see  -<b>setDur:</b>
*/
- (double) dur; 

/*!
  @brief Returns the receiver's old end time (duration + timeTag) and sets duration 
  to newEndTime - timeTag, or MK_NODVAL if not a MK_noteDur or MK_mute.
 */
- (double) setEndTime: (double) newEndTime;

/*!
  @brief Returns the receiver's end time (duration + timeTag), or MK_NODVAL if not a MK_noteDur or MK_mute. 
 */
- (double) endTime;

/*!
  @brief Return the MKNote's note tag, or MAXINT if it isn't set.
  @return Returns an int.
  @see  -<b>setNoteTag:</b>, <b>MKNoteTag()</b>
*/
- (int) noteTag; 

/*!
  @param  newTag is an int.
  @return  Returns <b>self</b>.
  @brief Sets the MKNote's note tag to <i>newTag</i>; if the note type is
  <b>MK_mute</b> it's changed to MK_noteUpdate.
  
  MKNote tags are used to associate different MKNotes with
  each other, thus creating an identifiable (by the note
  tag value) "Note stream." For example, you
  create a noteOn/noteOff pair by giving the two MKNotes
  identical note tag values.  Also, you can associate any
  number of noteUpdates with a single noteDur, or with a
  noteOn/noteOff pair, through similarly matching note
  tags.  While note tag values are arbitrary, they should
  be unique across an entire application; to ensure this,
  you should never create noteTag values but through the
  <b>MKNoteTag()</b> C function.
  
  @see -<b>noteTag</b>, <b>MKNoteTag()</b> 
*/
- setNoteTag: (int) newTag; 

/*!
  @return Returns an id.
  @brief Removes the noteTag, if any.

  Same as [self setNoteTag:MAXINT].
*/
- removeNoteTag;

/*!
  @param  aName is a NSString.
  @return Returns an int.
  @brief Returns the integer that identifies the parameter named <i>aName</i>.

  If the named parameter doesn't have an identifier,
  one is created and thereafter associated with the parameter.            
  
  @see -<b>setPar:toDouble:</b>(etc), -<b>isParPresent:</b>, -<b>parNameForTag:</b>  
*/
+ (int) parTagForName: (NSString *) aName; 

/*!
  @brief Returns the name that identifies the parameter tagged <i>aTag</i>.
  
  For example [MKNote parNameForTag: MK_freq] returns "freq".
  If the parameter number given is not a valid parameter number, returns an empty string.
  Note that the string is not copied.
  @param  aTag is an int.
  @return Returns a NSString.
  @see -<b>setPar:toDouble:</b>(etc), -<b>isParPresent:</b>, -<b>parNameForTag:</b> 
*/
+ (NSString *) parNameForTag: (int) aTag;

/*!
  @brief Sets the value of the parameter identified by <i>parameterTag</i> to
  <i>aDouble</i>, and sets its data type to MK_double.

  If <i>aDouble</i> is the special value MK_NODVAL, this method is the
  same as <b>[self removePar:</b> <i>parameterTag</i><b>]</b>.
 
  @param  parameterTag is an int.
  @param  aDouble is a double.
  @return Returns self.
  @see +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>isParPresent:</b>, -<b>parAsDouble:</b> 
*/
- setPar: (int) parameterTag toDouble: (double) aDouble; 

/*!
  @brief Sets the value of the parameter identified by <i>parameterTag</i> to
  <i>anInteger</i>, and sets its data type to MK_int.

  If <i>anInteger</i> is MAXINT, this method is the same as 
  <b>[self removePar:</b> <i>parameterTag</i><b>]</b>. 
  @param  parameterTag is an int.
  @param  anInteger is an int.
  @return Returns <b>self</b>.
  @see +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>isParPresent:</b>, -<b>parAsInteger:</b> 
*/
- setPar: (int) parameterTag toInt: (int) anInteger; 

/*!
  @brief Sets the value of the parameter identified by <i>parameterTag</i> to
  <i>aString</i>, and sets its data type to MK_string.

  If <i>aString</i>is NULL or "", this method is the same as 
  <b>[self removePar:</b><i>parameterTag</i><b>].</b>
  @param  parameterTag is an int.
  @param  aString is an NSString instance.
  @return Returns <b>self</b>.
  @see +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>isParPresent:</b>, -<b>parAsString:</b>
*/
- setPar: (int) parameterTag toString: (NSString *) aString; 

/*!
  @brief Sets the value of the parameter identified by <i>parameterTag</i> to
  <i>anEnvelope</i>, and sets its data type to MK_envelope.

  If <i>anEnvelope</i>is <b>nil</b> , this method is the same as 
  <b>[self removePar:</b> <i>parameterTag</i><b>]</b>.
  @param  parameterTag is an int.
  @param  anEnvelope is an id. TODO Should be an MKEnvelope.
  @return Returns <b>self</b>.
  @see +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>isParPresent:</b>, -<b>parAsEnvelope:</b>
*/
- setPar: (int) parameterTag toEnvelope: (id) anEnvelope; 

/*!
  @brief Sets the value of the parameter identified by <i>parameterTag</i> to
  <i>aWaveTable</i>, and sets its data type to MK_waveTable.

  If <i>aWaveTable</i>is <b>nil</b> , this method is the same as 
  <b>[self removePar:</b> <i>parameterTag</i><b>]</b>.
  @param  parameterTag is an int.
  @param  aWaveTable is an MKWaveTable object.
  @return Returns <b>self</b>.
  @see +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>isParPresent:</b>, -<b>parAsWaveTable:</b>
*/
- setPar: (int) parameterTag toWaveTable: (id) aWaveTable; 

/*!
  @brief Sets the value of the parameter identified by <i>parameterTag</i> to
  <i>anObject</i>, and sets its data type to MK_object.

  If <i>anObject</i>is <b>nil</b>,  this method is the same as 
  <b>[self removePar:</b> <i>parameterTag</i><b>]</b>.
  
  While you can use this method to set the value of a
  parameter to any object, it's designed, principally, to
  allow you to use an instance of one of your own classes
  as a parameter value.  If you want the object to be
  written to and read from a scorefile, it must respond to
  the messages <b>writeASCIIStream:</b> and
  <b>readASCIIStream:</b>.  While response to these
  messages isn't a prerequisite for an object to be used
  as the argument to this method, if you try to write a
  MKNote that contains a parameter that doesn't respond to
  <b>writeASCIIStream:</b>, an error is generated. An object's ASCII representation
  shouldn't contain the character ']'.
  
  Note that unless you really need to write your object to
  a Scorefile, you are better off saving your object using
  the NXTypedStream archiving mechanism.
  
  None of the MusicKit classes implement <b>readASCIIStream:</b> or
  <b>writeASCIIStream:</b> so you can't use this method to set a parameter to a
  MusicKit object. If you're setting the value as an MKEnvelope or MKWaveTable
  object, you should use the <b>setPar:toEnvelope:</b> or
  <b>setPar:toWaveTable:</b> method, respectively.
  @param  parameterTag is an int.
  @param  anObject is an id.
  @return Returns <b>self</b>.
  @see +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>isParPresent:</b>, -<b>parAsObject:</b> 
*/
- setPar: (int) parameterTag toObject: (id) anObject; 

/*!
  @brief Returns a <b>double</b> value converted from the value of the
  parameter <i>identified by parameterTag</i>.

  If the parameter isn't present or if its value is an object, 
  returns MK_NODVAL (use the function <b>MKIsNoDVal()</b> to check for MK_NODVAL).
  You should use the <b>freq</b> method if you're want to retrieve the frequency of
  the MKNote.
  @param  parameterTag is an int.
  @return Returns a double.
  @see <b>MKGetNoteParAsDouble()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, -<b>isParPresent:</b> 
*/
- (double) parAsDouble: (int) parameterTag; 

/*!
  @brief Returns an <b>int</b> value converted from the value of the parameter identified by <i>parameterTag</i>.
  
  If the parameter isn't present, or if its value is an object, returns MAXINT.
  @param  parameterTag is an int.
  @return Returns an int.
  @see  <b>MKGetNoteParAsInt()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, <b>isParPresent:</b>
*/
- (int) parAsInt: (int) parameterTag; 

/*!
  @brief Returns a <b>string</b> converted from a copy of the value of the parameter identified by <i>parameterTag</i>.
  
  If the parameter isn't present, or if its value is an object, returns an empty string.
  @param  parameterTag is an int.
  @return Returns an NSString.
  @see <b>MKGetNoteParAsString()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, <b>isParPresent:</b>
*/
- (NSString *) parAsString: (int) parameterTag; 

/*!
  @brief Returns a <b>string</b> converted from a the value of the parameter identified by<i> parameterTag</i>.
  
  If the parameter was set as a string, then this returns a pointer to the actual string itself;
  you should neither delete nor alter the value returned by this
  method.  If the parameter isn't present, or if its value is an
  object, returns an empty string.
  
  @param  parameterTag is an int.
  @return Returns an NSString.
  @see <b>MKGetNoteParAsStringNoCopy()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, -<b>isParPresent:</b>
*/
- (NSString *) parAsStringNoCopy: (int) parameterTag; 

/*!
  @brief Returns the MKEnvelope value of <i>parameterTag</i>.
  
  If the parameter isn't present or if its value isn't an MKEnvelope, returns <b>nil</b>.
  @param  parameterTag is an int.
  @return Returns an id.
  @see  <b>MKGetNoteParAsEnvelope()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, -<b>isParPresent:</b>
*/
- parAsEnvelope: (int) parameterTag; 

/*!
  @brief Returns the MKWaveTable value of the parameter identified by <i>parameterTag</i>.
  
  If the parameter isn't present, or if it's value isn't a MKWaveTable, returns <b>nil</b>.
  @param  parameterTag is an int.
  @return Returns an id.
*/
- parAsWaveTable: (int) parameterTag;

/*!
  @brief Returns the object value of the parameter identified by <i>parameterTag</i>.
  
  If the parameter isn't present, or if its value isn't an object, returns <b>nil</b>.
  This method can be used to return MKEnvelope and MKWaveTable objects, in addition to non-MusicKit
  objects.
  @param  parameterTag is an int.
  @return Returns an id.
  @see  <b>MKGetNoteParAsObject()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, -<b>isParPresent:</b>
*/
- parAsObject: (int) parameterTag; 

/*!
  @brief Returns <b>YES</b> if the parameter <i>identified by
  parameterTag</i> is present in the MKNote (in other words, if its
  value has been set), and <b>NO</b> if it isn't.
  @see -<b>parVector:</b>, <b>MKIsNoteParPresent()</b>, <b>MKNextParameter()</b>, +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>setPar:toDouble:</b> (etc), -<b>parAsDouble:</b> (etc).
  @param  parameterTag is an int.
  @return Returns a BOOL.
*/
- (BOOL) isParPresent: (int) parameterTag;

/*!
  @brief Returns the data type of <i>the value of the parameter identified by parameterTag</i>.

  The data type is set when the parameter's value
  is set; the specific data type of the value, one of the MKDataType
  constants listed below, depends on which method you used to set it:
  
 <table border=1 cellspacing=2 cellpadding=0 align=center>
 <tr>
 <td align=left>Method</td>
 <td align=left>Data type</td>
 </tr>
 <tr>
 <td align=left>setPar:toInt:</td>
 <td align=left>MK_int</td>
 </tr>
 <tr>
 <td align=left>setPar:toDouble:</td>
 <td align=left>MK_double</td>
 </tr>
 <tr>
 <td align=left>setPar:toString:</td>
 <td align=left>MK_string</td>
 </tr>
 <tr>
 <td align=left>setPar:toWaveTable:</td>
 <td align=left>MK_waveTable</td>
 </tr>
 <tr>
 <td align=left>setPar:toEnvelope:</td>
 <td align=left>MK_envelope</td>
 </tr>
 <tr>
 <td align=left>setPar:toObject:</td>
 <td align=left>MK_object</td>
 </tr>
 </table>
 
  If the parameter's value hasn't been set, MK_noType is returned.
  @param  parameterTag is an int.
  @return Returns a MKDataType.
  @see  <b>MKGetNoteParAsWaveTable()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, -<b>isParPresent:</b>
*/
- (MKDataType) parType: (int) parameterTag; 

/*!
  @brief Removes the parameter identified by <i>parameterTag</i> from the
  MKNote; in other words, this sets the parameter's value to indicate
  that the parameter isn't set.

  If the parameter was present, then the MKNote is returned; if not, <b>nil</b> is returned.
  @param  parameterTag is an int.
  @return Returns an id.
  @see  +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>isParPresent:</b>, -<b>setPar:toDouble:</b> (etc).
*/
- removePar: (int) parameterTag; 

/*!
  @brief Copies <i>aNote</i>'s parameters into the receiving MKNote.

  Object-valued parameters are shared by the two MKNotes.
  @param  aNote is an MKNote instance.
  @return Returns <b>self</b>.
  @see  -<b>copy</b>, -<b>copyFromZone:</b>, -<b>split::</b>
*/
- copyParsFrom: (MKNote *) aNote; 

/*!
  @brief This method returns the MKNote's frequency, measured in Hertz or
  cycles-per-second.

  If the frequency parameter MK_freq is present,
  its value is returned; otherwise, the frequency is converted from
  the key number value given by the MK_keyNum parameter according to
  the installed tuning system (see the MKTuningSystem class).  In the
  absence of both MK_freq and MK_keyNum, MK_NODVAL is returned (use
  the function <b>MKIsNoDVal()</b> to check for MK_NODVAL).  The
  correspondence between key numbers and frequencies is given in
<a href=http://www.musickit.org/MusicKitConcepts/musictables.html>
the section entitled Music Tables
</a>.
  
  Frequency and key number are the only two parameters whose values are
  retrieved through specialized methods.  All other parameter values should be
  retrieved through one of the <b>parAs</b><i>Type</i><b>:</b> methods.
  @return Returns a double.
  @see  -<b>keyNum</b>, -<b>setPar:toDouble:</b>
*/
- (double) freq;

/*!
  @brief This method returns the key number of the MKNote.
  
  Key numbers are integers that enumerate discrete pitches; they're provided primarily
  to accommodate MIDI.  If the MK_keyNum parameter is present, its
  value is returned; otherwise, the key number that corresponds to the
  value of the MK_freq parameter, if present, is returned. This value is
  computed according to the installed tuning system (see the MKTuningSystem class).
  In the absence of both MK_keyNum and MK_freq, MAXINT is returned.
  The correspondence between key numbers and frequencies is given in
<a href=http://www.musickit.org/MusicKitConcepts/musictables.html>
the section entitled Music Tables
</a>.
  
  Frequency and key number are the only two parameters whose values are retrieved through specialized methods.  All other parameter values should be retrieved through one of the <b>parAs</b><i>Type</i><b>:</b> methods.
  @return Returns an int.  
  @see  -<b>freq</b>, -<b>setPar:toInt:</b>
*/
- (int) keyNum; 

/*!
  @brief Writes the MKNote, in scorefile format, to the stream, that is, the data object
  <b><i>aStream</i></b>.

  You rarely invoke this method yourself; it's invoked from the
  scorefile-writing methods defined by MKScore and MKScorefileWriter.
  @param  aStream is a NSMutableData instance.
  @return Returns self.
*/
- writeScorefileStream: (NSMutableData *) aStream; 

/* 
 You never send this message directly.
 Archives parameters, noteType, noteTag, and timeTag. Also archives
 performer and part using MKWriteObjectReference(). 
 */
- (void) encodeWithCoder: (NSCoder *) aCoder;

/* 
 You never send this message directly.  
 Reads MKNote back from archive file. Note that the noteTag is NOT mapped
 onto a unique note tag. This is left up to the MKPart or MKScore with which
 the MKNote is unarchived.
 */
- (id) initWithCoder: (NSCoder *) aDecoder;

/*!
  @brief Returns the number of parameter bit vectors that the MKNote is using
  to accommodate all its parameters identifiers.

  Normally you only need to know this if you're iterating over the parameter vectors.
  @return Returns an int.
  @see  -<b>parVector</b>
*/
- (int) parVectorCount;

/*!
  @brief Returns an integer bit vector that indicates the presence of the
  <i>index</i>'th set of parameters.

  Each bit vector represents 32 parameters. For example, if <i>index</i> is 1, the bits in the
  returned value indicate the presence of parameters 0 through 31,
  where 1 means the parameter is present and 0 means that it's absent.
  An <i>index</i> of 2 returns a vector that represents parameters 32
  through 63, and so on.  To query for the presence of a particular
  parameter, use the following predicate formula:
  	
  <tt>[aNote parVector: (parameterTag / 32)] &amp; (1 &lt;&lt; (parameterTag % 32))</tt>
  
  In this formula, <i>parameterTag</i> identifies the parameter that you're interested
  in. Keep in mind that the parameter bit vectors only indicate the presence of a parameter, not its value.
  @param  index is an unsigned.
  @return Returns an unsigned.
  @see  -<b>parVectorCount</b>, -<b>isParPresent:</b>
*/
- (unsigned) parVector: (unsigned) index;
 /* 
 * Returns a bit vector indicating the presence of parameters 
 * identified by integers (index * BITS_PER_INT) through 
 * ((index + 1) * BITS_PER_INT - 1). For example,
 *
 * .ib
 * unsigned int parVect = [aNote checkParVector:0];
 * .iq
 *
 * returns the vector for parameters 0-31.
 * An argument of 1 returns the vector for parameters 32-63, etc.
 *
 * parVectorCount gives the number of parVectors. For example, if the
 * highest parameter is 65, parVectorCount returns 3.
 */

// for debugging
- (NSString *) description;

/*!
  @brief Allocates and initializes a new MKNote and returns it autoreleased.
  @return Returns a MKNote.
*/
+ note;

/*!
  @brief Allocates and initializes a new MKNote and returns it autoreleased.

  Sets timeTag as specified and sets type to mute.
  If aTimeTag is MK_ENDOFTIME, the timeTag isn't set.
  @param  aTimeTag is a double in seconds.
  @return Returns a MKNote.
*/
+ noteWithTimeTag: (double) aTimeTag; 

@end

/*! 
 @defgroup NoteTagFns Create note tags. 
 */

/*!
  @brief Create note tags. <b>MKNoteTag()</b> returns a note tag value
  that's guaranteed to be unique across your entire application.

  Note tags are positive integers used to identify a series of MKNote
  objects as part of the same musical event, gesture, or phrase.  A common
  use of note tags is to create a noteOn/noteOff pair by giving the two
  MKNotes the same note tag value.  
   
  You should never create note tag values except through these functions.
  @return Returns MAXINT (the maximum note tag value) if a sufficient number of
   note tags aren't available, an unlikely occurrence.
  @ingroup NoteTagFns
*/
extern unsigned MKNoteTag(void);

/*!
  @brief Create note tags. <b>MKNoteTags()</b> returns the first of a
  block of <i>n</i> unique, contiguous note tags.  

  Note tags are positive integers used to identify a series of MKNote
  objects as part of the same musical event, gesture, or phrase.  A common
  use of note tags is to create a noteOn/noteOff pair by giving the two
  MKNotes the same note tag value.  
        
  You should never create note tag values except through these functions.
  @param n is an unsigned.
  @return Returns MAXINT (the maximum note tag value) if a sufficient number of
   note tags aren't available, an unlikely occurrence.
  @see MKNoteTag().
  @ingroup NoteTagFns
*/
extern unsigned MKNoteTags(unsigned n);

/*!
 @defgroup AmplitudeFns Convert amplitude to and from MIDI values.
 */

/*!
  @brief Convert decibels to amplitude.

  <b>MKdB()</b> returns an amplitude value (within the range [0.0, 1.0])
  converted from its argument specified as decibels. The returned value
  can be used to set a MKUnitGenerator's amplitude, for example.  The
  value is converted using the following formula:
   
   	<i>amplitude</i> = 10.0 <i>dB</i> / 20.0 

  For example, MKdB(-60) returns ca. .001 and MKdB(0.0) returns 1.0. 
  @param  dB is a double.
  @return Returns a double.
  @ingroup AmplitudeFns
*/
extern double MKdB(double dB);          

/*!
  @ingroup AmplitudeFns
  @brief Translate loudness from the MusicKit to MIDI. Maps MIDI
  value (such as velocity) onto an amplitude scaler such that 64->1.0,
  127->10.0, and 0->0.

  These functions help you convert MusicKit amplitude values to MIDI
  values and vice versa. This is primarily designed for scaling
  amplitude by a value derived from MIDI velocity.
   
  <b>MKAmpToMidi()</b> and <b>MKMidiToAmp()</b> are
  complementary<b></b> functions that provide a non-linear mapping of
  amplitude to MIDI values, as described below:
   
  <b>MKAmpToMidi(</b>double <i>amp</i><b>)</b> returns 64 + (64 * log10 <i>amp</i>)
  <b>MKMidiToAmp(</b>int <i>midiValue</i><b>)</b> returns 10.0 (<i>midiValue</i> - 64) / 64
   
  This provides a scale in which an amp of 0.0 yields a MIDI value of
  0, 1.0 produces 64, and 10.0 gives 127.  
   
  <b>MKAmpAttenuationToMidi()</b> and <b>MKMidiToAmpAttenuation()</b>
  are similarly complementary, and the curve of the mapping is the same as
  in the foregoing, but the scale is attenuated by a factor of ten:  0.0
  maps to 0, 0.1 to 64, and 1.0 to 127. 
   
  The multiplicity of conversion functions is provided in deference to
  the nature of MIDI volume computation: Unlike DSP-bound amplitude
  values (specifically, the value of the MK_amp parameter), effective
  MIDI volume is a combination of a number of parameters, the primary
  ones being velocity, main volume control, and foot pedal control.
  While the velocity value generated by a MIDI instrument is almost
  never at the maximum, the other values often are.  In general, you
  use <b>MKAmpToMidi()</b> and <b>MKMidiToAmp()</b> (or
  <b>MKMidiToAmpWithSensitivy()</b>) to convert between amplitude and
  velocity.  The amp attenuation functions are used to generate a
  value from or to be applied to one of MIDI controller parameters.

  @param  midiValue is an int.
  @return Returns a double.
  @see <b>MKAmpToMidi()</b>.
*/
extern double MKMidiToAmp(int midiValue);

/*!
  @ingroup AmplitudeFns
  @brief Translate loudness from the MusicKit to MIDI. Same as MKMidiToAmp, but uses sensitivity to control how much effect midiValue has.

  These functions help you convert MusicKit amplitude values to MIDI
  values and vice versa.
   
  <b>MKMidiToAmpWithSensitivity()</b> and
  <b>MKMidiToAmpAttenuationWithSensitivity()</b> are modifications of
  the similarly named MKMidiToAmp and MKMidiToAmpAttenuation
  functions in which an additional sensitivity value, nominally in
  the range 0.0 to 1.0, is used to scale the product of the
  conversion.
  
  The multiplicity of conversion functions is provided in deference
  to the nature of MIDI volume computation: Unlike DSP-bound amplitude
  values (specifically, the value of the MK_amp parameter), effective
  MIDI volume is a combination of a number of parameters, the primary
  ones being velocity, main volume control, and foot pedal control.
  While the velocity value generated by a MIDI instrument is almost
  never at the maximum, the other values often are.  In general, you
  use <b>MKAmpToMidi()</b> and <b>MKMidiToAmp()</b> (or
  <b>MKMidiToAmpWithSensitivy()</b>) to convert between amplitude and
  velocity.  The amp attenuation functions are used to generate a
  value from or to be applied to one of MIDI controller parameters.
  @param midiValue is an int.  @param sensitivity is a double.
  @return Returns a double.
  @see <b>MKAmpToMidi()</b>.
*/
extern double MKMidiToAmpWithSensitivity(int midiValue, double sensitivity);

/*!
  @ingroup AmplitudeFns
  @brief Translate loudness from the MusicKit to MIDI. Maps an amplitude scaler onto velocity such that MKAmpToMidi(MKMidiToAmp(x)) == x.

  <b>These functions help you convert MusicKit amplitude values to MIDI
  values and vice versa.</b>
   
  <b>MKAmpToMidi()</b> and <b>MKMidiToAmp()</b> are
  complementary<b></b> functions that provide a non-linear mapping of
  amplitude to MIDI values, as described below:
   
 <b>MKAmpToMidi(</b>double <i>amp</i><b>)</b> returns 64 + (64 * log10 <i>amp</i>)
 <b>MKMidiToAmp(</b>int <i>midiValue</i><b>)</b> returns 10.0 (<i>midiValue</i> - 64) / 64
   
  This provides a scale in which an amp of 0.0 yields a MIDI value of
  0, 1.0 produces 64, and 10.0 gives 127.  
   
  The multiplicity of conversion functions is provided in deference to
  the nature of MIDI volume computation: Unlike DSP-bound amplitude
  values (specifically, the value of the MK_amp parameter), effective
  MIDI volume is a combination of a number of parameters, the primary
  ones being velocity, main volume control, and foot pedal control.
  While the velocity value generated by a MIDI instrument is almost
  never at the maximum, the other values often are.  In general, you
  use <b>MKAmpToMidi()</b> and <b>MKMidiToAmp()</b> (or
  <b>MKMidiToAmpWithSensitivy()</b>) to convert between amplitude and
  velocity.  The amp attenuation functions are used to generate a
  value from or to be applied to one of MIDI controller parameters.
  @param amp is a double.
  @return Returns an int.
*/
extern int MKAmpToMidi(double amp);

/*!
  @ingroup AmplitudeFns
  @brief Translate loudness from the MusicKit to MIDI. Maps MIDI controller values (e.g. volume pedal) onto an amplitude scaler such that 64->0.1, 127->1.0, and 0->0. 

  <b>These functions help you convert MusicKit amplitude values to MIDI
  values and vice versa.</b>
   
  <b>MKAmpAttenuationToMidi()</b> and <b>MKMidiToAmpAttenuation()</b>
  are similarly complementary, and the curve of the mapping is the
  same as MKAmpToMidi() and MKMidiToAmp, but the scale is attenuated
  by a factor of ten: 0.0 maps to 0, 0.1 to 64, and 1.0 to 127.
   
  The multiplicity of conversion functions is provided in deference to
  the nature of MIDI volume computation: Unlike DSP-bound amplitude
  values (specifically, the value of the MK_amp parameter), effective
  MIDI volume is a combination of a number of parameters, the primary
  ones being velocity, main volume control, and foot pedal control.
  While the velocity value generated by a MIDI instrument is almost
  never at the maximum, the other values often are.  In general, you
  use <b>MKAmpToMidi()</b> and <b>MKMidiToAmp()</b> (or
  <b>MKMidiToAmpWithSensitivy()</b>) to convert between amplitude and
  velocity.  The amp attenuation functions are used to generate a
  value from or to be applied to one of MIDI controller parameters.

  @param  midiValue is an int.
  @return Returns a double.
  @see <b>MKMidiToAmp()</b>, <b>MKAmpToMidi()</b>, <b>MKAmpToMidi()</b>.
*/
extern double MKMidiToAmpAttenuation(int midiValue);

/*!
  @ingroup AmplitudeFns
  @brief Translate loudness from the MusicKit to MIDI. Maps MIDI
  controller values (e.g. volume pedal) onto an amplitude scaler such
  that 64->0.1, 127->1.0, and 0->0. Uses sensitivity to control how
  much effect midiValue has.

  <b>These functions help you convert MusicKit amplitude values to MIDI
  values and vice versa.</b>
   
  <b>MKAmpToMidi()</b> and <b>MKMidiToAmp()</b> are
  complementary<b></b> functions that provide a non-linear mapping of
  amplitude to MIDI values, as described below:
   
   	<b>MKAmpToMidi(</b>double <i>amp</i><b>)</b>	returns		64 + (64 *
  log10 <i>amp</i>)
   	<b>MKMidiToAmp(</b>int <i>midiValue</i><b>)</b>	returns 
  10.0(<i>midiValue</i>-64)/64
   
  This provides a scale in which an amp of 0.0 yields a MIDI value of
  0, 1.0 produces 64, and 10.0 gives 127.  
   
  <b>MKMidiToAmpWithSensitivity()</b> and <b>MKMidiToAmpAttenuationWithSensitivity()</b> 
  are modifications of the similarly named MKMidiToAmp and MKMidiToAmpAttenuation
  functions in which an additional sensitivity value, nominally in the range
  0.0 to 1.0, is used to scale the product of the conversion. 
  
  The multiplicity of conversion functions is provided in deference to
  the nature of MIDI volume computation:  Unlike DSP-bound amplitude
  values (specifically, the value of the MK_amp parameter), effective MIDI
  volume is a combination of a number of parameters, the primary ones
  being velocity, main volume control, and foot pedal control.  While the
  velocity value generated by a MIDI instrument is almost never at the
  maximum, the other values often are.  In general, you use
  <b>MKAmpToMidi()</b> and <b>MKMidiToAmp()</b> (or <b>MKMidiToAmpWithSensitivy()</b>)
  to convert between amplitude and velocity.  The amp attenuation 
  functions are used to generate a value from or to be applied to one
  of MIDI controller parameters.
  @param  midiValue is an int.
  @param  sensitivity is a double.
  @return Returns a double.
  @see <b>MKAmpToMidi()</b>.
*/
extern double MKMidiToAmpAttenuationWithSensitivity(int midiValue, double sensitivity);

/*!
  @ingroup AmplitudeFns
  @brief Translate loudness from the MusicKit to MIDI. Maps an
  amplitude scaler onto velocity such that
  MKAmpAttenuationToMidi(MKMidiToAmpAttenuation(x)) == x. 

  <b>These functions help you convert MusicKit amplitude values to MIDI
  values and vice versa.</b>
   
   <b>MKAmpToMidi()</b> and <b>MKMidiToAmp()</b> are
  complementary<b></b> functions that provide a non-linear mapping of
  amplitude to MIDI values, as described below:
   
   	<b>MKAmpToMidi(</b>double <i>amp</i><b>)</b>	returns		64 + (64 *
  log10 <i>amp</i>)
   	<b>MKMidiToAmp(</b>int <i>midiValue</i><b>)</b>	returns 
  10.0(<i>midiValue</i>-64)/64
   
  This provides a scale in which an amp of 0.0 yields a MIDI value of
  0, 1.0 produces 64, and 10.0 gives 127.  
   
  <b>MKAmpAttenuationToMidi()</b> and <b>MKMidiToAmpAttenuation()</b>
  are similarly complementary, and the curve of the mapping is the same as
  in the foregoing, but the scale is attenuated by a factor of ten:  0.0
  maps to 0, 0.1 to 64, and 1.0 to 127. 
   
  <b>MKMidiToAmpWithSensitivity()</b> and <b>MKMidiToAmpAttenuationWithSensitivity()</b>
  are modifications of the similarly named MKMidiToAmp and MKMidiToAmpAttenuation functions
  in which an additional sensitivity value, nominally in the range 0.0 to 1.0, is used to 
  scale the product of the conversion. 
   
  The multiplicity of conversion functions is provided in deference to
  the nature of MIDI volume computation:  Unlike DSP-bound amplitude
  values (specifically, the value of the MK_amp parameter), effective MIDI
  volume is a combination of a number of parameters, the primary ones
  being velocity, main volume control, and foot pedal control.  While the
  velocity value generated by a MIDI instrument is almost never at the
  maximum, the other values often are.  In general, you use
  <b>MKAmpToMidi()</b> and <b>MKMidiToAmp()</b> (or <b>MKMidiToAmpWithSensitivy()</b>)
  to convert between amplitude and velocity.  The amp attenuation functions are used to
  generate a value from or to be applied to one of MIDI controller parameters.
  @param  amp is a double.
  @return Returns an int.
  @see MKAmpToMidi().
*/
extern int MKAmpAttenuationToMidi(double amp);

/*!
 @defgroup ParameterFns Query for a MKNote's parameters.
 */

/*!
  @brief Returns the parameter tag of the highest numbered parameter.
 
  This can be used, for example, to print the names of all known parameters as follows:
 
<pre>
  for (i = 0; i <= MKHighestPar(); i++) 
     printf([MKNote parNameForTag: i]);
</pre>
  @return Returns an int.
  @see <b>MKGetNoteParAsDouble()</b>, <b>MKGetNoteParAsInt()</b>, 
  <b>MKIsNoDVal()</b>, <b>MKIsNoteParPresent()</b>, etc.
  @ingroup ParameterFns
 */
extern int MKHighestPar(void);

/*!
  @brief Query for a MKNote's parameters

  <b>MKInitParameterIteration()</b> and <b>MKNextParameter()</b> work
  together to return, one by one, the full complement of a MKNote's
  parameter identifiers.  <b>MKInitParameterIteration()</b> primes its
  MKNote argument for successive calls to <b>MKNextParameter()</b>, each
  of which retrieves the next parameter in the MKNote.  When all the
  parameters have been visited, <b>MKNextParameter()</b> returns the value
  MK_noPar.  The pointer returned by <b>MKInitParameterIteration()</b>
  must be passed as the <i>iterationState</i> argument to
  <b>MKNextParameter()</b>.  Keep in mind that <b>MKNextParameter()</b>
  returns parameter identifiers; you still must retrieve the value of the
  parameter.  An example for your delight:
   
<pre>
// Initialize the iteration state for the desired MKNote. 
void *aState = MKInitParameterIteration(aNote);
int par;

// Get the parameters until the MKNote is exhausted. 
while ((par = MKNextParameter(aNote, aState)) != MK_noPar) {
    // Operate on the parameters of interest. 
    switch (par) 
    {
	case MK_freq:
	    // Get the value of MK_freq and apply it. 
	    ... 
	    break;
	case MK_amp:
	    // Get the value of MK_amp and apply it. 
	    ... 
	    break;
	default: 
	    // Ignore all other parameters. 
	    break;  
    }
}
</pre>
   
  In essence, this example and the example shown in MKIsNoteParPresent() do the same
  thing:  They find and operate on parameters of interest.  Which methodology to 
  adopt - whether to test for the existence of  particular parameters as in the first
  example, or to retrieve the identifiers of all present parameters as in
  the second - depends on how &ldquo;saturated&rdquo; the MKNote is with
  interesting parameters.  If you only want a couple of parameters then
  it's generally more efficient to call <b>MKIsNoteParPresent()</b> for
  each of them.  However, if you're interested in most - or what you
  assume to be most - of a MKNote's parameters (as is usually the case for
  a reasonably sophisticated MKSynthPatch, for example), then it's
  probably faster to iterate over all the parameters through
  <b>MKNextParameter()</b>.  
   
  @param  aNote is a MKNote instance.
  @return Returns a NSHashEnumerator.
  @see <b>MKIsNoteParPresent()</b>, <b>MKGetNoteParAsDouble()</b>, <b>MKGetNoteParAsInt()</b>,
  <b>MKIsNoDVal()</b>, etc.
  @ingroup ParameterFns
*/
extern NSHashEnumerator *MKInitParameterIteration(MKNote *aNote);

/*!
  @brief Retrieve the next parameter.

  <b>MKInitParameterIteration()</b> and <b>MKNextParameter()</b> work
  together to return, one by one, the full complement of a MKNote's
  parameter identifiers.  <b>MKInitParameterIteration()</b> primes its
  MKNote argument for successive calls to <b>MKNextParameter()</b>, each
  of which retrieves the next parameter in the MKNote.  When all the
  parameters have been visited, <b>MKNextParameter()</b> returns the value
  MK_noPar.  The pointer returned by <b>MKInitParameterIteration()</b>
  must be passed as the <i>iterationState</i> argument to
  <b>MKNextParameter()</b>.  Keep in mind that <b>MKNextParameter()</b>
  returns parameter identifiers; you still must retrieve the value of the
  parameter. 
  It is illegal to reference aState after MKNextParameter() has returned
  <b>MK_noPar</b>.
 
  @param  aNote is a Note.
  @param  iterationState is a NSHashEnumerator *.
  @return Returns an int.
  @see <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>, <b>MKGetNoteParAsDouble()</b>, 
       <b>MKGetNoteParAsInt()</b>, <b>MKIsNoDVal()</b>, etc.
  @ingroup ParameterFns
*/
extern int MKNextParameter(MKNote *aNote, NSHashEnumerator *iterationState);

/*!
  @defgroup NoteParameterFns Set and retrieve a MKNote's parameters. Functions that are equivalent to MKNote methods, for speed. 
 */

/*@{*/

/*!
  @ingroup NoteParameterFns
  @brief Set a MKNote's parameter to a double value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar:MK_freq toDouble:440.0]</b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is an MKNote instance.
  @param  par is an int.
  @param  value is a double.
  @return The <b>MKSetParTo...()</b> functions return <i>aNote</i>, or <b>nil</b>
   if either <i>aNote</i> is <b>nil</b> or <i>par</i> isn't a valid
   parameter identifier. 

   The <b>MKGetParAs...()</b> functions
   return the<i></i> requested value, or <b>nil</b> if either <i>aNote</i>
   is <b>nil</b> of <i>par</i> isn't a valid parameter identifier.  If the
   parameter value hasn't been set, an indicative value is
   returned:

<table border=1 cellspacing=2 cellpadding=0 align=center>
<tr>
<td align=left>Function</td>
<td align=left>No-set return value</td>
</tr>
<tr>
<td align=left>MKGetNoteParAsInt()</td>
<td align=left>MAXINT</td>
</tr>
<tr>
<td align=left>MKGetNoteParAsDouble()</td>
<td align=left>MK_NODVAL (check with <b>MKIsNoDVal()</b>)</td>
</tr>
<tr>
<td align=left>MKGetNoteParAsString()</td>
<td align=left>""</td>
</tr>
<tr>
<td align=left>MKGetNoteParAsStringNoCopy()</td>
<td align=left>""</td>
</tr>
<tr>
<td align=left>MKGetNoteParAsEnvelope()</td>
<td align=left><b>nil</b></td>
</tr>
<tr>
<td align=left>MKGetNoteParAsWaveTable()</td>
<td align=left><b>nil</b></td>
</tr>
<tr>
<td align=left>MKGetNoteParAsObject()</td>
<td align=left><b>nil</b></td>
</tr>
</table>

  @see <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>, <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>.
*/
extern id MKSetNoteParToDouble(MKNote *aNote, int par, double value);

/*!
  @ingroup NoteParameterFns
  @brief Set a MKNote's parameter to an integer value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar:MK_freq toDouble:440.0] </b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is a MKNote isntance.
  @param  par is an int.
  @param  value is an int.
  @see <b>MKSetNoteParToDouble()</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern id MKSetNoteParToInt(MKNote *aNote, int par, int value);

/*!
  @ingroup NoteParameterFns
  @brief Set a MKNote's parameter to a NSString value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar: MK_freq toDouble: 440.0]</b></tt>
     
  As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is a MKNote instance.
  @param  par is an int.
  @param  value is a NSString.
  @see <b>MKSetNoteParToDouble()</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern id MKSetNoteParToString(MKNote *aNote, int par, NSString *value);

/*!
  @ingroup NoteParameterFns
  @brief Set a MKNote's parameter to a MKEnvelope value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar:MK_freq toDouble:440.0] </b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is an MKNote instance.
  @param  par is an int.
  @param  envObj is an MKEnvelope instance.
  @see <b>MKSetNoteParToDouble()</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern id MKSetNoteParToEnvelope(MKNote *aNote, int par, id envObj);

/*!
  @ingroup NoteParameterFns
  @brief Set a MKNote's parameter to a MKWaveTable value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar: MK_freq toDouble: 440.0]</b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is an MKNote instance.
  @param  par is an int.
  @param  waveObj is a MKWaveTable instance.
  @see <b>MKSetNoteParToDouble()</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern id MKSetNoteParToWaveTable(MKNote *aNote, int par, id waveObj);

/*!
  @ingroup NoteParameterFns
  @brief Set a MKNote's parameter to an Object value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar:MK_freq toDouble:440.0] </b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is a MKNote instance.
  @param  par is an int.
  @param  anObj is an id.
  @see <b>MKSetNoteParToDouble()</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern id MKSetNoteParToObject(MKNote *aNote, int par, id anObj);

/*!
  @ingroup NoteParameterFns
  @brief Retrieve an MKNote's parameter as a double value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar:MK_freq toDouble:440.0] </b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is a MKNote instance.
  @param  par is an int.
  @return The <b>MKGetParAs...()</b> functions return the requested
  value, or <b>nil</b> if either <i>aNote</i>
   is <b>nil</b> of <i>par</i> isn't a valid parameter identifier.  If the
   parameter value hasn't been set, an indicative value is
   returned:

 <table border=1 cellspacing=2 cellpadding=0 align=center>
 <tr>
 <td align=left>Function</td>
 <td align=left>No-set return value</td>
 </tr>
 <tr>
 <td align=left>MKGetNoteParAsInt()</td>
 <td align=left>MAXINT</td>
 </tr>
 <tr>
 <td align=left>MKGetNoteParAsDouble()</td>
 <td align=left>MK_NODVAL (check with <b>MKIsNoDVal()</b>)</td>
 </tr>
 <tr>
 <td align=left>MKGetNoteParAsString()</td>
 <td align=left>""</td>
 </tr>
 <tr>
 <td align=left>MKGetNoteParAsStringNoCopy()</td>
 <td align=left>""</td>
 </tr>
 <tr>
 <td align=left>MKGetNoteParAsEnvelope()</td>
 <td align=left><b>nil</b></td>
 </tr>
 <tr>
 <td align=left>MKGetNoteParAsWaveTable()</td>
 <td align=left><b>nil</b></td>
 </tr>
 <tr>
 <td align=left>MKGetNoteParAsObject()</td>
 <td align=left><b>nil</b></td>
 </tr>
 </table>

  @see <b>MKSetNoteParToDouble()</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>.
*/
extern double MKGetNoteParAsDouble(MKNote *aNote, int par);

/*!
  @ingroup NoteParameterFns
  @brief Retrieve an MKNote's parameter as an integer value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar:MK_freq toDouble:440.0] </b></tt>
     
  As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is a MKNote instance.
  @param  par is an int.
  @return Returns an integer.
  @see <b>MKSetNoteParToDouble()</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern int MKGetNoteParAsInt(MKNote *aNote, int par);

/*!
  @ingroup NoteParameterFns
  @brief Retrieve an MKNote's parameter as a NSString value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar:MK_freq toDouble:440.0]</b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is a Note.
  @param  par is an int.
  @return Returns an NSString instance.
  @see <b>MKSetNoteParToDouble()</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern NSString *MKGetNoteParAsString(MKNote *aNote, int par);

/*!
  @ingroup NoteParameterFns
  @brief Retrieve an MKNote's parameter as a NSString value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar:MK_freq toDouble:440.0] </b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is a MKNote instance.
  @param  par is an int.
  @see <b>MKSetNoteParToDouble()</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern NSString *MKGetNoteParAsStringNoCopy(MKNote *aNote, int par);

/*!
  @ingroup NoteParameterFns
  @brief Retrieve an MKNote's parameter as an MKEnvelope value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0)</b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar: MK_freq toDouble: 440.0]</b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is a Note.
  @param  par is an int.
  @return Returns an MKEnvelope instance.
  @see <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern id MKGetNoteParAsEnvelope(MKNote *aNote, int par);

/*!
  @ingroup NoteParameterFns
  @brief Retrieve an MKNote's parameter as an MKWaveTable value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar:MK_freq toDouble:440.0] </b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is a MKNote instance.
  @param  par is an int.
  @return Returns an MKWaveTable instance.
  @see <b>MKSetNoteParToDouble</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern id MKGetNoteParAsWaveTable(MKNote *aNote, int par);

/*!
  @ingroup NoteParameterFns
  @brief Retrieve an MKNote's parameter as an object value.

  These functions set and retrieve the values of a MKNote's parameters,
  one parameter at a time. They're equivalent to the similarly named
  MKNote methods<b>; for example, the function call </b>
     
   <tt><b>MKSetNoteParToDouble(aNote, MK_freq, 440.0) </b></tt>
     
   is the same as the message:
   
   <tt><b>[aNote setPar:MK_freq toDouble:440.0] </b></tt>
     
   As ever, calling a function is somewhat faster than sending a
  message, thus you may want to use these functions, rather than the
  corresponding methods, if you're examining and manipulating barrels of
  parameters, or in situations where speed is crucial.  See the method
  descriptions in the MKNote class for more information (by implication)
  regarding the operations of these functions.
  @param  aNote is a Note.
  @param  par is an int.
  @return Returns an id.
  @see <b>MKSetNoteParToDouble()</b>, <b>MKIsNoteParPresent()</b>, <b>MKInitParameterIteration()</b>,
  <b>MKNextParameter()</b>, <b>MKIsNoDVal()</b>
*/
extern id MKGetNoteParAsObject(MKNote *aNote, int par);

/*@}*/

/*!
  @brief Query for a MKNote's parameters

  <b>MKIsNoteParPresent()</b> returns YES or NO as the parameter
  <i>par</i> within the MKNote <i>aNote</i> is or isn't present; a
  parameter is considered present only if it's been given a value.  The
  function is equivalent to MKNote's <b>isParPresent:</b> method.  Unless
  the mere existence of the parameter is significant, you would follow a
  call to <b>MKIsNoteParPresent()</b> with a parameter value retrieval
  function, such as <b>MKGetNoteParAsDouble()</b>:
   
<pre>
double freq;
   
// Get the value of MK_freq only if the parameter has been set.
if (MKIsNoteParPresent(aNote, MK_freq)) {
    freq = MKGetParAsDouble(aNote, MK_freq);
    ... // do something with freq.
}
</pre>
      
  @param  aNote is a MKNote instance.
  @param  par is an int.
  @return Returns a BOOL.
  @see <b>MKGetNoteParAsDouble()</b>, <b>MKGetNoteParAsInt()</b>, etc.,
  <b>MKIsNoDVal()</b>
  @ingroup ParameterFns
*/
extern BOOL MKIsNoteParPresent(MKNote *aNote, int par);

#endif
