#pragma once
#include "faad.h"

#define AAC_BUFFER_SIZE		1024*4

class CFaaddec
{
public:
	CFaaddec(void);
	~CFaaddec(void);

	long decoder(unsigned char* buffer, long bufferLen, unsigned char* decBuffer);

private:
	bool init(unsigned char* buffer, long bufferLen);
	bool free();
private:
	NeAACDecHandle fDecoder;
	unsigned long fSamplerate;
	unsigned char fChannels;

	unsigned char	fBuffer[AAC_BUFFER_SIZE];
};