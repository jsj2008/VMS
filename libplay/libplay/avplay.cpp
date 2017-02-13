//#include "crtdbg.h"
//
//#ifdef _DEBUG
//#define new new(_NORMAL_BLOCK, __FILE__, __LINE__)
//#endif
//
//inline void EnableMemLeakCheck()
//{
//	int ret = _CrtSetDbgFlag(_CrtSetDbgFlag(_CRTDBG_REPORT_FLAG) | _CRTDBG_LEAK_CHECK_DF);
//}

#include "avplay_sdk.h"
#include "AVDShow.h"

#define			MAX_AVPLAY_CHANNEL	300

CAVDShow		*g_AVDShow = NULL;


unsigned char	MAIN_VER = 		1;
unsigned char	SUB_VER	 = 		0;

bool			g_bInit = false;	//  «∑Ò≥ı ºªØ

// ≥ı ºªØ
AVPLAY_API bool AVPLAY_Init()
{
    if(g_bInit)
        return false;
    
    //EnableMemLeakCheck();
    //long ret = _CrtSetBreakAlloc(72);
    
    g_AVDShow = new CAVDShow[MAX_AVPLAY_CHANNEL];
    
    av_register_all();
    avcodec_register_all() ;
    
    CSDLDrawYUV::initSDL();
    
    for(int i = 0; i < MAX_AVPLAY_CHANNEL; i++)
    {
        g_AVDShow[i].SetChannel(i);
    }
    
    g_bInit = true;
    
    return true ;
}

//  Õ∑≈
AVPLAY_API bool AVPLAY_Cleanup()
{
	if(!g_bInit)
		return false;

	g_bInit = false;

	for(int i = 0; i < MAX_AVPLAY_CHANNEL; i++)
	{
		g_AVDShow[i].Stop();
	}

	if (g_AVDShow != NULL)
	{
		delete[] g_AVDShow;
		g_AVDShow = NULL;
	}

	CSDLDrawYUV::freeSDL();


	return true ;
}

AVPLAY_API int  AVPLAY_FreePort()
{
    int freePort = -1;
    for (int port = 0; port < MAX_AVPLAY_CHANNEL; port++) {
        if (!g_AVDShow[port].IsStart()) {
            freePort = port;
            break;
        }
    }
    return freePort;
}
// ø™ º
AVPLAY_API bool AVPLAY_Play(long port,
                            void* hWnd,
                            AUDIO_STATE_CHANGE_CALLBACK audioStateChangeCallback,
                            DECODE_COMPLETE_CB decodeCompleteCb,
                            void *userData)
{
	if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
		return false ;

	if(!g_bInit)
		return false;

	return g_AVDShow[port].Start(hWnd,audioStateChangeCallback,decodeCompleteCb,userData);
}

// ‘›Õ£
AVPLAY_API bool AVPLAY_Pause(long port, bool isPause)
{
	if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
		return false ;

	if(!g_bInit)
		return false;

	g_AVDShow[port].Pause(isPause);

	return true ;
}

// Õ£÷π
AVPLAY_API bool AVPLAY_Stop(long port)
{
	if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
		return false ;

	if(!g_bInit)
		return false;

	g_AVDShow[port].Stop();

	return true ;
}

// …Ë÷√≤•∑≈¿‡–Õ
AVPLAY_API bool AVPLAY_SetPlayType(long port, long playType)
{
	if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
		return false ;

	if(!g_bInit)
		return false;

	return 	g_AVDShow[port].SetPlayType(playType);
}

//  ”∆µ ˝æ›
AVPLAY_API bool AVPLAY_InputVideoData( long port, unsigned char* buffer, unsigned long bufferSize, double pt )
{
	if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
		return false ;

	if(buffer == NULL || bufferSize == 0)
		return false;

	if(!g_bInit)
		return false;

	g_AVDShow[port].DoVideoData(buffer, bufferSize, pt);

	return true ;
}

// “Ù∆µ ˝æ›
AVPLAY_API bool AVPLAY_InputAudioData( long port, unsigned char* buffer, unsigned long bufferSize, double pt )
{
	if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
		return false ;

	if(buffer == NULL || bufferSize == 0)
		return false;

	if(!g_bInit)
		return false;

	g_AVDShow[port].DoAudioData(buffer, bufferSize, pt);

	return true ;
}

// ◊•≈ƒŒ™BMPŒƒº˛
AVPLAY_API bool AVPLAY_Snap(long port,char* filePathName, long type,unsigned int snapType)
{
	if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
		return false ;

	if(!g_bInit)
		return false;

	return g_AVDShow[port].snap(filePathName, type,snapType);
}

// ªÒµ√∞Ê±æ∫≈
AVPLAY_API unsigned int AVPLAY_GetSDKVersion()
{
	return (MAIN_VER << 8 && 0xff00) || SUB_VER ;
}

AVPLAY_API void AVPLAY_SetShow(long port,bool isShow)
{
    if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
        return;
    
    if(!g_bInit)
        return;
    
    
}

AVPLAY_API void AVPLAY_Release(long port)
{
    if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
        return;
    
    if(!g_bInit)
        return;
    
    g_AVDShow[port].Clean();
}

// …Ë÷√¥∞ø⁄
AVPLAY_API bool AVPLAY_SetPlayWnd(long port, void* hWnd)
{
	if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
		return false ;
	
	if(!g_bInit)
		return false;

	return g_AVDShow[port].setPlayWnd(hWnd);
}

// …Ë÷√“Ù∆µ≤Œ ˝
AVPLAY_API bool AVPLAY_SetAudio( long port, long audioType, long channel, long bitrate, long samplebit, long sample )
{
	if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
		return false ;

	if(!g_bInit)
		return false;

	return g_AVDShow[port].setAudio(audioType, channel, bitrate, samplebit, sample);
}

// º‡Ã˝
AVPLAY_API bool AVPLAY_Listen(long port, bool isListen)
{
	if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
		return false ;

	if(!g_bInit)
		return false;

    if (isListen) {
        for (int p = 0; p < MAX_AVPLAY_CHANNEL; p++) {
            g_AVDShow[p].listen(false);
        }
    }
	return g_AVDShow[port].listen(isListen);
}

AVPLAY_API void AVPLAY_DecodeLock(long port)
{
    if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
        return;
    
    if(!g_bInit)
        return;
    
    g_AVDShow[port].DecodeLock();
}

AVPLAY_API void AVPLAY_DecodeUnLock(long port)
{
    if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
        return;
    
    if(!g_bInit)
        return;
    
    g_AVDShow[port].DecodeUnlock();
}

//获取解码后的数据,需要配合锁一起用
AVPLAY_API bool AVPLAY_GetDecodedData(long port, void **data, int *lineSize,int *width,int *height)
{
    if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
        return false;
    
    if(!g_bInit)
        return false;
    
    return g_AVDShow[port].GetDecodedData(data, lineSize,width,height);
}

AVPLAY_API bool AVPLAY_GetSnapData(long port, void **data, int *lineSize,int *width,int *height)
{
    if(port < 0 || port >= MAX_AVPLAY_CHANNEL)
        return false;
    
    if(!g_bInit)
        return false;
    
    return g_AVDShow[port].GetSnapData(data, lineSize,width,height);
}

