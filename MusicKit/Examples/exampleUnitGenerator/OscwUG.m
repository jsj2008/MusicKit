/* This is a minimal implementation of OscwUG.m, a subclass of UnitGenerator.
   It was auto-generated by dspwrap from DSP source code.
   This file and OscwUG.h should be extended and rewritten to provide a 
   higher level, device-independent interface to the SynthPatch programmer.
   See /usr/include/musickit/UnitGenerator.h and the UnitGenerator spec
   for more information regarding unit-generator method design.
*/

#import "OscwUG.h"

@implementation OscwUG:UnitGenerator
{
	/* Instance variables go here */
}

enum args { c, u, aout, s, v };

#import "oscwUGInclude.m"

/*------- Default methods for poking unit generator memory arguments ----------
 * 
 * A default method has been written by dspwrap for every memory argument
 * defined in the unit-generator DSP source file.
 * Each method name is created from the symbolic name specified in
 * the second argument to the new_xarg or new_yarg macro in the DSP
 * source code.  This is also the same name that is used in the 
 * DSPWRAP ARGUMENT INFO comment field to declare the memory argument type.
 * 
 * A UG memory argument may be either a datum or a DSP memory address.
 * At present, a DSPDatum is 24 bits, right justified in a 32-bit int.
 * An address argument is passed as a SynthData object.
 * The method names distinguish between input and output addresses
 * if the "(input)" and "(output)" type qualifiers are used in the
 * DSPWRAP ARGUMENT INFO comment field.
 * 
 * We recommend that you re-implement the datum-setting methods to accept
 * abstract parameters as floating-point numbers between 0 and 1.0, and 
 * physically meaningful parameters as floating-point numbers in natural 
 * physical units such as Hertz, seconds, etc.  Note that only those 
 * arguments which the user needs to set should be exported; internally 
 * managed "state variables" need not be exported.
 */


- setC:(DSPDatum)aFix24 {
	return [self setDatumArg:c to:aFix24];
}

- setU:(DSPDatum)aFix24 {
	return [self setDatumArg:u to:aFix24];
}

- setOutputAout:(id)aPatchPoint {
	return [self setAddressArg:aout to:aPatchPoint];
}

- setS:(DSPDatum)aFix24 {
	return [self setDatumArg:s to:aFix24];
}

- setV:(DSPDatum)aFix24 {
	return [self setDatumArg:v to:aFix24];
}

/*----------------- Default unit-generator control methods --------------------
 * 
 * Only the "idleSelf" method below is actually required, and then
 * only when the unit generator has at least one output.
 */

/* 
 * The "init" method is called once just after the unit generator
 * is instantiated.  Instantiation implies loading of the DSP code.  After
 * instantiation, a unit generator may be allocated and deallocated many
 * times by the Orchestra object in the process of building and freeing
 * SynthPatches.  Initialization happens only the first time.  A nil return
 * normally means there was not sufficient room on the DSP to load the
 * unit generator.
 */
- init {
	if (![super init])
		return nil;
	/* Initialize instance variables here */
	return self;
}

/* 
 * The "idleSelf" method places the UnitGenerator in a "turned off"
 * state. This happens every time a unit generator is "deallocated".
 * At the very least, all outputs must be patched to the special 
 * patchpoint "sink". In rare cases, inputs should be patched to "zero",
 * e.g., Out2sum.
 */
- idleSelf {
	[self setAddressArgToSink:aout];
	return self;
}

/* 
 * The "runSelf" method is invoked when the unit generator is sent the
 * "run" message.  This is done each time before the unit generator is
 * used.  The "runSelf" method should set any default initial state in
 * the unit generator.  For envelopes, as an example, the envelope
 * is triggered (or retriggered) from the beginning by this method.
 * For oscillators, the phase may be reset to zero here.
 * 
 * While "init" happens only once, "run" happens every time 
 * the unit generator is reactivated after an "idle" message.
 * Note that a unit generator may remain loaded on the DSP
 * and belong to several different SynthPatches in succession.
 * Each usage is bracketed by "run" and "idle".
 */
- runSelf {
	return self;
}

@end
