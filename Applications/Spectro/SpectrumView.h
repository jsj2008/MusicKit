/* 
   $Id$

   Interface for SpectrumView class 

   Part of Spectro.app

   Modifications Copyright (c) 2003 The MusicKit Project, All Rights Reserved.

   Legal Statement Covering Additions by The MusicKit Project:

    Permission is granted to use and modify this code for commercial and
    non-commercial purposes so long as the author attribution and copyright
    messages remain intact and accompany all relevant code.

*/

#import <AppKit/AppKit.h>

@interface SpectrumView: NSView
{
    id delegate;
    NSColor *spectrumColor;
    NSColor *cursorColor;
    NSColor *gridColor;
    int lastLength;
    int length;
    double dataFactor;			/* Number of data points per pixel */
    float *coefs;			/* The FFT coefficients */
    int cursorPixel;			/* Cursor location (as pixel column) */
    BOOL draw;
    BOOL frames;
}

- initWithFrame: (NSRect) theFrame;
- (void) setDelegate: (id) anObject;
- delegate;
- frames: (BOOL) value;
- setDataFactor: (double) dFactor;
- (double) dataFactor;
- getCursorLocation: (float *) cursorPoint;
- setCursor: (float) cursorPoint;
- drawSpectrum: (int) npoints array: (float *) f;
- (void) drawRect: (NSRect) rects;
- (BOOL) acceptsFirstMouse: (NSEvent *) theEvent;
- (void) mouseDown: (NSEvent *) event;
- (void) setColors;

@end
