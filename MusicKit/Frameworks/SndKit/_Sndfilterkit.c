/*
 filterkit.c (library "filterkit.a"):  Kaiser-windowed low-pass filter support.

 Original License:
   Copyright (c) 1984, Julius Smith
   All rights reserved.
        
   This is free software from the Digital Audio Resampling Home Page:
   http://www-ccrma.stanford.edu/~jos/resample/.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:
	      
   Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
   Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
   Neither the name of CCRMA, Stanford University, nor the names of its
   contributors may be used to endorse or promote products derived from this
   software without specific prior written permission.
    
   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNERS OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.

 Subsequent changes:
   Copyright (c)1999-2002 tomandandy inc.
 
 */
/* filterkit.c
 *
 * LpFilter() - Calculates the filter coeffs for a Kaiser-windowed low-pass
 *                   filter with a given roll-off frequency.  These coeffs
 *                   are stored into a array of doubles.
 * writeFilter() - Writes a filter to a file.
 * makeFilter() - Calls LpFilter() to create a filter, then scales the double
 *                   coeffs into an array of half words.
 * readFilter() - Reads a filter from a file.
 * FilterUp() - Applies a filter to a given sample when up-converting.
 * FilterUD() - Applies a filter to a given sample when up- or down-
 *                   converting.
 * initZerox() - Initialization routine for the zerox() function.  Must
 *                   be called before zerox() is called.  This routine loads
 *                   the correct filter so zerox() can use it.
 * zerox() - Given a pointer into a sample, finds a zero-crossing on the
 *                   interval [pointer-1:pointer+2] by iteration.
 */

// both sox and SndKit use Julius Smiths resampling code, logically sox should be the final version and SndKit use that.
#define SUPERCEDED 1 

#ifdef GNUSTEP
#include <stdio.h>
#include "SndResample.h"
#include "_Sndfilterkit.h"
#include <math.h>
#include <malloc.h>
#else

#import "SndResample.h"
#import "_Sndfilterkit.h"

#ifndef WIN32
#import <libc.h>
#else
#import <stdio.h>
#import <stdlib.h>
#import <malloc.h>
#import <wtypes.h>
#endif
#import <math.h>
#endif


/* LpFilter()
 *
 * reference: "Digital Filters, 2nd edition"
 *            R.W. Hamming, pp. 178-179
 *
 * Izero() computes the 0th order modified bessel function of the first kind.
 *    (Needed to compute Kaiser window).
 *
 * LpFilter() computes the coeffs of a Kaiser-windowed low pass filter with
 *    the following characteristics:
 *
 *       c[]  = array in which to store computed coeffs
 *       frq  = roll-off frequency of filter
 *       N    = Half the window length in number of coeffs
 *       Beta = parameter of Kaiser window
 *       Num  = number of coeffs before 1/frq
 *
 * Beta trades the rejection of the lowpass filter against the transition
 *    width from passband to stopband.  Larger Beta means a slower
 *    transition and greater stopband rejection.  See Rabiner and Gold
 *    (Theory and Application of DSP) under Kaiser windows for more about
 *    Beta.  The following table from Rabiner and Gold gives some feel
 *    for the effect of Beta:
 *
 * All ripples in dB, width of transition band = D*N where N = window length
 *
 *               BETA    D       PB RIP   SB RIP
 *               2.120   1.50  +-0.27      -30
 *               3.384   2.23    0.0864    -40
 *               4.538   2.93    0.0274    -50
 *               5.658   3.62    0.00868   -60
 *               6.764   4.32    0.00275   -70
 *               7.865   5.0     0.000868  -80
 *               8.960   5.7     0.000275  -90
 *               10.056  6.4     0.000087  -100
 */


#define IzeroEPSILON 1E-21               /* Max error acceptable in Izero */

#ifndef SUPERCEDED

static double Izero(double x)
{
   double sum, u, halfx, temp;
   int n;

   sum = u = n = 1;
   halfx = x/2.0;
   do {
      temp = halfx/(double)n;
      n += 1;
      temp *= temp;
      u *= temp;
      sum += u;
      } while (u >= IzeroEPSILON*sum);
   return(sum);
}

void LpFilter(double c[], int N, double frq, double Beta, int Num)
{
   double IBeta, temp, inm1;
   int i;

   /* Calculate ideal lowpass filter impulse response coefficients: */
   c[0] = 2.0*frq;
   for (i=1; i<N; i++) {
       temp = PI*(double)i/(double)Num;
       c[i] = sin(2.0*temp*frq)/temp; /* Analog sinc function, cutoff = frq */
   }

   /*
    * Calculate and Apply Kaiser window to ideal lowpass filter.
    * Note: last window value is IBeta which is NOT zero.
    * You're supposed to really truncate the window here, not ramp
    * it to zero. This helps reduce the first sidelobe.
    */
   IBeta = 1.0/Izero(Beta);
   inm1 = 1.0/((double)(N-1));
   for (i=1; i<N; i++) {
       temp = (double)i * inm1;
       c[i] *= Izero(Beta*sqrt(1.0-temp*temp)) * IBeta;
   }
}

#endif

/* Write a filter to a file
 *    Filter file format:
 *       file name: "F" Nmult "T" Nhc ".filter"
 *       1st line:  the string "ScaleFactor" followed by its value.
 *       2nd line:  the string "Length" followed by Nwing's value.
 *       3rd line:  the string "Nmult" followed by Nmult's value.
 *       4th line:  the string "Coeffs:" on a separate line.
 *       following lines:  Nwing number of 16-bit impulse response values
 *          in the right wing of the impulse response (the Imp[] array).
 *         (Nwing is equal to Npc*(Nmult+1)/2+1, where Npc is defined in the
 *         file "resample.h".)  Each coefficient is on a separate line.
 *       next line:  the string "Differences:" on a separate line.
 *       following lines:  Nwing number of 16-bit impulse-response
 *          successive differences:  ImpD[i] = Imp[i+1] - Imp[i].
 * ERROR codes:
 *   0 - no error
 *   1 - could not open file
 */

int writeFilter(SND_HWORD Imp[], SND_HWORD ImpD[], SND_UHWORD LpScl, SND_UHWORD Nmult,
                SND_UHWORD Nwing)
{
   char fname[30];
   FILE *fp;
   int i;

   sprintf(fname, "F%dT%d.filter", Nmult, Nhc);
   fp = fopen(fname, "wb");
   if (!fp)
      return(1);
   fprintf(fp, "ScaleFactor %d\n", LpScl);
   fprintf(fp, "Length %d\n", Nwing);
   fprintf(fp, "Nmult %d\n", Nmult);
   fprintf(fp, "Coeffs:\n");
   for (i=0; i<Nwing; i++)   /* Put array of 16-bit filter coefficients */
      fprintf(fp, "%d\n", Imp[i]);
   fprintf(fp, "Differences:\n");
   for (i=0; i<Nwing; i++)   /* Put array of 16-bit filter coeff differences */
      fprintf(fp, "%d\n", ImpD[i]);
   fclose(fp);
   printf("Wrote filter file '%s' in current directory.\n",fname);
   return(0);
}

/* ERROR return codes:
 *    0 - no error
 *    1 - Nwing too large (Nwing is > MAXNWING)
 *    2 - Froll is not in interval [0:1)
 *    3 - Beta is < 1.0
 *    4 - LpScl will not fit in 16-bits
 *
 * Made following global to avoid stack problems in Sun3 compilation: */

#define MAXNWING   8192

#ifndef SUPERCEDED

static double ImpR[MAXNWING];

int makeFilter(SND_HWORD Imp[], SND_HWORD ImpD[], SND_UHWORD *LpScl, SND_UHWORD Nwing,
               double Froll, double Beta)
{
   double DCgain, Scl, Maxh;
   SND_HWORD Dh;
   int i, temp;

   if (Nwing > MAXNWING)                      /* Check for valid parameters */
      return(1);
   if ((Froll<=0) || (Froll>1))
      return(2);
   if (Beta < 1)
      return(3);

   /*
    * Design Kaiser-windowed sinc-function low-pass filter
    */
   LpFilter(ImpR, (int)Nwing, 0.5*Froll, Beta, Npc);

   /* Compute the DC gain of the lowpass filter, and its maximum coefficient
    * magnitude. Scale the coefficients so that the maximum coeffiecient just
    * fits in Nh-bit fixed-point, and compute LpScl as the NLpScl-bit (signed)
    * scale factor which when multiplied by the output of the lowpass filter
    * gives unity gain. */
   DCgain = 0;
   Dh = Npc;                       /* Filter sampling period for factors>=1 */
   for (i=Dh; i<Nwing; i+=Dh)
      DCgain += ImpR[i];
   DCgain = 2*DCgain + ImpR[0];    /* DC gain of real coefficients */

   for (Maxh=i=0; i<Nwing; i++)
      Maxh = MAX(Maxh, fabs(ImpR[i]));

   Scl = ((1<<(Nh-1))-1)/Maxh;     /* Map largest coeff to 16-bit maximum */
   temp = fabs((1<<(NLpScl+Nh))/(DCgain*Scl));
   if (temp >= 1<<16)
   return(4);                   /* Filter scale factor overflows SND_UHWORD */
   *LpScl = temp;

   /* Scale filter coefficients for Nh bits and convert to integer */
   if (ImpR[0] < 0)                /* Need pos 1st value for LpScl storage */
      Scl = -Scl;
   for (i=0; i<Nwing; i++)         /* Scale them */
      ImpR[i] *= Scl;
   for (i=0; i<Nwing; i++)         /* Round them */
      Imp[i] = ImpR[i] + 0.5;

   /* ImpD makes linear interpolation of the filter coefficients faster */
   for (i=0; i<Nwing-1; i++)
      ImpD[i] = Imp[i+1] - Imp[i];
   ImpD[Nwing-1] = - Imp[Nwing-1];      /* Last coeff. not interpolated */

   return(0);
}

#endif

/* Read-in a filter
 *    Filter file format:
 *       file name: "F" Nmult "T" Nhc ".filter"
 *       1st line:  the string "ScaleFactor" followed by its value.
 *       2nd line:  the string "Length" followed by Nwing's value.
 *       3rd line:  the string "Coeffs:" on separate line.
 *       Nwing number of 16-bit impulse response values in the right
 *          wing of the impulse response.  (Length=Npc*(Nmult+1)/2+1,
 *          where originally Npc=2^9, and Nmult=13.)   Each on separate line.
 *       The string "Differences:" on separate line.
 *       Nwing number of 16-bit impulse-response successive differences:
 *          ImpDiff[i] = Imp[i+1] - Imp[i].
 *
 * ERROR return codes:
 *    0 - no error
 *    1 - file not found
 *    2 - invalid ScaleFactor in file
 *    3 - invalid Length in file
 *    4 - invalid Nmult in file
 */
int readFilter(char *filterFile, SND_HWORD **ImpP, SND_HWORD **ImpDP, SND_UHWORD *LpScl,
               SND_UHWORD *Nmult, SND_UHWORD *Nwing)
{
    char *fname;
    FILE *fp;
    int i, temp;
    SND_HWORD *Imp,*ImpD;

    if (!filterFile || !(*filterFile)) {
        fname = (char *) malloc(32);
        if ((*Nmult)>0 && ((*Nmult)&1))
          sprintf(fname, "F%dT%d.filter", *Nmult, Nhc);
        else
          sprintf(fname, "F65dT%d.filter", Nhc);
    } else
      fname = filterFile;

    fp = fopen(fname, "rb");
    if (fp == NULL)
      return(1);

    fscanf(fp, "ScaleFactor ");
    if (1 != fscanf(fp,"%d",&temp))
      return(2);
    *LpScl = temp;

    fscanf(fp, "\nLength ");
    if (1 != fscanf(fp,"%d",&temp))
      return(3);
    *Nwing = temp;

    fscanf(fp, "\nNmult ");
    if (1 != fscanf(fp,"%d",&temp))
      return(4);
    *Nmult = temp;

    Imp = (SND_HWORD *) malloc(*Nwing * sizeof(SND_HWORD));

    fscanf(fp, "\nCoeffs:\n");
    for (i=0; i<*Nwing; i++)  { /* Get array of 16-bit filter coefficients */
        fscanf(fp, "%d\n", &temp);
        Imp[i] = temp;
    }

ImpD = (SND_HWORD *) malloc(*Nwing * sizeof(SND_HWORD));

    fscanf(fp, "\nDifferences:\n");
    for (i=0; i<*Nwing; i++)  { /* Get array of 16bit filter coeff differences */
        fscanf(fp, "%d\n", &temp);
        ImpD[i] = temp;
    }

    fclose(fp);
    if (!filterFile || !(*filterFile))
      free(fname);
    *ImpP = Imp;
    *ImpDP = ImpD;
    return(0);
}

SND_WORD FilterUp(SND_HWORD Imp[], SND_HWORD ImpD[],
                  SND_UHWORD Nwing, BOOL Interp,
                  SND_HWORD *Xp, SND_HWORD Ph, SND_HWORD Inc)
{
    SND_HWORD *Hp, *Hdp = NULL, *End;
    SND_HWORD a = 0;
    SND_WORD v, t;

    v=0;
    Hp = &Imp[Ph>>Na];
    End = &Imp[Nwing];
    if (Interp) {
        Hdp = &ImpD[Ph>>Na];
        a = Ph & Amask;
    }
    if (Inc == 1)		/* If doing right wing...              */
    {				/* ...drop extra coeff, so when Ph is  */
        End--;			/*    0.5, we don't do too many mult's */
        if (Ph == 0)		/* If the phase is zero...           */
        {			/* ...then we've already skipped the */
            Hp += Npc;		/*    first sample, so we must also  */
            Hdp += Npc;		/*    skip ahead in Imp[] and ImpD[] */
        }
    }
    if (Interp)
      while (Hp < End) {
          t = *Hp;		/* Get filter coeff */
      t += (((SND_WORD)*Hdp)*a)>>Na; /* t is now interp'd filter coeff */
          Hdp += Npc;		/* Filter coeff differences step */
          t *= *Xp;		/* Mult coeff by input sample */
          if (t & (1<<(Nhxn-1)))  /* Round, if needed */
            t += (1<<(Nhxn-1));
          t >>= Nhxn;		/* Leave some guard bits, but come back some */
          v += t;			/* The filter output */
          Hp += Npc;		/* Filter coeff step */
          Xp += Inc;		/* Input signal step. NO CHECK ON BOUNDS */
      }
    else
      while (Hp < End) {
          t = *Hp;		/* Get filter coeff */
          t *= *Xp;		/* Mult coeff by input sample */
          if (t & (1<<(Nhxn-1)))  /* Round, if needed */
            t += (1<<(Nhxn-1));
          t >>= Nhxn;		/* Leave some guard bits, but come back some */
          v += t;			/* The filter output */
          Hp += Npc;		/* Filter coeff step */
          Xp += Inc;		/* Input signal step. NO CHECK ON BOUNDS */
      }
    return(v);
}

SND_WORD FilterUD( SND_HWORD Imp[], SND_HWORD ImpD[],
                   SND_UHWORD Nwing, BOOL Interp,
                   SND_HWORD *Xp, SND_HWORD Ph, SND_HWORD Inc, SND_UHWORD dhb)
{
    SND_HWORD a;
    SND_HWORD *Hp, *Hdp, *End;
    SND_WORD v, t;
    SND_UWORD Ho;

    v=0;
    Ho = (Ph*(SND_UWORD)dhb)>>Np;
    End = &Imp[Nwing];
    if (Inc == 1)		/* If doing right wing...              */
    {				/* ...drop extra coeff, so when Ph is  */
        End--;			/*    0.5, we don't do too many mult's */
        if (Ph == 0)		/* If the phase is zero...           */
          Ho += dhb;		/* ...then we've already skipped the */
    }				/*    first sample, so we must also  */
                                /*    skip ahead in Imp[] and ImpD[] */
    if (Interp)
      while ((Hp = &Imp[Ho>>Na]) < End) {
          t = *Hp;		/* Get IR sample */
          Hdp = &ImpD[Ho>>Na];  /* get interp (lower Na) bits from diff table*/
          a = Ho & Amask;	/* a is logically between 0 and 1 */
          t += (((SND_WORD)*Hdp)*a)>>Na; /* t is now interp'd filter coeff */
          t *= *Xp;		/* Mult coeff by input sample */
          if (t & 1<<(Nhxn-1))	/* Round, if needed */
            t += 1<<(Nhxn-1);
          t >>= Nhxn;		/* Leave some guard bits, but come back some */
          v += t;			/* The filter output */
          Ho += dhb;		/* IR step */
          Xp += Inc;		/* Input signal step. NO CHECK ON BOUNDS */
      }
    else
      while ((Hp = &Imp[Ho>>Na]) < End) {
          t = *Hp;		/* Get IR sample */
          t *= *Xp;		/* Mult coeff by input sample */
          if (t & 1<<(Nhxn-1))	/* Round, if needed */
            t += 1<<(Nhxn-1);
          t >>= Nhxn;		/* Leave some guard bits, but come back some */
          v += t;			/* The filter output */
          Ho += dhb;		/* IR step */
          Xp += Inc;		/* Input signal step. NO CHECK ON BOUNDS */
      }
    return(v);
}

/*
 * double zerox(Data, Factor)
 * SND_HWORD *Data;
 * double Factor;
 *    Given a pointer into a sound sample, this function uses a low-pass
 * filter to estimate the x coordinate of the zero-crossing which must ocurr
 * between Data[0] and Data[1].  This value is returned as the value of the
 * function.  A return value of -100 indicates there was no zero-crossing in
 * the x interval [-1,2].  Factor is the resampling factor: Rate(out) /
 * Rate(in).  Nmult (which determines which filter is used) is passed the
 * zerox's initialization routine: initZerox(Nmult)
 *                                 SND_UHWORD Nmult;
 */

static SND_UHWORD LpScl, Nmult, Nwing;
static SND_HWORD Imp[MAXNWING];
static SND_HWORD ImpD[MAXNWING];

/* ERROR return values:
 *   0 - no error
 *   1 - Nmult is even (should be odd)
 *   2 - filter file not found
 *   3 - invalid ScaleFactor in input file
 *   4 - invalid Length in file
 *   5 - invalid Nmult in file
 */
int initZerox(SND_UHWORD tempNmult)
{
   int err;

   /* Check for illegal input values */
   if (!(tempNmult % 2))
      return(1);
   if ((err = readFilter(NULL, (SND_HWORD **)&Imp, (SND_HWORD **)&ImpD,
                        &LpScl, &tempNmult, &Nwing)))
      return(1+err);

   Nmult = tempNmult;
   return(0);
}

#define MAXITER 64
#define ZeroxEPSILON (1E-4)
#define ZeroxMAXERROR (5.0)

double zerox(SND_HWORD *Data, double Factor)
{
   double x, out;
   double lo, hi;
   double dh;
   SND_UWORD dhb;
   SND_WORD v;
   int i;

   if (!Data[0])
      return (0.0);
   if (!Data[1])
      return (1.0);

   if (Data[0] < Data[1])
      {
      lo = -1.0;
      hi =  2.0;
      }
   else
      {
      lo =  2.0;
      hi = -1.0;
      }
   dh = (Factor<1) ? (Factor*Npc) : (Npc);
   dhb = dh * (1<<Na) + 0.5;

   for (i=0; i<MAXITER; i++)
      {
      x = (hi+lo)/2.0;
   v  = FilterUD(Imp,ImpD,Nwing,YES,Data,  (SND_HWORD)(x*Pmask),    -1,dhb);
   v += FilterUD(Imp,ImpD,Nwing,YES,Data+1,(SND_HWORD)((1-x)*Pmask), 1,dhb);
      v >>= Nhg;
      v *= LpScl;
      out = (double)v / (double)(1<<NLpScl);
      if (out < 0.0)
         lo = x;
      else
         hi = x;
      if (ABS(out) <= ZeroxEPSILON)
         return(x);
      }
   printf("|ZeroX Error| x:%g, \t Data[x]:%d, \t Data[x+1]:%d\n",
      x, *Data, *(Data+1));
   printf("|\tABS(out):%g \t EPSILON:%g\n", ABS(out),ZeroxEPSILON);
   if (ABS(out) <= ZeroxMAXERROR)
      return(x);
   return(-100.0);
}
