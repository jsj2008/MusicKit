/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:16  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_pitches_H___
#define __MK_pitches_H___

#import <MusicKit/keynums.h>
#import <MusicKit/MKTuningSystem.h>

#ifndef PITCHES_H
#define PITCHES_H

/* Here are macros for getting pitches in Hz. Note that you may not set
   these pseudo-variables! They are really function calls. 
   
   For the sake of terseness and convenience of use, we break here from the 
   Music Kit convention of appending MK_ to the start of macros. 
  */

#define c00 MKKeyNumToFreq(c00k)
#define cs00 MKKeyNumToFreq(cs00k)
#define df00 MKKeyNumToFreq(cs00k)
#define d00 MKKeyNumToFreq(d00k) 
#define ds00 MKKeyNumToFreq(ds00k) 
#define ef00 MKKeyNumToFreq(ds00k) 
#define e00 MKKeyNumToFreq(e00k) 
#define es00 MKKeyNumToFreq(f00k) 
#define ff00 MKKeyNumToFreq(e00k) 
#define f00 MKKeyNumToFreq(f00k) 
#define fs00 MKKeyNumToFreq(fs00k) 
#define gf00 MKKeyNumToFreq(fs00k) 
#define g00 MKKeyNumToFreq(g00k) 
#define gs00 MKKeyNumToFreq(gs00k) 
#define af00 MKKeyNumToFreq(gs00k) 
#define a00 MKKeyNumToFreq(a00k) 
#define as00 MKKeyNumToFreq(as00k) 
#define bf00 MKKeyNumToFreq(as00k) 
#define b00 MKKeyNumToFreq(b00k) 
#define bs00 MKKeyNumToFreq(c0k) 
#define cf0 MKKeyNumToFreq(bs00k) 
#define c0 MKKeyNumToFreq(c0k)
#define cs0 MKKeyNumToFreq(cs0k)
#define df0 MKKeyNumToFreq(cs0k)
#define d0 MKKeyNumToFreq(d0k) 
#define ds0 MKKeyNumToFreq(ds0k) 
#define ef0 MKKeyNumToFreq(ds0k) 
#define e0 MKKeyNumToFreq(e0k) 
#define es0 MKKeyNumToFreq(f0k)
#define ff0 MKKeyNumToFreq(e0k)
#define f0 MKKeyNumToFreq(f0k) 
#define fs0 MKKeyNumToFreq(fs0k) 
#define gf0 MKKeyNumToFreq(fs0k) 
#define g0 MKKeyNumToFreq(g0k) 
#define gs0 MKKeyNumToFreq(gs0k) 
#define af0 MKKeyNumToFreq(gs0k) 
#define a0 MKKeyNumToFreq(a0k) 
#define as0 MKKeyNumToFreq(as0k) 
#define bf0 MKKeyNumToFreq(as0k) 
#define b0 MKKeyNumToFreq(b0k) 
#define bs0 MKKeyNumToFreq(c1k)
#define cf1 MKKeyNumToFreq(b0k) 
#define c1 MKKeyNumToFreq(c1k) 
#define cs1 MKKeyNumToFreq(cs1k)
#define df1 MKKeyNumToFreq(cs1k)
#define d1 MKKeyNumToFreq(d1k)
#define ds1 MKKeyNumToFreq(ds1k)
#define ef1 MKKeyNumToFreq(ds1k)
#define e1 MKKeyNumToFreq(e1k)
#define es1 MKKeyNumToFreq(f1k)
#define ff1 MKKeyNumToFreq(e1k)
#define f1 MKKeyNumToFreq(f1k)
#define fs1 MKKeyNumToFreq(fs1k)
#define gf1 MKKeyNumToFreq(fs1k)
#define g1 MKKeyNumToFreq(g1k)
#define gs1 MKKeyNumToFreq(gs1k)
#define af1 MKKeyNumToFreq(gs1k)
#define a1 MKKeyNumToFreq(a1k)
#define as1 MKKeyNumToFreq(as1k)
#define bf1 MKKeyNumToFreq(as1k)
#define b1 MKKeyNumToFreq(b1k)
#define bs1 MKKeyNumToFreq(c2k)
#define cf2 MKKeyNumToFreq(b1k)
#define c2 MKKeyNumToFreq(c2k)
#define cs2 MKKeyNumToFreq(cs2k)
#define df2 MKKeyNumToFreq(cs2k)
#define d2 MKKeyNumToFreq(d2k)
#define ds2 MKKeyNumToFreq(ds2k)
#define ef2 MKKeyNumToFreq(ds2k)
#define e2 MKKeyNumToFreq(e2k)
#define es2 MKKeyNumToFreq(f2k)
#define ff2 MKKeyNumToFreq(e2k)
#define f2 MKKeyNumToFreq(f2k)
#define fs2 MKKeyNumToFreq(fs2k)
#define gf2 MKKeyNumToFreq(fs2k)
#define g2 MKKeyNumToFreq(g2k)
#define gs2 MKKeyNumToFreq(gs2k)
#define af2 MKKeyNumToFreq(gs2k)
#define a2 MKKeyNumToFreq(a2k)
#define as2 MKKeyNumToFreq(as2k)
#define bf2 MKKeyNumToFreq(as2k)
#define b2 MKKeyNumToFreq(b2k)
#define bs2 MKKeyNumToFreq(c3k)
#define cf3 MKKeyNumToFreq(b2k)
#define c3 MKKeyNumToFreq(c3k)
#define cs3 MKKeyNumToFreq(cs3k)
#define df3 MKKeyNumToFreq(cs3k)
#define d3 MKKeyNumToFreq(d3k)
#define ds3 MKKeyNumToFreq(ds3k)
#define ef3 MKKeyNumToFreq(ds3k)
#define e3 MKKeyNumToFreq(e3k)
#define es3 MKKeyNumToFreq(f3k)
#define ff3 MKKeyNumToFreq(e3k)
#define f3 MKKeyNumToFreq(f3k)
#define fs3 MKKeyNumToFreq(fs3k)
#define gf3 MKKeyNumToFreq(fs3k)
#define g3 MKKeyNumToFreq(g3k)
#define gs3 MKKeyNumToFreq(gs3k)
#define af3 MKKeyNumToFreq(gs3k)
#define a3 MKKeyNumToFreq(a3k)
#define as3 MKKeyNumToFreq(as3k)
#define bf3 MKKeyNumToFreq(as3k)
#define b3 MKKeyNumToFreq(b3k)
#define bs3 MKKeyNumToFreq(c4k)
#define cf4 MKKeyNumToFreq(b3k)
#define c4 MKKeyNumToFreq(c4k)
#define cs4 MKKeyNumToFreq(cs4k)
#define df4 MKKeyNumToFreq(cs4k)
#define d4 MKKeyNumToFreq(d4k)
#define ds4 MKKeyNumToFreq(ds4k)
#define ef4 MKKeyNumToFreq(ds4k)
#define e4 MKKeyNumToFreq(e4k)
#define es4 MKKeyNumToFreq(f4k)
#define ff4 MKKeyNumToFreq(e4k)
#define f4 MKKeyNumToFreq(f4k)
#define fs4 MKKeyNumToFreq(fs4k)
#define gf4 MKKeyNumToFreq(fs4k)
#define g4 MKKeyNumToFreq(g4k)
#define gs4 MKKeyNumToFreq(gs4k)
#define af4 MKKeyNumToFreq(gs4k)
#define a4 MKKeyNumToFreq(a4k)
#define as4 MKKeyNumToFreq(as4k)
#define bf4 MKKeyNumToFreq(as4k)
#define b4 MKKeyNumToFreq(b4k)
#define bs4 MKKeyNumToFreq(c5k)
#define cf5 MKKeyNumToFreq(b4k)
#define c5 MKKeyNumToFreq(c5k)
#define cs5 MKKeyNumToFreq(cs5k)
#define df5 MKKeyNumToFreq(cs5k)
#define d5 MKKeyNumToFreq(d5k)
#define ds5 MKKeyNumToFreq(ds5k)
#define ef5 MKKeyNumToFreq(ds5k)
#define e5 MKKeyNumToFreq(e5k)
#define es5 MKKeyNumToFreq(f5k)
#define ff5 MKKeyNumToFreq(e5k)
#define f5 MKKeyNumToFreq(f5k)
#define fs5 MKKeyNumToFreq(fs5k)
#define gf5 MKKeyNumToFreq(fs5k)
#define g5 MKKeyNumToFreq(g5k)
#define gs5 MKKeyNumToFreq(gs5k)
#define af5 MKKeyNumToFreq(gs5k)
#define a5 MKKeyNumToFreq(a5k)
#define as5 MKKeyNumToFreq(as5k)
#define bf5 MKKeyNumToFreq(as5k)
#define b5 MKKeyNumToFreq(b5k)
#define bs5 MKKeyNumToFreq(c6k)
#define cf6 MKKeyNumToFreq(b5k)
#define c6 MKKeyNumToFreq(c6k)
#define cs6 MKKeyNumToFreq(cs6k)
#define df6 MKKeyNumToFreq(cs6k)
#define d6 MKKeyNumToFreq(d6k)
#define ds6 MKKeyNumToFreq(ds6k)
#define ef6 MKKeyNumToFreq(ds6k)
#define e6 MKKeyNumToFreq(e6k)
#define es6 MKKeyNumToFreq(f6k)
#define ff6 MKKeyNumToFreq(e6k)
#define f6 MKKeyNumToFreq(f6k)
#define fs6 MKKeyNumToFreq(fs6k)
#define gf6 MKKeyNumToFreq(fs6k)
#define g6 MKKeyNumToFreq(g6k)
#define gs6 MKKeyNumToFreq(gs6k)
#define af6 MKKeyNumToFreq(gs6k)
#define a6 MKKeyNumToFreq(a6k)
#define as6 MKKeyNumToFreq(as6k)
#define bf6 MKKeyNumToFreq(as6k)
#define b6 MKKeyNumToFreq(b6k)
#define bs6 MKKeyNumToFreq(c7k)
#define cf7 MKKeyNumToFreq(b6k)
#define c7 MKKeyNumToFreq(c7k)
#define cs7 MKKeyNumToFreq(cs7k)
#define df7 MKKeyNumToFreq(cs7k)
#define d7 MKKeyNumToFreq(d7k)
#define ds7 MKKeyNumToFreq(ds7k)
#define ef7 MKKeyNumToFreq(ds7k)
#define e7 MKKeyNumToFreq(e7k)
#define es7 MKKeyNumToFreq(f7k)
#define ff7 MKKeyNumToFreq(e7k)
#define f7 MKKeyNumToFreq(f7k)
#define fs7 MKKeyNumToFreq(fs7k)
#define gf7 MKKeyNumToFreq(fs7k)
#define g7 MKKeyNumToFreq(g7k)
#define gs7 MKKeyNumToFreq(gs7k)
#define af7 MKKeyNumToFreq(gs7k)
#define a7 MKKeyNumToFreq(a7k)
#define as7 MKKeyNumToFreq(as7k)
#define bf7 MKKeyNumToFreq(as7k)
#define b7 MKKeyNumToFreq(b7k)
#define bs7 MKKeyNumToFreq(c8k)
#define cf8 MKKeyNumToFreq(b7k)
#define c8 MKKeyNumToFreq(c8k)
#define cs8 MKKeyNumToFreq(cs8k)
#define df8 MKKeyNumToFreq(cs8k)
#define d8 MKKeyNumToFreq(d8k)
#define ds8 MKKeyNumToFreq(ds8k)
#define ef8 MKKeyNumToFreq(ds8k)
#define e8 MKKeyNumToFreq(e8k)
#define es8 MKKeyNumToFreq(f8k)
#define ff8 MKKeyNumToFreq(e8k)
#define f8 MKKeyNumToFreq(f8k)
#define fs8 MKKeyNumToFreq(fs8k)
#define gf8 MKKeyNumToFreq(fs8k)
#define g8 MKKeyNumToFreq(g8k)
#define gs8 MKKeyNumToFreq(gs8k)
#define af8 MKKeyNumToFreq(gs8k)
#define a8 MKKeyNumToFreq(a8k)
#define as8 MKKeyNumToFreq(as8k)
#define bf8 MKKeyNumToFreq(as8k)
#define b8 MKKeyNumToFreq(b8k)
#define bs8 MKKeyNumToFreq(c9k)
#define cf9 MKKeyNumToFreq(b8k)
#define c9 MKKeyNumToFreq(c9k)
#define cs9 MKKeyNumToFreq(cs9k)
#define df9 MKKeyNumToFreq(cs9k)
#define d9 MKKeyNumToFreq(d9k)
#define ds9 MKKeyNumToFreq(ds9k)
#define ef9 MKKeyNumToFreq(ds9k)
#define e9 MKKeyNumToFreq(e9k)
#define es9 MKKeyNumToFreq(f9k)
#define ff9 MKKeyNumToFreq(e9k)
#define f9 MKKeyNumToFreq(f9k)
#define fs9 MKKeyNumToFreq(fs9k)
#define gf9 MKKeyNumToFreq(fs9k)
#define g9 MKKeyNumToFreq(g9k)

#endif PITCHES_H



#endif
