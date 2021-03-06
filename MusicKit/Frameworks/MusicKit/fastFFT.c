/*
  $Id$
  Defined In: The MusicKit

  Description: 
    Routines for split-radix, real-only transforms.

  Original Author: R. E. Crandall, NeXT Scientific Computation Group

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

   $Log$
   Revision 1.6  2002/04/03 03:59:41  skotmcdonald
   Bulk = NULL after free type paranoia, lots of ensuring pointers are not nil before freeing, lots of self = [super init] style init action

   Revision 1.5  2001/05/12 09:32:55  sbrandon
   - GNUSTEP: changed imports to includes

   Revision 1.4  2001/01/24 22:00:10  skot
   Optimized fft algs, in particular sin/cos look up tables, for approx ~40% speedup

   Revision 1.3  2000/10/05 08:06:40  skot
   Added fastFFT.h, made fft functions extern linkable (non static)

   Revision 1.2  1999/07/29 01:26:04  leigh
   Added Win32 compatibility, CVS logs, SBs changes

   16/April/1991 - Reverted back to Richard's version.  Added "static".
   22/Aug/1991 -   Changes due to new compiler. (id -> i_d)
*/
 /* These routines are adapted from
  * Sorenson, et. al., (1987)
  * I.E.E.E. Trans. Acous. Sp. and Sig. Proc., ASSP-35, 6, 849-863
  *
  * When all x[j] are real the standard DFT of (x[0],x[1],...,x[N-1]),
  * call it x^, has the property of Hermitian symmetry: x^[j] = x^[N-j]*.
  * Thus we only need to find the set
  * (x^[0].re, x^[1].re,..., x^[N/2].re, x^[N/2-1].im, ..., x^[1].im)
  * which, like the original signal x, has N elements.
  * The two key routines perform forward (real-to-Hermitian) FFT,
  * and backward (Hermitian-to-real) FFT, respectively.
  * For example, the sequence:
  *
  * fft_real_to_hermitian(x, N);
  * fftinv_hermitian_to_real(x, N);
  *
  * is an identity operation on the signal x.
  * To convolve two pure-real signals x and y, one goes:
  *
  * fft_real_to_hermitian(x, N);
  * fft_real_to_hermitian(y, N);
  * mul_hermitian(y, x, N);
  * fftinv_hermitian_to_real(x, N);
  *
  * and x is the pure-real cyclic convolution of x and y.
  */
 
#ifdef GNUSTEP
# include <math.h>
# include <stdlib.h>
#else
# import <math.h>
# import <stdlib.h> /*sb, for free and malloc */
#endif

#define TWOPI (double)(2*3.14159265358979323846264338327950)

static int cur_run = 0;
static int quart = 0;
static double *sintable=NULL;
static double *costable=NULL;

#define SQRTHALF ((double)0.7071067811865475) /* 1/sqrt((double)2.0) */

static void scramble_real(double *x, int n);

// SKoT: old attitude was to conserve memory by using single quarter-frame look up table for
// sin and cos. New attitude says memory is there to use, and cheap these days, so lets go
// for speed and have a full table for both!

static void init_sincos(int n) {
	
    if(n == cur_run)
        return;
    else {
        int j;
        double e = TWOPI/n;

        cur_run = n;
        quart = (cur_run>>2);
        if(sintable) { free(sintable); sintable = NULL; }
        if(costable) { free(costable); costable = NULL; }

        sintable = (double *)malloc(sizeof(double)*(1+n));
        costable = (double *)malloc(sizeof(double)*(1+n));
        for(j=0;j<=n;j++) {
            sintable[j] = sin(e*j);
            costable[j] = cos(e*j);
        }
/*        
	sincos = (double *)malloc(sizeof(double)*(1+(n>>2)));
	for(j=0;j<=(n>>2);j++) {
		sincos[j] = sin(e*j);
	}
*/
    }
}

inline static double s_sin(int n) {

    return sintable[n];
/*    
	int seg = n/(cur_run>>2);
	
	switch(seg) {
		case 0: return(sincos[n]);
		case 1: return(sincos[(cur_run>>1)-n]);
		case 2: return(-sincos[n-(cur_run>>1)]);
		case 3: return(-sincos[cur_run-n]);
	}
	return 0; // make compiler happy 
*/    
}

inline static double s_cos(int n)
{
    return costable[n]; 
/*    
	int quart = (cur_run>>2);
	if(n < quart) return(s_sin(n+quart));
	return(-s_sin(n-quart));
*/
}

void fft_real_to_hermitian(double* z, int n)
/* Output is {Re(z^[0]),...,Re(z^[n/2),Im(z^[n/2-1]),...,Im(z^[1]).
   This is a decimation-in-time, split-radix algorithm.
 */
{	
    register double cc1, ss1, cc3, ss3;
    register int is, i_d, i0, i1, i2, i3, i4, i5, i6, i7, i8,
        a, a3, b, b3, nminus = n-1, dil, expand;
    register double *x, e;
    int nn = n>>1;
    double t1, t2, t3, t4, t5, t6;
    register int n2, n4, n8, i, j;

    init_sincos(n);
    expand = cur_run/n;
    scramble_real(z, n);
    x = z-1;  /* FORTRAN compatibility. */
    is = 1;
    i_d = 4;
    do{
        for(i0 = is; i0 <= n; i0 += i_d) {
            i1 = i0+1;
            e = x[i0];
            x[i0] = e + x[i1];
            x[i1] = e - x[i1];
        }
        is = (i_d<<1)-1;
        i_d <<= 2;
    } while(is < n);
    n2 = 2;
    while(nn>>=1) {
        n2  <<= 1;
        n4  = n2>>2;
        n8  = n2>>3;
        is  = 0;
        i_d = n2<<1;
        do {
            for(i = is; i < n; i += i_d) {
                i1 = i+1;
                i2 = i1 + n4;
                i3 = i2 + n4;
                i4 = i3 + n4;
                t1 = x[i4]+x[i3];
                x[i4] -= x[i3];
                x[i3] = x[i1] - t1;
                x[i1] += t1;
                if(n4 == 1)
                    continue;
                i1 += n8;
                i2 += n8;
                i3 += n8;
                i4 += n8;
                t1 = (x[i3]+x[i4])*SQRTHALF;
                t2 = (x[i3]-x[i4])*SQRTHALF;
                x[i4] = x[i2] - t1;
                x[i3] = -x[i2] - t1;
                x[i2] = x[i1] - t2;
                x[i1] += t2;
            }
            is = (i_d<<1) - n2;
            i_d <<= 2;
        } while(is<n);
        dil = n/n2;
        a = dil;
        for(j = 2; j <= n8; j++) {
            a3  = (a+(a<<1)) & nminus;
            b   = a*expand;
            b3  = a3*expand;
            cc1 = s_cos(b);
            ss1 = s_sin(b);
            cc3 = s_cos(b3);
            ss3 = s_sin(b3);
            a   = (a+dil) & nminus;
            is  = 0;
            i_d = n2<<1;
            do {
                for(i = is; i < n; i += i_d) {
                    i1 = i+j;
                    i2 = i1 + n4;
                    i3 = i2 + n4;
                    i4 = i3 + n4;
                    i5 = i + n4 - j + 2;
                    i6 = i5 + n4;
                    i7 = i6 + n4;
                    i8 = i7 + n4;
                    t1 = x[i3]*cc1 + x[i7]*ss1;
                    t2 = x[i7]*cc1 - x[i3]*ss1;
                    t3 = x[i4]*cc3 + x[i8]*ss3;
                    t4 = x[i8]*cc3 - x[i4]*ss3;
                    t5 = t1 + t3;
                    t6 = t2 + t4;
                    t3 = t1 - t3;
                    t4 = t2 - t4;
                    t2 = x[i6] + t6;
                    x[i3] = t6 - x[i6];
                    x[i8] = t2;
                    t2 = x[i2] - t3;
                    x[i7] = -x[i2] - t3;
                    x[i4] = t2;
                    t1 = x[i1] + t5;
                    x[i6] = x[i1] - t5;
                    x[i1] = t1;
                    t1 = x[i5] + t4;
                    x[i5] -= t4;
                    x[i2] = t1;
                }
                is = (i_d<<1) - n2;
                i_d <<= 2;
            } while(is < n);
        }
    }
}

void fftinv_hermitian_to_real (double* z, int n)
/* Input is {Re(z^[0]),...,Re(z^[n/2),Im(z^[n/2-1]),...,Im(z^[1]).
   This is a decimation-in-frequency, split-radix algorithm.
 */
{	
    register double cc1, ss1, cc3, ss3;
    register int is, i_d, i0, i1, i2, i3, i4, i5, i6, i7, i8,
        a, a3, b, b3, nminus = n-1, dil, expand;
    register double *x, e;
    int nn = n>>1;
    double t1, t2, t3, t4, t5;
    int n2, n4, n8, i, j;

    init_sincos(n);
    expand = cur_run/n;
    x = z-1;
    n2 = n<<1;
    while(nn >>= 1) {
        is = 0;
        i_d = n2;
        n2 >>= 1;
        n4 = n2>>2;
        n8 = n4>>1;
        do {
            for(i=is;i<n;i+=i_d) {
                i1 = i+1;
                i2 = i1 + n4;
                i3 = i2 + n4;
                i4 = i3 + n4;
                t1 = x[i1] - x[i3];
                x[i1] += x[i3];
                x[i2] += x[i2];
                x[i3] = t1 - 2.0*x[i4];
                x[i4] = t1 + 2.0*x[i4];
                if(n4==1)
                    continue;
                i1 += n8;
                i2 += n8;
                i3 += n8;
                i4 += n8;
                t1 = (x[i2]-x[i1])*SQRTHALF;
                t2 = (x[i4]+x[i3])*SQRTHALF;
                x[i1] += x[i2];
                x[i2] = x[i4]-x[i3];
                x[i3] = -2.0*(t2+t1);
                x[i4] = 2.0*(t1-t2);
                }
            is = (i_d<<1) - n2;
            i_d <<= 2;
            } while(is<n-1);
        dil = n/n2;
        a = dil;
        for(j = 2; j <= n8; j++) {
            a3  = (a+(a<<1))&nminus;
            b   = a*expand;
            b3  = a3*expand;
            cc1 = s_cos(b);
            ss1 = s_sin(b);
            cc3 = s_cos(b3);
            ss3 = s_sin(b3);
            a   = (a+dil)&nminus;
            is  = 0;
            i_d = n2<<1;
            do {
                for(i=is;i<n;i+=i_d) {
                    i1 = i+j;
                    i2 = i1+n4;
                    i3 = i2+n4;
                    i4 = i3+n4;
                    i5 = i+n4-j+2;
                    i6 = i5+n4;
                    i7 = i6+n4;
                    i8 = i7+n4;
                    t1 = x[i1] - x[i6];
                    x[i1] += x[i6];
                    t2 = x[i5] - x[i2];
                    x[i5] += x[i2];
                    t3 = x[i8] + x[i3];
                    x[i6] = x[i8] - x[i3];
                    t4 = x[i4] + x[i7];
                    x[i2] = x[i4] - x[i7];
                    t5 = t1 - t4;
                    t1 += t4;
                    t4 = t2 - t3;
                    t2 += t3;
                    x[i3] = t5*cc1 + t4*ss1;
                    x[i7] = -t4*cc1 + t5*ss1;
                    x[i4] = t1*cc3 - t2*ss3;
                    x[i8] = t2*cc3 + t1*ss3;
                    }
                is = (i_d<<1) - n2;
                i_d <<= 2;
                } while(is<n-1);
            }
        }
    is = 1;
    i_d = 4;
    do {
        for(i0=is;i0<=n;i0+=i_d){
            i1 = i0+1;
            e = x[i0];
            x[i0] = e + x[i1];
            x[i1] = e - x[i1];
            }
        is = (i_d<<1) - 1;
        i_d <<= 2;
        } while(is<n);
    scramble_real(z, n);
    e = 1.0/(double)n;
    for(i=0;i<n;i++)
        z[i] *= e;				
}

#if 0
static void mul_hermitian(double *a, double *b, int n)
/* b becomes b*a in Hermitian representation. */
{
	int k, half = n>>1;
	register double c, d, e, f;
	
	b[0] *= a[0];
	b[half] *= a[half];
	for(k=1;k<half;k++) {
	        c = a[k]; d = b[k]; e = a[n-k]; f = b[n-k];
		b[n-k] = c*f + d*e;
		b[k] = c*d - e*f;
	}
}
#endif
 
static void scramble_real(double *x, int n)
{	
    register int i,j,k,halfN = n >> 1;
    double tmp;
    for(i=0,j=0;i<n-1;i++) {
        if(i<j) {
            tmp = x[j];
            x[j]=x[i];
            x[i]=tmp;
        }
        k = halfN;
        while(k<=j) {
            j -= k;
            k>>=1;
        }
        j += k;
    }
}

