#ifndef __PRECISION_TIME_H__
#define __PRECISION_TIME_H__

#include <SDL_timer.h>
#include "AVGQueue.h"

class CPrecisionTime
{
public:
	CPrecisionTime(void);
	~CPrecisionTime(void);

	void SetBaseTime();	// 设置基准时间
	double GetCurrentTimeInSec();	// 获得当前时间 单位:秒 second

	void Loop(double dSecTime);	// 循环等待指定的时间 单位：秒
	void uSleep(double dSecTime); // 微妙级别循环等待指定的时间 单位：秒 精度 us
	void usWait(double dSecTime);
	bool IsSetBase();

	double GetSleepaccurate();

	double mSleep(double dSecTime); // 毫秒级别Sleep
private:
	Uint64		m_freq;
	Uint64		m_counter;
	bool				m_bSetBase;

	double				m_dSleepaccurate;        //sleep的误差,最高0.02s

	CAVGQueue			m_AVGQSleep;
};

#endif