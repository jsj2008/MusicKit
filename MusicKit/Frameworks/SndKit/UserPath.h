/* 
 * UserPath.h by Bruce Blumberg, NeXT Computer, Inc.
 *
 * You may freely copy,distribute and re-use the code in this example. NeXT
 * disclaims any warranty of any kind, expressed or implied, as to its fitness
 * for any particular purpose
 *
 * This file and its associated .m file define a data structure and set of
 * functions aimed at facilitating the use of user paths. Here is a simple
 * example:
 *
 * UserPath *arect;
 * arect = newUserPath(); // creates an empty user path
 * beginUserPath(arect,YES);  // initialize user path and cache
 *   UPmoveto(arect,0.0,0.0); // add moveto to userpath; update bounding box
 *   UPrlineto(arect,0.0,100.0); // add rlineto to path; update bounding box
 *   UPrlineto(arect,100.0,0.0); // add rlineto to path; update bounding box
 *   UPrlineto(arect,0.0,-100.0); // add rlineto to path; update bounding box
 *   closePath(arect); // close path
 * endUserPath(arect,dps_stroke); // close user path and specify operator
 * sendUserPath(arect);
 *
 * As you will note, the set of routines manage the allocation and growth of
 * the operator and operand arrays, as well as the calculation of the bounding
 * box. A user path created via these functions may be optionally cached down
 * at the window server, or repeatedly sent down.  The user paths created by
 * this set of functions are all allocated in a unique zone.
 *
 * Note: the associated file is a .m file because it pulls in some .h files
 * which reference objective C methods. 
 */

// Determine the MacOsX derivative being compiled on. This is a passing phase (MOXS 1.2) until the two O.S. merge API
#define macosx (defined(__ppc__) && !defined(ppc))
#define macosx_server (defined(__ppc__) && defined(ppc))

#if macosx
#define QUARTZ_RENDERING
#endif
// this file is not used if using CoreGraphics
#ifndef QUARTZ_RENDERING

#import <AppKit/dpsclient.h>
#import <AppKit/NSDPSContext.h>

typedef struct _UP {
    float          *points;
    int             numberOfPoints;
    char           *ops;
    NSPoint         cp;
    int             numberOfOps;
    int             max;
    float           bbox[4];
    int             opForUserPath;
    BOOL            ping;
} UserPath;

/* UserPath functions */
NSZone *userPathZone();
UserPath *newUserPath();
void freeUserPath(UserPath *up);
void debugUserPath(UserPath *up, BOOL shouldPing);
void growUserPath(UserPath *up);
void beginUserPath(UserPath *up, BOOL cache);
void endUserPath(UserPath *up, int op);
int sendUserPath(UserPath *up);
void UPmoveto(UserPath *up, float x, float y);
void UPrmoveto(UserPath *up, float x, float y);
void UPlineto(UserPath *up, float x, float y);
void UPrlineto(UserPath *up, float x, float y);
void UPcurveto(UserPath *up, float x1, float y1, float x2, float y2, float x3,
	       float y3);
void UPrcurveto(UserPath *up, float dx1, float dy1, float dx2, float dy2,
		float dx3, float dy3);
void UParc(UserPath *up, float x, float y, float r, float ang1, float ang2);
void UParcn(UserPath *up, float x, float y, float r, float ang1, float ang2);
void UParct(UserPath *up, float x1, float y1, float x2, float y2, float r);
void closePath(UserPath *up);
void addPts(UserPath *up, float x, float y);
void addOp(UserPath *up, int op);
void add(UserPath *up, int op, float x, float y);
void checkBBox(UserPath *up, float x, float y);

#endif
// QUARTZ_RENDERING
