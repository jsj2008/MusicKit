#ifndef __MK_RandomPerformer_H___
#define __MK_RandomPerformer_H___
#import <MusicKit/MusicKit.h>

@interface RandomPerformer:MKPerformer
{
    id noteOn,noteOff;
    double rhythmicValue;
    int octaveOffset;
    BOOL on;
    double oldRanValue;
}

-setRhythmicValueTo:(double)r;
-setOctaveTo:(int)octaveNumber;
-init;
-perform;
-pause;
@end

#endif
