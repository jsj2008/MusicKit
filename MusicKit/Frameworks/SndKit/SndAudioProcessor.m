////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndAudioProcessor.h"
#import "SndAudioBuffer.h"
#import "SndAudioProcessorInspector.h"

@implementation SndAudioProcessor

#define SNDAUDIOPROCESSOR_DEBUG 0

static NSMutableArray *fxClassesArray = nil;

////////////////////////////////////////////////////////////////////////////////
// registerAudioProcessorClass:
////////////////////////////////////////////////////////////////////////////////

+ (void) registerAudioProcessorClass: (id) fxclass
{
  if (!fxClassesArray)
    fxClassesArray = [[NSMutableArray alloc] init];

  if (fxclass != [SndAudioProcessor class]) {// don't want to register the base class!
    if (![fxClassesArray containsObject: fxclass]) {
      [fxClassesArray addObject: fxclass];
#if SNDAUDIOPROCESSOR_DEBUG
      NSLog(@"registering FX class: %@",[fxclass className]);
#endif
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
// fxClasses
////////////////////////////////////////////////////////////////////////////////

+ (NSArray*) fxClasses
{
  if (fxClassesArray)
    return [[fxClassesArray retain] autorelease];
  else
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
// audioProcessor
////////////////////////////////////////////////////////////////////////////////

+ audioProcessor
{
  return [[SndAudioProcessor new] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];
  if (self) {
    [SndAudioProcessor registerAudioProcessorClass: [self class]];
    numParams = 0;
    bActive   = FALSE;
  }
  return self;
}

- initWithParamCount: (const int) count name: (NSString*) s
{
  self = [super init];
  if (self) {
    [SndAudioProcessor registerAudioProcessorClass: [self class]];
    [self setName: s];
    numParams = count;
    bActive   = FALSE;
  }
  return self;
}

//////////////////////////////////////////////////////////////////////////////
// dealloc
//////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  [super dealloc];
}

//////////////////////////////////////////////////////////////////////////////
// description
//////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
  return [NSString stringWithFormat: @"%@ params:%i",name,numParams];
}

////////////////////////////////////////////////////////////////////////////////
// setNumParams
////////////////////////////////////////////////////////////////////////////////

- setNumParams: (const int) c
{
  numParams = c;
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// reset
////////////////////////////////////////////////////////////////////////////////

- reset
{
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// paramCount
////////////////////////////////////////////////////////////////////////////////

- (int) paramCount
{
  return numParams;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue:
////////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (const int) index
{
  /* Example:
  switch (index) {
    case kYourParamKeys:
      return discoFunkinessAmount;
      break;
  }
  */
  return 0.0f;
}

////////////////////////////////////////////////////////////////////////////////
// paramName:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramName: (const int) index
{
  /* Example:
  switch (index) {
    case kYourParamKeys:
      return = @"TheParameterName";
      break;
  }
  */
  return @"<unnamed>";
}

////////////////////////////////////////////////////////////////////////////////
// paramLabel:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramLabel: (const int) index
{
  /* Example:
  switch (index) {
    case kYourParamKeyForAttenuation:
      return @"deciBels";
      break;
  }
  */
  return nil;
}

////////////////////////////////////////////////////////////////////////////////
// paramName:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramDisplay: (const int) index
{
  /* Example:
  switch (index) {
    case kYourParamKeyForAttenuation:
      return [NSString stringWithFormat: @"%03f", linearToDecibels(attenuation)];
      break;
  }
  */
  return nil;
}

////////////////////////////////////////////////////////////////////////////////
// setParam:toValue:
////////////////////////////////////////////////////////////////////////////////

- setParam: (const int) index toValue: (const float) v
{
  /* Example:
  switch (index) {
    case kYourParamKeys:
      YourParams = v;
      break;
  }
  */
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer:outputBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB
{
  // no processing? return FALSE!
  // remember to check bActive in derived classes.

  // in derived classes, return TRUE if the output buffer has been written to
  return FALSE;
}

////////////////////////////////////////////////////////////////////////////////
// setAudioProcessorChain
////////////////////////////////////////////////////////////////////////////////

- (void) setAudioProcessorChain:(SndAudioProcessorChain*)inChain
{
  audioProcessorChain = inChain; /* non retained back pointer */
}

////////////////////////////////////////////////////////////////////////////////
// audioProcessorChain
////////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessorChain*) audioProcessorChain
{
  return [[audioProcessorChain retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// isActive
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isActive
{
  return bActive;
}

- setActive: (const BOOL) b
{
  bActive = b;
  return self;
}

//////////////////////////////////////////////////////////////////////////////
// name
//////////////////////////////////////////////////////////////////////////////

- setName: (NSString*) aName
{
  if (name != nil)
    [name release];
  name = [aName retain];
  return self;
}

- (NSString*) name
{
  return [[name retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// paramDictionary
////////////////////////////////////////////////////////////////////////////////

- (NSDictionary*) paramDictionary
{
  int i;
  NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
  for (i = 0; i < numParams; i++) {
    [dictionary setObject: [self paramObjectForIndex: i] forKey: [self paramName: i]];
  }
  return dictionary;
}

////////////////////////////////////////////////////////////////////////////////
// setParamWithKey:toValue:
////////////////////////////////////////////////////////////////////////////////

- setParamWithKey: (NSString*) keyName toValue: (NSValue*) value
{
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// paramObjectForIndex:
////////////////////////////////////////////////////////////////////////////////

- (id) paramObjectForIndex: (const int) i
{
  float f = [self paramValue: i];
  return [NSValue value: &f withObjCType: @encode(float)];
}

////////////////////////////////////////////////////////////////////////////////

@end
