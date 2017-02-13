#include "AVGQueue.h"


CAVGQueue::CAVGQueue(unsigned long dwQueueCount):m_pData(NULL),
m_dwQueueCount(25),
m_dwCurPosition(0),
m_dAllValue(0),
m_dAVGAll(0.0),
m_dwAllCount(0),
m_dAVGQueue(0.0),
m_dQueueValue(0)
{
	SetQueueCount(dwQueueCount);
}

CAVGQueue::~CAVGQueue(void)
{
	Release();
}

int	CAVGQueue::En_Queue(double dData)
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	if (m_pData == NULL)
	{
		return 0;
	}

	int iRet = 0;

	// save data
	double dOld = m_pData[m_dwCurPosition];
	m_pData[m_dwCurPosition] = dData;

	// 总值平均
	m_dwAllCount++;
	m_dAllValue += dData;
	m_dAVGAll = (double)m_dAllValue/(double)m_dwAllCount;

	// 队列平均数
	m_dQueueValue += dData;
	unsigned long dwQueueCount = m_dwCurPosition + 1;

	if(m_dwAllCount > m_dwQueueCount)
	{
		m_dQueueValue -= dOld;
		dwQueueCount = m_dwQueueCount;
	}
	m_dAVGQueue = (double)m_dQueueValue/(double)dwQueueCount;

	m_dwCurPosition++;
	if(m_dwCurPosition >= m_dwQueueCount) m_dwCurPosition -= m_dwQueueCount;

	return iRet;
}

double	CAVGQueue::GetAVGQ()
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	return m_dAVGQueue;
}

double CAVGQueue::GetAVGAll()
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	return m_dAVGAll;
}

void CAVGQueue::SetQueueCount(int iCount)
{
	if(iCount <= 0) return;

	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	Release();

	if(m_pData == NULL)
	{
		m_dwQueueCount = iCount;
		m_pData = new double[m_dwQueueCount];
		memset(m_pData, 0, m_dwQueueCount);
	}
}

void CAVGQueue::Release()
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	if(m_pData != NULL)
	{
		delete[] m_pData;
		m_pData = NULL;
	}
	m_dwQueueCount = 0;
	m_dwCurPosition = 0;
	m_dAVGAll = 0;
	m_dAllValue = 0;
	m_dwAllCount = 0;
	m_dAVGQueue = 0;
	m_dQueueValue = 0;
}
