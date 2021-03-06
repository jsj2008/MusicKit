
/* Generated by Interface Builder */

#import <SndKit/SndView.h>

/*   SpectrumView is a class I made which knows something about the processing
of time domain signals into spectra, and the displaying of those spectra.  In
a more generic application, the Hartley transform and log magnitude conversion
routines are in another class called SignalProcessor.  For this application, 
however, the SpectrumView class itself can calculate the spectrum from the data.	*/


@interface SpectrumView: NSView
{
    id logFreq;
    id freqFields;
}

- setFreqFields:anObject;
- setLogFreq:anObject;
- setBackGround: (float) gray;
- setDraw: (float) gray;
- displayData: (int) powerOfFour array: (float *) f;
- drawSpectrum: (int) length array: (float *) f;
- drawSpectrum: (int) length array: (float *) f erase: (BOOL) erase;
- placeMarkerAt: (float) pos height: (float) height erase: (BOOL) erase;
- placeHorizontal: (float) height;
- clear;
- logLinear;
- (int) logFreq: (int) length array: (float *) f;
- logMag: (int) size array: (float *) f floor: (float) fl;
- fhtRX4: (int) powerOfFour array: (float *) array;
- getPeaks: (int) size array: (float *) array 
		numPeaks: (int) numPeaks locs: (float *) locs gains: (float *) gains;

@end
