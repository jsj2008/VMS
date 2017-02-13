#ifndef __AVG_QUEUE_H__
#define __AVG_QUEUE_H__

#include "sdlbasemutex.h"

// 均值队列
class CAVGQueue
{
public:
	CAVGQueue(unsigned long dwQueueCount = 25);
	~CAVGQueue(void);

	int	En_Queue(double dData);
	double	GetAVGQ();
	double GetAVGAll();
	void	SetQueueCount(int iCount);
private:
	void	Release();
private:
	double*		m_pData;	// 数据队列
	unsigned long		m_dwQueueCount;	// 队列总数
	unsigned long		m_dwCurPosition;	// 队列当前位置
	
	double		m_dAllValue;	// 所有数据总值
	double		m_dAVGAll; // 所有数据均值
	unsigned long		m_dwAllCount; // 所有数据总数
	
	double		m_dQueueValue; // 队列数据总值
	double		m_dAVGQueue;	// 队列数据均值

	CBaseSDLMutex	fBaseSDLMutex;
};

#endif