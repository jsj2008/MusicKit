/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:48  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_PatchTemplate_H___
#define __MK_PatchTemplate_H___

#import <Foundation/NSObject.h>

@interface MKPatchTemplate : NSObject
/* 
 * 
 * A PatchTemplate is a recipe for building a SynthPatch object.  It
 * contains specifications for the UnitGenerator and SynthData objects
 * that are needed and instructions for connecting these objects
 * together.
 * 
 * PatchTemplate's addUnitGenerator:ordered: and addSynthData:length:
 * methods describe the objects that make up the SynthPatch.  It's
 * important to keep in mind that these methods don't add actual objects
 * to the PatchTemplate.  Instead, they specify the types of objects that
 * will be created when the SynthPatch is constructed by the Orchestra.
 * 
 * A PatchTemplate's UnitGenerators are specified by their class, given
 * as the first argument to the addUnitGenerator:ordered: method.  The
 * argument should be a UnitGenerator leaf class, not a master class
 * (leaf and master classes are explained in the UnitGenerator class
 * description).
 * 
 * The UnitGenerator is further described as being ordered or unordered,
 * as the argument to the ordered: keyword is YES or NO.  Ordered
 * UnitGenerators are executed (on the DSP) in the order that they're
 * added to the PatchTemplate; unordered UnitGenerators are executed in
 * an undetermined order.  Usually, the order in which UnitGenerators are
 * executed is significant; for example, if the output of UnitGenerator A
 * is read by UnitGenerator B, then A must be executed before B if no
 * delay is to be incurred.  As a convenience, the addUnitGenerator:
 * method is provided to add UnitGenerators that are automatically
 * declared as ordered.  The advantage of unordered UnitGenerators is
 * that their allocation is less constrained.
 * 
 * SynthDatas are specified by a DSP memory segment and a length.  The
 * memory segment is given as the first argument to addSynthData:length:.
 * This can be either MK_xData, for x data memory, or MK_yData, for y
 * data memory.  Which memory segment to specify depends on where the
 * UnitGenerators that access it expects it to be.  The argument to the
 * length: keyword specifies the size of the SynthData, or how much DSP
 * memory it represents, and is given as DSPDatum (24-bit) words.
 * 
 * A typical use of a SynthData is to create a location called a
 * patchpoint that's written to by one UnitGenerator and then read by
 * another.  A patchpoint, which is always 8 words long, is ordinarily
 * the only way that two UnitGenerators can communicate.  The
 * addPatchPoint: method is provided as a convenient way to add
 * SynthDatas that are used as patchpoints.  The argument to this method
 * is either MK_xPatch or MK_yPatch, for x and y patchpoint memory,
 * respectively.
 * 
 * The four object-adding methods return a unique integer that identifies
 * the added UnitGenerator or SynthData.
 * 
 * Once you have added the requisite synthesis elements to a
 * PatchTemplate, you can specify how they are connected.  This is done
 * through invocations of the to:sel:arg: method.  The first argument is
 * an integer that identifies a UnitGenerator (such as returned by
 * addUnitGenerator:), the last argument is an integer that identifies a
 * SynthData (or patchpoint).  The argument to the sel: keyword is a
 * selector that's implemented by the UnitGenerator and that takes a
 * SynthData object as its only argument.  Typical selectors are
 * setInput: (the UnitGenerator reads from the SynthData) and setOuput:
 * (it writes to the SynthData).  Notice that you can't connect a
 * UnitGenerator directly to another UnitGenerator.
 * 
 * CF: UnitGenerator, SynthData, SynthPatch
 */
{    
    /* All PatchTemplate instance variables are for internal use only */
    id _elementStorage; 
    id _connectionStorage; 
    id *_deallocatedPatches;
    unsigned int _eMemSegments;
    void *_reservedPatchTemplate5;
}

- init;
 /* Initializes new PatchTemplate object. */

- copyWithZone:(NSZone *)zone;
 /* Returns a copy of the PatchTemplate. */

-copy;
 /* Same as [self copyFromZone:[self zone]]; */
   
- to:(unsigned )anObjInt sel:(SEL )aSelector arg:(unsigned )anArgInt; 
 /* 
  * Specifies a connection between the UnitGenerator identified by objInt1
  * and the SynthData identified by objInt2.  The means of the connection
  * are specified in the method aSelector, to which the UnitGenerator must
  * respond.  objInt1 and objInt2 are identifying integers returned by
  * PatchTemplate's add methods.  If either of these arguments are invalid
  * identifiers, the method returns nil, otherwise it returns the
  * receiver.  */

-(unsigned ) addUnitGenerator:aUGClass ordered:(BOOL )isOrdered; 
 /* 
  * Adds a UnitGenerator specification to the receiver.  The UnitGenerator
  * is an instance of aUGClass, a UnitGenerator leaf class.  If isOrdered
  * is YES, then the order in which the specification is added (in
  * relation to the receiver's other UnitGenerators) is the order in which
  * the UnitGenerator, once created, is executed on the DSP.  */

-(unsigned ) addUnitGenerator:aUGClass; 
 /* 
  * Adds an ordered UnitGenerator specification to the receiver.
  * Implemented as [self addUnitGenerator:aUGClass ordered:YES].  Returns
  * an integer that identifies the UnitGenerator specification.  */

-(unsigned ) addSynthData:(MKOrchMemSegment )segment length:(unsigned )len; 
 /* 
  * Adds a SynthData specification to the receiver.  The SynthData has a
  * length of len DSPDatum words and is allocated from the DSP segment
  * segment, which should be either MK_xData or MK_yData.  Returns an
  * integer that identifies the SynthData specification.  */

-(unsigned)addPatchpoint:(MKOrchMemSegment)segment;
 /* 
  * Adds a patchpoint (SynthData) specification to the receiver.  segment
  * is the DSP memory segment from which the patchpoint is allocated.  It
  * can be either MK_xPatch or MK_yPatch.  Returns an integer that
  * identifies the patchpoint specification.  */

-(unsigned)synthElementCount;
 /* 
  * Returns the number of UnitGenerator and SynthData specifications (including
  * patchpoints) that have been added to the receiver.  
*/

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     */
- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
//- awake;
  /* Gets newly unarchived object ready for use. */

+ new; 
 /* Obsolete */

@end



#endif
