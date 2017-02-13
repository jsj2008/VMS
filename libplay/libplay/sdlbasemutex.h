#include <SDL.h>

#ifndef __SDLBASEMUTEX_H__
#define __SDLBASEMUTEX_H__

#if 1
class CBaseSDLMutex
{
public:
	CBaseSDLMutex()
	{
		fMutex = SDL_CreateMutex();
	}
	~CBaseSDLMutex()
	{
		SDL_DestroyMutex(fMutex);
	}

	int lock()
	{
		return SDL_LockMutex(fMutex);
	}

	int unLock()
	{
		return SDL_UnlockMutex(fMutex);
	}
private:
	SDL_mutex	*fMutex;
};
#endif

#if 0
#include <windows.h>

class CBaseSDLMutex
{
public:
	CBaseSDLMutex()
	{
		::InitializeCriticalSection (&m_cs);
	}
	~CBaseSDLMutex()
	{
		::DeleteCriticalSection (&m_cs);
	}

	int lock()
	{
		::EnterCriticalSection (&m_cs);
		return 0;
	}

	int unLock()
	{
		::LeaveCriticalSection (&m_cs);
		return 0;
	}
private:
	CRITICAL_SECTION m_cs;
};
#endif

class CAutoLockSDLMutex
{
public:
	CAutoLockSDLMutex(CBaseSDLMutex *baseSDLMutex)
	{
		fBaseSDLMutex = baseSDLMutex;
		if (fBaseSDLMutex != NULL)		fBaseSDLMutex->lock();
	}
	~CAutoLockSDLMutex()
	{
		if (fBaseSDLMutex != NULL)		fBaseSDLMutex->unLock();
	}

private:
	CBaseSDLMutex *fBaseSDLMutex;
};


#endif