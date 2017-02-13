#pragma once
#include <windows.h>
// event
class CBaseEvent
{
public:

	// copy constructor
	CBaseEvent(const CBaseEvent& refEvent){m_hEvent = refEvent.m_hEvent;};

	// Construction/Destruction
	CBaseEvent(BOOL bManualReset = FALSE){m_hEvent = CreateEvent(NULL, bManualReset, FALSE, NULL);};
	~CBaseEvent(){if(m_hEvent != NULL)CloseHandle(m_hEvent);};

	// function
	BOOL Reset(){return ResetEvent(m_hEvent);};
	BOOL Set(){return SetEvent(m_hEvent);}

	BOOL Wait(DWORD dwTimeout = INFINITE) {return (WaitForSingleObject(m_hEvent, dwTimeout) == WAIT_OBJECT_0);}
	BOOL Check(){return Wait(0);};

	// operator
	operator HANDLE() const {return(m_hEvent);}
	CBaseEvent& operator =(CBaseEvent& refEvent){m_hEvent = refEvent.m_hEvent;}

protected:
	// data
	HANDLE m_hEvent;
};

class CMutilEvent
{
public:
	// Construction/Destruction
	CMutilEvent(const unsigned int iCount, BOOL bManualReset = FALSE){
		m_iCount = iCount;m_pEvent = new HANDLE[iCount]; 
		for(unsigned int i = 0; i < m_iCount; i++ ) m_pEvent[i] = CreateEvent(NULL, bManualReset, FALSE, NULL);}
	~CMutilEvent(){
		if(m_pEvent != NULL){ for(unsigned int i = 0; i < m_iCount; i++ ) CloseHandle(m_pEvent[i]);delete []m_pEvent;m_pEvent = NULL;} }

	// functions
	BOOL Set(const unsigned int iIndex){
		if( iIndex < m_iCount && m_pEvent != NULL )	return ::SetEvent (m_pEvent[iIndex]);
		return FALSE;}

	BOOL Reset (const unsigned int iIndex){
		if( iIndex < m_iCount && m_pEvent != NULL )	return ::ResetEvent (m_pEvent[iIndex]);
		return FALSE;}

	long Wait(BOOL bWaitAll, DWORD dwTimeout = INFINITE){ 
		return ::WaitForMultipleObjects (m_iCount, m_pEvent, bWaitAll, dwTimeout);}

	unsigned long GetCount(){return m_iCount;}

	// operator
	const HANDLE& operator[](const unsigned int iIndex){if( iIndex < m_iCount && m_pEvent != NULL )	return m_pEvent[iIndex];}

protected:
	// data
	unsigned int	m_iCount;
	HANDLE*			m_pEvent;
};


struct IBaseLock
{
	virtual void Lock() = 0;
	virtual void UnLock() = 0;
};

class CBaseCS:public IBaseLock
{
public:
	// Construction/Destruction
	CBaseCS(){::InitializeCriticalSection (&m_cs);}
	~CBaseCS(){::DeleteCriticalSection (&m_cs);}

	// functions
	void Lock(){::EnterCriticalSection (&m_cs);}
	void UnLock(){::LeaveCriticalSection (&m_cs);}

	// operators
	operator CRITICAL_SECTION( ) const {return m_cs;}

protected:
	// data
	CRITICAL_SECTION m_cs;
};

class CAutoLock
{
public:
	// Construction/Destruction
	CAutoLock(IBaseLock* pLock){m_pLock = pLock; if(m_pLock != NULL) pLock->Lock();}
	~CAutoLock(){if( m_pLock != NULL ) m_pLock->UnLock();}
protected:
	// data
	IBaseLock*	m_pLock;
};

