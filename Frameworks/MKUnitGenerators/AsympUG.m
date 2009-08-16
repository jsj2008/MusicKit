/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/*
Modification history:

  10/06/89/daj - Changed to use _exportedPrivateMusickit.h instead of
                 copied _musickit.h
  11/13/89/daj - Removed extra check in _nextPoint. Also note the following
                 optimizations that should be made:
		 Cache the value T48COEFF/_samplingRate for use in smoothValue.
		 Go to C-func interface with super class.
  11/22/89/daj - Changed to use UnitGenerator C functions instead of methods.
                 Optimized canceling of messages a bit.
		 Fixed envelopeStatus to return MK_noMorePoints if anEnv
		 is nil. Changed to use _MKGetEnvelopeNth(). Put in checks
		 for non-idle status (and thus insure that this C function
		 is safe to use -- see -runSelf below).
  11/26/89/daj - Added calls to _MKBeginUGBlock/_MKEndUGBlock in _nextPoint as
                 an optimization.
  11/26/89/daj - Added optimization instance variable _smoothConstant and
                 put smoothValue in-line.
  12/5/89/daj  - Changed setTarget: to setTargetVal: to avoid conflict with
                 Appkit. Note that this is an API change.
  01/8/90/daj  - Changed MKPreemptDuration() to MKGetPreemptDuration().
  01/25/90/daj - Added freeSelf.
  04/17/90/mmm - Added abortSelf as synonym for abortEnvelope, since it's in
                 the interface.
  04/27/90/daj - Flushed check to see if _MKClassEnvelope is loaded. It
                 always is, now that we're a shlib.
  08/28/90/daj - Changed initialize to init.
  09/02/90/daj - Changed MAXDOUBLE references to noDVal.h way of doing things
  09/29/90/daj - Commented out INLINE_MATH since 040 exp bug is fixed
  02/18/91/daj - Added error checking to calls to _MKGetEnvelopeNth().
                 Enabled MK_INLINE (compiler bug is reputed to be fixed.)
  08/28/91/daj - Added comments explaining approximation used in setT60:.
                 Changed time constant to give more accurately a -48dB value.
		 Added setT48:.
  2/6/93/daj -   Changed DSP code to not use R_L.  Added version check.
  6/12/93/daj -  Removed define of MK_INLINE
  7/16/94/daj -  Added setting of arrivalStatus to MK_noMorePoints to avoid
                 crash if someone sends setEnvelope:... followed by finish
		 with no intervening run (a wrong thing to do, but shouldn't
		 crash).  We use MK_noMorePoints to mean "envelope not
		 initialized".
  3/7/94/daj -   Added MINSMOOTH to work around exp() bug in NS486.
*/

/* AsympUG assumes that the envelope is not modified once it's set. */

// #define INLINE_MATH 1 /* Workaround for exp() bug. */
#import <MusicKit/MusicKit.h>
#import "_exportedPrivateMusickit.h"
#import "_unitGeneratorInclude.h"

#import "AsympUG.h"

#ifndef MAX
#define  MAX(A,B)	((A) > (B) ? (A) : (B))
#endif

@implementation AsympUG:MKUnitGenerator
/* Asymptotic ramper for writing to patch points.
   This may be used as a simple ramper but also contains
   support for sending an envelope to the DSP incrementally.

   Conductor used for timing of envelope values is always the
   Conductor class, although finish is sent based on the arrival of a
   noteOff, which is (usually) managed by another Conductor.

   The mathematical interpretation of asymptotic envelopes is as follows:
 * * 	Yn is the target, considered to be in the infinite future
 * *	Xn is the time of the right-hand side of the segment
 * * 	    (i.e. the time to interrupt the trajectory toward Yn)
 * *	Tn is the smoothing constant to get to Yn. If Tn is 0, the point
 * *        is reached immediately. If Tn=1, the point is reached, within about
 * *        60dB at the time of the next update. If Tn is larger, the point
 * *        is not reached by the time of the next update.
 * *
 * *	The first point, X0, is assumed to be the right-hand side of the
 * * 	non-existant first segment.
 * *	Y0 is the initial point (which may or may not be used, depending on
 * *          value of useInitialvalue).
 * * 	t0 is ignored. 	
 */
{
    id anEnv;                     /* The envelope, if any. */
    double (*scalingFunc)();      /* scalingFunc is a double-valued scaling
				     function of two arguments:
				     the current double value
				     and the UnitGenerator instance id.
				     If funPtr is NULL,
				     the identity mapping is used. */
    int envelopeStatus;           /* Status of last envelope point accessed.
				     I.e. if we just set the target which  
				     is the stickpoint, envelopeStatus is
				     MK_stickPoint. */
    int arrivalStatus;            /* Status of actual progression on the
				     DSP. I.e. if we have already interrupted
				     the trajectory to the stickpoint,
				     arrivalStatus is MK_stickPoint. */
    double timeScale;             /* time scaling. The time constants are
				     scaled as well. */
    double releaseTimeScale;      /* For the post-stick-point segment. */
    double yScale;                /* Y scale */
    double yOffset;               /* Y offset */
    double targetX;               /* X value of current target. */
    char useInitialValue;         /* Controls whether initial value of
				     envelope is used. */
    int curPt;                    /* Current envelope point. */
    double _reservedAsymp1;
    MKMsgStruct * _reservedAsymp2;
    double _reservedAsymp3;
    double _reservedAsymp4;
    double _reservedAsymp5;
    double _reservedAsymp6;
    double _reservedAsymp7;
    DSPDatum _reservedAsymp8;
}
enum _args { aout, trg, rate, amp};

#define _tScale _reservedAsymp1
#define _msgPtr _reservedAsymp2
#define _transitionTime _reservedAsymp3
#define _samplingRate _reservedAsymp4
#define _smoothConstant _reservedAsymp5
#define _targetY _reservedAsymp6
#define _startTimeThisSegment _reservedAsymp7
#define _rateValue _reservedAsymp8

#include "asympUGInclude.m"

#if _MK_UGOPTIMIZE
+(BOOL)shouldOptimize:(unsigned) arg
{
    return (arg != amp);
}
#endif _MK_UGOPTIMIZE

/* T48COEFF times the "time constant" gives time to decay 48dB exponentially */
// #define T48COEFF 5.25
/* JOS - I get 45.6 dB decay from the above constant, using the formula
   -20 Log[10,Exp[-5.25]] in Mathematica.  The formula for T48COEFF is
   -N[Log[10^(-48/20)]] = 5.52620422318571
*/
#define T48COEFF 5.52620422318571

/*
  We scale the time-constants along with the
  "interruption intervals".  Otherwise, as an envelope is shortened, for
  example, it may "melt down", i.e., there is no longer time for an envelope
  segment to reach its target.  If time is to be scaled by g, then we go from
  exp(-t/rate) to exp(-g*t/rate).  Thus, the time constant should be
  divided by the scale factor g. - Julius
*/

#define MAXINTRATE 0xfffff /* Can't let it get too big cause of bug in asymp */
#define MAXRATE .125
#define MINSMOOTH .0001 /* Otherwise exp() goes ape on 486 */

static id clockConductor = nil;

-init
{
  char version;
  int release;
  [super init];
  [orchestra getMonitorVersion:&version release:&release];
  if (version != 'A')
    MKErrorCode(MK_dspMonitorVersionError,[self class]);
  clockConductor = [_MKClassConductor() clockConductor];
  _samplingRate = [orchestra samplingRate];
  _smoothConstant = -T48COEFF / _samplingRate;
  arrivalStatus = MK_noMorePoints;
  return self;
}

-(MKEnvStatus)envelopeStatus
/* Status of last envelope point accessed.
   I.e. if we just set the target which  
   is the stickpoint, envelopeStatus is
   MK_stickPoint. If no envelope, returns MK_noMorePoints. */
{
    return (anEnv) ? envelopeStatus : MK_noMorePoints;
}

-setOutput:aPatchPoint
  /* Set output of ramper */
{
    return MKSetUGAddressArg(self,aout,aPatchPoint);
}

-setTarget:(double)aVal
  /* Same as setTargetVal:. This method will be phased out because it collides
     with an Appkit method. */
{
    if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
                   "Setting target of UG%d_%s to %f",_instanceNumber,[NSStringFromClass([self class]) cString],aVal);
    return MKSetUGDatumArg(self,trg,_MKDoubleToFix24(aVal));
}

-setTargetVal:(double)aVal
  /* Sets the target of the exponential.
     If the receiver is already
     processing an envelope, that envelope is not interrupted. The new
     point is simply inserted. */
{
    if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
                   "Setting target of UG%d_%s to %f",_instanceNumber,[NSStringFromClass([self class]) cString],aVal);
    return MKSetUGDatumArg(self,trg,_MKDoubleToFix24(aVal));
}

-setCurVal:(double)aVal
  /* Sets the current value of the exponential.
     If the receiver is already
     processing an envelope, that envelope is not interrupted. The new
     point is simply inserted. */
{
    DSPFix48 aFix48;
    if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
                   "Setting current value of UG%d_%s to %f",_instanceNumber,[NSStringFromClass([self class]) cString],aVal);
    DSPDoubleToFix48UseArg(aVal,&aFix48);
    return MKSetUGDatumArgLong(self,amp,&aFix48);
}

static id setRate(AsympUG *self,double aVal)
{
    self->_rateValue = (aVal >= MAXRATE) ? MAXINTRATE : _MKDoubleToFix24(aVal);
    if (_MK_ORCHTRACE(self->orchestra,MK_TRACEDSP))
      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
                   "Setting rate of UG%d_%s to %f",self->_instanceNumber,[NSStringFromClass([self class]) cString],aVal);
    return MKSetUGDatumArg(self,rate,self->_rateValue);
}

-setRate:(double)aVal
  /* Sets the rate of the exponential. (1-e^T/tau), where T is sampling
     period and tau is the time constant.
     If the receiver is already
     processing an envelope, that envelope is not interrupted. The new
     point is simply inserted. */
{
    return setRate(self,aVal);
}

static id setT60(AsympUG *self,double seconds)
    /* This uses the approximation 1-exp(x) = -x, which is close as long
     * as x doesn't approach 0.
     * The truly correct value here would be 1-exp(-7.0/seconds*samplingRate)
     */
{
    return setRate(self,7.0/(seconds * self->_samplingRate));
}

-setT60:(double)seconds
  /* Sets the time constant of the exponential. Same as
     [self setRate:7.0/(seconds*srate)]. */
{
    return setT60(self,seconds);
}

-setT48:(double)seconds
  /* Sets the time constant of the exponential. Same as
     [self setRate:5.52/(seconds*srate)]. */
{
    return setRate(self,T48COEFF/(seconds * self->_samplingRate));
}

-setEnvelope:anEnvelope yScale:(double)yScaleVal yOffset:(double)yOffsetVal
 xScale:(double)xScaleVal releaseXScale:(double)rXScaleVal
 funcPtr:(double(*)())func
  /* Inits envelope handler with the values specified. func is described above.
     */
{
    if (!anEnvelope)
      if (anEnv) {
	  [self abortEnvelope];
	  return nil;
      }
    if (![anEnvelope isKindOfClass: _MKClassEnvelope()])
      return nil;
    if (_msgPtr)
      _msgPtr = [_MKClassConductor() _cancelMsgRequest:_msgPtr];
    arrivalStatus = MK_noMorePoints;
    anEnv = anEnvelope;
    curPt = 0;
    yScale = yScaleVal;
    yOffset = yOffsetVal;
    timeScale = xScaleVal;
    releaseTimeScale = rXScaleVal;
    scalingFunc = func;
    useInitialValue = YES;
    _transitionTime = MK_NODVAL;
    return self;
}

#if 0
-resetEnvelope:anEnvelope yScale:(double)yScaleVal yOffset:(double)yOffsetVal
    xScale:(double)xScaleVal releaseXScale:(double)rXScaleVal
    funcPtr:(double(*)())func
  /* Like setEnvelope:yScaleVal:yOffset:xScale:releaseXScale:funcPtr:, but
     doesn't bind the first value of the envelope.  */
{
    id rtnVal = [self setEnvelope:anEnvelope yScale:yScaleVal
	       yOffset:yOffsetVal xScale:xScaleVal
	       releaseXScale:(double)rXScaleVal funcPtr:func];
    if ([anEnvelope pointCount] == 1)
      return rtnVal;
    useInitialValue = NO;
    _transitionTime = MAXDOUBLE;
    return rtnVal;
}
#endif

#define ENV_ERROR(_x) (_x < 0)

-preemptEnvelope
  /* Head to last point of envelope in time specified by
     MKSetPreemptDuration(). */
{
    int nPts;
    double lastVal,dummy1,dummy2;
    if (!anEnv || status == MK_idle)
      return self;
    nPts = [anEnv pointCount];
    if (nPts &&
	_MKGetEnvelopeNth(anEnv,nPts - 1,&dummy1,&lastVal,&dummy2) >= 0)
	{
	    if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
	      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
                    "Setting target of UG%d_%s to %f",_instanceNumber,[NSStringFromClass([self class]) cString],
			   lastVal);
	    MKSetUGDatumArg(self,trg,DSPDoubleToFix24(lastVal));
	    setT60(self,MKGetPreemptDuration());
	}
    [self abortEnvelope];
    return self;
}

-useInitialValue:(BOOL)yesOrNo
{
	useInitialValue = yesOrNo;
	return self;
}

-resetEnvelope:anEnvelope yScale:(double)yScaleVal yOffset:(double)yOffsetVal
    xScale:(double)xScaleVal releaseXScale:(double)rXScaleVal
    funcPtr:(double(*)())func  transitionTime:(double)transTime
  /* Like setEnvelope:yScaleVal:yOffset:xScale:releaseXScale:funcPtr:, but
     doesn't bind the first value of the envelope.  TransitionTime is the
     absolute time used to get to the second value of the envelope (xScale
     is not used here). If set to MK_NODVAL, the time will be the normal time
     of the first envelope segment (after any scaling). */
{
    id rtnVal = [self setEnvelope:anEnvelope yScale:yScaleVal
	       yOffset:yOffsetVal xScale:xScaleVal
	       releaseXScale:(double)rXScaleVal funcPtr:func];
    if ([anEnvelope pointCount] == 1)
      return rtnVal;
    useInitialValue = NO;
    _transitionTime = transTime;
    return rtnVal;
}

-setYScale:(double)yScaleVal yOffset:(double)yOffsetVal
  /* Resets the scale and offset. If envelope is running, does the following:

     This is what SHOULD happen. Currently, I just slam the value:

     1. It computes the ESTIMATED current value (this is inexact do to
     the fact that we never really reach the target). Set target to that value
     and head for it with MKGetPreemptDuration().
     2. Reschedule a message to us for MKGetPreemptDuration() from now. At that
     time, head for the original point again. Be careful to cancel this
     message in -nextPoint.


*/
{
    if (!MKIsNoDVal(yScaleVal))
      yScale = yScaleVal;
    if (!MKIsNoDVal(yOffsetVal))
      yOffset = yOffsetVal;
    if (anEnv && (curPt > 0)) {
	double newCurrentAmp,newTargetY,dummy;
	DSPFix48 aVal;
	envelopeStatus = _MKGetEnvelopeNth(anEnv,curPt-1,&targetX,&newTargetY,
					   &dummy);
	if (envelopeStatus < 0)              /* Error */
	  return nil;
	newTargetY *= yScaleVal; /* New scale */
	newTargetY += yOffsetVal;/* New offset */
	if (scalingFunc)
	  newTargetY = scalingFunc(newTargetY,self);
	/* we head for the new target y */
	if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
	  _MKOrchTrace(self->orchestra,MK_TRACEDSP,
                "Setting target of UG%d_%s to %f",_instanceNumber,[NSStringFromClass([self class]) cString],
		       newTargetY);
	MKSetUGDatumArg(self,trg,_MKDoubleToFix24(newTargetY));
	if (arrivalStatus != MK_noEnvError || curPt == 1)
	  newCurrentAmp = newTargetY;
	else { /* Figure current amplitude */
	    double multiplier,deltaX,deltaY,exponent,newPreviousTargetY;
	    /* We have to rescale the previous point too to find out where
	       we are. *SIGH* */
	    _MKGetEnvelopeNth(anEnv,curPt-2,&dummy,&newPreviousTargetY,&dummy);
	    newPreviousTargetY *= yScaleVal; /* New scale */
	    newPreviousTargetY += yOffsetVal;/* New offset */
	    if (scalingFunc)
	      newPreviousTargetY = scalingFunc(newPreviousTargetY,self);
	    multiplier = 1-DSPFix24ToDouble(_rateValue);
	    deltaX = MKGetTime()-_startTimeThisSegment;
	    deltaY = newPreviousTargetY - newTargetY;
	    exponent = _samplingRate * deltaX;
	    newCurrentAmp = newTargetY + pow(multiplier,exponent) * deltaY;
	}
	if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
	  _MKOrchTrace(self->orchestra,MK_TRACEDSP,
                "Setting amp of UG%d_%s to %f",_instanceNumber,[NSStringFromClass([self class]) cString],
		       newCurrentAmp);
	MKSetUGDatumArgLong(self,amp,
			    DSPDoubleToFix48UseArg(newCurrentAmp,&aVal));
	_targetY = newTargetY;
    }
    return self;
}


-setReleaseXScale:(double)rXScaleVal
  /* Sets only an envelope's release X scaler */
{
    releaseTimeScale = rXScaleVal;
    return self;
}

-envelope
  /* Returns envelope or nil if none. */
{
    return anEnv;
}

#define NEXTPOINT() (*_msgPtr->_methodImp)(self,@selector(_nextPoint))
#define NEXTTIME _msgPtr->_timeOfMsg


-runSelf
  /* Invoked by -run. Starts the envelope on its way. If you send run
     twice, the envelope is triggered twice. However, note that idleSelf
     causes the envelope to be 'forgotten'. */
{
    double smoothVal;
    if (!anEnv)                    
      return self;
    curPt = 0;
    if (_msgPtr)
      _msgPtr = [_MKClassConductor() _cancelMsgRequest:_msgPtr];
    _msgPtr = [_MKClassConductor() _newMsgRequestAtTime:0.0
		   sel:@selector(_nextPoint) to:self argCount:0];
    arrivalStatus = MK_noEnvError;
    /* 1st pt */
    envelopeStatus =
      [anEnv getNth:curPt++ x:&targetX y:&_targetY smoothing:&smoothVal];
    /* Use method here since we need to validate envelope. The private
       C function alternative is streamlined to omit validation. */
    if (envelopeStatus == MK_noMorePoints) { /* Bad envelope */
	anEnv = nil;
	return self;
    }
    _tScale = timeScale;
    if (useInitialValue == YES) {           /* Blast in y0 optionally */
	DSPFix48 aVal;
	_targetY *= yScale;
	_targetY += yOffset;
	if (scalingFunc)
	  _targetY = scalingFunc(_targetY,self);
	if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
	  _MKOrchTrace(self->orchestra,MK_TRACEDSP,
                "Setting amp of UG%d_%s to %f",_instanceNumber,[NSStringFromClass([self class]) cString],_targetY);
	MKSetUGDatumArgLong(self,amp,DSPDoubleToFix48UseArg(_targetY,&aVal));
	switch (envelopeStatus) {
	    /* This is to check for a special case.
	       If the first point is a stick or last point, we need to
	       set the target. */
	  case MK_lastPoint:
//	    anEnv = nil; /* Added by DAJ (then removed by DAJ!) */
	  case MK_stickPoint:
            if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
	      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
                    "Setting target of UG%d_%s to %f",_instanceNumber,[NSStringFromClass([self class]) cString],
			   _targetY);
            MKSetUGDatumArg(self,trg,_MKDoubleToFix24(_targetY));
	  default:
	    break;
	}
    }
    NEXTPOINT();  /* Get next point and immediately head toward it */
    return self;
}

-idleSelf
  /* Resetting a Ramper sets the current value and sets envelope to nil. */
{
#   if 0
    DSPFix48 zeros = {0,0};
    if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
		   "Setting amp of UG%d_%s to 0 (idle).",_instanceNumber,[self name],;
    MKSetUGDatumArgLong(self,amp,&zeros); /* Leave ramper in a known state.
					   At this point, we have given
					   ourselves MKGetPreemptDuration() time
					   to get to our final value so,
					   most likely we are there. */
#   endif
    [self setAddressArgToSink:aout]; /* Patch output to sink. */
    anEnv = nil;
    arrivalStatus = MK_noMorePoints;		 
    if (_msgPtr)
      _msgPtr = [_MKClassConductor() _cancelMsgRequest:_msgPtr];
    return self;
}

-abortEnvelope
  /* Use to terminate an envelope before it has completed. */
{
    if (_msgPtr)
      _msgPtr =  [_MKClassConductor() _cancelMsgRequest:_msgPtr];
    anEnv = nil;
    return self;
}

-abortSelf
{
  return [self abortEnvelope];
}

-freeSelf
{
    if (_msgPtr)
      _msgPtr =  [_MKClassConductor() _cancelMsgRequest:_msgPtr];
    return self;
}

-setConstant:(double)aVal
  /* Abort any existing envelope and set both amp and target to the same value. */
{
    DSPFix48 aFix48;
    if (_msgPtr)
      _msgPtr =  [_MKClassConductor() _cancelMsgRequest:_msgPtr];
    anEnv = nil;
    DSPDoubleToFix48UseArg(aVal,&aFix48);
    if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
		   "Setting rate of UG%d_%s to 0, amp and target to %f.",_instanceNumber,
                   [NSStringFromClass([self class]) cString],aVal);
    MKSetUGDatumArg(self,rate,_rateValue = 0); /* fixes overflow bug in ug */
    MKSetUGDatumArgLong(self,amp,&aFix48);
    MKSetUGDatumArg(self,trg,_MKDoubleToFix24(aVal));
    return self;
}

-_nextPoint
  /* Private method which implements the next point in the envelope.
     We always read one point ahead. */
{
    double curX,scaledDeltaX,smoothVal,v;
    /* envelopeStatus is the status of point where we think we're arriving. */

    switch (envelopeStatus) { /* The point at which we think we're arriving.
			         I.e. we are interrupting the trajectory
				 toward this point. */
      case MK_stickPoint:
	arrivalStatus = MK_stickPoint;
	return self;      /* Don't schedule now. */
      case MK_lastPoint:  {
	  double preemptDur = MKGetPreemptDuration();
	  /* Make sure we get to last value. */
	  setT60(self,preemptDur);
	  NEXTTIME = preemptDur + MKGetTime();
	  /* In case we haven't yet received finish, we need to
	     do this so that finishSelf can tell how much time
	     to dealloc */
	  //	anEnv = nil; /* Added by DAJ , then removed by DAJ */
	  arrivalStatus = MK_lastPoint;
	  return self;  	/* Signal finishSelf and don't schedule. */
      }
      case MK_noEnvError:            
	break;                      /* Proceed to next point. */
      default:
	return nil; /* Error */
    }
    arrivalStatus = MK_noEnvError;
    curX = targetX;                 /* Envelope data is in absolute time. */
    /* Next pt */
    envelopeStatus = _MKGetEnvelopeNth(anEnv,curPt++,&targetX,&_targetY,
				       &smoothVal);
    if (envelopeStatus < 0)         /* Shouldn't normally happen. */
	return nil;
    if (curPt > 2) /* Don't do it on first call of _nextPoint */
      _MKBeginUGBlock(orchestra);
    _targetY *= yScale;
    _targetY += yOffset;
    /* Rate(n) is the time constant to go to the next point y(n). */
    if (MKIsNoDVal(_transitionTime))  /* Not in portamento */
      scaledDeltaX = (targetX - curX) * _tScale;
    else {                             /* Portamento. */
	scaledDeltaX = _transitionTime;
	_transitionTime = MK_NODVAL;
    }
    smoothVal *= scaledDeltaX;
    setRate(self,(smoothVal > MINSMOOTH) ? 1-exp(_smoothConstant/smoothVal) : MAXRATE);
//    setRate(self,(smoothVal > 0) ? 1-exp(_smoothConstant/smoothVal) : MAXRATE);
    if (scalingFunc)
      _targetY = scalingFunc(_targetY,self);
    /* we head for the new target y(n) */
    if (_MK_ORCHTRACE(orchestra,MK_TRACEDSP))
      _MKOrchTrace(self->orchestra,MK_TRACEDSP,
                   "Setting target of UG%d_%s to %f.",_instanceNumber,[NSStringFromClass([self class]) cString],_targetY);
    MKSetUGDatumArg(self,trg,_MKDoubleToFix24(_targetY));
    /* Schedule a _nextPoint message to self at time targetX. This is
       the time to interrupt the trajectory towards y(n) */
    _startTimeThisSegment = MKGetTime();
    NEXTTIME = _startTimeThisSegment + scaledDeltaX;
    [clockConductor _scheduleMsgRequest:_msgPtr];
    if (curPt > 2)
      _MKEndUGBlock();
    return self;
}


-(double)finishSelf
  /* This is sent to signal the beginning of the 'noteOff' portion. */
{
    /* If sticking, proceed. If not yet at stick point, head for point
       after stick pont. If no stick point, has no effect.
       Also returns time to end of envelope plus a little grace time to get
       to the final value. */
#   define DONTCARE 0.0
    int nPts,stickPoint;
    double dummy1,endSmooth,endX,dummy2,rtn;
    if (!anEnv || status == MK_idle || arrivalStatus == MK_noMorePoints)
      /*
       * If simply used as a ramper, we allow no grace period.
       * We check for MK_noMorePoints in case someone called setEnvelope:
       * and then sent finish.
       */
      return 0.0;
    if (arrivalStatus == MK_lastPoint) {
	rtn = NEXTTIME - MKGetTime();
	return MAX(0.0,rtn); /* If we already interrupted at what we think
				is the last point, we return what's left
				of the FINALDELAY, if any. */
    }
    if (arrivalStatus == MK_stickPoint) {
        double stickX = targetX;
	_tScale = releaseTimeScale;
	envelopeStatus = MK_noEnvError;
	NEXTPOINT();	 /* If we have already interrupted at what we think
			    is the stick point, we need to explicitly call
			    _nextPoint to get going again. */
	nPts = [anEnv pointCount];
	if (nPts == 0 ||
	    _MKGetEnvelopeNth(anEnv,nPts - 1,&endX,&dummy1,&endSmooth) < 0)
	    return 0;
	return (
		(endX - stickX) * releaseTimeScale
		/* the above is time from next update to end of env  */
		+ MKGetPreemptDuration()
		/* time for last point a chance to reach final val */
		);
    }

    /* If we made it here, there is a message scheduled to ourselves for the
       next time. */

    stickPoint = [anEnv stickPoint];
    if (stickPoint == MAXINT) { /* No stick point? */
	nPts = [anEnv pointCount];
	if (nPts == 0 ||
	    _MKGetEnvelopeNth(anEnv,nPts - 1,&endX,&dummy1,&endSmooth) < 0)
	    return 0;
	/* Figure the return value and just continue. */
	return (
		(endX - targetX) * timeScale
		/* the above is time from next update to end of env  */
		+ (NEXTTIME - MKGetTime())
		/* the above is time left in current seg */
		+ MKGetPreemptDuration()
		/* the above is time for last point to reach final val */
		);
    }


    /* If we made it here, we have a stick point and we are still not there
       yet. */
    _tScale = releaseTimeScale;

    /* First we make it look like we're at the stick point. */
    envelopeStatus = _MKGetEnvelopeNth(anEnv,stickPoint,&targetX,&dummy1,
				       &dummy2);
    curPt = stickPoint + 1;
    if (envelopeStatus != MK_lastPoint) /* Don't stop at stick point */
      envelopeStatus = MK_noEnvError;

    /* Figure return value */
    nPts = [anEnv pointCount];
    /* Cancel old msg. */
    if (_msgPtr)
	_msgPtr = [_MKClassConductor() _cancelMsgRequest:_msgPtr];
    if (envelopeStatus < 0 ||
	_MKGetEnvelopeNth(anEnv,nPts - 1,&endX,&dummy1,&endSmooth) < 0)
	return 0;
    /* Make a new one. */
    _msgPtr = [_MKClassConductor() _newMsgRequestAtTime:DONTCARE
		   sel:@selector(_nextPoint) to:self argCount:0];
    rtn = ((endX - targetX) * releaseTimeScale
	   /* the above is time from next update to end of env  */
	   + MKGetPreemptDuration()
	   /* the above is time for last point to reach final val */
	   );
    NEXTPOINT();
    return rtn;
}

@end
