/* $Id$ */
#import <MusicKit/MusicKit.h>
#import <AppKit/psopsOpenStep.h>
#import <math.h>
#import "TadPole.h"
#import "PartView.h"

@implementation TadPole

- (void)setTadNote:aNote
{
	id oldNote;
	
	oldNote = tadNote;
	tadNote = aNote;
}

- whatisTadNote
{
	return tadNote;
}

- initNote:aNote second:bNote partNum:(int)partNumber beatscale:(double) bscale freqscale:(double) fscale
{
	NSRect aRect;
	
	[super init];
//#error ViewConversion: 'setClipping:' is obsolete. Views always clip to their bounds. Use PSinitclip instead.
//	[self setClipping:NO];
	if (!bNote)
		aRect = NSMakeRect([aNote timeTag]*bscale, log([aNote freq])*fscale, [aNote dur]*bscale, 6.0);
	else
		aRect = NSMakeRect([aNote timeTag]*bscale, log([aNote freq])*fscale, ([bNote timeTag]-[aNote timeTag])*bscale, 6.0);
	[self setFrame:aRect];
	tadNote = aNote;
	tadNoteb = bNote;
	partNum = partNumber;
	return self;
}

//#warning RectConversion: drawRect:(NSRect)rects (used to be drawSelf:(const NXRect *)rects :(int)rectCount) no longer takes an array of rects
- (void)drawRect:(NSRect)rects
{
	double color;
	double xmax, xmin;

	if (rects.size.width > [self bounds].size.width)
		xmax = rects.size.width;
	else
		xmax = [self bounds].size.width;
	if (rects.origin.x > 2)
		xmin = rects.origin.x;
	else
		xmin = 2;
	color = (partNum % 5)/10.0 + .5;
	PSnewpath();
	if (moving) {
	 	PSsetinstance(YES);
		PSnewinstance();
	}
	else PSsetinstance (NO);
	PSsetlinewidth(1.0);
	PSsetgray(selected);
	PSmoveto (xmin, [self bounds].size.height/2);
	PSlineto (xmax, [self bounds].size.height/2);
	PSstroke();
	if (xmin == 2) {
		PSnewpath();
		if (moving)
		 	PSsetinstance(YES);
		else PSsetinstance (NO);
		PSsetlinewidth(3.0);
		PSsetgray(color);
		PSmoveto (2, 0);
		PSlineto (2,[self bounds].size.height);
		PSstroke();
	}
}

- (BOOL)isSelected
{
	return selected;
}

- (void)unHighlight
{
	selected = NO;
	[self display]; 
}

- (void)doHighlight
{
	selected = YES;
	[self erase];
	[self display]; 
}

- (void)erase
{
	[self lockFocus];
	PSnewpath();
	PSsetinstance(NO);
	PSsetgray(NSDarkGray);
	PSrectfill([self bounds].origin.x, [self bounds].origin.y, [self bounds].size.width, [self bounds].size.height);
	PSstroke();
	[self unlockFocus]; 
}

- (void)setMoving:(BOOL)ismoving
{
	moving = ismoving; 
}

- (void)setFromPosWith:(double)bscale :(double)fscale
{
	[tadNote setTimeTag:[self frame].origin.x/bscale];
	[tadNote setPar:MK_freq toDouble:exp([self frame].origin.y/fscale)]; 
}

- (void)mouseDown:(NSEvent *)theEvent 
{
	[[self superview] gotClicked:self with:theEvent];
}

@end
