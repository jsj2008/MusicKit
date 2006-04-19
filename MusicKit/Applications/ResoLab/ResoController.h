
/* Generated by Interface Builder */

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>

#define MAXPOLES 30
#define ZEROSBEGIN 3

typedef struct P_ZRec {
	int num_poles;
        float cen_res[MAXPOLES * 2];
} P_ZRec;

@interface ResoController: NSObject
{
    id  poleGains;
    id	button;
    id	pulseLevel;
    id	noiseLevel;
    id  randLevel;
    id  perLevel;
    id  vibField;
    id  numHarmonics;
    id	filterFields;
    id	filterZFields;
    id  pitchField;
    id	sourceFader;
    id	mySpectrum;
    id	myZPlane;
    id  my3DZPlane;
    MKNote      *theNote;
    MKNote      *theNoteUpdate;
    MKOrchestra *theOrch;
    MKSynthInstrument  *theIns;
    id  theWave; 
    id  theXform;
    id  linkSpectrum;
    
    P_ZRec theP_Z;
}

- init;
- setPoleGains:anObject;
- setLinkSpectrum:anObject;
- setButton:anObject;
- setPulseLevel:anObject;
- setNoiseLevel:anObject;
- setRandLevel:anObject;
- setPerLevel:anObject;
- setVibField:anObject;
- setNumHarmonics:anObject;
- setFilterFields:anObject;
- setPitchField:anObject;
- setSourceFader:anObject;
- setMySpectrum:anObject;
- setMyZPlane:anObject;
- setMy3DZPlane:anObject;
- makeNoise:sender;
- changeSource:sender;
- changeFilter:sender;
- bumpFilter:sender;
- changeHarmonics:sender;
- changeMod:sender;
- graph3D:sender;
- update;
- changePitch:sender;
- makeVowel:sender;
- (P_ZRec *) data;
- xform;

@end