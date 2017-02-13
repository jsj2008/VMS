#include "SampleMax.h"


CSampleMax::CSampleMax(void):
m_dMaxValue(0.0f),
m_dPrevMaxValue(0.0f),
m_dSampleTime(2.0f),
m_dBeginSampleTime(0.0f)
{
	m_pt.SetBaseTime();
	m_AVGQMaxIFS.SetQueueCount(10);
}

CSampleMax::~CSampleMax(void)
{
}

void CSampleMax::En_Data(double dValue)
{
	double dCurrent = m_pt.GetCurrentTimeInSec();
	if(m_dBeginSampleTime < 0.0000001)
		m_dBeginSampleTime = dCurrent;

	m_dMaxValue = m_dMaxValue > dValue?m_dMaxValue:dValue;

	if(dCurrent - m_dBeginSampleTime > m_dSampleTime) // 采样周期结束
	{
		m_dBeginSampleTime = dCurrent;
		m_dPrevMaxValue = m_dMaxValue;
		m_AVGQMaxIFS.En_Queue(m_dPrevMaxValue);
		m_dMaxValue = 0.0f;
	}
}

double CSampleMax::GetValue()
{
	return m_dPrevMaxValue;
}

double CSampleMax::GetAVGQValue()
{
	return m_AVGQMaxIFS.GetAVGQ();
}

void CSampleMax::Reset()
{
	m_dMaxValue = 0.04f;
	m_dPrevMaxValue = 0.04f;
	m_dSampleTime = 5.0f;
}

void CSampleMax::SetSampleTime(double dSampleTime)
{
	m_dSampleTime = dSampleTime;
}