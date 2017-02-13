
#include "AVDShow.h"
#include "SampleMax.h"
#include <SDL.h>
#include <unistd.h>
#include <sys/time.h>
#import <Cocoa/Cocoa.h>

#define		SPEEX_AUDIO		0 // ƒ¨»œœ˚≥˝‘Î“Ù
#if	SPEEX_AUDIO
#include "speex\speex_preprocess.h" 
#endif

#define	VIDEO_BUFFER_SIZE		1024*1024*2//1024*1024*2
#define AUDIO_BUFFER_SIZE		1024*1024
#define MAX_INTERFRAME_SPACE 1000	// ÷°º‰∏Ù ±º‰  ∫¡√Î
#define MIN_INTERFRAME_SPACE 40
#define  VIDEO_BUFFER_FRAME_0       0        
#define  VIDEO_BUFFER_FRAME_1       5       
#define  VIDEO_BUFFER_FRAME_2       7        
#define  VIDEO_BUFFER_FRAME_3       10
#define  MAX_VIDEO_FRAME_BUFFER		1024*1024

int VideoShowCB(void* pParam)
{
	if(pParam != NULL)
	{
		CAVDShow* pSV = (CAVDShow*)pParam;
		pSV->ShowVideo();
	}

	return 0;
}

int PlayAudioCB(void* pParam)
{
	if(pParam != NULL)
	{
		CAVDShow* pSV = (CAVDShow*)pParam;
		pSV->PlayAudio();
	}

	return 0;
}

double time_2_dbl(timeval time_value) 
{
	double new_time = 0.0; 
	new_time = (double) (time_value.tv_usec) ; 
	new_time /= 1000000.0; 
	new_time += (double)time_value.tv_sec; 
	//printf("the time.. %f\n", new_time); 
	return(new_time); 
} /* end time_2_dbl() */ 


CAVDShow::CAVDShow():fVideoWnd(NULL)
, m_bPause(false)
, m_bRecvSPS(false)
, m_bRecvPPS(false)
, m_iCurRecvDataDT(0)
, m_bShowVideoThread(false)
, m_bDecodeVideoThread(false)
, m_bStarted(false)
, m_iShowVideoType(VIDEO_BUFFER_FRAME_2)
, m_bPlayAudioThread(false)
, fPlayAudioThread(NULL)
, m_bAutoBufferFrame(true)
, m_iChannel(-1)
, m_dPrevFrameTime(0.0f)
, fPlayVideoThread(NULL)
, fPlayType(AVPLAY_TYPE_FILE)
, fAudioChannel(1)
, fAudioType(AVPLAY_AUDIO_TYPE_PCM)
, fBitrate(8000)
, fSamplebit(16)
, fSample(480)
, fIsListen(false)
{
	m_ptIFS.SetBaseTime();
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&fDecodeMutex,&attr);
}

CAVDShow::~CAVDShow()
{
	Stop();
}

void CAVDShow::ShowVideo(void)
// œ‘ æ
{
	CPrecisionTime pt;
	pt.SetBaseTime();

	double dFUT = 0.0f; // µ±«∞÷° π”√ ±º‰
	double dIFS = 0.0f; // ÷°º‰∏Ù ±º‰
	double prevFramePT = 0.0f;
	double dDS	= 0.0f; // Ω‚¬Îœ‘ æ ±º‰

	CAVGQueue		AVGQFUT(10); // fut
	CAVGQueue		AVGQDS(10);  // decode show
	CAVGQueue		AVGQIFS(40); // interframe space ÷°º‰∏Ù ±º‰

	double dAVGQIFS = 0;
	double dWT = 0;
	double dNextWT = 0;
	double dNextFUT = 0;

	// ª∫¥Ê÷° ˝◊‘  ”¶
	CSampleMax sm;
	CAVGQueue		AVGQIFS2(100); // interframe space ÷°º‰∏Ù ±º‰
	int iBufFrameCount = 0;
	sm.SetSampleTime(2.0);

	double dPrevDelay = 0.0f;

	//void* hOldWnd = NULL;

	int iDecodeRet = 0;
	int iWidth = 0;
	int iHeight = 0;
	int iOldWidth = 0;
	int iOldHeight = 0;
	AVPixelFormat pix_fmt = AV_PIX_FMT_NONE;

	char* pBuffer = NULL;
	int iBufferLen = 0;
	bool bWaitIFrame = true; //  «∑Òµ»¥˝I÷° Ω‚æˆ¬Ì»¸øÀŒ Ã‚
	//unsigned char	ucFrameType = 0;

	long dataBufferSize = 1024*1024*2;
	char* dataBuffer = new char[dataBufferSize];
	memset(dataBuffer, 0, dataBufferSize);

	while(m_bShowVideoThread)
	{
		int iCurQCount = (int)fVideoData.count();
		if (iCurQCount > 0)
		{
			for(int i = 0; i < iCurQCount; i++)
			{
				if(!m_bShowVideoThread)
                    break;

				dAVGQIFS = AVGQIFS.GetAVGQ();
                
				double  curFramePT  = 0.0f;
				int     dataSize    = (int)fVideoData.dequeue(dataBuffer, dataBufferSize, curFramePT);
                
				pBuffer     = dataBuffer;
				iBufferLen  = dataSize;
                
				if(pBuffer == NULL || iBufferLen <= 5)
                    continue;

				long frameType = pBuffer[4]&0x1f;
				//if (!(frameType == 1 || frameType == 5 || frameType == 7 ||frameType == 8))
				//{
				//	continue;
				//}

				if (prevFramePT < 0.0000001)
					prevFramePT = curFramePT;
				
				dIFS        = curFramePT - prevFramePT;
				prevFramePT = curFramePT;
				dIFS        = dIFS > double(MAX_INTERFRAME_SPACE)/1000?double(MAX_INTERFRAME_SPACE)/1000:dIFS;

				// start decode and draw
				double  dStartDS    = pt.GetCurrentTimeInSec();
				AVFrame *pAVFrame   = NULL;

                
                this->DecodeLock();
                
                if (fIsShow) {
                    if(!m_H264Decode.IsStarted())
                        m_H264Decode.StartDecode(2, m_iChannel);
                    
                    //printf("b0=%d,b1=%d,b2=%d,b3=%d,b4=%d,len=%d\n",pBuffer[0],pBuffer[1],pBuffer[2],pBuffer[3],pBuffer[4],iBufferLen);
                    if (bWaitIFrame)
                    {
                        if (frameType == 7 || frameType == 8 || frameType == 5) {
                            iDecodeRet = m_H264Decode.Decode((unsigned char*)pBuffer, iBufferLen, &pAVFrame);
                        }
                    }
                    else
                        iDecodeRet = m_H264Decode.Decode((unsigned char*)pBuffer, iBufferLen, &pAVFrame);
                    
                    
                    bWaitIFrame = (iDecodeRet < 0);
                    
                    // draw
                    if(pAVFrame != NULL && !m_bPause && !bWaitIFrame)
                    {
                        m_H264Decode.GetRect(iWidth, iHeight);
                        pix_fmt = m_H264Decode.GetPixFmt();
                        
                        if (iOldWidth != iWidth || iOldHeight != iHeight)
                        {
                            fSDLDrawYUV.freeYUV();
                            iOldWidth = iWidth;
                            iOldHeight = iHeight;
                        }
                        
                        if(iDecodeRet > 0 && iWidth > 0 && iHeight > 0 && pix_fmt != AV_PIX_FMT_NONE)
                        {
                            fSDLDrawYUV.initYUV((void*)fVideoWnd,iWidth,iHeight, pix_fmt,fUserData);
                            fSDLDrawYUV.render(pAVFrame, iWidth, iHeight);
                            
                            //解码成功，通知回调
                            if (fDecodeCompleteCallback)
                                fDecodeCompleteCallback(m_iChannel,fUserData);
                        }
                    }
                }
                
                this->DecodeUnlock();

				// Ω‚¬Îœ‘ æ ±º‰
				dDS     = pt.GetCurrentTimeInSec() - dStartDS;
				dFUT    = dDS + dWT;

				// ª∫¥Ê÷° ˝◊‘  ”¶
				sm.En_Data(dIFS);
				if(m_bAutoBufferFrame)
				{
					iBufFrameCount = sm.GetAVGQValue()/AVGQIFS2.GetAVGQ() + 1;
					if(iBufFrameCount > 1)
						m_iShowVideoType = iBufFrameCount;
				}

				if (dIFS > 0.0000001)
				{
					AVGQFUT.En_Queue(dFUT > double(MAX_INTERFRAME_SPACE)/1000?double(MAX_INTERFRAME_SPACE)/1000:dFUT);
					AVGQDS.En_Queue(dDS > double(MAX_INTERFRAME_SPACE)/1000?double(MAX_INTERFRAME_SPACE)/1000:dDS);
					AVGQIFS.En_Queue(dIFS > double(MAX_INTERFRAME_SPACE)/1000?double(MAX_INTERFRAME_SPACE)/1000:dIFS);
					AVGQIFS2.En_Queue(dIFS > double(MAX_INTERFRAME_SPACE)/1000?double(MAX_INTERFRAME_SPACE)/1000:dIFS);
				}

				if (fPlayType == AVPLAY_TYPE_STREAM)
                    dNextFUT = (iCurQCount <= m_iShowVideoType)?dAVGQIFS :dAVGQIFS*m_iShowVideoType/iCurQCount;
				else
					dNextFUT = dAVGQIFS;

                
				dNextWT = dNextFUT - dDS;
				if(dNextWT < 0.000001)
					dNextWT = 0.0f;		

                
				dWT = dNextWT + dPrevDelay;
				double dUsedTime = pt.mSleep(dWT);
				dPrevDelay = dWT - dUsedTime;

				if(dWT < 0.000001)
					dWT = 0.0f;
			}
		}
		else
		{
			dPrevDelay = 0.0f;
			dWT = 0.01;
			pt.mSleep(dWT);
		}
	}

	delete[] dataBuffer;
    fSDLDrawYUV.freeYUV();
}

void CAVDShow::DoVideoData( unsigned char * buffer, long bufferSize, double pt )
{
	if(buffer == NULL || bufferSize <= 0)
		return;

	if(!m_bStarted)
		return;

#if 0
	char msg[255] = {0};
	//sprintf(msg, "input data pt %f\r\n", time_2_dbl(pt));
	sprintf(msg, "avplay input video data %d %d %d %d %d %d %d\r\n", buffer[0], buffer[1], buffer[2], buffer[3], buffer[4], bufferSize, m_iChannel);
	::OutputDebugString(msg);
#endif

	//long frameType = buffer[4]&0x1f;
	double pt2 = pt;
	if (fPlayType == AVPLAY_TYPE_STREAM)
	{
		pt2 = m_ptIFS.GetCurrentTimeInSec();
	}
	/*long ret = */fVideoData.enqueue(buffer, bufferSize, pt2);
    //NSLog(@"%zu",fVideoData.count());
#if 0
	if (ret <= 0)
	{
		char msg[255] = {0};
		sprintf(msg, "avplay input video data len %d type %d\n", bufferSize, buffer[4]);
		::OutputDebugString(msg);
	}
#endif
}

void CAVDShow::DoAudioData( unsigned char * buffer, long bufferSize, double pt )
{
#if 0
	char msg[255] = {0};
	sprintf(msg, "avplay_sdk channel %d input audio data size %d\n", m_iChannel, bufferSize);
	::OutputDebugString(msg);

	//if (bufferSize < 50)
	//{
	//	return;
	//}
#endif

	if(buffer == NULL || bufferSize <= 0)
		return;

	if(!m_bStarted)
		return;

	if (!fIsListen)
	{
		return;
	}

	fAudioData.enqueue(buffer, bufferSize, pt);
}

bool CAVDShow::Start(void *hWnd,
                     AUDIO_STATE_CHANGE_CALLBACK audioStateChangeCb,
                     DECODE_COMPLETE_CB decodeCompleteCb,
                     void *userData)
{
//	if (hWnd == NULL)
//	{
//		return false;
//	}

	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	bool bRet = false;

	if(!m_bStarted)
	{
		fPlayAudioThread = NULL;

		m_PlayAudio.Stop();
		m_H264Decode.StopDecode();
		fSDLDrawYUV.freeYUV();

		m_bRecvPPS = false;
		m_bRecvSPS = false;

		fVideoWnd = hWnd;
        fUserData = userData;
        
        fSaveBmpCallback = NULL;
        fAudioStateChangeCallback = audioStateChangeCb;
        fDecodeCompleteCallback = decodeCompleteCb;
        
		m_iCurRecvDataDT = 0;
		if(m_H264Decode.StartDecode(2, m_iChannel))
		{
			memset((void*)&m_curRTPTS, 0, sizeof(m_curRTPTS));

			fVideoData.init(VIDEO_BUFFER_SIZE);
			m_bStarted = true;

			// ø™ ºœ‘ æœﬂ≥Ã
			m_bShowVideoThread = true;
            fIsShow = true;
			fPlayVideoThread = SDL_CreateThread(VideoShowCB, "", this);

			bRet = true;
		}
	}

	return bRet;
}

void CAVDShow::Clean()
{
    if (m_bStarted) {
        fVideoData.cleanUp();
        fAudioData.cleanUp();
    }
}

void CAVDShow::setShow(bool isShow)
{
    this->DecodeLock();
    fIsShow = isShow;
    this->DecodeUnlock();
}

bool CAVDShow::Stop()
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	bool bRet = false;

	if(m_bStarted)
	{
		try
		{
			listen(false);

			// Õ£÷πœ‘ æœﬂ≥Ã
			int status = 0;
			m_bShowVideoThread = false;
			SDL_WaitThread(fPlayVideoThread, &status);
			m_H264Decode.StopDecode();
			fSDLDrawYUV.freeYUV();
			fVideoData.free();

			m_bRecvPPS = false;
			m_bRecvSPS = false;

			m_iCurRecvDataDT = 0;
			m_iShowVideoType = VIDEO_BUFFER_FRAME_2;
			m_bPause = false;
			memset((void*)&m_curRTPTS, 0, sizeof(m_curRTPTS));
			fVideoWnd = NULL;
			m_bAutoBufferFrame = true;

			m_dPrevFrameTime = 0.0f;

			m_bStarted = false;
			bRet = true;
		}
		catch(...)
		{
		}
	}

	return bRet;
}

void CAVDShow::Pause(bool bPause)
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	m_bPause = bPause;
}

bool CAVDShow::SetShowVideoType(int iType)
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	m_bAutoBufferFrame = false;
	if(iType >= 3)
		m_iShowVideoType = iType;
	else if(iType == 0)
		m_bAutoBufferFrame = true;
	else
		m_iShowVideoType = 3;

	return true;
}

void CAVDShow::SetChannel(int iChannel)
{
	m_iChannel = iChannel;
}

bool CAVDShow::snap( char* filePathName, long type ,unsigned int snapType)
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	return fSDLDrawYUV.snap(filePathName, type,snapType,fSaveBmpCallback);
}

bool CAVDShow::IsStart()
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	return m_bStarted;
}

bool CAVDShow::IsPause()
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	return m_bPause;
}

void CAVDShow::PlayAudio(void)
{
	int iQCount = 0;
	unsigned char* pBuffer = NULL;
	int iBufferLen = 0;

	unsigned char szAudioDecode[1024*4] = {0};
	unsigned char szAudioDenose[1024*4] = {0};
	int  nRetG711 = 0;

#if SPEEX_AUDIO
	char szAudioZero[320] = {0};
	SpeexPreprocessState  *audioProcNose = NULL ; 
	int denoise_enabled = 1;
	//‘Î…˘
	audioProcNose = speex_preprocess_state_init(160, 8000); //πÃ∂® « 16K≤…—˘°¢10∫¡√Î≥§∂»
	speex_preprocess_ctl(audioProcNose, SPEEX_PREPROCESS_SET_DENOISE, &denoise_enabled);
	denoise_enabled = 120 ;
	speex_preprocess_ctl(audioProcNose, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &denoise_enabled);
#endif

	long dateLen = 1024*4;
	unsigned char data[1024*4] = {0};

	while(m_bPlayAudioThread)
	{
		try
		{
			iQCount = fAudioData.count();
			if(iQCount > 0)
			{
				// ªÒµ√ ˝æ›
				double user = 0.0;
				long size = fAudioData.dequeue(data, dateLen, user);
				if (size <= 0)
				{
					continue;
				}

#if 0
				char msg[255] = {0};
				sprintf(msg, "avplay_sdk channel %d get audio data size %d count %d\n", m_iChannel, size, iQCount);
				::OutputDebugString(msg);
#endif

				if(size > 0)
				{
					pBuffer = data;
					iBufferLen = size;

					if(!m_bPause)
					{
						if(pBuffer != NULL && iBufferLen > 0)
						{
							if(!m_PlayAudio.IsStart())
							{
								m_PlayAudio.Start(fAudioChannel, fBitrate, fSamplebit, fSample);
								memset(szAudioDecode, 0x00, sizeof(szAudioDecode)) ;
							}
							try
							{
								// Ω‚¬Î
								unsigned char *audioData = szAudioDecode;
								long decLen = 0;
								switch (fAudioType)
								{
								case AVPLAY_AUDIO_TYPE_AAC:
									decLen = fFaaddec.decoder(pBuffer, iBufferLen, szAudioDecode);
									break;
								case AVPLAY_AUDIO_TYPE_PCM:
									audioData = pBuffer;
									decLen = iBufferLen;
									break;
								case AVPLAY_AUDIO_TYPE_G711:
									//nRetG711 =  m_g711.ULawDecode((signed short *)szAudioDecode,(const unsigned char *)pBuffer, iBufferLen);
									break;
								}

								if (decLen > 0)
								{
									m_PlayAudio.Play((unsigned char*)audioData, decLen);
								}
							}
							catch(...)
							{
							}
							if(nRetG711 > 0 )
							{
#if SPEEX_AUDIO
								//// ‘Î“Ùœ˚≥˝¥¶¿Ì
								//if(SPEEX_AUDIO == 1)
								//{
								//	for(int i = 0;i < 6;i++)
								//	{
								//		memcpy(szAudioZero, szAudioDecode + i*320, 320);
								//		speex_preprocess(audioProcNose, (__int16*)szAudioZero, NULL);
								//		memcpy(szAudioDenose + 320*i, szAudioZero, 320) ;
								//	}
								//}
								//m_PlayAudio.Play((unsigned char*)szAudioDenose, decLeny) ;
#endif
							}
						}
					}
				}
			}
			else
			{
				SDL_Delay(1);
			}
		}
		catch(...)
		{
		}
	}

#if SPEEX_AUDIO
	speex_preprocess_state_destroy(audioProcNose); 
#endif
}

bool CAVDShow::SetPlayType( long playType )
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	fPlayType = playType;
	return true;
}

bool CAVDShow::setPlayWnd( void *hWnd )
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	if (hWnd == NULL)
	{
		return false;
	}

	fSDLDrawYUV.freeYUV();
	fVideoWnd = hWnd;

	return true;
}

bool CAVDShow::setAudio( long audioType, long channel, long bitrate, long samplebit, long sample )
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	fAudioType = audioType;
	fAudioChannel = channel;
	fBitrate = bitrate;
	fSamplebit = samplebit;
	fSample = sample;

	return true;
}

bool CAVDShow::listen( bool isListen )
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	if (isListen)
	{
        if (!fIsListen) {
            // setAudio(AVPLAY_AUDIO_TYPE_AAC, 2, 44100, 16, 1024);
            if (m_PlayAudio.Start(fAudioChannel, fBitrate, fSamplebit, fSample))
            {
                fAudioData.init(AUDIO_BUFFER_SIZE);
                
                m_bPlayAudioThread = true;
                SetListen(true);
                fPlayAudioThread = SDL_CreateThread(PlayAudioCB, "", this);
            }
        }
	}
	else
	{
        if (fIsListen) {
            int status = 0;
            m_bPlayAudioThread = false;
            if (fPlayAudioThread != NULL)
            {
                SDL_WaitThread(fPlayAudioThread, &status);
                fPlayAudioThread = NULL;
            }
            m_PlayAudio.Stop();
            fAudioData.free();
            SetListen(false);
        }
	}

	return true;
}

void CAVDShow::SetListen(bool isListen)
{
    fIsListen = isListen;
    
    if (fAudioStateChangeCallback) {
        fAudioStateChangeCallback(m_iChannel,fIsListen,fUserData);
    }
}

void CAVDShow::DecodeLock(void)
{
    pthread_mutex_lock(&fDecodeMutex);
}

void CAVDShow::DecodeUnlock(void)
{
    pthread_mutex_unlock(&fDecodeMutex);
}

bool CAVDShow::GetDecodedData(void **data, int *lineSize,int *width,int *height)
{
    if (m_bStarted) {
        AVFrame *frame = fSDLDrawYUV.getYUVFrame();
        
        if (frame) {
            *data = frame->data[0];
            *lineSize = frame->linesize[0];
            *width = frame->width;
            *height = frame->height;
            
            return  true;
        }
    }
    
    return false;
}

bool CAVDShow::GetSnapData(void **data, int *lineSize,int *width,int *height)
{
    if (m_bStarted) {
        AVFrame *frame = fSDLDrawYUV.getRGBFrame();
        
        if (frame) {
            *data = frame->data[0];
            *lineSize = frame->linesize[0];
            *width = frame->width;
            *height = frame->height;
            
            return  true;
        }
    }
    
    return false;
}

