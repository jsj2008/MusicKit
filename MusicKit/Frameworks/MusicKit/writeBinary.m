#ifdef SHLIB
#include "shlib.h"
#endif

/*
  $Id$
  Defined In: The MusicKit

  Description:
    This file supports the writing of binary ("optimized") scorefiles. These
    files have the extension .playscore. See the file binaryScorefile.doc
    on the musickit source directory.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:19  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  01/08/90/daj - Added comments.
  12/11/93/daj - Added byte swapping for Intel hardware.
*/

#import "_musickit.h"
#import "tokens.h"
#import "_scorefile.h"

void _MKWriteIntPar(NSMutableData *aStream,int anInt)
{
    short aType = NSSwapHostShortToBig(MK_int);
    anInt = NSSwapHostIntToBig(anInt);
    [aStream appendBytes:&aType length:sizeof(aType)];
    [aStream appendBytes:&anInt length:sizeof(anInt)];
}

void _MKWriteDoublePar(NSMutableData *aStream,double aDouble)
{
    short aType = NSSwapHostShortToBig(MK_double);
    NSSwappedDouble bDouble = NSSwapHostDoubleToBig(aDouble);
    [aStream appendBytes:&aType length:sizeof(aType)];
    [aStream appendBytes:&bDouble length:sizeof(bDouble)];
}

void _MKWriteStringPar(NSMutableData *aStream,NSString *aString)
{
    short aType = NSSwapHostShortToBig(MK_string);
    const char *convString = [aString cString];
    [aStream appendBytes:&aType length:sizeof(aType)];
    [aStream appendBytes:convString length:strlen(convString)+1];
}

void _MKWriteVarPar(NSMutableData *aStream,NSString *aString)
{
    short aType = NSSwapHostShortToBig(_MK_typedVar);
    const char *convString = [aString cString];
    [aStream appendBytes:&aType length:sizeof(aType)];
    [aStream appendBytes:convString length:strlen(convString)+1];
}

void _MKWriteInt(NSMutableData *aStream,int anInt)
{
    anInt = NSSwapHostIntToBig(anInt);
    [aStream appendBytes:&anInt length:sizeof(anInt)];
}

void _MKWriteShort(NSMutableData *aStream,short aShort)
{
    aShort = NSSwapHostShortToBig(aShort);
    [aStream appendBytes:&aShort length:sizeof(aShort)];
}

void _MKWriteDouble(NSMutableData *aStream,double aDouble)
{
    NSSwappedDouble bDouble = NSSwapHostDoubleToBig(aDouble);
    [aStream appendBytes:&bDouble length:sizeof(bDouble)];
}

void _MKWriteFloat(NSMutableData *aStream,float aFloat)
{
    NSSwappedFloat bFloat = NSSwapHostFloatToBig(aFloat);
    [aStream appendBytes:&bFloat length:sizeof(bFloat)];
}

void _MKWriteChar(NSMutableData *aStream,char aChar)
{
    [aStream appendBytes:&aChar length:sizeof(aChar)];
}

void _MKWriteString(NSMutableData *aStream,char *aString)
{
    [aStream appendBytes:aString length:strlen(aString)+1];
}

void _MKWriteNSString(NSMutableData *aStream,NSString *aString)
{
    const char *convString = [aString cString];
    [aStream appendBytes:convString length:strlen(convString)+1];
}

