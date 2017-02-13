#ifndef __FIFO_H__
#define __FIFO_H__



#define USE_SDL			1
#define USE_BOOST		0

#if USE_SDL
#include "sdlbasemutex.h"
#endif

#if USE_BOOST
#include <boost/thread/recursive_mutex.hpp>
#endif

class CFifo
{
public:
	CFifo(void);
	~CFifo(void);

	long			init (unsigned long bufferSize);
	unsigned long	max_size ();
	long			enqueue(void* buffer, unsigned long size, double userData);
	long			dequeue (void *buffer, unsigned long size, double& userData);
	void			free ();
	void			cleanUp();

	long			count() ;

private:
	void			Count(long val) ;

private:
	char *fFirst, *fLast;
	char *fBegin, *fEnd;
	long fFull;
	long fCount;

	char *fBuffer;
	unsigned long fBufferSize;

#if USE_BOOST
	boost::recursive_mutex fRMutexData;
#endif

#if USE_SDL
	CBaseSDLMutex	fBaseSDLMutex;
#endif
};

#endif