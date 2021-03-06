#import "MySlider.h"
#import "MySliderCell.h"

@implementation MySlider

+ newFrame:(const NSRect *)frameRect
  /* We fool Interface Builder into creating an object of our class. */
{
    [super setCellClass:[MySliderCell class]];
    self = [super newFrame:frameRect];
    [super setCellClass:[NSSliderCell class]];
    return self;
}

- (void) setReturnValue:(void *)aValue
    /* Set the value that the slider will snap back to. */
{
    returnValue = aValue;
    [[self cell] setReturnValue:aValue];
    return self;
}

- sendAction:(SEL)theAction to:theTarget
{
    return [super sendAction:theAction to:theTarget];
}

@end


