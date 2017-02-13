#ifndef __PRECISION_TIME_H__
#define __PRECISION_TIME_H__

#include <SDL_timer.h>
#include "AVGQueue.h"

class CPrecisionTime
{
public:
	CPrecisionTime(void);
	~CPrecisionTime(void);

	void SetBaseTime();	// ���û�׼ʱ��
	double GetCurrentTimeInSec();	// ��õ�ǰʱ�� ��λ:�� second

	void Loop(double dSecTime);	// ѭ���ȴ�ָ����ʱ�� ��λ����
	void uSleep(double dSecTime); // ΢���ѭ���ȴ�ָ����ʱ�� ��λ���� ���� us
	void usWait(double dSecTime);
	bool IsSetBase();

	double GetSleepaccurate();

	double mSleep(double dSecTime); // ���뼶��Sleep
private:
	Uint64		m_freq;
	Uint64		m_counter;
	bool				m_bSetBase;

	double				m_dSleepaccurate;        //sleep�����,���0.02s

	CAVGQueue			m_AVGQSleep;
};

#endif