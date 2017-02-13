#ifndef __SDLDRAWYUV_H__
#define __SDLDRAWYUV_H__

#include "sdlbasemutex.h"

#ifdef __cplusplus
extern "C"
{
#endif

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libswscale/swscale.h>
#include <libavutil/base64.h>

#ifdef __cplusplus
}
#endif

//#include "WriteBmpFile.h"
//渲染将要呈现回调函数
//作用是在每一帧图像被呈现前，增加自定义的绘画功能.

typedef void (*RENDER_CALLBACK)(
const void *data,
int lineSize,
int port,
int videoW,
int videoH,
void *userData);

typedef bool (*SAVE_BMP_CALLBACK)(
const void *data,
int videoW,
int videoH,
int lineSize,
const char *path,
unsigned int snapPath,
void *userData);

class CSDLDrawYUV
{
public:
	CSDLDrawYUV(void);
	~CSDLDrawYUV(void);

	static bool initSDL();
	static bool freeSDL();

	bool initYUV(void* hVideo,
                 int width,
                 int height,
                 AVPixelFormat pix_fmt,
                 void *userData);
	bool freeYUV();
	bool render(AVFrame *yuv420Frame,
                int width,
                int height);
	bool snap(char *filePathName, long type,unsigned int snapType,SAVE_BMP_CALLBACK saveBmpCb);
    AVFrame *getYUVFrame();
    AVFrame *getRGBFrame();
private:

	SDL_Window		*fWindow;
	SDL_Rect		fDstRect;
	SDL_Rect		fSrcRect;
	SDL_Renderer	*fRenderer;
	SDL_Texture		*fTexture;

    void *fUserData;
    
	AVFrame	*fYUVFrame;
	SwsContext *fsws_ctx;
	uint8_t *fout_buffer;
	void *fVideoWnd;

	long fWidth;
	long fHeight;

	//Œ™≈ƒ’’
	unsigned char*		m_pRGBData ;
	AVFrame*			m_pFrameRGB ; 
	AVPicture*			m_pPictureCapture;
    int m_DecodedW;
    int m_DecodedH;
	//SwsContext*			m_pImg2Ctx ; //◊™ªª∆˜
	SwsContext *		m_pImg2Ctx2 ; //◊™ªª∆˜

	//CWriteBmpFile		m_WriteFile; // ◊•≈ƒŒƒº˛

	CBaseSDLMutex	fBaseSDLMutex;
};

#endif
