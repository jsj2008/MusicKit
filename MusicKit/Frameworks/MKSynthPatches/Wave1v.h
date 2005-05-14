/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    (See discussion below)

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.5  2005/05/14 03:23:05  leighsmith
  Clean up of parameter names to correct doxygen warnings

  Revision 1.4  2005/05/09 15:27:44  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.3  2001/09/10 17:38:28  leighsmith
  Added abstracts from IntroSynthPatches.rtf

  Revision 1.2  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
//  classgroup WaveTable Synthesis
/*!
  @class Wave1v
  @brief Wavetable synthesis with 1 non-interpolating (drop-sample) oscillator and
  random and periodic vibrato.
  
  

  This class is just like Wave1vi but overrides the interpolating osc
  with a non-interpolating osc. Thus, it is slightly less expensive than
  Wave1vi. 
*/

#ifndef __MK_Wave1v_H___
#define __MK_Wave1v_H___

#import "Wave1vi.h"

@interface Wave1v:Wave1vi
{
}

/*!
  @param  aNote is an id.
  @return Returns an id.
  @brief  Returns a template using the non-interpolating osc.

  
*/
+patchTemplateFor: (MKNote *) aNote;

@end

#endif
