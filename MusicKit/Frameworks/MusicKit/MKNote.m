/*
  $Id$
  Defined In: The MusicKit

  Description:
    (See MKNote.h)

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:

  $Log$
  Revision 1.8  2000/05/06 00:32:59  leigh
  Converted _binaryIndecies to NSMutableDictionary

  Revision 1.7  2000/04/04 00:13:21  leigh
  Made class reference clear in description

  Revision 1.6  2000/03/31 00:07:05  leigh
  Adopted OpenStep naming of factory methods

  Revision 1.5  2000/02/08 00:10:56  leigh
  Added duration display in -description

  Revision 1.4  2000/02/07 00:31:39  leigh
  improved description method, printing parameter values

  Revision 1.3  1999/09/24 05:49:31  leigh
  cleaned up documentation, improved description method, changed parameter type of writeNoteAux to NSString

  Revision 1.2  1999/07/29 01:16:37  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  09/18/89/daj - Changed hash table to be non-object variety. Changed parameters
                 to be structs rather than objects. Added C-function access
                 to many methods.
  09/19/89/daj - Changed definition of _ISMKPAR to be a little faster.
  10/06/89/daj - Changed to use new _MKNameTable.
  10/20/89/daj - Added binary scorefile support.
  01/02/90/daj - Flushed possiblyUpdateNoteType()
  03/13/90/daj - Moved private methods to category.
  03/17/90/daj - Fixed bugs in parameter iteration.
  03/19/90/daj - Added MKSetNoteClass() MKGetNoteClass.
                 Changed to use memset to clear _mkPars.
  03/21/90/daj - Added archiving support.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  05/13/90/daj - Simultaneously fixed 2 bugs. The bugs were 1) that unarchived
                 Parts could 'lose' Notes because id of Notes may come in
		 wrong order. 2) that Notes in a Scorefile can get reordered.
		 The fix is to change _reservedNote5 to be an int and use
		 it to store an "orderTag" which is an int assigned by the 
		 Part. This tag is used to disambiguate Notes with the same
		 timeTag. The former use of this field, to hold the 
		 'placeHolder' Notes is implemented as a negative order tag.
		 Note that I changed the semantics of the compare: 
		 method. This is a backward incompatible change.
  08/13/90/daj - Removed extraneous checks for noteClassInited and 
                 parClassInited. Added method +nameOfPar:.
  08/23/90/daj - Changed to zone API.
  09/02/90/daj - Changed MAXDOUBLE references to noDVal.h way of doing things
  11/7/91/daj  - Added clearing of performer in initWithTimeTag:
                 Added conductor instance variable.  This (slightly) cleans
		 up semantics of conductor method, in that it allows conductor
		 to be set from objects other than Performer. It also 
		 eliminates the problem of dangling Performer references in 
		 copied Notes. The dangling reference problem still exists in
		 another form, however, in that we now can have dangling
		 references to the conductor. As a precaution, PartRecorder
		 clears conductor field when it writes a note to a Part.
  02/19/92/daj - Fixed bug in _noteOffForNoteDur--it wasn't saving midiChan.
  06/04/92/daj - Fixed bug in MKNextParameter().  (Was including private
                 parameters.)
  06/06/92/daj - Changed setPar() to remove parameter if passed an invalid
                 value.
  10/20/92/daj - Fixed bug in 6/6/92 feature.
  10/23/92/daj - Fixed another bug in 6/23/92 feature.  Incremented archive version
  11/17/92/daj - Minor change to remove compiler warnings.
  6/27/93/daj -  Changed getNoteDur to support MK_restDur mute notes.
  11/9/94/daj -  Fixed truly-ugly bug in Note archiving:
                 In release 4.1, we introduced some new public Music Kit
		 parameters.  The problem is that if there is an archived
		 MKNote object with a private parameter (e.g. _dur), it will
		 show up as the wrong parameter, since by adding public
		 parameters, we have, in effect, "inserted" parameters.
		 The fix is to write out parameter numbers only for 
		 true public parameters.  This means we need to "fix up"
		 old files.  See read: below.
  03/08/95/daj/nick - Added check for MK_noPar in -isParPresent:
*/

/*** Oft-used Methods to make c funcs

  -conductor
  -_noteOffForNoteDur
  -free
  -unionWith
  -copy
  -timeTag
  -part
  -_setPartLink
  -setNoteTag:
  -noteDur
  -noteType
  -noteTag

LMS: All the _parameter hashtable stuff needs to be converted to NSMutableArray accesses
***/

#define INT(_x) ((int) _x)

#import <objc/hashtable.h>
#define MK_INLINE 1
#import "_musickit.h"
#import "tokens.h"
#import "_noteRecorder.h"
#import "_error.h"
#import "_ParName.h"
#import "_MKNameTable.h" 
#import "NotePrivate.h"

@implementation MKNote:NSObject 

/* Creation, copying, deleting------------------------------------------ */


static id setPar(); /* forward refs */

#define setObjPar(_self,_parameter,_value,_type) \
  setPar(_self,_parameter,_value, _type)
#define setDoublePar(_self,_parameter,_value) \
  setPar(_self,_parameter,& _value, MK_double)
#define setIntPar(_self,_parameter,_value) \
  setPar(_self,_parameter,& _value, MK_int)
#define setStringPar(_self,_parameter,_value) \
  setPar(_self,_parameter, _value, MK_string)

static BOOL isParPresent(); /* forward ref */

#define DEFAULTPARSSETSIZE 5

static BOOL parClassInited = NO;

#define ISPAR(_x) (ISMKPAR(_x) || ISAPPPAR(_x))

#define ISMKPAR(_x) \
((((int)(_x))>((int)MK_noPar))&&(((int)(_x))<((int)MK_privatePars)))

#define ISAPPPAR(_x)  \
((((int)(_x))<=(MKHighestPar()))&&(((int)(_x))>=((int) _MK_FIRSTAPPPAR)))

#define ISPRIVATEPAR(_x) \
  ((((int)(_x))>((int)MK_privatePars))&&(((int)(_x))<((int)MK_appPars)))

#define _ISMKPAR(_x) ((((int)(_x))>((int)MK_noPar))&&(((int)(_x))<((int)MK_appPars)))

#define _ISPAR(_x) (_ISMKPAR(_x) || ISAPPPAR(_x))

static id theSubclass = nil;

BOOL MKSetNoteClass(id aClass)
{
    if (!_MKInheritsFrom(aClass,[MKNote class]))
      return NO;
    theSubclass = aClass;
    return YES;
}

id MKGetNoteClass(void)
{
    if (!theSubclass)
      theSubclass = [MKNote class];
    return theSubclass;
}

+(int)parName:(NSString *)aName
    /* Obsolete */
{
    return [self parTagForName:aName];
}    

+(int)parTagForName:(NSString *)aName
  /* Returns the par int corresponding to the given name. If a parameter
     with aName does not exist, creates a new one. */
{
    id aPar;
    return _MKGetPar(aName,&aPar);
}    

+(NSString *)nameOfPar:(int)aPar
  /* Returns the name corresponding to the parameter number given.
     If the parameter number given is not a valid parameter number,
     returns "". Note that the string is not copied. */
{
    return [self parNameForTag:aPar];
}    

+(NSString *)parNameForTag:(int)aPar
  /* Returns the name corresponding to the parameter number given.
     If the parameter number given is not a valid parameter number,
     returns "". Note that the string is not copied. */
{
    if (_MKIsPar(aPar))
      return _MKParNameStr(aPar);
    else return nil;
}    

#define DEFAULTNUMPARS 1

#define HASHTABLECACHESIZE 16
static NXHashTable *hashTableCache[HASHTABLECACHESIZE];
static unsigned hashTableCachePtr = 0;

#define PARNUM(_x) ((_MKParameter *)_x)->parNum

static unsigned hashFun(const void *info, const void *data)
{
    return (unsigned)PARNUM(data);
}

static int isEqualFun(const void *info, const void *data1, const void *data2)
{
    return (PARNUM(data1) == PARNUM(data2));
}

static void freeFun(const void *info, void *data)
{
    _MKFreeParameter(data);
}

static NXHashTablePrototype htPrototype = {hashFun,isEqualFun,freeFun,0};

static NXHashTable *allocHashTable(void)
    /* alloc a new table. */
{
    if (hashTableCachePtr) 
      return hashTableCache[--hashTableCachePtr]; 
    else return NXCreateHashTable(htPrototype,DEFAULTNUMPARS,NULL);
}

static NXHashTable *freeHashTable(NXHashTable *tab)
{
    if (!tab)
      return NULL;
    if (tab) {
        if (hashTableCachePtr < HASHTABLECACHESIZE) {
            /* We only need to free elements if we're not freeing 
               the table. If we do free the table, we free elements in freeFun 
               above */
            _MKParameter *data;
            NXHashState state;
            state = NXInitHashState(tab);
            while (NXNextHashState (tab, &state, (void **)&data))
              _MKFreeParameter(data); /* Free all parameters. */
            NXEmptyHashTable(tab);
            hashTableCache[hashTableCachePtr++] = tab;
        }
        else NXFreeHashTable(tab); 
    }
    return NULL;
}

static _MKParameter *dummyPar = NULL;
static id noteClass = nil;

#define VERSION2 2
#define VERSION3 3
#define VERSION4 4

static void initNoteClass()
{
    noteClass = [MKNote class];
    if (!parClassInited)
      parClassInited = _MKParInit();
    dummyPar = _MKNewIntPar(0,MK_noPar);
}

+ (void)initialize
{
    if (!noteClass)
      initNoteClass();
    if (self != [MKNote class])
      return;
//    [self setVersion:VERSION4]; 
    [MKNote setVersion:VERSION4]; //sb: suggested by Stone conversion guide
    /* Changed to version 3, 10/23/92-DAJ */
    /* Changed to version 4, 11/9/94-DAJ */
    return;
}

#define NOTECACHESIZE 8
static id noteCache[NOTECACHESIZE];
static unsigned noteCachePtr = 0;

-initWithTimeTag:(double)aTimeTag
{
/*    [super init]; Not needed -- we omit in this case, for efficiency */
    noteTag = MAXINT;
    noteType = MK_mute;
    timeTag = aTimeTag;
    performer = conductor = nil;
    return self;
}

-init
{
    return [self initWithTimeTag:MK_ENDOFTIME];
}

+noteWithTimeTag:(double)aTimeTag
  /* TYPE: Creating; Creates a new MKNote and sets its timeTag.
   * Creates and initializes a new (mute) MKNote object 
   * with a timeTag value of aTimeTag.
   * If aTimeTag is MK_ENDOFTIME, the timeTag isn't set.
   * Returns the new object.
   */
{
    MKNote *newObj;
    if (self == noteClass && noteCachePtr) { 
	/* We initialize reused Notes here. */
	newObj = noteCache[--noteCachePtr]; 
	newObj->_parameters = NULL;
	memset(&(newObj->_mkPars[0]), 0, 
	       MK_MKPARBITVECTS * sizeof(newObj->_mkPars[0])); 
	newObj->_highAppPar = 0;
	newObj->_appPars = NULL;
    }
    else 
      newObj = [super allocWithZone:NSDefaultMallocZone()];
    [newObj initWithTimeTag:aTimeTag];
    return newObj; // LMS: we should be autoreleasing here...and one day will when I trust we have the correct num of retains...
}

+ note 
  /* TYPE: Creating; Creates a new MKNote object.
   * Creates, initializes and returns a new MKNote object.
   * Implemented as noteWithTimeTag:MK_ENDOFTIME.
   */
{
    return [self noteWithTimeTag:MK_ENDOFTIME];
}

#if 0
/* Might want to add this some day */
- (void)removeAllObjects
{
    freeHashTable((NXHashTable *)_parameters); /* Frees all parameters */
    _parameters = NULL;
    /* Clear bit vectors */
    memset(&(_mkPars[0]), 0, MK_MKPARBITVECTS * sizeof(_mkPars[0])); 
    if (_highAppPar) {
        free(_appPars);
        _appPars = NULL;
    }
    _highAppPar = 0;
    return;
}
#endif

- (void)dealloc
  /* TYPE: Creating; Frees the receiver and its contents.
   * Removes the receiver from its Part, if any, and then frees the
   * receiver and its contents.
   * Envelope and WaveTable objects are not freed.
   */
{
    [part removeNote:self];
    freeHashTable((NXHashTable *)_parameters);
    if (_highAppPar) 
      free(_appPars);
    if (((NSObject *)(self->isa)) == noteClass)
      if (noteCachePtr < NOTECACHESIZE) {
          noteCache[noteCachePtr++] = self;
      } else [super dealloc];
    else [super dealloc];
}


static int nAppBitVects(); /* forward ref */

- copyWithZone:(NSZone *)zone
  /* TYPE: Copying; Returns a new MKNote as a copy of the receiver.
   * Creates and returns a new MKNote object as a copy of the receiver.
   * The new MKNote's parameters, timing information, noteType and noteTag
   * are the same as the receiver's.
   * However, it isn't added to a Part 
   * regardless of the state of the receiver.
   *
   * Note: Envelope and WaveTable objects aren't copied, the new MKNote shares the
   * receiver's Envelope objects.
   */
{
    MKNote *newObj;
    _MKParameter *aPar;
    NXHashState state;
    int i, vectorCount;
//    newObj = [super copyWithZone:zone];
    newObj = [MKNote allocWithZone:zone] ;//sb: suggested in Stone porting guide
    newObj->noteTag = noteTag;//sb
    newObj->noteType = noteType;//sb
    newObj->timeTag = timeTag;//sb
/*sb: FIXME - I don't think that all parameters have been copied correctly. The call to
 * super was previously supposed to copy all instance variables, but I am afraid this does not work
 * any more
 */
    newObj->part = nil;
    newObj->conductor = performer ? [performer conductor] : conductor;
    newObj->performer = nil; 
    if (!_parameters) 
      return newObj;
    state = NXInitHashState((NXHashTable *)_parameters);
    newObj->_parameters =  /* Don't use allocHashtable 'cause we know size */
      NXCreateHashTable(htPrototype, NXCountHashTable((NXHashTable *)_parameters),NULL);
    while (NXNextHashState((NXHashTable *)_parameters,&state,(void **)&aPar))
      NXHashInsert((NXHashTable *)newObj->_parameters,
                   (void *)_MKCopyParameter(aPar));

    for (i = 0; i < MK_MKPARBITVECTS; i++) // reinstated by LMS
        newObj->_mkPars[i] = _mkPars[i];

    vectorCount = nAppBitVects(self);
    if (vectorCount) {
        _MK_MALLOC(newObj->_appPars, unsigned, vectorCount);
        for (i = 0; i < vectorCount; i++)
          newObj->_appPars[i] = _appPars[i];
    }
    return newObj;
}

-split:(id *)aNoteOn :(id *)aNoteOff
  /* TYPE: Type; Splits the noteDur receiver into two Notes.
   * If receiver isn't a noteDur, returns nil.   Otherwise,
   * creates two new Notes (a noteOn and a noteOff), splits the information
   * in the receiver between the two of them, places the new Notes in the
   * arguments,
   * and returns the receiver
   * (which is neither freed
   * nor otherwise affected).
   *
   * The receiver's parameters are copied into the new noteOn
   * except for MK_relVelocity which, if present
   * in the receiver, is copied into the noteOff.
   * The noteOn takes the receiver's timeTag while the noteOff's
   * timeTag is that of the receiver plus its duration.
   * If the receiver has a noteTag, it's copied into the two new Notes;
   * otherwise a new noteTag is generated for them.
   * The new Notes are added to the Part of the receiver, if any.
   *
   * Note: Envelope objects aren't copied, the new Notes share the
   * receiver's Envelope objects.
   */
{
    *aNoteOff = [(*aNoteOn = [self copyWithZone:NSDefaultMallocZone()]) _splitNoteDurNoCopy];
    if (*aNoteOff)
      return self;
    return nil;
}

static double getNoteDur(MKNote *aNote);



/* Perfomers, Conductors, Parts */


-performer      
  /* TYPE: Perf; Returns the Performer that's sending the Note.
   */
{
        return performer;
}

-part     
  /* TYPE: Acc; Return the receiver's Part.
   * Returns the Part that the receiver is a member of, or nil if none.
   */
{
    return part;
}

-setConductor:aConductor
{
    conductor = aConductor;
    return self;
}

-conductor
  /* If note is being sent by a Performer, returns the Performer's 
   * Conductor. Otherwise, if conductor was set, returns conductor.
   * Otherwise returns the default Conductor.
   */
{
    id aCond;
    if ((!performer) && conductor)
    	return conductor;
    aCond = [performer conductor];
    return aCond ? aCond : [_MKClassConductor() defaultConductor];
}

- addToPart:aPart
  /* TYPE: Acc; Adds the receiver to aPart.
   * Removes the receiver from the Part that it's currently 
   * a member of and adds it to aPart.
   * Returns the receiver's old Part, if any. 
   */
{
    id oldPart = part;
    [aPart addNote:self];
    return oldPart;
}

- (double)timeTag
  /* TYPE: Timing; Returns the receiver's timeTag.
   * Returns the receiver's timeTag.  If the timeTag isn't set, 
   * returns MK_ENDOFTIME.
   */
{ 
    return timeTag;
}

- (double) setTimeTag:(double)newTimeTag    
  /* TYPE: Timing; Sets the receiver's timeTag.
   * Sets the receiver's timeTag to newTimeTag and returns the old 
   * timeTag, or MK_ENDOFTIME if none. 
   * If newTimeTag is negative, it's clipped to 0.0.
   *
   * Note:  If the receiver is a member of a Part, 
   * it's first removed from the Part,
   * the timeTag is set, and then it's
   * re-added in order to ensure that its ordinal position within the
   * Part is correct.
   */
{ 
    double tmp = timeTag;
    id aPart = part;    /* Save it because remove causes it to be set to nil */
    newTimeTag = MIN(MAX(newTimeTag,0.0),MK_ENDOFTIME); 
    [aPart removeNote:self];
    timeTag = newTimeTag;
    [aPart addNote:self];
    return tmp; 
}

- removeFromPart
  /* TYPE: Acc; Removes the receiver from its Part.
   * Removes the receiver from its Part, if any.
   * Returns the old Part, or nil if none. 
   */
{
    id tmp = part;
    if (part) {
        [part removeNote:self];
        part = nil;
    }
    return tmp;
}

void _MKMakePlaceHolder(MKNote *aNote)
{
    if (aNote->_orderTag > 0)
      aNote->_orderTag = -aNote->_orderTag;
}

BOOL _MKNoteIsPlaceHolder(MKNote *aNote)
{
    return (aNote->_orderTag < 0);
}

#ifndef ABS
#define ABS(_x) ((_x < 0) ? -_x : _x)
#endif

int _MKNoteCompare(const void *el1,const void *el2)
    /* This must match code in MKNote. (Or move this function into MKNote.) */
{
    MKNote *id1 = *((MKNote **)el1);
    MKNote *id2 = *((MKNote **)el2);
    double t1,t2;
    if (id1 == id2)
        return NSOrderedSame; /*0;*/
    if (!id1)      /* Push nils to the end. */
        return NSOrderedDescending; /*1;*/
    if (!id2)
        return NSOrderedAscending; /*-1;*/
    t1 = id1->timeTag;
    t2 = id2->timeTag;
    if (t2 == t1)   /* Same time */
        return ((ABS(id1->_orderTag)) < (ABS(id2->_orderTag))) ? NSOrderedAscending : NSOrderedDescending; /*-1 : 1;*/
    return (t1 < t2) ? NSOrderedAscending : NSOrderedDescending; /*-1 : 1;*/
}

- (int)compare:aNote  
  /* TYPE: Copying; Compares the receiver with aNote.
   * Compares the receiver with aNote and returns a value as follows:
   *
    *  * If the receiver's timeTag < aNote's timeTag, returns -1.  NSOrderedAscending
    *  * If the receiver's timeTag > aNote's timeTag, returns 1.  NSOrderedDescending
   *
   * If their timeTags are equal, the two objects are compared 
   * by their order in the Part.
   *
   * This comparison indicates the order in which the
   * two Notes would be stored if they were members of the same Part.
   */
{ 
    /* We must only return 0 in one case: when aNote == the receiver.
       This insures that the binary tree will be correctly maintained. */
    if (![aNote isKindOfClass:noteClass])
      return -1;
    return _MKNoteCompare(&self,&aNote);
}

/* NoteType, duration, noteTag ---------------------------------------------- */

-(MKNoteType) noteType
  /* TYPE: Type; Returns the receiver's noteType.
   * Returns the receiver's noteType.
   */
{
    return noteType;
}

#define ISNOTETYPE(_x) ((int)_x >= (int)MK_noteDur && (int)_x <= (int)MK_mute)

- (id)setNoteType :(MKNoteType) newNoteType
 /* TYPE: Type; Sets the receiver's noteType to newNoteType.
  * Sets the receiver's noteType to newNoteType,
  * which must be one of:
  *
  *  * MK_noteDur
  *  * MK_noteOn
  *  * MK_noteOff
  *  * MK_noteUpdate
  *  * MK_mute
  *
  * Returns the receiver or nil if newNoteType is not a legal noteType.
  */
{
    if (ISNOTETYPE(newNoteType)) {
        noteType = newNoteType;
        return self;
    }
    else return nil;
}

-(double) setDur:(double) value
  /* TYPE: Timing; Sets the receiver's duration to value.
   * Sets the receiver's duration to value beats
   * and sets its 
   * noteType to MK_noteDur.
   * value must be positive.
   * Returns value.
   */
{       
    if (value < 0)
      return MK_NODVAL;
    noteType = MK_noteDur;
    setDoublePar(self,_MK_dur,value);
    return value;
}

void _MKSetNoteDur(MKNote *aNote, double dur)
{
    aNote->noteType = MK_noteDur;
    setDoublePar(aNote,_MK_dur,dur);
}

static double getNoteDur(MKNote *aNote)
{
    switch (aNote->noteType) {
      case MK_mute:
	return MKGetNoteParAsDouble(aNote,MK_restDur);
      case MK_noteDur:
	return MKGetNoteParAsDouble(aNote,_MK_dur);
      default:
	break;
    }
    return MK_NODVAL;
}

-(double)dur
  /* TYPE: Timing; Returns the receiver's duration.
   * Returns the receiver's duration, or MK_NODVAL if
   * it isn't set or if the receiver noteType isn't MK_noteDur.
   */
{       
    return getNoteDur(self);
}

- (int)noteTag
 /* TYPE: Type; Returns the receiver's noteTag.
  * Return the receiver's noteTag, or MAXINT if it isn't set.
  */
{
    return noteTag;
}

- removeNoteTag
    /* Same as [self setNoteTag:MAXINT] */
{
    noteTag = MAXINT;
    return self;
}

- setNoteTag:(int)newTag
 /* TYPE: Type; Sets the receiver's noteTag to newTag.
  * Sets the receiver's noteTag to newTag;
  * if the noteType is MK_mute 
  * it's automatically changed to MK_noteUpdate.
  * Returns the receiver.
  */
{
    noteTag = newTag;
    if (noteType == MK_mute)
      noteType = MK_noteUpdate;
    return self;
}

/* Raw setting methods */
void _MKSetNoteType(MKNote *aNote,MKNoteType aType)
{
    aNote->noteType = aType;
}

void _MKSetNoteTag(MKNote *aNote,int aTag)
{
    aNote->noteTag = aTag;
}


/* Parameters ------------------------------------------------- */


static BOOL _isMKPar(aPar)
    unsigned aPar;
    /* Returns YES if aPar is a public or private musickit parameter */
{
    return _ISMKPAR(aPar);
}

BOOL _MKIsPar(unsigned aPar)
    /* Returns YES if aPar is a public parameter */
{
    return ISPAR(aPar);
}


#if 0
static BOOL isPublicOrPrivatePar(unsigned aPar)
    /* Returns YES if aPar is a public or private parameter */
{
    return _ISPAR(aPar);
}
#endif

BOOL _MKIsPrivatePar(unsigned aPar)
    /* Returns YES if aPar is a private parameter */
{
    return ISPRIVATEPAR(aPar);
}

/* We represent pars in 2 bit-vector arrays, one for MK pars,
   the other for app pars. 
   The 0th MK par is not used so the LSB is always 0 in the MK low-order
   bit vector. The number of MK bit vectors is defined in musickit.h as
   big enough to hold the highest MK par, but not the place-holder
   MK_appPars. 
   */

static BOOL isParPresent(MKNote *aNote, unsigned aPar)
    /* Returns whether or not param is present. ANote is assumed to be a MKNote object. */
{
    if (aPar <= MK_noPar) return NO; /* Added by Nick 3/8/95 to stop a SB bug */

    if (!aNote->_parameters)
      return NO;
    if (_ISMKPAR(aPar))
      return ((aNote->_mkPars[aPar / BITS_PER_INT] & (1 << (aPar % BITS_PER_INT))) != 0);
    else if (aNote->_highAppPar != 0)
      return ((aPar <= aNote->_highAppPar) && 
            ((aNote->_appPars[aPar / BITS_PER_INT - MK_MKPARBITVECTS] &
             (1 << (aPar % BITS_PER_INT))) != 0));
    else return NO;    
}

static int nAppBitVects(self)
    MKNote *self;
    /* Assumes we have an appBitVect. */
{
    return (self->_highAppPar) ? (self->_highAppPar - _MK_FIRSTAPPPAR) / BITS_PER_INT + 1 : 0;
}

static BOOL setParBit(self,aPar)
    MKNote *self;
    unsigned aPar;
    /* Returns whether or not param is present and sets bit. */
{
    register unsigned bitVectIndex = aPar / BITS_PER_INT;
    register unsigned modBit = aPar % BITS_PER_INT;
    if (!self->_parameters)
      self->_parameters = allocHashTable();
    if (_ISMKPAR(aPar)) {
        if (self->_mkPars[bitVectIndex] & (1 << modBit))
           return YES;
        self->_mkPars[bitVectIndex] |= (1 << modBit);
        return NO;
    }
    bitVectIndex -= MK_MKPARBITVECTS;
    if (aPar > self->_highAppPar) {
        int i;
        if (self->_highAppPar != 0)
           _MK_REALLOC(self->_appPars,unsigned,(bitVectIndex + 1));
        else 
           _MK_MALLOC(self->_appPars,unsigned,(bitVectIndex + 1));
        for (i = nAppBitVects(self); i < bitVectIndex; i++)
          self->_appPars[i] = 0; /* Zero out added bit vects. */
        self->_highAppPar = (bitVectIndex + MK_MKPARBITVECTS + 1)
                 * BITS_PER_INT - 1;
        self->_appPars[bitVectIndex] = (1 << modBit);
        return NO;
    }
    if (self->_appPars[bitVectIndex] & (1 << modBit))
      return YES;
    self->_appPars[bitVectIndex] |= (1 << modBit);
    return NO;
}

/* Clears param bit if set. Returns whether param was present. */

static BOOL clearParBit(self,aPar)
    MKNote *self;
    unsigned aPar;
{
    unsigned thisBitVect = aPar / BITS_PER_INT;
    unsigned modBit = aPar % BITS_PER_INT;
    if (_isMKPar(aPar)) {
        BOOL wasSet = ((self->_mkPars[thisBitVect] & (1 << modBit)) > 0);
        self->_mkPars[thisBitVect] &= (~(1 << modBit));
        return wasSet;
    }
    if (self->_highAppPar && aPar <= self->_highAppPar) {
        self->_appPars[thisBitVect - MK_MKPARBITVECTS] &= (~(1 << modBit));
        return YES;
    }
    return NO;
}

id MKSetNoteParToDouble(MKNote *aNote,int par,double value)
{
    if (!_MKIsPar(par))
      return nil;
    return setDoublePar(aNote,par,value);
}

-setPar:(int)par toDouble:(double) value
  /* TYPE: Parameters; Sets parameter par to double value.
   * Sets the parameter par to value, which must be a
   * double.
   * Returns the receiver.
   */
{
    return MKSetNoteParToDouble(self,par,value);
}

id MKSetNoteParToInt(MKNote *aNote,int par,int value)
{
    if (!_MKIsPar(par))
      return nil;
    return setIntPar(aNote,par,value);
}

-setPar:(int)par toInt:(int) value
  /* TYPE: Parameters;  Sets parameter par to int value.
   * Set the parameter par to value, which must be an int.
   * Returns the receiver.
   */
{       
    return MKSetNoteParToInt(self,par,value);
}

id MKSetNoteParToString(MKNote *aNote,int par,NSString *value)
{
    if (!_MKIsPar(par))
      return nil;
    return setStringPar(aNote,par,value);
}

-setPar:(int)par toString:(NSString *) value
  /* Set the parameter par to a copy of value, which must be a NSString.
   * Returns the receiver.
   */
{
    return MKSetNoteParToString(self,par,value);
}

id MKSetNoteParToEnvelope(MKNote *aNote,int par,id envObj)
{
    if (!_MKIsPar(par))
      return nil;
    return setObjPar(aNote,par,envObj,MK_envelope);
}

-setPar:(int)par toEnvelope:(id)envObj
  /* TYPE: Parameters; Sets parameter par to the Envelope envObj.
   * Points the parameter par to 
   * envObj (envObj isn't copied).
   * Scaling and offset information is retained. 
   * Returns the receiver.
   */
{
    return MKSetNoteParToEnvelope(self,par,envObj);
}

id MKSetNoteParToWaveTable(MKNote *aNote,int par,id waveObj)
{
    if (!_MKIsPar(par))
      return nil;
    return setObjPar(aNote,par,waveObj,MK_waveTable);
}

-setPar:(int)par toWaveTable:(id)waveObj
  /* TYPE: Parameters; Sets parameter par to the WaveTable waveObj.
   * Points the parameter par to 
   * waveObj (waveObj isn't copied).
   * Returns the receiver.
   */
{
    return MKSetNoteParToWaveTable(self,par,waveObj);
}


id MKSetNoteParToObject(MKNote *aNote,int par,id anObj)
{
    if (!_MKIsPar(par))
      return nil;
    return setObjPar(aNote,par,anObj,MK_object);
}

-setPar:(int)par toObject:(id)anObj
  /* TYPE: Parameters; Sets parameter par to the specified object.
   * Points the parameter par to 
   * anObj (anObj isn't copied).
   * The object may be of any class, but must be able to write itself
   * out in ASCII when sent the message -writeASCIIStream:.
   * It may write itself any way it wants, as long as it can also read
   * itself when sent the message -readASCIIStream:.
   * The only restriction on these methods is that the ASCII representation
   * should not contain the character ']'.
   * The header file scorefileObject.h is an abstract interface to this
   * protocol.
   * Note that no Music Kit classes implement these methods. The support
   * in MKNote is provided purely for outside extensibility.
   * Returns the receiver.
   */
{
    return MKSetNoteParToObject(self,par,anObj);
}


#define SETDUMMYPAR(_par) dummyPar->parNum = _par;

/*** FIXME Might be faster to just do the hash here, rather than calling 
  isParPresent? ***/
#define GETPAR(self,_getFun,_noVal) \
if (!self || !isParPresent(self,par)) return _noVal; \
SETDUMMYPAR(par); \
return _getFun(NXHashGet((NXHashTable *)self->_parameters, (const void *)dummyPar))

double MKGetNoteParAsDouble(MKNote *aNote,int par)
{
    GETPAR(aNote,_MKParAsDouble,MK_NODVAL);
}

-(double)parAsDouble:(int)par
 /* TYPE: Parameters; Returns the value of par as a double.
  * Returns a double value converted from the value
  * of the parameter par. 
  * If the parameter isn't present, returns MK_NODVAL.
  */
{
    return MKGetNoteParAsDouble(self,par);
}

int MKGetNoteParAsInt(MKNote *aNote,int par)
{
//    GETPAR(aNote,_MKParAsInt,MAXINT);
if (!aNote || !isParPresent(aNote,par)) return MAXINT;
SETDUMMYPAR(par);
return _MKParAsInt(NXHashGet((NXHashTable *)aNote->_parameters, (const void *)dummyPar));

}

-(int)parAsInt:(int)par
 /* TYPE: Parameters; Returns the value of par as an int.
  * Returns an int value converted from the value
  * of the parameter par. 
  * If the parameter isn't present, returns MAXINT.
  */
{
    return MKGetNoteParAsInt(self,par);
}

NSString *MKGetNoteParAsString(MKNote *aNote,int par)
{
    GETPAR(aNote,_MKParAsString,@"");//sb: was _MKMakeStr("")
}

-(NSString *)parAsString:(int)par
  /* Returns a NSString converted from a copy of the value
   * of the parameter par. 
   * If the parameter isn't present, returns a copy of "". 
   */
{
    return MKGetNoteParAsString(self,par);
}

NSString *MKGetNoteParAsStringNoCopy(MKNote *aNote,int par)
{
    if (!aNote || !isParPresent(aNote,par)) 
      return @"";//sb: was (char *)_MKUniqueNull(); 
    SETDUMMYPAR(par);
    return _MKParAsStringNoCopy(NXHashGet((NXHashTable *)aNote->_parameters, (const void *)dummyPar));
}

-(NSString *)parAsStringNoCopy:(int)par
  /* TYPE: Parameters; Returns the value of par as a NSString.
  * Returns a NSString to the value of the
  * parameter par.
  * You shouldn't delete, alter, or store the value 
  * returned by this method.
  * If the parameter isn't present, returns "". 
  * Note that the strings returned are 'unique' in the sense that
  * they are returned by NXUniqueString(). See hashtable.h for details.
  */
{
    return MKGetNoteParAsStringNoCopy(self,par);
}


id MKGetNoteParAsEnvelope(MKNote *aNote,int par)
{
    GETPAR(aNote,_MKParAsEnv,nil);
}

-parAsEnvelope:(int)par
  /* TYPE: Parameters; Returns par's Envelope object.
   * If par is an envelope, returns its Envelope object.
   * Otherwise returns nil.
   */
{
    return MKGetNoteParAsEnvelope(self,par);
}

id MKGetNoteParAsWaveTable(MKNote *aNote,int par)
{
    GETPAR(aNote,_MKParAsWave,nil);
}

-parAsWaveTable:(int)par
  /* TYPE: Parameters; Returns par's WaveTable object.
   * If par is a waveTable, returns its WaveTable object.
   * Otherwise returns nil.
   */
{
    return MKGetNoteParAsWaveTable(self,par);
}

id MKGetNoteParAsObject(MKNote *aNote,int par)
{
    GETPAR(aNote,_MKParAsObj,nil);
}

-parAsObject:(int)par
  /* TYPE: Parameters; Returns par's object.
   * If par is an object (including an Envelope or WaveTable), 
   * returns its object. Otherwise returns nil.
   */
{
    return MKGetNoteParAsObject(self,par);
}

BOOL MKIsNoteParPresent(MKNote *aNote,int par)
{
    return isParPresent(aNote,par);
}

-(BOOL)isParPresent:(int)par
  /* TYPE: Parameters; Checks for presence of par.
   * Returns YES if the parameter par is present in the
   * receiver (i.e. if its value has been set), NO if it isn't.
   */
{
    return isParPresent(self,par);
}

-(MKDataType)parType:(int)par
   /* TYPE: Parameters; Returns the data type of par.
    * Returns the parameter data type of par
    * as an MKDataType:
    * 
    *  * MK_double 
    *  * MK_int
    *  * MK_string
    *  * MK_envelope
    *  * MK_waveTable
    *  * MK_object
    * 
    * If the parameter isn't present, returns _MK_undef.
    */
{
    if (!isParPresent(self,par)) 
      return MK_noType;
    SETDUMMYPAR(par);
    return ((_MKParameter *)NXHashGet((NXHashTable *)_parameters, (const void *)dummyPar))->_uType;
}

-removePar:(int)par
  /* TYPE: Parameters; Removes par form the receiver.
   * Removes the parameter par from the receiver.
   * Returns the receiver if the parameter was present, otherwise
   * returns nil.
   */
{
    _MKParameter *aParameter;
    if (!_MKIsPar(par) || !clearParBit(self,par))
      return nil;
    SETDUMMYPAR(par);
    aParameter = (_MKParameter *)NXHashRemove((NXHashTable *)_parameters,
                                              (const void *)dummyPar);
    _MKFreeParameter(aParameter);
    return self;
}

-(unsigned)parVector:(unsigned)index
  /* TYPE: Parameters; Checks presence of a number of parameters at once.
   * Returns a bit vector indicating the presence of parameters 
   * identified by integers (index * BITS_PER_INT) through 
   * ((index  + 1) * BITS_PER_INT - 1). For example,
   *
   * .ib
   * unsigned int parVect = [aNote checkParVector:0];
   * .iq
   *
   * returns the vector for parameters 0-31.
   * An argument of 1 returns the vector for parameters 32-63, etc.
   */
{
    return (index < MK_MKPARBITVECTS) ?  _mkPars[index] :
      (index >= (nAppBitVects(self) + MK_MKPARBITVECTS)) ? 0 :
        _appPars[index - MK_MKPARBITVECTS];
}

-(int)parVectorCount
   /* TYPE: Parameters; Returns the # of bit vectors for parameters.
    * Returns the number of bit vectors (unsigned ints)
    * indicating presence of parameters in the receiver. 
    * 
    * See also checkParVector:.
    */
{
    return MK_MKPARBITVECTS + nAppBitVects(self);
}

static void copyPars(); /* forward ref */

-copyParsFrom:aNote
  /* TYPE: Copying; Copies parameters and dur (if any) from aNote to receiver.
   * Copies aNote's parameters and duration into
   * the receiver (Envelope and WaveTables and other objects are shared rather than copied).
   * Overwrites such values already present in the receiver.
   * Returns the receiver.
   */
  /* (cf. unionWith) */
{
    copyPars(self,aNote,YES);
    return self;
}

/* Parameter getting methods which provide defaults. --------------- */

#if 0
-(double)amp
  /* TYPE: Parameters; Returns the receiver's amplitude.
   * Returns the value of MK_amp if present. 
   * If not, the return value is derived from MK_velocity thus:
   * 
   *    Vel       Amp       Meaning
   *    127     1.0 (almost)    Maximum representable amplitude
   *    64        .1    mezzo-forte
   *    0       0.0     minus infinity dB
   *
   * If MK_velocity is missing, returns MAXDOUBLE.
   */
{
    int velocity;
    double ampVal = [self parAsDouble:MK_amp];
    if (ampVal != MAXDOUBLE) 
      return MIN(MAX(ampVal,0.0),1.0);
    velocity = [self parAsInt:MK_velocity];
    if (velocity == MAXINT)
      return MAXDOUBLE;
    return MKMidiToAmp(velocity);
}

-(int)velocity
  /* TYPE: Parameters; Returns the receiver velocity.
   * Returns the value of the MK_velocity parameter if present.
   * If not, derives a return value from MK_amp (see
   * amp for the conversion table).
   *
   * If amp is absent,returns MAXINT.
   */
{
    double similarPar;
    int midiVel = [self parAsInt:MK_velocity];
    if (midiVel != MAXINT)
      return MAX(0,MIDI_DATA(midiVel));
    if ((similarPar = [self parAsDouble:MK_amp]) != MAXDOUBLE)
      return MKAmpToMidi(similarPar);
    return MAXINT;
}
#endif

-(double)freq
  /* TYPE: Parameters; Returns the frequency of the receiver.
   * Returns the value of MK_freq, if present.  If not,
   * converts and returns the value of MK_keyNum.
   * And if that parameter is missing, returns MK_NODVAL.
   */
{
    int keyNumVal;
    double freqVal = MKGetNoteParAsDouble(self,MK_freq);
    if (!MKIsNoDVal(freqVal))
      return freqVal;
    keyNumVal = MKGetNoteParAsInt(self,MK_keyNum);
    if (keyNumVal == MAXINT)
      return MK_NODVAL;
    return MKKeyNumToFreq(keyNumVal);
}

-(int)keyNum
  /* TYPE: Parameters; Returns the key number of the recevier.
   * Returns the value of MK_keyNum, if present.  If not,
   * converts and returns the value of MK_freq.
   * If MK_freq isn't present, returns MAXINT.
   */
{
    int keyNum;
    keyNum = MKGetNoteParAsInt(self,MK_keyNum);
    if (keyNum != MAXINT)
      return MIDI_DATA(MAX(0,keyNum));
    {
        double freqPar = MKGetNoteParAsDouble(self,MK_freq);
        if (MKIsNoDVal(freqPar))
          return MAXINT;
        return MKFreqToKeyNum(freqPar,NULL,0);
    }
}


/* Writing ------------------------------------------------------------ */

#define BINARY(_p) (_p && _p->_binary)

void _MKWriteParameters(MKNote *self,NSMutableData *aStream,_MKScoreOutStruct *p)
{
    _MKParameter *aPar;
    NXHashState state;
    if (self->_parameters) {
        state = NXInitHashState((NXHashTable *)self->_parameters);
        if (BINARY(p)) {
            while (NXNextHashState((NXHashTable *)self->_parameters,
                                   &state,(void **)&aPar))
              _MKParWriteOn(aPar,aStream,p);
        }
        else {
            int parCnt = 0;
            while (NXNextHashState((NXHashTable *)self->_parameters,
                                   &state,(void **)&aPar))
              if (_MKIsParPublic(aPar)) {  /* Private parameters don't print */
#                 if _MK_LINEBREAKS
#                 define PARSPERLINE 5
                  [aStream appendData:[@", " dataUsingEncoding:NSNEXTSTEPStringEncoding]]; 
                  if (++parCnt > PARSPERLINE) {
                      parCnt = 0; 
                      [aStream appendData:[@"\n\t" dataUsingEncoding:NSNEXTSTEPStringEncoding]];
                  }
#                 else
                  if (parCnt++) 
                    [aStream appendData:[@", " dataUsingEncoding:NSNEXTSTEPStringEncoding]]; 
#                 endif
                  _MKParWriteOn(aPar,aStream,p);
              }
        }
    }
    if (BINARY(p))
      _MKWriteInt(aStream,MAXINT);
    else [aStream appendData:[@";\n" dataUsingEncoding:NSNEXTSTEPStringEncoding]];
}

static id writeBinaryNoteAux(MKNote *self,id aPart,_MKScoreOutStruct *p)
{
    NSMutableData *aStream = p->_stream;
    _MKWriteShort(aStream, _MK_partInstance);
    _MKWriteShort(aStream, [[p->_binaryIndecies objectForKey: aPart] intValue]);
    switch (self->noteType) {
      case MK_noteDur: {
          double dur = ((p->_ownerIsNoteRecorder) ? 
			_MKDurForTimeUnit(self,[p->_owner timeUnit]) :
			getNoteDur(self));
	  _MKWriteShort(aStream,MK_noteDur);
          _MKWriteDouble(aStream,dur);
          _MKWriteInt(aStream,self->noteTag);
          break;
      }
      case MK_noteOn:
      case MK_noteOff:
      case MK_noteUpdate:
        _MKWriteShort(aStream,self->noteType);
        _MKWriteInt(aStream,self->noteTag);
        break;
      case MK_mute:
      default:
        _MKWriteInt(aStream,self->noteType);
        break;
    }
    _MKWriteParameters(self,aStream,p);
    return self;
}

static id writeNoteAux(MKNote *self,_MKScoreOutStruct *p,
                       NSMutableData *aStream,NSString *partName)
    /* Never invoke this function when writing a binary scorefile */
{
    /* The part should always have a name. This is just in case of lossage. */
    if (!partName)
      partName = @"anon";
    [aStream appendData:[[NSString stringWithFormat:@"%@ ", partName] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    [aStream appendData:[@"(" dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    switch (self->noteType) {
      case MK_noteDur: {
          double dur = 
            ((p && p->_ownerIsNoteRecorder) ? 
	     _MKDurForTimeUnit(self,[p->_owner timeUnit]) :
	     getNoteDur(self));
          [aStream appendData:[[NSString stringWithFormat:@"%.5f", dur] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
          if (self->noteTag != MAXINT) 
            [aStream appendData:[[NSString stringWithFormat:@" %d", self->noteTag] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
          break;
      }
      case MK_noteOn:
      case MK_noteOff:
      case MK_noteUpdate:
        [aStream appendData:[[NSString stringWithFormat:@"%s", _MKTokNameNoCheck(self->noteType)] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
        if (self->noteTag != MAXINT)
          [aStream appendData:[[NSString stringWithFormat:@" %d", self->noteTag] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
        break;
      case MK_mute:
      default:
        [aStream appendData:[[NSString stringWithFormat:@"%s", _MKTokNameNoCheck(self->noteType)] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
        break;
    }
    [aStream appendData:[@") " dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    _MKWriteParameters(self,aStream,p);
    return self;
}

-writeScorefileStream:(NSMutableData *)aStream
  /* TYPE: Display; Displays the receiver in ScoreFile format.
   * Displays, on aStream, the receiver in ScoreFile format.
   * Returns the receiver.
   */
{
    return writeNoteAux(self,NULL,aStream,MKGetObjectName(part));
}

id _MKWriteNote2(MKNote *self,id aPart,_MKScoreOutStruct *p)
    /* Used internally for writing notes to scorefiles. */
{
    id tmp;

    if (p->_binary)
        return writeBinaryNoteAux(self,aPart,p);
    return writeNoteAux(self,p,p->_stream, _MKNameTableGetObjectName(p->_nameTable, aPart, &tmp));
}

/* Assorted C functions ----------------------------------------- */

#define VELSCALE 64.0 /* Mike Mcnabb says this is right. */

double 
MKMidiToAmp(int v)
{ 
    /* We do the following map:
       
       VELOCITY  AMP SCALING           MEANING
       ----      -----------           -------
       127      10.0          Maximum amplitude scaling  
       64       1.0 (almost)  No modification of amp
       0         0            minus infinity dB
       */
    if (!v) 
      return 0.0;
    return pow(10.,((double)v-VELSCALE)/VELSCALE);
}

double MKMidiToAmpWithSensitivity(int v, double sensitivity)
{
    return (1 - sensitivity) + sensitivity * MKMidiToAmp(v); 
}

int MKAmpToMidi(double amp)
{ 
    int v;
    if (!amp) 
      return 0.0;
    v = VELSCALE + VELSCALE * log10(amp);
    return MAX(v,0);
}

#define VOLCONST 127.0
#define VOLSCALE 64.0

double 
MKMidiToAmpAttenuation(int v)
{ 
    /* We do the following map:
       
       VELOCITY  AMP SCALING           MEANING
       ----      -----------           -------
       127      1.0           No modification of amp
       64       .1            
       0         0            minus infinity dB
       */
    if (!v) 
      return 0.0;
    return pow(10.,((double)v-VOLCONST)/VOLSCALE);
}

double MKMidiToAmpAttenuationWithSensitivity(int v, double sensitivity)
{
    return (1 - sensitivity) + sensitivity * MKMidiToAmpAttenuation(v); 
}

int MKAmpAttenuationToMidi(double amp)
{ 
    int v;
    if (!amp) 
      return 0.0;
    v = VOLCONST + VOLSCALE * log10(amp);
    return MAX(v,0);
}

static id _removePar(self,aPar)
    MKNote *self;
    _MKParameter *aPar;
{
    aPar = (_MKParameter *)NXHashRemove((NXHashTable *)self->_parameters,
					(const void *)aPar);
    _MKFreeParameter(aPar);
    return self;
}

static id setPar(self,parNum,value,type)
    MKNote *self;
    int parNum;
    void *value;
    MKDataType type;
{
    register _MKParameter *aPar;
    if (!self)
      return nil;
    if (setParBit(self,parNum)) { /* Parameter is already present */
        SETDUMMYPAR(parNum);
        aPar = (_MKParameter *)NXHashGet((NXHashTable *)self->_parameters,
                                         (const void *)dummyPar);
        switch (type) {
          case MK_double:
	    if (MKIsNoDVal(*((double *)value))) {
		_removePar(self,aPar);
		clearParBit(self,parNum);
	    }
	    else _MKSetDoublePar(aPar,*((double *)value));
            break;
          case MK_string:
	    if ((NSString *)value == nil ) { //sb: separated the nil and the zero-length tests
		_removePar(self,aPar);
		clearParBit(self,parNum);
	    }
              else if ( ![(NSString *)value length] ) {
                  _removePar(self,aPar);
                  clearParBit(self,parNum);
                  }
              else _MKSetStringPar(aPar,(NSString *)value);
            break;
          case MK_int:
	    if (*((int *)value) == MAXINT) {
		_removePar(self,aPar);
		clearParBit(self,parNum);
	    }
	    else _MKSetIntPar(aPar,*((int *)value));
            break;
          default:
	    if (!(id)value) {
		_removePar(self,aPar);
		clearParBit(self,parNum);
	    }
	    else _MKSetObjPar(aPar,(id)value,type);
            break;
        }
    }
    else { /* New parameter */
        switch (type) {
          case MK_int:
	    if (*((int *)value) == MAXINT) {
		clearParBit(self,parNum);
		return self;
	    }
            aPar = _MKNewIntPar(*((int *)value),parNum); 
            break;
          case MK_double:
	    if (MKIsNoDVal(*((double *)value))) {
		clearParBit(self,parNum);
		return self;
	    }
            aPar = _MKNewDoublePar(*((double *)value),parNum); 
            break;
          case MK_string:
	    if ((char *)value == NULL || (((char *)value)[0]) == '\0') {
		clearParBit(self,parNum);
		return self;
	    }
            aPar = _MKNewStringPar((char *)value,parNum); 
            break;
          default:
	    if (!(id)value) {
		clearParBit(self,parNum);
		return self;
	    }
	    aPar = _MKNewObjPar((id)value,parNum,type); 
            break;
        }
        NXHashInsert((NXHashTable *)self->_parameters,(void *)aPar);
    }
    return self;
}

static void addParameter(MKNote *self,_MKParameter *aPar); /* Forward decl */

static void copyPars(toObj,fromObj,override)
    MKNote *toObj;
    MKNote *fromObj;
    BOOL override;
{
    /* Copies parameters from fromObj to toObj. If override
       is YES, the value from fromObj takes parameter. Otherwise, the
       value from toObj takes priority. */
    _MKParameter *aPar;
    NXHashState state;
    if ((!fromObj) || (!toObj) || (![fromObj isKindOfClass:noteClass]))
      return;
    if (!fromObj->_parameters)
      return;
    state = NXInitHashState((NXHashTable *)fromObj->_parameters);
    while (NXNextHashState((NXHashTable *)fromObj->_parameters,
                           &state,(void **)&aPar))
      if (PARNUM(aPar) != _MK_dur)
        if (override || !isParPresent(toObj,PARNUM(aPar)))
          addParameter(toObj,aPar);
}

-(unsigned)hash
   /* Notes hash themselves based on their noteTag. */
{
    return noteTag;
}

-(BOOL)isEqual:aNote
   /* Notes are considered 'equal' if their noteTags are the same. */
{
   return [aNote isKindOfClass:noteClass] && (((MKNote *)aNote)->noteTag == noteTag);
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Archives parameters, noteType, noteTag, and timeTag. Also archives
     performer and part using MKWriteObjectReference(). This object should
     be written with NXWriteRootObject(). */
{
    NXHashState state;
    _MKParameter *aPar;
    int parCount;

    /*[super encodeWithCoder:aCoder];*/ /*sb: unnec */
    
    /* First archive the note's type, noteTag, timeTag, and number of pars */
    if (_parameters)
      parCount = NXCountHashTable((NXHashTable *)_parameters);
    else parCount = 0;
    [aCoder encodeValuesOfObjCTypes:"iiidi", &noteType, &noteTag, &parCount, 
                 &timeTag,&_orderTag];
    [aCoder encodeConditionalObject:performer];
    [aCoder encodeConditionalObject:part];
    
    if (!_parameters)
      return;

    /* Archive pars */
    state = NXInitHashState((NXHashTable *)_parameters);
    while (NXNextHashState((NXHashTable *)_parameters,&state,
                           (void **)&aPar)) 
      _MKArchiveParOn(aPar,aCoder);
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Unarchives object. See write:.  */
{
    _MKParameter aPar;
    int parCount,i;
    int version;
    /* First check version */

    /*[super initWithCoder:aDecoder];*/ /*sb: unnec */
    version = [aDecoder versionForClassName:@"MKNote"];
    if (version >= VERSION2) {
        /* First unarchive the note's type, noteTag, timeTag, 
           and number of pars */
        [aDecoder decodeValuesOfObjCTypes:"iiidi", &noteType, &noteTag, &parCount, 
                    &timeTag,&_orderTag];
        performer = [[aDecoder decodeObject] retain];
        part = [[aDecoder decodeObject] retain];
        
        if (parCount) /* Don't use allocHashtable 'cause we know size */
          _parameters =  NXCreateHashTable(htPrototype,parCount,NULL);
        for (i=0; i<parCount; i++) {
            _MKUnarchiveParOn(&aPar,aDecoder); /* Writes into aPar */
	    if (version <= VERSION3) {
		if (aPar.parNum == MK_orchestraIndex)
		  /* This used to be _dur.  Fix it.  SIGH! 
		   * Starting in version4, I only archive as numbers the  
		   * public parameters.  Since we never remove public
		   * parameters, this should always work.
		   */
		  aPar.parNum = _MK_dur;
	    }
            if (version == VERSION2) {
		/* Version 2 files could have parameters with nil, "", MAXINT, etc 
		 * So we need to repair them.
		 */
		switch (aPar._uType) {
		  case MK_double:
		    if (MKIsNoDVal(aPar._uVal.rval)) {
			continue;
		    }
		    break;
		  case MK_string:
                      if ([aPar._uVal.sval isEqualToString:@""]) { //sb: was: aPar._uVal.sval == _MKUniqueNull()
			continue;
		    }
		    break;
		  case MK_envelope:
		  case MK_waveTable:
		  case MK_object:
		    if (!aPar._uVal.symbol) {
			continue;
		    }
		    break;
		  default:
		  case MK_int:
		    if (aPar._uVal.ival == MAXINT) {
			continue;
		    }
		    break;
		    
		}
	    }   /* End of VERSION2 block */
            addParameter(self,&aPar);
        }
    }
    return self;
}

#if 0
-(int)parameterCount
{
    if (!aNote->_parameters)
      return 0;
    return (int)NXCountHashTable(aNote->_parameters);
}
#endif

static unsigned highestTag = 0; /* Has the current highestTag. 1-based. */

unsigned MKNoteTag(void)
{
    /* Return a new noteTag or generate an error and return
       MAXINT if no more noteTags. */
    if (highestTag < MAXINT)
      return ++highestTag;
    else _MKErrorf(MK_noMoreTagsErr);
    return MAXINT;
}

unsigned MKNoteTags(unsigned n)
{
    /* Return the first of a block of n noteTags or generate an error
       and return MAXINT if no more noteTags or n is 0. */
    int base = highestTag + 1;
    if (((int)MAXINT) - ((int)n) >= highestTag) { 
        highestTag += n;
        return base;
    }
    _MKErrorf(MK_noMoreTagsErr);
    return MAXINT;
}

static void addParameter(MKNote *self,_MKParameter *aPar)
   /* Allows a Parameter object to be added directly. 
      The object is first copied. Returns nil. */
{
    aPar = _MKCopyParameter(aPar);
    setParBit(self,PARNUM(aPar));
    aPar = (_MKParameter *)NXHashInsert((NXHashTable *)self->_parameters,
                                        (const void *)aPar);
    _MKFreeParameter(aPar);
}

void _MKNoteShiftTimeTag(MKNote *aNote, double timeShift)
    /* Assumes timeTag is valid */
{
    aNote->timeTag += timeShift;
}

static NXHashState *cachedHashState = NULL;

void *MKInitParameterIteration(MKNote *aNote)
    /* Call this to start an iteration over the parameters of a MKNote.
       Usage:

    void *aState = MKInitParameterIteration(aNote);
    int par;
    while ((par = MKNextParameter(aNote,aState)) != MK_noPar) {
        select (par) {
          case freq0: 
            something;
            break;
          case amp0:
            somethingElse;
            break;
          default: // Skip unrecognized parameters
            break;
        }}
    */
{
    NXHashState *aState;
    if (!aNote || !aNote->_parameters)
      return NULL;
    if (cachedHashState) {
        aState = cachedHashState;
        cachedHashState = NULL;
    }
    else _MK_MALLOC(aState,NXHashState,1);
    *aState = NXInitHashState((NXHashTable *)aNote->_parameters);
    return (void *)aState;
}

int MKNextParameter(MKNote *aNote,void *aState)
{
    id aPar;
    if (!aNote || !aState) 
      return MK_noPar;
    if (NXNextHashState((NXHashTable *)aNote->_parameters,
                        (NXHashState *) aState, (void **)&aPar))
      if (_MKIsPar(PARNUM(aPar))) /* Is it public? */
	return PARNUM(aPar); 
      else return MKNextParameter(aNote,aState);
    else {
        if (cachedHashState) { /* Cache is full */
            free(aState);
        }
	else
	    cachedHashState = (NXHashState *)aState; /* Cache it */
        return MK_noPar;
    }
}

/* FIXME Needed due to a compiler bug */
static void setNoteOffFields(MKNote *aNoteOff,int aNoteTag,id aPerformer,id aConductor)
{
    aNoteOff->noteTag = aNoteTag;
    aNoteOff->performer = nil;
    aNoteOff->conductor = aPerformer ? [aPerformer conductor] : aConductor;
    aNoteOff->part = nil;
    aNoteOff->noteType = MK_noteOff;
}

// for debugging
- (NSString *) description
{
    NSMutableString *paramString = [[NSMutableString alloc] initWithString: @"Parameters: "];
    NSString *partString;
    NSString *performerString;
    NSString *durAndNoteTagString;
    void *aState = MKInitParameterIteration(self);
//  id conductor; // if necessary.
    int par;
    double duration;

    if(performer != nil) 
        performerString = [NSString stringWithFormat: @"performed by (%@)", performer];
    else
        performerString = @"";
// we have self referential problem if we have defined a [MKPart description] method. For this case we want the default description method [[part super] description].
//    if(part != nil)
//        partString = [NSString stringWithFormat: @"of (%@)", part];
//    else
        partString = @"";

    // loop thru the parameter table and list all parameters being used and their values.
    par = MKNextParameter(self, aState);
    do {
        if(par != MK_noPar) {
            [paramString appendFormat: @"%@: %@", _MKParNameStr(par), MKGetNoteParAsString(self, par)];
            par = MKNextParameter(self, aState);
        }
        [paramString appendString: (par != MK_noPar) ? @", " : @"."];
    } while(par != MK_noPar);

    if(MKIsNoDVal(duration = getNoteDur(self)))
        durAndNoteTagString = [NSString stringWithFormat: @"%d", noteTag];
    else
        durAndNoteTagString = [NSString stringWithFormat: @"%.5lf %d", duration, noteTag];

    return [NSString stringWithFormat: @"MKNote at %lf: %s(%@) %@ %@\n%@\n",
        timeTag, _MKTokName(noteType), durAndNoteTagString, partString, performerString, paramString];
}

@end


@implementation MKNote(Private)

-_unionWith:aNote
    /* Copies parameters from aNote to the receiver. For 
       parameters which are already present in the receiver, the
       value from the receiver is used. (cf. -copyFrom:) */
{
    copyPars(self,aNote,NO);
    return self;
}

-_noteOffForNoteDur
  /* If the receiver isn't a noteDur, returns nil. Otherwise, returns
   * the noteOff created according to the rules described in
   * -split::.
   */
{
    MKNote *aNoteOff;

    if (noteType != MK_noteDur) {
        _MKErrorf(MK_musicKitErr, @"receiver isnt a noteDur\n");
        return nil;
    }
    aNoteOff = [noteClass noteWithTimeTag: timeTag + getNoteDur(self)];
    if (noteTag == MAXINT)
        noteTag = MKNoteTag(); 
    setNoteOffFields(aNoteOff, noteTag, performer, conductor);
    if (isParPresent(self,MK_relVelocity))
        MKSetNoteParToInt(aNoteOff, MK_relVelocity, MKGetNoteParAsInt(self, MK_relVelocity));
    if ([self isParPresent: MK_midiChan])   /* This is needed by _MKWriteMidiOut */
        MKSetNoteParToInt(aNoteOff, MK_midiChan, MKGetNoteParAsInt(self, MK_midiChan));
    return aNoteOff;
}

-_splitNoteDurNoCopy
  /* Same as -_noteOffForNoteDur except the receiver's noteType 
   * is set to MK_noteOn.
   */
{
    MKNote *aNoteOff = [self _noteOffForNoteDur];
    noteType = MK_noteOn;
    return aNoteOff;
}

-(void)_setPerformer:anObj
  /* Private method sent by MKNoteSender class.  */
{
    performer = anObj;
}

- _setPartLink:aPart order:(int)orderTag
  /* Private method used for interface with Part class. */
{
    id oldPart;
    oldPart = part;
    part = aPart;
    if (aPart)
      _orderTag = orderTag;
    conductor = nil;
    return oldPart;
}

@end

