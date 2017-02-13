#include "PrecisionTime.h"

#ifdef WIN32
#include <Windows.h>
#else
#include <unistd.h>
#endif

CPrecisionTime::CPrecisionTime(void):
m_bSetBase(false),
m_dSleepaccurate(0.005f)
{
#ifdef WIN32
	timeBeginPeriod(1);
#endif
	m_freq = 0;
	m_counter = 0;
	m_AVGQSleep.SetQueueCount(100);
	m_AVGQSleep.En_Queue(m_dSleepaccurate);
}

CPrecisionTime::~CPrecisionTime(void)
{
#ifdef WIN32
	timeEndPeriod(1);
#endif
}

void CPrecisionTime::SetBaseTime()
{
	m_freq = SDL_GetPerformanceFrequency();
	m_counter = SDL_GetPerformanceCounter();

	m_bSetBase = true;
}

double CPrecisionTime::GetCurrentTimeInSec()
{
	if(m_bSetBase)
	{
		Uint64 counter;
		counter = SDL_GetPerformanceCounter();
		return (double)((long double)(counter - m_counter) / (long double) m_freq);
	}
	else return 0;
}

void CPrecisionTime::Loop(double dSecTime)	
{
	double dBeginTime = GetCurrentTimeInSec();
	while((GetCurrentTimeInSec()-dBeginTime) < dSecTime);
}

void CPrecisionTime::uSleep(double dSecTime)
{
	double dBeginTime = GetCurrentTimeInSec();

	if(dSecTime < m_dSleepaccurate)
	{
		return Loop(dSecTime);
	}
	if( m_dSleepaccurate < 0.000001f)
	{
#ifdef WIN32
		Sleep(dSecTime*1000);
#else
        usleep(dSecTime*1000000);
#endif
	}
	else
	{
		m_dSleepaccurate = m_AVGQSleep.GetAVGQ();

		int iSleepMS = dSecTime*1000 - (m_dSleepaccurate+0.001)*1000;
		if(iSleepMS > 0)
#ifdef WIN32
            Sleep(iSleepMS);
#else
            usleep(iSleepMS*1000);
#endif
        
		else iSleepMS = 0;
		
		double dEndTime = GetCurrentTimeInSec();

		double dtmp = abs((dEndTime - dBeginTime) - double(iSleepMS)/1000);
		m_AVGQSleep.En_Queue(dtmp);

		Loop(dSecTime - dEndTime + dBeginTime);
	}
}

bool CPrecisionTime::IsSetBase()
{
	return m_bSetBase;
}

void CPrecisionTime::usWait(double dSecTime)
{
	//CBaseEvent bs;
	//
	//double dBeginTime = GetCurrentTimeInSec();
	//if(dSecTime < m_dSleepaccurate)
	//{
	//	return Loop(dSecTime);
	//}
	//bs.Wait(dSecTime*1000 - m_dSleepaccurate*1000);
	//Loop(dSecTime - GetCurrentTimeInSec() + dBeginTime);
}

double CPrecisionTime::GetSleepaccurate()
{
	return m_dSleepaccurate;
}

double CPrecisionTime::mSleep(double dSecTime)
{
	if( dSecTime < 0.000001) return 0.0f;

	double dBeginTime = GetCurrentTimeInSec();

	unsigned long dwWT = dSecTime*1000; // ms

	SDL_Delay(dwWT);
	
	double dEndTime = GetCurrentTimeInSec();

	//dSleepDelay = (dEndTime - dBeginTime) - double(dwWT)/1000;

	return dEndTime - dBeginTime; // used time
}