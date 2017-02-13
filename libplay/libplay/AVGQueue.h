#ifndef __AVG_QUEUE_H__
#define __AVG_QUEUE_H__

#include "sdlbasemutex.h"

// ��ֵ����
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
	double*		m_pData;	// ���ݶ���
	unsigned long		m_dwQueueCount;	// ��������
	unsigned long		m_dwCurPosition;	// ���е�ǰλ��
	
	double		m_dAllValue;	// ����������ֵ
	double		m_dAVGAll; // �������ݾ�ֵ
	unsigned long		m_dwAllCount; // ������������
	
	double		m_dQueueValue; // ����������ֵ
	double		m_dAVGQueue;	// �������ݾ�ֵ

	CBaseSDLMutex	fBaseSDLMutex;
};

#endif