// Allpass filter declaration
//
// Written by Jezar at Dreampoint, June 2000
// http://www.dreampoint.co.uk
// This code is public domain

#ifndef _allpass_
#define _allpass_
#include "denormals.h"

class sndreverb_allpass
{
public:
				sndreverb_allpass();
	void	setbuffer(float *buf, int size);
	inline  float	process(float inp);
	void	processBufferReplacing(float *input, float *output, long bufferLength, int skip);
	void	mute();
	void	setfeedback(float val);
	float	getfeedback();
  
// private:
	float	 feedback;
	float	*buffer;
	int		 bufsize;
	int		 bufidx;
};


// Big to inline - but crucial for speed

inline float sndreverb_allpass::process(float input)
{
	float output;
	float bufout;
	
	bufout = buffer[bufidx];
	undenormalise(bufout);
	
	output = -input + bufout;
	buffer[bufidx] = input + (bufout*feedback);

	if(++bufidx>=bufsize) bufidx = 0;

	return output;
}

#endif//_allpass

//ends
