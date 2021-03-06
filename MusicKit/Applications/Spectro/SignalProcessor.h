
/* Generated by Interface Builder */

#import <Foundation/NSObject.h>
#import <AppKit/AppKit.h>

@interface SignalProcessor:NSObject
{
	int lastLength;
	float *sines;
	float *cosines;
}

- init;
- window:(int)size array:(float *)array;
- window:(int)size array:(float *)array type:(NSString *)type;
- window:(int)size array:(float *)array type:(NSString *)type phase:(BOOL)phase;
- dht:(float *)inputArray output:(float *)outputArray length:(int)length;
- makeSines:(int)length;
- scramble:(int)length array:(float *)f;
- fftRX2:(int)powerOfTwo array:(float *)array;
- fhtRX4:(int)powerOfFour array:(float *)array;
- logMag:(int)size array:(float *)f;
- logMag:(int)size array:(float *)f floor:(float)fl;
- logMag:(int)size array:(float *)f floor:(float)fl ceiling:(float)ceiling;
- log:(int)size array:(float *)f floor:(float)fl;
- log:(int)size array:(float *)f floor:(float)fl ceiling:(float)ceiling;
- squareMag:(int)size magnitudeIn:(float *)magIn squareMagOut:(float *)squarMagOut;
- magnitude:(int)size array:(float *)array magOut:(float *)mag;
- normalize:(int)size array:(float *)array;

@end
