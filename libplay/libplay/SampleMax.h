#ifndef __SAMPLE_MAX_H__
#define __SAMPLE_MAX_H__

#include "PrecisionTime.h"
#include "AVGQueue.h"
// ���������ڻ�ȡ���ֵ
class CSampleMax
{
public:
	CSampleMax(void);
	~CSampleMax(void);

	void En_Data(double dValue); // �����������
	double GetValue(); // ��ȡ���ֵ
	void Reset(); // ����
	void SetSampleTime(double dSampleTime); // ���ò���ʱ�� ��λ����
	double GetAVGQValue();
private:
	// ����֡������Ӧ
	double	m_dMaxValue; // ���֡���ʱ�� ��λ����
	double	m_dPrevMaxValue; // Prev���֡���ʱ�� ��λ����
	double	m_dSampleTime; // ���֡���ʱ���������ʱ�� ��λ����
	double	m_dBeginSampleTime; // ���ڲ�����ʼʱ��
	CPrecisionTime	m_pt; // ����ʱ��
	CAVGQueue		m_AVGQMaxIFS; // 
};

#endif