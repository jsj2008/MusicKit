/*
  $Id$
  Defined In: The MusicKit

  Description:
    Simple sine table of size 1024 with linear interpolation.  Note that this
    version differs from the one in fastFFT.c in that the latter takes its
    argument in terms of the FFT size.  This one makes no such assumptions.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2002 The MusicKit Project.
*/
/*
Modification history:

  $Log$
  Revision 1.1  2002/09/25 22:28:52  leighsmith
  Renamed mySin and myCos to MKSine, MKCosine and placed into better named file and split out prototypes to a header for inclusion in MKPartials

  Revision 1.5  2002/09/25 17:40:37  leighsmith
  Commented out unused MKCosine function to stop warnings

  Revision 1.4  2001/05/12 09:37:37  sbrandon
  - GNUSTEP: include headers, don't import them

  Revision 1.3  2000/12/15 02:02:28  leigh
  Initial Revision

  Revision 1.2  1999/07/29 01:26:17  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifdef GNUSTEP
# include <math.h>
#else
# import <math.h>
#endif

#define SINTABLEN 1024

// Dear WinNT doesn't know about PI, stolen from MacOSX-Servers math.h definition
#ifndef M_PI
#define M_PI            3.14159265358979323846  /* pi */
#endif
#ifndef M_PI_2
#define M_PI_2          1.57079632679489661923  /* pi/2 */
#endif

static unsigned char sinTabInited = 0;
static double sinTab[SINTABLEN];

static void initSineTab(void)
{
    int i;
    for (i=0; i<SINTABLEN; i++) 
	sinTab[i] = sin(i * (M_PI * 2/SINTABLEN));
}

double MKSine(double x)
{
    int floorVal;
    double diff;
    if (!sinTabInited) {
	initSineTab();
	sinTabInited = 1;
    }
    while (x < 0) 
	x += (M_PI * 2);
    while (x > (M_PI*2))
	x -= (M_PI * 2);
    x *= SINTABLEN/(2 * M_PI);
    floorVal = x; 
    diff = x-floorVal;
    if (floorVal == SINTABLEN-1)
	return sinTab[floorVal] * (1-diff) + sinTab[0] * diff;
    else return sinTab[floorVal] * (1-diff) + sinTab[floorVal+1] * diff;
}

double MKCosine(double x)
{
    return MKSine(x + M_PI_2);
}
