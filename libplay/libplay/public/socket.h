#pragma once

#include "syncobj.h"
#include "thread.h"



#define		DELETE_NULL(X)		{delete (x); x = NULL;}




#define FD_READ_BIT      0
#define FD_READ          (1 << FD_READ_BIT)

#define FD_WRITE_BIT     1
#define FD_WRITE         (1 << FD_WRITE_BIT)

#define FD_OOB_BIT       2
#define FD_OOB           (1 << FD_OOB_BIT)

#define FD_ACCEPT_BIT    3
#define FD_ACCEPT        (1 << FD_ACCEPT_BIT)

#define FD_CONNECT_BIT   4
#define FD_CONNECT       (1 << FD_CONNECT_BIT)

#define FD_CLOSE_BIT     5
#define FD_CLOSE         (1 << FD_CLOSE_BIT)

#define FD_QOS_BIT       6
#define FD_QOS           (1 << FD_QOS_BIT)

#define FD_GROUP_QOS_BIT 7
#define FD_GROUP_QOS     (1 << FD_GROUP_QOS_BIT)

#define FD_ROUTING_INTERFACE_CHANGE_BIT 8
#define FD_ROUTING_INTERFACE_CHANGE     (1 << FD_ROUTING_INTERFACE_CHANGE_BIT)

#define FD_ADDRESS_LIST_CHANGE_BIT 9
#define FD_ADDRESS_LIST_CHANGE     (1 << FD_ADDRESS_LIST_CHANGE_BIT)

#define FD_MAX_EVENTS    10
#define FD_ALL_EVENTS    ((1 << FD_MAX_EVENTS) - 1)



// socket
enum SOCKET_EVENT
{
	SOCKET_EVENT_NONE		= 0,
	SOCKET_EVENT_READ		= FD_READ ,		// 1
	SOCKET_EVENT_WRITE		= FD_WRITE ,	// 2
	SOCKET_EVENT_ACCEPT		= FD_ACCEPT ,	// 8
	SOCKET_EVENT_CONNECT	= FD_CONNECT ,	// 16
	SOCKET_EVENT_CLOSE		= FD_CLOSE 	// 32
};

enum SOCKET_STATUS
{
	SOCKET_STATUS_ERROR		= SOCKET_ERROR, // -1
	SOCKET_STATUS_OK		= 0
};

#define	SOCKET_BUFFER_DEFAULT_SIZE		8192
#define	SOCKET_BUFFER_MAX_SIZE			65535
#define	SOKCET_SELECT_WAIT_TIME			2		// second



class CSocketData
{
public:
	// Construction/Destruction
	CSocketData():m_lEvent(SOCKET_EVENT_READ|SOCKET_EVENT_CLOSE), m_iReadBufDataLen(0), m_hSocket(INVALID_SOCKET), m_lKey(0)
	{
	}
	~CSocketData()
	{
	}

	BOOL Create(const unsigned int uiReadBufLen = SOCKET_BUFFER_DEFAULT_SIZE)
	{
		m_iReadBufLen = uiReadBufLen;
		m_pReadBuf = new char[m_iReadBufLen];
		return TRUE;
	}

	BOOL Destroy()
	{
		delete[] m_pReadBuf;
		m_pReadBuf = NULL;
		m_hSocket = INVALID_SOCKET;
		m_iReadBufDataLen = 0;
		return TRUE;
	}

	// data
	SOCKET		m_hSocket;	// socket
	long		m_lKey;		// user key
	char*		m_pReadBuf;		// read buffer
	int			m_iReadBufLen;	// read buffer len
	int			m_iReadBufDataLen;	// read buffer data len
	long		m_lEvent;			// the socket event
};

struct ISocketCB	// socket callback
{
	virtual void SocketCBFun(CSocketData* pSocketData, long Type, long Error) = 0;
};


// Buffer
struct IBaseBuffer
{
	virtual long	Read(void* pbuf, unsigned int iMax) = 0;
	virtual long	Write(const void* pbuf, unsigned int iMax) = 0;
};

class CBuffer:public IBaseBuffer
{
public:
	// Construction/Destruction
	CBuffer(const unsigned long lLen = 8192):m_pBuffer(NULL), m_lDataLen(0)
	{
		m_pBuffer = new char[lLen];
		m_lLen = lLen;
	}

	~CBuffer()
	{
		if( m_lLen > 0 ) delete []m_pBuffer; 
		m_lLen = 0;
		m_pBuffer = NULL;
	}

	// functions
	long	Read(void* pbuf, unsigned int iMax)
	{
		CAutoLock Lock((IBaseLock*)&m_cs);
		long lSize = 0;
		if( iMax > m_lDataLen )
		{
			lSize = m_lDataLen;
			memcpy(pbuf, m_pBuffer, lSize);
			m_lDataLen = 0;
		}
		else
		{
			lSize = iMax;
			memcpy(pbuf, m_pBuffer, lSize);
			m_lDataLen -= lSize;
			char* tmp = new char[m_lLen];
			memcpy(tmp, m_pBuffer + lSize, m_lDataLen);
			memcpy(m_pBuffer, tmp, m_lDataLen);
			delete tmp;
			tmp = NULL;
		}
		
		return lSize;
	}

	long	Write(const void* pbuf, unsigned int iMax)
	{
		CAutoLock Lock((IBaseLock*)&m_cs);
		long lSize = iMax <= m_lLen - m_lDataLen?iMax:m_lLen - m_lDataLen;
		memcpy(m_pBuffer + m_lDataLen, pbuf, lSize);
		m_lDataLen += lSize;
		return lSize; 
	}

protected:
	// data
	char		*m_pBuffer;	// data
	long		m_lLen;		// count len
	long		m_lDataLen;	// the data len
	CBaseCS		m_cs;		// lock
};

// Socket
struct IBaseSocket
{
	virtual BOOL	Create() = 0;
	virtual long	Receive(char* buf, int len) = 0;
	virtual long	Send(const char* buf, const int len, const char* pDestIP, const unsigned short usDestPort) = 0;
	virtual BOOL	Close() = 0;
	virtual BOOL	Bind(const unsigned short Port, const char* pIP) = 0;
	virtual operator SOCKET() const = 0;
	virtual long	GetError() = 0;
};

// TCP Socket
class CTCPSocket:public IBaseSocket
{
public:
	// Construction/Destruction
	CTCPSocket():m_Socket(INVALID_SOCKET){}
	~CTCPSocket(){}
	
	// static
	static BOOL Startup()
	{
		WORD wVersionRequested;
		WSADATA wsaData;
		int iRet;
		wVersionRequested = MAKEWORD( 2, 2 );
		iRet = WSAStartup( wVersionRequested, &wsaData );
		if ( iRet != 0 ) return FALSE;
		else return TRUE;
	}
	
	static BOOL Cleanup()
	{
		return ( WSACleanup() == 0 )?TRUE:FALSE;
	}

	// overlapped
	BOOL Create()
	{ 
		if( IsExist() ) return FALSE; 
		// return (m_Socket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) == INVALID_SOCKET?FALSE:TRUE;
		m_Socket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
		if( m_Socket == INVALID_SOCKET )
		{
			int iRet = GetLastError();
			return FALSE;
		}
		else return TRUE;
	}

	BOOL Close(){BOOL bRet = closesocket(m_Socket) == SOCKET_ERROR?FALSE:TRUE; m_Socket = INVALID_SOCKET; return bRet;}
	BOOL Bind(const unsigned short Port, const char* pIP)
	{
		sockaddr_in addr;
		addr.sin_family = AF_INET;
		if( pIP == NULL ) addr.sin_addr.s_addr = htonl(INADDR_ANY);
		else addr.sin_addr.s_addr = inet_addr(pIP);
		addr.sin_port = htons(Port);
		return bind( m_Socket,(SOCKADDR*) &addr, sizeof(addr)) == SOCKET_ERROR?FALSE:TRUE;
	}
	long Send(const char* buf, const int len, const char* pDestIP = NULL, const unsigned short usDestPort = 0){return send(m_Socket, buf, len, 0);}
	long Receive(char* buf, int len){return recv(m_Socket, buf, len, 0);}
	long GetError(){return GetLastError();}

	// functions
	long	Select(int nfds, fd_set* readfds, fd_set* writefds, fd_set* exceptfds, const struct timeval* timeout){return ::select(nfds, readfds, writefds, exceptfds, timeout);}
	BOOL	Connect(const unsigned short Port, const char* pIP)
	{
		sockaddr_in addr;
		addr.sin_family = AF_INET;
		addr.sin_addr.s_addr = inet_addr(pIP);
		addr.sin_port = htons(Port);
		return connect( m_Socket,(SOCKADDR*) &addr, sizeof(addr)) == SOCKET_ERROR?FALSE:TRUE;
	}
	BOOL	Listen(const int backlog = 5){return listen(m_Socket, backlog) == SOCKET_ERROR?FALSE:TRUE;}
	SOCKET	Accept(struct sockaddr* addr = NULL, int* addrlen = NULL){return accept(m_Socket, addr, addrlen);}
	BOOL	IsExist(){return m_Socket == INVALID_SOCKET?FALSE:TRUE;}

	// operators
	operator SOCKET() const {return m_Socket;}
protected:
	// data
	SOCKET	m_Socket;
};

// Listen Socket
class CListenSocket:public CTCPSocket, public IThreadRun
{
public:
	// Construction/Destruction
	CListenSocket():m_pSocketCB(NULL){}
	~CListenSocket(){StopListen();}

	// start listen
	BOOL StartListen(const unsigned short Port, const char* pIP, ISocketCB* pCB, long Key = 0, const int backlog = 5)
	{
		BOOL bRet = FALSE;
		if( IsExist() || pCB == NULL ) return bRet;

		if( ( bRet = Create() ) )
		{
			if( ( bRet = Bind(Port, pIP) ) )
			{
				if( ( bRet = Listen(backlog) ) )
				{
					m_pSocketCB				= pCB;
					m_SocketData.m_hSocket 	= m_Socket;
					m_SocketData.m_lEvent	= SOCKET_EVENT_ACCEPT|SOCKET_EVENT_CLOSE;
					m_SocketData.m_lKey		= Key;

					// 启动线程
					m_SimpleThread .CreateEx (this);
				}
				else Close();
			}
			else Close();
		}

		return bRet;
	}

	// stop listen
	BOOL StopListen()
	{
		BOOL bRet = FALSE;
		if( IsExist() )
		{
			// 退出线程
			bRet = m_SimpleThread.Close ();
			bRet = Close();
		}
		return bRet;
	}
protected:
	// thread callback function
	DWORD Run(void *pParam, DWORD dwKey)
	{
		long lRet = -1;

		CAutoLock	Lock((IBaseLock*)&m_cs);

		fd_set fdread ;

		FD_ZERO( &fdread ) ;
		FD_SET(m_Socket, &fdread);
		timeval time_wait;
		time_wait.tv_sec = SOKCET_SELECT_WAIT_TIME;
		time_wait.tv_usec = 0;
		lRet = Select(0 , &fdread , NULL, NULL , &time_wait ) ;
		if( lRet > 0 ) 
		{
			// success
			SOCKET sock = Accept();
			if(m_pSocketCB != NULL)
			{
				m_SocketData.m_hSocket = sock;
				if( sock != INVALID_SOCKET )
					m_pSocketCB->SocketCBFun (&m_SocketData, SOCKET_EVENT_ACCEPT, SOCKET_STATUS_OK);
				else m_pSocketCB->SocketCBFun (&m_SocketData, SOCKET_EVENT_ACCEPT, GetError());
			}
		}
		else if( lRet == 0 )
		{
			// time out
			// TRACE(_T("listen thread time out\n"));
		}
		else 
		{
			// error
			if( m_pSocketCB != NULL )
			{
				// StopListen();
				m_pSocketCB->SocketCBFun(&m_SocketData, SOCKET_EVENT_NONE, GetError());
			}
		}

		return lRet;
	}


	// data
	CSimpleThread					m_SimpleThread;
	CBaseCS							m_cs;
	ISocketCB*						m_pSocketCB;
	CSocketData						m_SocketData;
};


// Client TCP Socket
class CSimpleTCPSocket:public CTCPSocket, public IThreadRun
{
public:
	// Construction/Destruction
	CSimpleTCPSocket():m_pSocketCB(NULL),m_pSocketData(NULL){}
	~CSimpleTCPSocket(){Disconnect();}

	// functions
	BOOL Attach(CSocketData* pSocketData, ISocketCB* pCB = NULL)
	{
		BOOL bRet = FALSE;
		if( !IsExist() ) 
		{
			if( pSocketData != NULL )
				if( pSocketData->m_hSocket != INVALID_SOCKET)
				{
					m_Socket = pSocketData->m_hSocket;
					if( pCB != NULL )
					{
						m_pSocketCB	= pCB;
						m_pSocketData = pSocketData;
						bRet = TRUE;
						bRet = m_SimpleThread .CreateEx(this);
						if( !bRet )
						{
							m_Socket = INVALID_SOCKET;
							m_pSocketCB = NULL;
						}
					}
				}
		}
		return bRet;
	}

	// connect
	BOOL ConnectServer(const unsigned short Port, const char* pIP, CSocketData* pSocketData, ISocketCB* pCB = NULL)
	{
		BOOL bRet = FALSE;
		if( !IsExist() )
		{
			if( bRet = Create() )
			{
				if( bRet = Connect(Port, pIP) )
				{
					if( pSocketData != NULL )
					{
						m_pSocketData = pSocketData;
						m_pSocketData->m_hSocket = m_Socket;
						// 启动线程
						if( pCB != NULL )
						{
							m_pSocketCB	= pCB;
							m_SimpleThread .CreateEx(this);
						}
					}
				}
				else Close();
			}
		}
		return bRet;
	}

	// disconnect
	BOOL Disconnect()
	{
		BOOL bRet = FALSE;
		if( IsExist() )
		{
			bRet = m_SimpleThread.Exit();
			bRet = Close();
			// delete m_pSocketData;
		}
		return bRet;
	}

protected:
	// data
	ISocketCB*							m_pSocketCB;
	CBaseCS								m_cs;
	CSimpleThread						m_SimpleThread;
	CSocketData*						m_pSocketData;

	// thread callback fucntion
	DWORD Run(void *pParam, DWORD dwKey)
	{
		long lRet = -1;

	
		CAutoLock	Lock((IBaseLock*)&m_cs);

		if( m_pSocketData == NULL || m_pSocketCB == NULL ) return lRet;

		// event
		fd_set	fdread ;
		fd_set	fdwrite;
		FD_ZERO( &fdread ) ;
		FD_ZERO( &fdwrite ) ;
		if( m_pSocketData->m_lEvent & SOCKET_EVENT_READ )
			FD_SET(m_Socket, &fdread);
		if( m_pSocketData->m_lEvent & SOCKET_EVENT_WRITE )
			FD_SET(m_Socket, &fdwrite);

		timeval time_wait;
		time_wait.tv_sec = SOKCET_SELECT_WAIT_TIME;
		time_wait.tv_usec = 0;

		lRet = Select(0 , &fdread , &fdwrite, NULL , &time_wait ) ;
		if( lRet > 0 ) 
		{
			if( FD_ISSET(m_Socket, &fdread) )
			{
				// success
				lRet = Receive(m_pSocketData->m_pReadBuf + m_pSocketData->m_iReadBufDataLen, m_pSocketData->m_iReadBufLen - m_pSocketData->m_iReadBufDataLen);
				if( lRet > 0 )
				{
					// recv success
					m_pSocketData->m_iReadBufDataLen += lRet;
					m_pSocketCB->SocketCBFun (m_pSocketData, SOCKET_EVENT_READ, SOCKET_STATUS_OK);
				}
				else if( lRet == 0 )
				{
					// socket close
					m_pSocketCB->SocketCBFun (m_pSocketData, SOCKET_EVENT_CLOSE, GetError());
				}
				else 
				{
					// error
					m_pSocketCB->SocketCBFun (m_pSocketData, SOCKET_EVENT_READ, GetError());
				}
			}
			if( FD_ISSET(m_Socket, &fdwrite) )
			{
				m_pSocketCB->SocketCBFun (m_pSocketData, SOCKET_EVENT_WRITE, 0);
			}
		}
		else if( lRet == 0 )
		{
			// time out
			// TRACE(_T("listen thread time out\n"));
		}
		else 
		{
			// error
			m_pSocketCB->SocketCBFun(m_pSocketData, SOCKET_EVENT_NONE, GetError());
		}
	
		return lRet;
	}
};

class CTCPSocketManage:public IThreadRun
{
public:

	typedef std::map<SOCKET, CSocketData*>	CSocketDataMap;

	// Construction/Destruction
	CTCPSocketManage():m_pSocketCB(NULL){}
	~CTCPSocketManage(){Uninit();}

	// init
	BOOL	Init(ISocketCB* pSocketCB)
	{
		BOOL bRet = FALSE;
		if( pSocketCB != NULL )
		{
			m_pSocketCB = pSocketCB;
			// start thread 
			m_SimpleThread.SetTimeout (10);
			bRet = m_SimpleThread .CreateEx (this);
		}
		return bRet;
	}
	void	Uninit()
	{
		CAutoLock lock(&m_cs);

		// exit thread
		m_SimpleThread .Close ();
		m_pSocketCB = NULL;
		// delete socketdata map
		for (CSocketDataMap::iterator itr = m_SocketDataMap.begin(); itr != m_SocketDataMap.end(); ++itr)
		{
			CSocketData* pSocketData = itr->second;
			closesocket(pSocketData->m_hSocket);
			delete pSocketData;
			pSocketData = NULL;
		}
		m_SocketDataMap.clear ();
	}

	// functions

	// attach
	BOOL	Attach(CSocketData* pSocketData)
	{

		BOOL bRet = FALSE;
		if( pSocketData != NULL )
		{
			{
				CAutoLock lock(&m_cs);
				m_SocketDataMap.insert (std::make_pair(pSocketData->m_hSocket, pSocketData));
			}
			bRet = TRUE;
		}
		return bRet;
	}
	// send data
	long	Send(SOCKET hSocket, char* pbuf, int ibuflen)
	{
		CAutoLock lock(&m_cs);
		long lRet = -1;
		CSocketData* pSocketData = m_SocketDataMap[hSocket];
		if( pSocketData != NULL )
		{
			lRet = send(pSocketData->m_hSocket, pbuf, ibuflen, 0);
		}
		return lRet;
	}
	// receive data
	long	Receive(SOCKET hSocket, char* pbuf, int ibuflen)
	{
		CAutoLock lock(&m_cs);
		long lRet = -1;
		CSocketData* pSocketData = m_SocketDataMap[hSocket];
		if( pSocketData != NULL )
		{
			if( ibuflen >= pSocketData->m_iReadBufDataLen )
			{
				memcpy(pbuf, pSocketData->m_pReadBuf, pSocketData->m_iReadBufDataLen);
				lRet = pSocketData->m_iReadBufDataLen;
				pSocketData->m_iReadBufDataLen = 0;
			}
			else
			{
				memcpy(pbuf, pSocketData->m_pReadBuf, ibuflen);
				lRet = ibuflen;
				char* tmp = new char[pSocketData->m_iReadBufLen];
				memcpy(tmp, pSocketData->m_pReadBuf + ibuflen, pSocketData->m_iReadBufDataLen - ibuflen);
				memcpy(pSocketData->m_pReadBuf, tmp, pSocketData->m_iReadBufDataLen - ibuflen);
				pSocketData->m_iReadBufDataLen -= ibuflen;
				delete tmp;tmp = NULL;
			}
		}
		return lRet;
	}
	// close socket
	BOOL	Close(SOCKET hSocket)
	{
		CAutoLock lock(&m_cs);

		BOOL bRet = FALSE;
		
		CSocketData* pSocketData = m_SocketDataMap[hSocket];
		if( pSocketData != NULL )
		{
			pSocketData->m_lEvent = SOCKET_EVENT_NONE;
			closesocket(pSocketData->m_hSocket);
			pSocketData->m_hSocket = INVALID_SOCKET;
		}
		return bRet;
	}

	const CSocketData* GetSocketData(SOCKET hSocket)
	{
		CAutoLock lock(&m_cs);
		return m_SocketDataMap[hSocket];
	}
protected:
	// the thread callback
	DWORD	Run(void *pParam, DWORD dwKey)
	{
		CAutoLock	Lock((IBaseLock*)&m_cs);

		long lRet = -1;

		if( m_pSocketCB == NULL ) return lRet;
		
		// event
		fd_set	fdread ;
		fd_set	fdwrite;
		FD_ZERO( &fdread ) ;
		FD_ZERO( &fdwrite ) ;

		for (CSocketDataMap::iterator itr = m_SocketDataMap.begin(); itr != m_SocketDataMap.end(); ++itr)
		{
			CSocketData* pSocketData = itr->second;

			if( pSocketData->m_hSocket == INVALID_SOCKET )
			{
				delete pSocketData;pSocketData = NULL;
				itr = m_SocketDataMap.erase (itr);
				continue;
			}
			
			if( pSocketData->m_lEvent & SOCKET_EVENT_READ )
				FD_SET(pSocketData->m_hSocket, &fdread);
			if( pSocketData->m_lEvent & SOCKET_EVENT_WRITE )
				FD_SET(pSocketData->m_hSocket, &fdwrite);

			timeval time_wait;
			time_wait.tv_sec = 0;
			time_wait.tv_usec = 0;
			lRet = select(0 , &fdread , &fdwrite, NULL , &time_wait ) ;
			if( lRet > 0 ) 
			{
				if( FD_ISSET(pSocketData->m_hSocket, &fdread) )
				{
					// success
					lRet = recv(pSocketData->m_hSocket, pSocketData->m_pReadBuf + pSocketData->m_iReadBufDataLen, pSocketData->m_iReadBufLen - pSocketData->m_iReadBufDataLen, 0);
					if( lRet > 0 )
					{
						// recv success
						pSocketData->m_iReadBufDataLen += lRet;
						m_pSocketCB->SocketCBFun (pSocketData, SOCKET_EVENT_READ, SOCKET_STATUS_OK);
					}
					else if( lRet == 0 )
					{
						// socket close
						m_pSocketCB->SocketCBFun (pSocketData, SOCKET_EVENT_CLOSE, WSAGetLastError());
					}
					else 
					{
						// error
						m_pSocketCB->SocketCBFun (pSocketData, SOCKET_EVENT_READ, WSAGetLastError());
					}
				}
				if( FD_ISSET(pSocketData->m_hSocket, &fdwrite) )
				{
					m_pSocketCB->SocketCBFun (pSocketData, SOCKET_EVENT_WRITE, 0);
				}
			}
			else if( lRet == 0 )
			{
				// time out
				// TRACE(_T("listen thread time out\n"));
			}
			else 
			{
				// error
				m_pSocketCB->SocketCBFun(pSocketData, SOCKET_EVENT_NONE, WSAGetLastError());
			}
		}
		return lRet;
	}

	// data
	CBaseCS							m_cs;
	CSimpleThread					m_SimpleThread;
	ISocketCB*						m_pSocketCB;
	CSocketDataMap					m_SocketDataMap;
};


class CUDPSocket:public IBaseSocket
{
public:
	// // Construction/Destruction
	CUDPSocket():m_Socket(INVALID_SOCKET){}
	~CUDPSocket(){}

	// overlapped
	BOOL	Create(){if( IsExist() ) return FALSE; return (m_Socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == INVALID_SOCKET?FALSE:TRUE;}
	long	Receive(char* buf, int len){return recvfrom(m_Socket, buf, len, 0, NULL, NULL);}
	long	Send(const char* buf, const int len, const char* pDestIP, const unsigned short usDestPort)
	{
		sockaddr_in addr;
		addr.sin_family = AF_INET;
		addr.sin_addr.s_addr = inet_addr(pDestIP);
		addr.sin_port = htons(usDestPort);
		return sendto(m_Socket, buf, len, 0,(SOCKADDR*) &addr, sizeof(addr)); 
	}
	BOOL	Close(){BOOL bRet = closesocket(m_Socket) == SOCKET_ERROR?FALSE:TRUE; m_Socket = INVALID_SOCKET; return bRet;}
	BOOL	Bind(const unsigned short Port, const char* pIP)
	{
		sockaddr_in addr;
		addr.sin_family = AF_INET;
		if( pIP == NULL ) addr.sin_addr.s_addr = htonl(INADDR_ANY);
		else addr.sin_addr.s_addr = inet_addr(pIP);
		addr.sin_port = htons(Port);
		return bind( m_Socket,(SOCKADDR*) &addr, sizeof(addr)) == SOCKET_ERROR?FALSE:TRUE;
	}

	BOOL	Setsockopt(int level, int optname, const char FAR* optval, int optlen)
	{
		return setsockopt(m_Socket, level, optname, optval, optlen) == SOCKET_ERROR?FALSE:TRUE;
	}

	long	GetError(){return WSAGetLastError();}

	// functions
	long	Select(int nfds, fd_set* readfds, fd_set* writefds, fd_set* exceptfds, const struct timeval* timeout){return ::select(nfds, readfds, writefds, exceptfds, timeout);}
	BOOL	IsExist(){return m_Socket == INVALID_SOCKET?FALSE:TRUE;}
	// operator
	operator SOCKET() const{ return m_Socket;}

protected:
	// data
	SOCKET m_Socket;
};

class CSimpleUDPSocket:public CUDPSocket, public IThreadRun
{
public:
	CSimpleUDPSocket(){}
	~CSimpleUDPSocket(){}

	BOOL Start(const unsigned short Port, const char* pIP, CSocketData* pSocketData, ISocketCB* pCB = NULL)
	{
		BOOL bRet = FALSE;

		if( bRet = Create() )
		{
			if( bRet = Bind(Port, pIP) )
			{
				m_pSocketData = pSocketData;
				if( pCB != NULL )
				{
					m_pSocketCB = pCB;
					m_SimpleThread .CreateEx (this);
				}
			}
			else Close();
		}

		return bRet;
	}

	BOOL Stop()
	{
		BOOL bRet = FALSE;
		if( IsExist() )
		{
			bRet = m_SimpleThread.Close ();
			bRet = Close();
			// delete m_pSocketData;
		}
		return bRet;
	}

private:
	// data
	ISocketCB*							m_pSocketCB;
	CBaseCS								m_cs;
	CSimpleThread						m_SimpleThread;
	CSocketData*						m_pSocketData;

	// thread callback fucntion
	DWORD Run(void *pParam, DWORD dwKey)
	{
		long lRet = -1;
	
		CAutoLock	Lock((IBaseLock*)&m_cs);

		if( m_pSocketData == NULL || m_pSocketCB == NULL ) return lRet;

		// event
		fd_set	fdread ;
		fd_set	fdwrite;
		FD_ZERO( &fdread ) ;
		FD_ZERO( &fdwrite ) ;
		if( m_pSocketData->m_lEvent & SOCKET_EVENT_READ )
			FD_SET(m_Socket, &fdread);
		if( m_pSocketData->m_lEvent & SOCKET_EVENT_WRITE )
			FD_SET(m_Socket, &fdwrite);

		timeval time_wait;
		time_wait.tv_sec = SOKCET_SELECT_WAIT_TIME;
		time_wait.tv_usec = 0;
		lRet = Select(0 , &fdread , &fdwrite, NULL , &time_wait ) ;
		if( lRet > 0 ) 
		{
			if( FD_ISSET(m_Socket, &fdread) )
			{
				// success
				lRet = Receive(m_pSocketData->m_pReadBuf + m_pSocketData->m_iReadBufDataLen, m_pSocketData->m_iReadBufLen - m_pSocketData->m_iReadBufDataLen);
				if( lRet > 0 )
				{
					// recv success
					m_pSocketData->m_iReadBufDataLen += lRet;
					m_pSocketCB->SocketCBFun (m_pSocketData, SOCKET_EVENT_READ, SOCKET_STATUS_OK);
				}
				else if( lRet == 0 )
				{
					// socket close
					m_pSocketCB->SocketCBFun (m_pSocketData, SOCKET_EVENT_CLOSE, GetError());
				}
				else 
				{
					// error
					m_pSocketCB->SocketCBFun (m_pSocketData, SOCKET_EVENT_READ, GetError());
				}
			}
			if( FD_ISSET(m_Socket, &fdwrite) )
			{
				m_pSocketCB->SocketCBFun (m_pSocketData, SOCKET_EVENT_WRITE, 0);
			}
		}
		else if( lRet == 0 )
		{
			// time out
			// TRACE(_T("listen thread time out\n"));
		}
		else 
		{
			// error
			m_pSocketCB->SocketCBFun(m_pSocketData, SOCKET_EVENT_NONE, GetError());
		}
	
		return lRet;
	}
};

//
//
//class CMutilSocket
//{
//
//};
//
//typedef struct _SOCKET_DATAT
//{
//	CBaseSocket*	BaseSocket;
//	char*			Buffer;
//	long			BufferLen;
//	long			UserKey;
//	long			LastHeartTime;
//
//}SOCKET_DATAT, *PSOCKET_DATAT;
//
//typedef struct _SOCKET_GROUP
//{
//
//}SOCKET_GROUP, *PSOCKET_GROUP;
