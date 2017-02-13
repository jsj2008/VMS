#ifndef __PLAY_AUDIO_H__
#define __PLAY_AUDIO_H__

//#ifdef WIN32
//#include <Windows.h>
//#endif

#include "sdlbasemutex.h"

class CPlayAudio  
{
public:
	CPlayAudio();
	virtual ~CPlayAudio();

	bool	Start(int channel, int bitrate,int samplebit, int sample );
	void	Stop();
	void	Play(unsigned char *szSound, int nSoundLen);
	bool	IsStart();

private:
	bool			fStarted;
	SDL_AudioSpec	wanted_spec;
	long			fDataCount;

	// audio
	long		fChannel;
	long		fSampleRate;
	long		fSamplebit;
	long		fSample;

	CBaseSDLMutex	fAudioBaseSDLMutex;
};

#endif
