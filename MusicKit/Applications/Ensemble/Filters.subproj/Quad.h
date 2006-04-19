#ifndef __MK_Quad_H___
#define __MK_Quad_H___

/* Generated by Interface Builder */

#import "EnsembleNoteFilter.h"

@interface Quad:EnsembleNoteFilter
{
    id	conductor;
    id  xFractal;
    id  yFractal;
    BOOL midiIn;
    BOOL fractalEnabled;
    BOOL thru;
    float pitchBendSensitivity;
    float roomSize;
    float minDistance;
    float minXY;
    float distance;
    float currentX;
    float currentY;
    float interval;
    float delay;
    float displayDuration;
    int xController;
    int yController;
	float amps[4];
    int controlVals[4];
    unsigned int outControllers[4];
    int gravityControllers[5];
    float gravity[5];
    unsigned int nicheOffset;
    id pitchBendNote;
    float maxOffset;

    id  lineGraph;
    id	intervalField;
    id	intervalSlider;
    id  displayDurationField;
    id  displayDurationSlider;
	id  pathEnableSwitch;

    id	roomSizeField;
    id	roomSizeSlider;
    id	minDistanceField;
    id	minDistanceSlider;

 	id  channelButtons;
    id  delayField;
    id  delaySlider;
    id	pitchBendField;
    id	pitchBendSlider;

    id  outControlInterface;
	id	inControlInterface;
	id  gravControlInterface;
	
	id thruButton;
}

- takeFractalEnableFrom:sender;
- takeIntervalFrom:sender;
- takePitchBendFrom:sender;
- takeRoomSizeFrom:sender;
- takeMinDistanceFrom:sender;
- takeControllerFrom:sender;
- takeOutControllerFrom:sender;
- takeGravityControllerFrom:sender;
- takeNicheOffsetFrom:sender;
- takeDelayFrom:sender;
- takeDisplayDurationFrom:sender;
- takeThruFrom:sender;
- moveTo:(float)x :(float)y;
- reset;
- graphPath;
- inspectFractal:sender;

@end
#endif