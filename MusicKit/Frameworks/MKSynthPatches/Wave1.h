#ifndef __MK_Wave1_H___
#define __MK_Wave1_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* This class is just like Wave1i but overrides the interpolating osc
   with a non-interpolating osc. Thus, it is slightly less expensive than
   Wave1i. */

#import "Wave1i.h"

@interface Wave1:Wave1i
{
}

+patchTemplateFor:aNote;
/* Returns a template using the non-interpolating osc. */

@end

#endif
