/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is used by the Music Kit to signal "no value" from functions and
    methods that return double. The value MK_NODVAL is a particular "NaN"
    ("not a number"). You cannot test its value directly.
    Instead, use MKIsNoDVal().

    Example:

         double myFunction(int arg)
         {
                 if (arg == 2)
                         return MK_NODVAL;
                 else return (double) arg * 2;
         }

         main()
         {
                 double d = myFunction(2);
                 if (MKIsNoDVal(d))
                         printf("Illegal value.\n");
         }

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:10  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_noDVal_H___
#define __MK_noDVal_H___
  
#ifndef _MK_NANHI
#define _MK_NANHI 0x7ff80000 /* High bits of a particular non-signaling NaN */
#define _MK_NANLO 0x0        /* Low bits of a particular non-signaling NaN */
#endif

#ifndef MK_NODVAL

extern inline double MKGetNoDVal(void)
  /* Returns the special NaN that the Music Kit uses to signal "no value". */
{
	union {double d; int i[2];} u;
	u.i[0] = _MK_NANHI;
	u.i[1] = _MK_NANLO;
	return u.d;
}

extern inline int MKIsNoDVal(double val)
  /* Compares val to see if it is the special NaN that the Music Kit uses
     to signal "no value". */
{
	union {double d; int i[2];} u;
	u.d = val;
	return (u.i[0] == _MK_NANHI); /* Don't bother to check low bits. */
}

#define MK_NODVAL MKGetNoDVal()     /* For convenience */

#endif



#endif
