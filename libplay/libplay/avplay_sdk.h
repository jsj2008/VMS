
#define AVPLAY_API


/*
#ifdef AVPLAY_EXPORTS
#define AVPLAY_API extern "C" __declspec(dllexport)
#else
#define AVPLAY_API extern "C" __declspec(dllimport)
#endif
*/

typedef void (*DECODE_COMPLETE_CB)(int, void *);//解码完成一帧通知
typedef void (*RENDER_CALLBACK)(const void *data,int lineSize,int port,int videoW,int videoH,void *userData);

typedef bool (*SAVE_BMP_CALLBACK)(
const void *data,
int videoW,
int videoH,
int lineSize,
const char *path,
unsigned int snapType,
void *userData);

typedef void (*AUDIO_STATE_CHANGE_CALLBACK)(int port,int state,void *userData);//音频状态发生改变通知


#ifdef __cplusplus
extern "C"
{
#endif

#define AVPLAY_TYPE_FILE				0 // ≤•∑≈¿‡–Õ Œƒº˛¡˜
#define AVPLAY_TYPE_STREAM				1 // ≤•∑≈¿‡–Õ  µ ±¡˜

#define AVPLAY_AUDIO_TYPE_PCM		0
#define AVPLAY_AUDIO_TYPE_AAC		1
#define AVPLAY_AUDIO_TYPE_G711		2

#define MANUAL_SNAP                 0
#define ALARM_SNAP                  1
    
#define INVALID_PORT                -1
// ≥ı ºªØ
AVPLAY_API bool AVPLAY_Init();

//  Õ∑≈
AVPLAY_API bool AVPLAY_Cleanup();

    
AVPLAY_API int  AVPLAY_FreePort();
// ø™ º≤•∑≈
AVPLAY_API bool AVPLAY_Play(long port,
                            void* hWnd,
                            AUDIO_STATE_CHANGE_CALLBACK audioStateChangeCallback,
                            DECODE_COMPLETE_CB decodeCompleteCb,
                            void *userData);

// …Ë÷√¥∞ø⁄
AVPLAY_API bool AVPLAY_SetPlayWnd(long port, void* hWnd);

// ‘›Õ£≤•∑≈
AVPLAY_API bool AVPLAY_Pause(long port, bool isPause);

// Õ£÷π≤•∑≈
AVPLAY_API bool AVPLAY_Stop(long port);

// …Ë÷√≤•∑≈¿‡–Õ
AVPLAY_API bool AVPLAY_SetPlayType(long port, long playType);

// …Ë÷√“Ù∆µ≤Œ ˝
AVPLAY_API bool AVPLAY_SetAudio( long port, long audioType, long channel, long bitrate, long samplebit, long sample );

AVPLAY_API void AVPLAY_SetShow(long port,bool isShow);
// º‡Ã˝
AVPLAY_API bool AVPLAY_Listen(long port, bool isListen);

//  ‰»Î ”∆µ ˝æ›
AVPLAY_API bool AVPLAY_InputVideoData(long port, unsigned char* buffer, unsigned long bufferSize, double pt);

//  ‰»Î“Ù∆µ ˝æ›
AVPLAY_API bool AVPLAY_InputAudioData(long port, unsigned char* buffer, unsigned long bufferSize,  double pt);


AVPLAY_API void AVPLAY_DecodeLock(long port);
AVPLAY_API void AVPLAY_DecodeUnLock(long port);
//获取解码后的数据,需要配合锁一起用
AVPLAY_API bool AVPLAY_GetDecodedData(long port, void **data, int *lineSize,int *width,int *height);
AVPLAY_API bool AVPLAY_GetSnapData(long port, void **data, int *lineSize,int *width,int *height);
// ◊•≈ƒ
AVPLAY_API bool AVPLAY_Snap(long port,char* filePathName, long type,unsigned int snapType);

// ªÒµ√∞Ê±æ∫≈
AVPLAY_API unsigned int AVPLAY_GetSDKVersion();
    
AVPLAY_API void AVPLAY_Release(long port);
    
#ifdef __cplusplus
}
#endif


