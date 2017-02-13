#include "Fifo.h"

#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>
#import <Cocoa/Cocoa.h>

#define SZ_LONG		(sizeof(unsigned long))
#define SZ_CHAR		(sizeof(char))
#define SZ_HEAD		(sizeof(unsigned long) + sizeof(double))

CFifo::CFifo(void):
fFirst(NULL),
fLast(NULL),
fEnd(NULL),
fBegin(NULL),
fBuffer(NULL),
fBufferSize(0),
fCount(0),
fFull(0)
{
}

CFifo::~CFifo(void)
{
}

long CFifo::init( unsigned long bufferSize )
{
#if USE_BOOST
	boost::recursive_mutex::scoped_lock lock(fRMutexData);
#endif

#if USE_SDL
	CAutoLockSDLMutex lock(&fBaseSDLMutex);
#endif

	if (fBuffer != NULL)
	{
		return 0;
	}

	if (bufferSize == 0)
	{
		return 0;
	}

	fBufferSize = bufferSize;
	fBuffer = new char[fBufferSize];
	memset(fBuffer, 0, fBufferSize);

	fFirst = (char*)fBuffer;
	fLast = fFirst + fBufferSize;
	fBegin = fEnd = fFirst;
	fFull = 0;

	return fBufferSize;
}

void CFifo::free()
{
#if USE_BOOST
	boost::recursive_mutex::scoped_lock lock(fRMutexData);
#endif

#if USE_SDL
	CAutoLockSDLMutex lock(&fBaseSDLMutex);
#endif

	if (fBuffer == NULL)
	{
		return;
	}

	delete[] fBuffer;
	fBuffer = NULL;
	fBufferSize = 0;
	fCount = 0;

	fFirst = NULL;
	fLast = NULL;
	fEnd = NULL;
	fBegin = NULL;
}

unsigned long CFifo::max_size()
{
#if USE_BOOST
	boost::recursive_mutex::scoped_lock lock(fRMutexData);
#endif

#if USE_SDL
	CAutoLockSDLMutex lock(&fBaseSDLMutex);
#endif

	unsigned long s1, s2;

	if (fEnd >= fBegin) 
	{
		s1 = (unsigned long)(fLast - fEnd);
		s2 = (unsigned long)(fBegin - fFirst);

		return s1 >= s2?s1:s2;
	}
	else 
	{
		s1 = s2 = (unsigned long)(fBegin - fEnd);

		return s1;
	}
}


long CFifo::enqueue( void* buffer, unsigned long bufferSize, double userData )
{
#if USE_BOOST
	boost::recursive_mutex::scoped_lock lock(fRMutexData);
#endif

#if USE_SDL
	CAutoLockSDLMutex lock(&fBaseSDLMutex);
#endif

	long s1 = SZ_LONG;
	long s2 = sizeof(double);
	long s3 = SZ_HEAD;
    

	if (buffer == NULL)
	{
		return 0;
	}
	if (fFull == 1)
	{
		return 0;
	}

	if (max_size() < bufferSize + SZ_HEAD)
	{
		return 0;
	}

	unsigned long available;
	char *start;
	/* try to allocate from the end part of the fifo */
	if (fEnd >= fBegin) 
	{
		available = (unsigned long)(fLast - fEnd);
		if (available >= bufferSize + SZ_HEAD) 
		{
			char *ptr = fEnd;
			*(unsigned long*)ptr = bufferSize + SZ_HEAD;
			*(double*)(ptr + SZ_LONG) = userData;
			memcpy(ptr + SZ_HEAD, buffer, bufferSize);

#if 0
			char *buf = (char*)buffer;
			char msg[255] = {0};
			//sprintf(msg, "input data pt %f\r\n", time_2_dbl(pt));
			sprintf(msg, "enqueue data %d %d %d %d %d %d\r\n", buf[0], buf[1], buf[2], buf[3], buf[4], bufferSize);
			::OutputDebugString(msg);
#endif

			fEnd += (bufferSize + SZ_HEAD);
			if (fEnd == fLast)
				fEnd = fFirst;
			if (fEnd == fBegin)
				fFull = 1;

			fCount++;
            //NSLog(@"Enqueue %ld,%lu",fCount,bufferSize);
			return (long)bufferSize;
		}
		else
		{
            //没有足够空间了，修改结尾指针
			char *ptr = fEnd;
			if (fLast - ptr >= SZ_LONG)
			{
				*(unsigned long*)ptr = 0;
			}
			//fEnd = fFirst;
		}
	}

	/* try to allocate from the start part of the fifo */
	start = (fEnd < fBegin) ? fEnd : fFirst;
	available = (unsigned long)(fBegin - start);
	if (available >= bufferSize + SZ_HEAD) 
	{
		char *ptr = start;
		*(unsigned long*)ptr = bufferSize + SZ_HEAD;
		*(double*)(ptr + SZ_LONG) = userData;
		memcpy(ptr + SZ_HEAD, buffer, bufferSize);

#if 0
		char *buf = (char*)buffer;
		char msg[255] = {0};
		//sprintf(msg, "input data pt %f\r\n", time_2_dbl(pt));
		sprintf(msg, "E data %d %d %d %d %d %d\r\n", buf[0], buf[1], buf[2], buf[3], buf[4], bufferSize);
		::OutputDebugString(msg);
#endif

		fEnd = start + bufferSize + SZ_HEAD;

		if (fEnd == fBegin)
			fFull = 1;

		fCount++;
        //NSLog(@"Enqueue %ld,%lu",fCount,bufferSize);
		return bufferSize;
	}

	return 0;
}

long CFifo::dequeue( void *buffer, unsigned long bufferSize, double& userData )
{
#if USE_BOOST
	boost::recursive_mutex::scoped_lock lock(fRMutexData);
#endif

#if USE_SDL
	CAutoLockSDLMutex lock(&fBaseSDLMutex);
#endif
    
	if (buffer == NULL || bufferSize == 0)
	{
        
		return 0;
	}

	if (fBegin == fEnd && fFull == 0)
	{
        
		return 0;
	}

	if (fCount == 0)
	{
       
		return 0;
	}

	char *ptr = fBegin;
    
    if (!fBegin) {
        NSLog(@"Warning!!!!!!fBegin is NULL");
        return 0;
    }
	unsigned long size = *(unsigned long*)ptr;

    if (size == 0) {
        fBegin = fFirst;
        ptr = fBegin;
        size = *(unsigned long*)ptr;
    }
    
    
	if ( bufferSize < size - SZ_HEAD )
	{
        NSLog(@"Bug************************************************");
		return 0;
	}

	userData = *(double*)(ptr + SZ_LONG);
	memcpy(buffer, ptr + SZ_HEAD, size - SZ_HEAD);

#if 0
	char *buf = (char*)buffer;
	char msg[255] = {0};
	//sprintf(msg, "input data pt %f\r\n", time_2_dbl(pt));
	sprintf(msg, "dequeue data %d %d %d %d %d %d %f\r\n", buf[0], buf[1], buf[2], buf[3], buf[4], size - SZ_HEAD, userData);
	::OutputDebugString(msg);
#endif


	ptr += size;
	if (fLast - ptr < SZ_LONG)
	{
		ptr = fFirst;
		fBegin = ptr;
	}
	else if(*(unsigned long*)ptr == 0)
	{
		ptr = fFirst;
		fBegin = ptr;
//        if (fCount == 1) {
//            fEnd = fFirst;
//        }
	}
	else if (ptr == fLast - 1)
	{
		ptr = fFirst;
		fBegin = ptr;
	}
	else
	{
		fBegin = ptr;
	}

	fFull = 0;
	fCount--;
    
    if (fCount == 0) {
        //队列中没有元素了
        fBegin = fEnd;
    }
    //NSLog(@"Dequeue %ld,%lu",fCount,size - SZ_HEAD);
	return size - SZ_HEAD;
}

void CFifo::cleanUp()
{
#if USE_BOOST
	boost::recursive_mutex::scoped_lock lock(fRMutexData);
#endif

#if USE_SDL
	CAutoLockSDLMutex lock(&fBaseSDLMutex);
#endif

	memset(fBuffer, 0, fBufferSize);

	fFirst = (char*)fBuffer;
	fLast = fFirst + fBufferSize;
	fBegin = fEnd = fFirst;
	fFull = 0;
}

long CFifo::count()
{
#if USE_SDL
	CAutoLockSDLMutex lock(&fBaseSDLMutex);
#endif; 

#if USE_BOOST
	boost::recursive_mutex::scoped_lock lock(fRMutexData);
#endif

	return fCount; 
}

void CFifo::Count(long val) 
{ 	
#if USE_SDL
	CAutoLockSDLMutex lock(&fBaseSDLMutex); 
#endif;

#if USE_BOOST
	boost::recursive_mutex::scoped_lock lock(fRMutexData);
#endif

	fCount = val; 
}