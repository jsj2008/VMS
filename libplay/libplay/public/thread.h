#pragma once
#include "syncobj.h"
#include <map>
#include <vector>
enum _THREAD_STATUS
{
	THREAD_STATUS_IDLE = 0,		// ¿ÕÏÐ
	THREAD_STATUS_
};

struct IThreadRun
{
	virtual DWORD Run(void *pParam, DWORD dwKey) = 0;
};

// thread
class CBaseThread:public IThreadRun
{
public:
	// Construction/Destruction
	CBaseThread():m_hThread(NULL), m_dwKey(0), m_pParam(NULL){}
	virtual ~CBaseThread(){Wait();}

    static DWORD WINAPI AccessThreadProc(LPVOID pParam)
	{
		DWORD dwRet = -1;
		HRESULT hrCoInit = CBaseThread::CoInitializeHelper();
		if(SUCCEEDED(hrCoInit)) 
		{
			CBaseThread * pThread = (CBaseThread *) pParam;
			dwRet = pThread->ThreadProc();
		}
		if(SUCCEEDED(hrCoInit)) {
			CoUninitialize();
		}

		return dwRet;
	}

	static HRESULT CoInitializeHelper()
	{
		// call CoInitializeEx and tell OLE not to create a window (this
		// thread probably won't dispatch messages and will hang on
		// broadcast msgs o/w).
		//
		// If CoInitEx is not available, threads that don't call CoCreate
		// aren't affected. Threads that do will have to handle the
		// failure. Perhaps we should fall back to CoInitialize and risk
		// hanging?
		//

		// older versions of ole32.dll don't have CoInitializeEx

		HRESULT hr = E_FAIL;
		HINSTANCE hOle = GetModuleHandle(TEXT("ole32.dll"));
		if(hOle)
		{
			typedef HRESULT (STDAPICALLTYPE *PCoInitializeEx)(
				LPVOID pvReserved, DWORD dwCoInit);
			PCoInitializeEx pCoInitializeEx =
				(PCoInitializeEx)(GetProcAddress(hOle, "CoInitializeEx"));
			if(pCoInitializeEx)
			{
				hr = (*pCoInitializeEx)(0, COINIT_DISABLE_OLE1DDE );
			}
		}
		else
		{
			// caller must load ole32.dll
			// DbgBreak("couldn't locate ole32.dll");
		}

		return hr;
	}

	// init
	BOOL	Create(void* pParam, DWORD dwKey = 0)
	{
		if( IsExist() ) return FALSE;
		m_dwKey = dwKey;
		m_pParam = pParam;
		m_hThread = CreateThread (NULL, 0, CBaseThread::AccessThreadProc, this, 0, NULL);
		return m_hThread == NULL?FALSE:TRUE;
	}

	// wait
	BOOL	Wait(DWORD dwTimeout = INFINITE)
	{
		BOOL bRet = FALSE;
		if( IsExist() )
		{
			WaitForSingleObject (m_hThread, dwTimeout);
			CloseHandle(m_hThread); 
			m_hThread = NULL;
			bRet = TRUE;
		}
		return bRet;
	}

	// Thread Exist
	BOOL	IsExist(){ return (m_hThread != NULL);}

	// operator
	operator HANDLE() const {return m_hThread;}
protected:
	// data
	HANDLE m_hThread;
	void*	m_pParam;
	DWORD	m_dwKey;
	// the thread run function
	DWORD ThreadProc()
	{
		return Run(m_pParam, m_dwKey);
	}
};


class CSimpleThread: public CBaseThread
{
public:
	// the thread run callback function
	// typedef DWORD (T::*ThreadCB)(void* pParma, DWORD dwKey);
	
	// Construction/Destruction
	CSimpleThread():m_pThreadRun(NULL), m_dwTimeOut(0){}
	~CSimpleThread(){Close();}

	// init
	BOOL CreateEx(IThreadRun* pThreadRun, void* pParam = NULL, DWORD dwKey = 0)
	{
		BOOL bRet = FALSE;
		if( pThreadRun == NULL ) return bRet;
		if( IsExist() ) return bRet;

		m_pThreadRun	= pThreadRun;
		if( !( bRet = Create(pParam, dwKey) ) )
		{
			m_pThreadRun= NULL;
			m_hThread	= NULL;
		}

		return bRet;
	}

	// exit
	BOOL	Exit(){return m_hEvent.Set();}
	// close
	BOOL	Close(DWORD dwTimeout = INFINITE){Exit(); return CBaseThread::Wait ();}

	void	SetTimeout(DWORD dwMillSecond){m_dwTimeOut = dwMillSecond;}
	DWORD	GetTimeout(){return m_dwTimeOut;}


protected:
	// the thread run function
	DWORD Run(void* pParam, DWORD dwKey)
	{
		DWORD dwRet = 0;
		while(!m_hEvent.Wait (m_dwTimeOut))
		{
			if( m_pThreadRun != NULL )
				dwRet = m_pThreadRun->Run(pParam, dwKey);
		}

		return dwRet;
	}

	// data
	IThreadRun*		m_pThreadRun;
	CBaseEvent		m_hEvent;
	DWORD			m_dwTimeOut;	// millsecond
};

// Ïß³Ì³Ø
class CThreadPool
{
public:
	// Construction/Destruction
	CThreadPool(){}
	~CThreadPool(){}

	// Init
	BOOL	Init(int iSize);
	// Release
	void	Release();

	// Request
	BOOL	Request(IThreadRun* pThreadRun, void* pParam = NULL, DWORD dwKey = 0);

	// Call this method to get the number of threads in the pool.
	int		GetBusyThreadSize(int* pSize);
	// Set All Threads size
	int		SetSize(int iSize);
	// All Thread Size
	int		GetSize(int* pSize);
					
protected:
	// data
	std::vector<CSimpleThread*>		m_ThreadList;			// All thread list
	std::vector<CSimpleThread*>		m_BusyThreadList;		// Thread List
	std::vector<CSimpleThread*>		m_IdleThreadList;		// Idle List
	int			m_iAllThreadSize;
	int			m_iBusyThreadSize;
	int			m_iIdleThreadSize;

	CBaseCS		m_ThreadCS;
	CBaseCS		m_BusyThreadCS;
	CBaseCS		m_IdleThreadCS;
};
