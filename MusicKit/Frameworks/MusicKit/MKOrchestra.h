/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is the allocator and manager of DSP resources.

    The MKOrchestra class is used for managing DSP allocation and control for
    doing sound and music on the DSP. Actually, the MKOrchestra object supports
    multiple DSPs, although in the basic NeXT configuration, there is only one
    DSP.

    The MKOrchestra factory object manages all programs running on all the DSPs.
    Each instances of the MKOrchestra class corresponds to a single DSP. We call
    these instances "orchestra instances"
    or, simply, "orchestras". We call the sum total of all orchestras the
    "Orchestra". Each orchestra instance is referred to by an integer
    'orchIndex'. These indecies start at 0. For the basic
    NeXT configuration, orchIndex is always 0.

    There are two levels of allocation: MKSynthPatch allocation and
    unit generator allocation. MKSynthPatches are higher-level entities,
    collections of MKUnitGenerators. Both levels may be used at the same time.

    CF: MKUnitGenerator.m, MKSynthPatch.m, MKSynthData.m and MKPatchTemplate.m.

  Original Author: David A. Jaffe

  Copyright 1988-1992, NeXT Inc.  All rights reserved.
  DSP Serial Port and subclass support and other 4.0 release extensions,
  Copyright 1993, CCRMA, Stanford Univ.
*/
/*
  $Log$
  Revision 1.7  2000/06/16 23:22:54  leigh
  Imported all of Foundation since we are typing against several classes

  Revision 1.6  2000/06/09 03:27:53  leigh
  Typing of parameters passed to installSharedSynthDataWithSegmentAndLength methods

  Revision 1.5  2000/04/26 01:22:32  leigh
  outputCommandsFile now an NSString

  Revision 1.4  1999/09/20 02:51:38  leigh
  trace: now takes msg of NSString type

  Revision 1.3  1999/09/04 22:02:18  leigh
  Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

  Revision 1.2  1999/07/29 01:25:47  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Orchestra_H___
#define __MK_Orchestra_H___

#import <Foundation/Foundation.h>
#import "orch.h"
#import "MKDeviceStatus.h"
#import "MKSynthData.h"
#import <objc/HashTable.h> // for NXHashTable

typedef enum _MKOrchSharedType {
    MK_noOrchSharedType = 0, 
    MK_oscTable = 1, 
    MK_waveshapingTable = 2,
    MK_excitationTable = 3}
MKOrchSharedType;

typedef enum _MKEMemType {
    MK_orchEmemNonOverlaid = 0, 
    MK_orchEmemOverlaidXYP = 1, 
    MK_orchEmemOverlaidPX = 2}
MKEMemType;

extern double MKGetPreemptDuration(void);
extern void MKSetPreemptDuration(double seconds);
 
@interface MKOrchestra : NSObject
{
    double computeTime;      /* Runtime of orchestra loop in seconds. */
    double samplingRate;  /* Sampling rate. */
    NSMutableArray *stack;      /* Stack of UnitGenerator instances in the order they
                      appear in DSP memory. SynthData instances are not on
                      this stack. */
    NSString *outputSoundfile; /* For output sound samples. */
    id outputSoundDelegate;
    NSString *inputSoundfile; /* For output sound samples. */ /* READ DATA */
    NSString *outputCommandsFile; /* For output DSP commands. */
    id xZero;         /* Special pre-allocated x patch-point that always holds
                         0 and to which nobody ever writes, by convention.  */
    id yZero;         /* Special pre-allocated y patch-point that always holds
                         0 and to which nobody ever writes, by convention.  */
    id xSink;      /* Special pre-allocated x patch-point that nobody ever
                      reads, by convention. */
    id ySink;      /* Special pre-allocated y patch-point that nobody ever
                      reads, by convention. */
    id xModulusSink;/* Special pre-allocated x patch-point that nobody ever
                      reads, by convention. */
    id yModulusSink;/* Special pre-allocated y patch-point that nobody ever
                      reads, by convention. */
    id sineROM;    /* Special read-only SynthData object used to represent
                      the SineROM. */
    id muLawROM;   /* Special read-only SYnthData object used to represent
                      the Mu-law ROM. */
    MKDeviceStatus deviceStatus; /* Status of Orchestra. */
    unsigned short orchIndex;  /* Index of the DSP managed by this instance. */
    char isTimed;    /* Determines whether DSP commands go out timed or not. */
    BOOL useDSP;     /* YES if running on an actual DSP (Default is YES) */
    BOOL hostSoundOut;   /* YES if sound it going to the DACs. */
    BOOL serialSoundOut;
    BOOL serialSoundIn;
    BOOL isLoopOffChip; /* YES if loop has overflowed off chip. */
    BOOL fastResponse;  /* YES if response latency should be minimized */
    double localDeltaT; /* positive offset in seconds added to out-going
                           time-stamps */
    short onChipPatchPoints;
    id serialPortDevice;
    int release;
    char version;
    NSString *monitorFileName;   /* NULL uses default monitor */
    DSPLoadSpec *mkSys;
    char *lastAllocFailStr;
    id _sysUG;
    int _looper;
    void *_availDataMem[3];
    void  *_eMemList[3];
    NSMutableDictionary *_sharedSet;
    DSPAddress _piLoop;
    DSPAddress _xArg;
    DSPAddress _yArg;
    DSPAddress _lArg;
    DSPAddress _maxXArg;
    DSPAddress _maxYArg;
    DSPAddress *_xPatch;
    DSPAddress *_yPatch;
    unsigned long _xPatchAllocBits;
    unsigned long _yPatchAllocBits;
    double _headroom;
    double _effectiveSamplePeriod;
    id _orchloopClass;
    id _previousLosingTemplate;
    DSPFix48 _previousTimeStamp;
    int _parenCount;
    int _bottomOfMemory;
    int _bottomOfExternalMemory[3];
    int _topOfExternalMemory[3];
    int _onChipPPPartitionSize;
    int _numXArgs;
    int _numYArgs;
    float _xArgPercentage;
    float _yArgPercentage;
    void *_simFP;
    MKEMemType _overlaidEMem;
    BOOL _nextCompatibleSerialPort;
    char _errBuff[1024];
    NSString *_driverParMonitorFileName;
    // added in by LMS, thawing the ancient ivar freeze
    double previousTime;
    NXHashTable *sharedGarbage;
    char *simulatorFile;
    id readDataUG;
    id xReadData;
    id yReadData;
    double timeOffset;
    double synchTimeRatio;
    NSTimer *timedEntry;
    BOOL synchToConductor;
}

+ (void)initialize; 
-(MKDeviceStatus)deviceStatus;
- setHeadroom:(double)headroom;
+ setHeadroom:(double)headroom;
-(double)headroom;
- beginAtomicSection;
- endAtomicSection;
+ new; 
+ newOnDSP:(unsigned short)index; 
+ newOnAllDSPs;
+ flushTimedMessages; 
+(unsigned short)DSPCount;
+ nthOrchestra:(unsigned short)index; 
+ (void)dealloc; 
+ open; 
+ run; 
+ stop; 
+ close; 
+ abort;
-(void)synchTime:(NSTimer *)timer;
-(int) tickSize; 
-(double ) samplingRate; 
+ setSamplingRate:(double )newSRate; 
- setSamplingRate:(double )newSRate; 
#define MK_UNTIMED ((char)0)
#define MK_TIMED   ((char)1)
#define MK_SOFTTIMED ((char)2)
+ setTimed:(char )areOrchsTimed; 
- setTimed:(char )isOrchTimed; 
-(char ) isTimed; 
-setSynchToConductor:(BOOL)yesOrNo;
-setFastResponse:(char)yesOrNo;
+setFastResponse:(char)yesOrNo;
-(char)fastResponse;
+ setAbortNotification:aDelegate;
- setLocalDeltaT:(double)val;
- (double)localDeltaT;
+ setLocalDeltaT:(double)val;
- setHostSoundOut:(BOOL)yesOrNo;
-(BOOL)hostSoundOut;
-setSerialSoundOut:(BOOL)yesOrNo;
-(BOOL)serialSoundOut;
-setSerialSoundIn:(BOOL)yesOrNo;
-(BOOL)serialSoundIn;
-setSerialPortDevice:(id)obj;
-serialPortDevice;
-sendSCIByte:(unsigned char)b; 
-sendSCIByte:(unsigned char)b toRegister:(DSPSCITXReg)reg;
-setOutputSoundfile:(NSString *)fileName;
-(NSString *)outputSoundfile;
-setOutputSoundDelegate:aDelegate;
-outputSoundDelegate;
-setOutputCommandsFile:(NSString *)fileName;
-(NSString *)outputCommandsFile;
+ allocUnitGenerator:classObj; 
+ allocSynthData:(MKOrchMemSegment )segment length:(unsigned )size; 
+allocModulusSynthData:(MKOrchMemSegment)segment length:(unsigned )size;
+allocModulusPatchpoint:(MKOrchMemSegment)segment;
+ allocPatchpoint:(MKOrchMemSegment )segment; 
+ allocSynthPatch:aSynthPatchClass;
+ allocSynthPatch:aSynthPatchClass patchTemplate:p;
+ dealloc:aSynthResource;
- flushTimedMessages;
+(int)sharedTypeForName:(char *)str;
+(char *)nameForSharedType:(int)typeInt;
- installSharedObject:aSynthObj for:aKeyObj;
- installSharedObject:aSynthObj for:aKeyObj type:(MKOrchSharedType)aType;
-installSharedSynthDataWithSegment:aSynthDataObj for:aKeyObj;
-installSharedSynthDataWithSegment:aSynthDataObj for:aKeyObj 
 type:(MKOrchSharedType)aType;
-installSharedSynthDataWithSegmentAndLength: (MKSynthData *) aSynthDataObj
 for:aKeyObj;
-installSharedSynthDataWithSegmentAndLength: (MKSynthData *) aSynthDataObj for:aKeyObj 
 type:(MKOrchSharedType)aType;
- sharedObjectFor:aKeyObj;
- sharedObjectFor:aKeyObj type:(MKOrchSharedType)aType;
- sharedSynthDataFor:aKeyObj segment:(MKOrchMemSegment)whichSegment;
- sharedSynthDataFor:aKeyObj segment:(MKOrchMemSegment)whichSegment
  type:(MKOrchSharedType)aType; 
- sharedSynthDataFor:aKeyObj segment:(MKOrchMemSegment)whichSegment 
 length:(int)length;
- sharedSynthDataFor:aKeyObj segment:(MKOrchMemSegment)whichSegment length:(int)length type:(MKOrchSharedType)aType; 
- sineROM; 
- muLawROM; 
- segmentZero:(MKOrchMemSegment )segment; 
- segmentSink:(MKOrchMemSegment )segment; 
- segmentSinkModulus:(MKOrchMemSegment )segment; 
- open; 
- run; 
- stop; 
- close; 
- abort;
- (void)dealloc; 
- useDSP:(BOOL )useIt; 
-(BOOL ) isDSPUsed; 
- trace: (int) typeOfInfo msg: (NSString *) fmt,...; 
-(char * )segmentName:(int )whichSegment; 
-(MKEMemType)externalMemoryIsOverlaid; 
-(MKOrchMemStruct *)peekMemoryResources:(MKOrchMemStruct *)peek;
-(unsigned short) index; 
-(double ) computeTime; 
- allocSynthPatch:aSynthPatchClass; 
- allocSynthPatch:aSynthPatchClass patchTemplate:p; 
- allocUnitGenerator:aClass; 
- allocUnitGenerator:aClass before:aUnitGeneratorInstance; 
- allocUnitGenerator:aClass after:aUnitGeneratorInstance; 
- allocUnitGenerator:aClass between:aUnitGeneratorInstance :anotherUnitGeneratorInstance; 
- (char *)lastAllocationFailureString;
- allocSynthData:(MKOrchMemSegment )segment length:(unsigned )size; 
- allocModulusPatchpoint:(MKOrchMemSegment )segment;
-allocModulusSynthData:(MKOrchMemSegment)segment length:(unsigned)size ;
- allocPatchpoint:(MKOrchMemSegment )segment; 
- dealloc:aSynthResource;
-setOnChipMemoryConfigDebug:(BOOL)debugIt patchPoints:(short)count;
-setOffChipMemoryConfigXArg:(float)xPercentage yArg:(float)yPercentage;
-getMonitorVersion:(char *)versionP release:(int *)releaseP;
-(BOOL)isRealTime;
-(int)outputChannelOffset;
-(int)inputChannelOffset;
-(int)inputPadding;
-(BOOL)supportsSamplingRate:(double)rate;
-(int)hardwareSupportedSamplingRates:(double **)arr;
-(double)defaultSamplingRate;
-(BOOL)prefersAlternativeSamplingRate;
+setAbortNotification:aDelegate;
-setDefaultSoundOut;

#define MK_nextCompatibleDSPPort 1
#define MK_hostSoundOut (1<<1)
#define MK_serialSoundOut (1<<2)
#define MK_serialSoundIn (1<<3)
#define MK_soundfileOut (1<<4)

-(unsigned)capabilities;
-(int)outputChannelCount;
-(int)outputInitialOffset;
-(int)outputPadding;
-(BOOL)upSamplingOutput;
-setUpDSP;
-(BOOL)startSoundWhenOpening;
-(NSString *)monitorFileName;
-setMonitorFileName:(NSString *)name;
-(double)systemOverhead;
+registerOrchestraSubclass:(id)classObject forOrchIndex:(int)index;
-segmentInputSoundfile:(MKOrchMemSegment)segment;
-setInputSoundfile:(NSString *)file;
-(NSString *)inputSoundfile;
-pauseInputSoundfile;
-resumeInputSoundfile;

#if !m68k
+(int)getDriverNames:(char ***)driverNames units:(int **)driverUnits
 subUnits:(int **)driverSubUnits;
-(char *)driverName ;
-(int)driverUnit;
-(int)driverSubUnit;
+(NSString *)driverParameter:( NSString *)parameterName forOrchIndex:(unsigned short)index;
-(NSString *)driverParameter:( NSString *)parameterName;
+(int)getDriverNames:(char ***)driverNames units:(int **)driverUnits;
#endif

-awaitEndOfTime:(double)endOfTime timeStamp:(DSPTimeStamp *)aTimeStampP;
-writeSymbolTable:(NSString *)fileName;
-setSimulatorFile:(char *)filename;
-(char *)simulatorFile;
- sharedObjectFor:aKeyObj segment:(MKOrchMemSegment)whichSegment length:(int)length;
- sharedObjectFor:aKeyObj segment:(MKOrchMemSegment)whichSegment;
- setSoundOut:(BOOL)yesOrNo;
- (BOOL)soundOut;
@end

@interface OrchestraDelegate : NSObject

-orchestra:sender didRecordData:(short *)data size:(unsigned int)dataCount;

@end

#endif
