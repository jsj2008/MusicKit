
/* Generated by Interface Builder */

#import <musickit/NoteFilter.h>

typedef enum _actionType {STOP,THIN,PASS} actionType;

@interface MidiController:NoteFilter
{
    id	myHornController;
    id	blackKeys1;
    id	blackKeys2;
    id	blackKeys3;
    id	whiteKeys;
    id	blackKeys4;
    id	breathPressure;
    id	slide;
    id	blackKeys5;
    id	ampSliders;
    id	modSliders;
    id	regSlider;
    id	regMode;
    id  fastMode;
    unsigned lastVals[131];
    double lastTimes[131];
    unsigned minVals[131];
    double minTimes[131];
    actionType action[131];
    int lastKeyNum;
    id noteReceiver;
}

- center:sender;
- pitchWheel:sender;
- modWheel1:sender;
- volumePedal:sender;
- pressKey:sender;

@end
