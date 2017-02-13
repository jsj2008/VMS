#ifndef __AVDSHOW_H__
#define __AVDSHOW_H__

#include <SDL_thread.h>
#include "PrecisionTime.h"
#include "PlayAudio.h"
#include "VideoDecode.h"
#include "audio_encode.h"
#include "Fifo.h"
#include "SDLDrawYUV.h"
#include "Faaddec.h"
#include "avplay_sdk.h"
#include "RingQueue.h"

class CAVDShow
{
public:
	CAVDShow();
	virtual ~CAVDShow();

    void Clean();
	bool Start(void *hWnd,
               AUDIO_STATE_CHANGE_CALLBACK audioStateChangeCb,
               DECODE_COMPLETE_CB decodeCompleteCb,
               void *userData);
	bool Stop();
	void Pause(bool bPause);
	bool SetPlayType(long playType);
	bool setPlayWnd(void *hWnd);
    void setShow(bool isShow);
	bool setAudio(long audioType, long channel, long bitrate, long samplebit, long sample);
	bool listen(bool isListen);
	void ShowVideo(void);
    void PlayAudio(void);
	void DoVideoData(unsigned char * buffer, long bufferSize,  double pt);
	void DoAudioData(unsigned char * buffer, long bufferSize, double pt);
	bool snap(char* filePathName, long type,unsigned int snapType);
	bool IsStart();
	bool IsPause();
	void SetChannel(int iChannel);
    void SetListen(bool isListen);
    void DecodeLock(void);
    void DecodeUnlock(void);
    bool GetDecodedData(void **data, int *lineSize,int *width,int *height);
    bool GetSnapData(void **data, int *lineSize,int *width,int *height);
private:
	bool SetShowVideoType(int iType);
private:
	RingQueue			fVideoData;
	RingQueue			fAudioData;

	CSDLDrawYUV		fSDLDrawYUV;
	CVideoDecode	m_H264Decode;	// Ω‚¬Î∆˜
	G711            m_g711;			// “Ù∆µΩ‚¬Î 
	CFaaddec		fFaaddec;		// aac decoder
	CPlayAudio      m_PlayAudio;	// “Ù∆µ≤•∑≈

	SDL_Thread		*fPlayVideoThread;
	SDL_Thread		*fPlayAudioThread;

	void*			fVideoWnd;
    void*           fUserData;
  
	bool			m_bRecvSPS;
	bool			m_bRecvPPS;

	timeval			m_curRTPTS;
	int				m_iCurRecvDataDT;

	bool			m_bShowVideoThread;
	bool			m_bDecodeVideoThread;
	bool			m_bPlayAudioThread;

	bool			m_bStarted;
	bool			m_bPause;

	int				m_iChannel; // Õ®µ¿∫≈

	int				m_iShowVideoType;
	bool			m_bAutoBufferFrame; //  «∑Ò◊‘  ”¶ª∫¥Ê÷° ˝

	CPrecisionTime	m_ptIFS;
	double			m_dPrevFrameTime;

	long			fPlayType;

	// audio
	long			fAudioType;
	long			fAudioChannel;
	long			fBitrate;
	long			fSamplebit;
	long			fSample;

	bool			fIsListen;
    bool            fIsShow;

	CBaseSDLMutex	fBaseSDLMutex;
    RENDER_CALLBACK fRenderCallback;
    SAVE_BMP_CALLBACK fSaveBmpCallback;
    AUDIO_STATE_CHANGE_CALLBACK fAudioStateChangeCallback;
    DECODE_COMPLETE_CB fDecodeCompleteCallback;
    
    pthread_mutex_t fDecodeMutex;
};

#endif
