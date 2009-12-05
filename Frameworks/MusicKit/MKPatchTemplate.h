/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKPatchTemplate is a recipe for building a MKSynthPatch object.  It
    contains specifications for the MKUnitGenerator and MKSynthData objects
    that are needed and instructions for connecting these objects
    together.

    MKPatchTemplate's addUnitGenerator:ordered: and addSynthData:length:
    methods describe the objects that make up the MKSynthPatch.  It's
    important to keep in mind that these methods don't add actual objects
    to the MKPatchTemplate.  Instead, they specify the types of objects that
    will be created when the MKSynthPatch is constructed by the MKOrchestra.

    A MKPatchTemplate's MKUnitGenerators are specified by their class, given
    as the first argument to the addUnitGenerator:ordered: method.  The
    argument should be a MKUnitGenerator leaf class, not a master class
    (leaf and master classes are explained in the MKUnitGenerator class
    description).

    The MKUnitGenerator is further described as being ordered or unordered,
    as the argument to the ordered: keyword is YES or NO.  Ordered
    MKUnitGenerators are executed (on the DSP) in the order that they're
    added to the MKPatchTemplate; unordered MKUnitGenerators are executed in
    an undetermined order.  Usually, the order in which MKUnitGenerators are
    executed is significant; for example, if the output of MKUnitGenerator A
    is read by MKUnitGenerator B, then A must be executed before B if no
    delay is to be incurred.  As a convenience, the addUnitGenerator:
    method is provided to add MKUnitGenerators that are automatically
    declared as ordered.  The advantage of unordered MKUnitGenerators is
    that their allocation is less constrained.
  
    MKSynthDatas are specified by a DSP memory segment and a length.  The
    memory segment is given as the first argument to addSynthData:length:.
    This can be either MK_xData, for x data memory, or MK_yData, for y
    data memory.  Which memory segment to specify depends on where the
    MKUnitGenerators that access it expects it to be.  The argument to the
    length: keyword specifies the size of the MKSynthData, or how much DSP
    memory it represents, and is given as DSPDatum (24-bit) words.
  
    A typical use of a MKSynthData is to create a location called a
    patchpoint that's written to by one MKUnitGenerator and then read by
    another.  A patchpoint, which is always 8 words long, is ordinarily
    the only way that two MKUnitGenerators can communicate.  The
    addPatchPoint: method is provided as a convenient way to add
    MKSynthDatas that are used as patchpoints.  The argument to this method
    is either MK_xPatch or MK_yPatch, for x and y patchpoint memory,
    respectively.
  
    The four object-adding methods return a unique integer that identifies
    the added MKUnitGenerator or MKSynthData.
  
    Once you have added the requisite synthesis elements to a
    MKPatchTemplate, you can specify how they are connected.  This is done
    through invocations of the to:sel:arg: method.  The first argument is
    an integer that identifies a MKUnitGenerator (such as returned by
    addUnitGenerator:), the last argument is an integer that identifies a
    MKSynthData (or patchpoint).  The argument to the sel: keyword is a
    selector that's implemented by the MKUnitGenerator and that takes a
    MKSynthData object as its only argument.  Typical selectors are
    setInput: (the MKUnitGenerator reads from the MKSynthData) and setOuput:
    (it writes to the MKSynthData).  Notice that you can't connect a
    MKUnitGenerator directly to another MKUnitGenerator.
  
    CF: MKUnitGenerator, MKSynthData, MKSynthPatch

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*!
  @class MKPatchTemplate
  @brief A MKPatchTemplate is a recipe for building a MKSynthPatch object. It contains
specifications for the MKUnitGenerator and MKSynthData objects that are needed and
instructions for connecting these objects together.

MKPatchTemplate's <b>addUnitGenerator:ordered:</b> and <b>addSynthData:length:</b>
methods describe the objects that make up the MKSynthPatch.  It's important to
keep in mind that these methods don't add actual objects to the MKPatchTemplate. 
Instead, they specify the types of objects that will be created when the
MKSynthPatch is constructed by the MKOrchestra.

A MKPatchTemplate's MKUnitGenerators are specified by their class, given as the
first argument to the <b>addUnitGenerator:ordered:</b> method.  The argument
should be a MKUnitGenerator leaf class, not a master class (leaf and master
classes are explained in the MKUnitGenerator class description).

The MKUnitGenerator is further described as being ordered or unordered, as the
argument to the <b>ordered:</b> keyword is YES or NO.  Ordered MKUnitGenerators
are executed (on the DSP) in the order that they're added to the MKPatchTemplate;
unordered MKUnitGenerators are executed in an undetermined order.  Usually, the
order in which MKUnitGenerators are executed is significant; for example, if the
output of MKUnitGenerator A is read by MKUnitGenerator B, then A must be executed
before B if no delay is to be incurred.  As a convenience, the
<b>addUnitGenerator:</b> method is provided to add MKUnitGenerators that are
automatically declared as ordered.  The advantage of unordered MKUnitGenerators is
that their allocation is less constrained.

MKSynthDatas are specified by a DSP memory segment and a length.  The memory
segment is given as the first argument to <b>addSynthData:length:</b>.  This can
be either MK_xData, for x data memory, or MK_yData, for y data memory.  Which
memory segment to specify depends on where the MKUnitGenerators that access it
expects it to be.  The argument to the <b>length:</b> keyword specifies the size
of the MKSynthData, or how much DSP memory it represents, and is given as DSPDatum
(24-bit) words.

A typical use of a MKSynthData is to create a location called a <i>patchpoint</i>
that's written to by one MKUnitGenerator and then read by another.  A patchpoint,
which is always 8 words long, is ordinarily the only way that two MKUnitGenerators
can communicate.  The <b>addPatchPoint:</b> method is provided as a convenient
way to add MKSynthDatas that are used as patchpoints.  The argument to this method
is either MK_xPatch or MK_yPatch, for x and y patchpoint memory,
respectively.

The object-adding methods each return a unique integer that identifies the added
MKUnitGenerator or MKSynthData.

Once you have added the requisite synthesis elements to a MKPatchTemplate, you can
specify how they are connected.  This is done through invocations of the
<b>to:sel:arg:</b> method.  The first argument is an integer that identifies a
MKUnitGenerator (such as returned by <b>addUnitGenerator:</b>), the last argument
is an integer that identifies a MKSynthData (or patchpoint).  The argument to the
<b>sel:</b> keyword is a selector that's implemented by the MKUnitGenerator and
that takes a MKSynthData object as its only argument.  Typical selectors are
<b>setInput:</b> (the MKUnitGenerator reads from the MKSynthData) and
<b>setOuput:</b> (it writes to the MKSynthData).  Notice that you can't connect a
MKUnitGenerator directly to another MKUnitGenerator.

  @see  MKUnitGenerator, MKSynthData, MKSynthPatch
*/
#ifndef __MK_PatchTemplate_H___
#define __MK_PatchTemplate_H___

#import <Foundation/NSObject.h>

@interface MKPatchTemplate : NSObject
{    
    /* All MKPatchTemplate instance variables are for internal use only */
@private
    NSMutableArray *_elementStorage;         /* Array of template entries */
    NSMutableArray *_connectionStorage;      /* Array of MKPatchConnection objects of connection info */
    /* If MKOrchestra is loaded, this is an array of NSMutableArrays of deallocated patches, one per DSP. */
    NSMutableArray **_deallocatedPatches;
    unsigned int _eMemSegments; /* External memory segment bit vector */
}

/*!
  @brief Initializes a new MKPatchTemplate and returns <b>self</b>.
  @return Returns <b>self</b>.
*/
- init;

/*!
  @brief Returns a copy of the MKPatchTemplate. 
  @return Returns an id.
 */
- copyWithZone: (NSZone *) zone;

/*!
  @brief Specifies a connection between the MKUnitGenerator identified by
  <i>objInt1</i> and the MKSynthData identified by <i>objInt2</i>.

  The means of the connection are specified in the method
  <i>aSelector</i>, to which the MKUnitGenerator must respond. 
  <i>objInt1</i> and <i>objInt2</i> are identifying integers returned
  by MKPatchTemplate's add methods. If either of these arguments are
  invalid identifiers, the method returns <b>nil</b>, otherwise it
  returns the receiver.
 @param  anObjInt is an unsigned.
 @param  aSelector is a SEL.
 @param  anArgInt is an unsigned.
 @return Returns an id.
 */
- to: (unsigned) anObjInt sel: (SEL) aSelector arg: (unsigned) anArgInt; 

/*!
  @brief Adds a MKUnitGenerator specification to the receiver.

  The MKUnitGenerator is an instance of <i>aUGClass</i>, a MKUnitGenerator
  leaf class.  If <i>isOrdered</i> is YES, then the order in which the
  specification is added (in relation to the receiver's other
  MKUnitGenerators) is the order in which the MKUnitGenerator, once
  created, is executed on the DSP.
  @param  aUGClass is an id.
  @param  isOrdered is a BOOL.
  @return Returns an unsigned.
 */
- (unsigned) addUnitGenerator: (id) aUGClass ordered: (BOOL) isOrdered; 

/*!
  @brief Adds an ordered MKUnitGenerator specification to the receiver.

  Implemented as <b>[self addUnitGenerator:</b> <i>aUGClass</i> <b>ordered: YES]</b>. 
  @param  aUGClass is an id.
  @return Returns an unsigned integer that identifies the MKUnitGenerator specification.
*/
- (unsigned) addUnitGenerator: (id) aUGClass; 

/*!
  @brief Adds a MKSynthData specification to the receiver.

  The MKSynthData has a length of <i>len</i> DSPDatum words and is allocated from the DSP
  segment <i>segment</i>, which should be either MK_xData or MK_yData.
  @param  segment is a MKOrchMemSegment.
  @param  len is an unsigned.
  @return Returns an unsigned integer that identifies the MKSynthData specification.
 */
- (unsigned) addSynthData: (MKOrchMemSegment) segment length: (unsigned) len; 

/*!
  @brief Adds a patchpoint (MKSynthData) specification to the receiver.
  
  <i>segment</i> is the DSP memory segment from which the patchpoint
  is allocated.  It can be either MK_xPatch or MK_yPatch.  Returns an
  integer that identifies the patchpoint specification.
  @param  segment is a MKOrchMemSegment.
  @return Returns an unsigned.
*/
- (unsigned) addPatchpoint: (MKOrchMemSegment) segment;

/*!
  @brief Returns the number of MKUnitGenerator and MKSynthData specifications
  (including patchpoints) that have been added to the receiver.
  @return Returns an unsigned.
*/
- (unsigned) synthElementCount;

/* 
 You never send this message directly.  
*/
- (void) encodeWithCoder: (NSCoder *) aCoder;

/* 
 You never send this message directly.  
 Should be invoked via NXReadObject(). 
 See write:. 
*/
- (id) initWithCoder: (NSCoder *) aDecoder;

@end

#endif
