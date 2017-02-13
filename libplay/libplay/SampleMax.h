#ifndef __SAMPLE_MAX_H__
#define __SAMPLE_MAX_H__

#include "PrecisionTime.h"
#include "AVGQueue.h"
// 采样周期内获取最大值
class CSampleMax
{
public:
	CSampleMax(void);
	~CSampleMax(void);

	void En_Data(double dValue); // 输入采样数据
	double GetValue(); // 获取最大值
	void Reset(); // 重置
	void SetSampleTime(double dSampleTime); // 设置采样时间 单位：秒
	double GetAVGQValue();
private:
	// 缓存帧数自适应
	double	m_dMaxValue; // 最大帧间隔时间 单位：秒
	double	m_dPrevMaxValue; // Prev最大帧间隔时间 单位：秒
	double	m_dSampleTime; // 最大帧间隔时间采样周期时间 单位：秒
	double	m_dBeginSampleTime; // 周期采样开始时间
	CPrecisionTime	m_pt; // 采样时间
	CAVGQueue		m_AVGQMaxIFS; // 
};

#endif