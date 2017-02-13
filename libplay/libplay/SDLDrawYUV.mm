#include "SDLDrawYUV.h"
#ifdef WIN32
#include "windows.h"
#endif
#include "avplay_sdk.h"
#import <Cocoa/Cocoa.h>


CSDLDrawYUV::CSDLDrawYUV(void):
fWindow(NULL),
fRenderer(NULL),
fTexture(NULL),
fout_buffer(NULL),
fsws_ctx(NULL),
fYUVFrame(NULL),
fVideoWnd(NULL),
m_pPictureCapture(NULL),
m_pImg2Ctx2(NULL),
m_pRGBData(NULL),
m_pFrameRGB(NULL)
{
}

CSDLDrawYUV::~CSDLDrawYUV(void)
{
}

bool CSDLDrawYUV::initSDL()
{
	if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER)) 
	{  
		//printf( "Could not initialize SDL - %s\n", SDL_GetError()); 
		return false;
	}

	return true;
}

bool CSDLDrawYUV::freeSDL()
{
	SDL_Quit();

	return true;
}

bool CSDLDrawYUV::initYUV(void* hVideo,
                          int width,
                          int height,
                          AVPixelFormat pix_fmt,
                          void *userData)
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

    //fWindow = SDL_CreateWindowFrom(hVideo);
    //fVideoWnd = hVideo;
    //int dstWidth, dstHeight;
    //SDL_GetWindowSize(fWindow, &dstWidth, &dstHeight);
    //fDstRect.x = 0;
    //fDstRect.y = 0;
    //fDstRect.w = dstWidth;
    //fDstRect.h = dstHeight;
    
    //fSrcRect.x = 0;
    //fSrcRect.y = 0;
    //fSrcRect.w = dstWidth;
    //fSrcRect.h = dstHeight;
    
    //fRenderer = SDL_CreateRenderer(fWindow, -1, 0);
    
    fUserData = userData;
    // to yuv420p
    if (fsws_ctx == NULL)
    {
        fsws_ctx = sws_getContext(width, height, pix_fmt, width, height, AV_PIX_FMT_YUV420P, SWS_BILINEAR, NULL, NULL, NULL);
        fYUVFrame=av_frame_alloc();
        fout_buffer=(uint8_t *)av_malloc(avpicture_get_size(AV_PIX_FMT_YUV420P, width, height));
        avpicture_fill((AVPicture *)fYUVFrame, fout_buffer, AV_PIX_FMT_YUV420P, width, height);
        
        
        
        m_pPictureCapture = NULL ;
        int numBytes2 = avpicture_get_size(AV_PIX_FMT_BGR24, width, height);
        m_pFrameRGB = av_frame_alloc();
        while(m_pRGBData == NULL) //—≠ª∑∑÷≈‰
            m_pRGBData = new unsigned char [numBytes2];
        avpicture_fill((AVPicture *)m_pFrameRGB, m_pRGBData, AV_PIX_FMT_BGR24, width, height);
        sws_getContext(width,
                       height,
                       AV_PIX_FMT_YUV420P,
                       width,
                       height,
                       AV_PIX_FMT_BGR24,
                       SWS_BILINEAR,
                       NULL,
                       NULL,
                       NULL);
       
        fWidth = width;
        fHeight = height;
        
        return true;
    }

	return false;
}


/*
 *该方法用于追踪解码后的数据
 */
bool CSDLDrawYUV::render( AVFrame *yuv420Frame,int width,int height)
{
	if (yuv420Frame == NULL) return false;
	
	CAutoLockSDLMutex lock(&fBaseSDLMutex);
    
	m_pPictureCapture = (AVPicture*)yuv420Frame ;
    m_DecodedW = width;
    m_DecodedH = height;
    
	/*sws_scale(fsws_ctx,
              (uint8_t const * const *)yuv420Frame->data,
              yuv420Frame->linesize,
              0,
              height,
              fYUVFrame->data,
              fYUVFrame->linesize);
    fYUVFrame->width = width;
    fYUVFrame->height = height;*/
    
    return true;
}

AVFrame *CSDLDrawYUV::getYUVFrame()
{
    CAutoLockSDLMutex lock(&fBaseSDLMutex);
    
    if ((fsws_ctx != NULL) && (m_pPictureCapture != NULL) && (m_pPictureCapture->data[0] != NULL)) {
        sws_scale(fsws_ctx,
                  (uint8_t const * const *)m_pPictureCapture->data,
                  m_pPictureCapture->linesize,
                  0,
                  m_DecodedH,
                  fYUVFrame->data,
                  fYUVFrame->linesize);
        fYUVFrame->width = m_DecodedW;
        fYUVFrame->height = m_DecodedH;
        
        return fYUVFrame;
    }
    
    return NULL;
}

AVFrame *CSDLDrawYUV::getRGBFrame()
{
    CAutoLockSDLMutex lock(&fBaseSDLMutex);
    
    if ((m_pImg2Ctx2 != NULL) && (m_pPictureCapture != NULL) && (m_pPictureCapture->data[0] != NULL)) {
        sws_scale(m_pImg2Ctx2,
                  m_pPictureCapture->data,
                  m_pPictureCapture->linesize,
                  0,
                  m_DecodedH,
                  m_pFrameRGB->data ,
                  m_pFrameRGB->linesize);
        m_pFrameRGB->width = m_DecodedW;
        m_pFrameRGB->height = m_DecodedH;
        
        return m_pFrameRGB;
    }
    
    return NULL;
}

bool CSDLDrawYUV::freeYUV()
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	if ( fTexture != NULL )
	{
		SDL_DestroyTexture( fTexture );
		fTexture = NULL    ;
	}

	if ( fRenderer != NULL )
	{
		SDL_DestroyRenderer( fRenderer );
		fRenderer = NULL;
	}

	if ( NULL != fWindow )
	{
		SDL_DestroyWindow( fWindow );
       
		fWindow = NULL;
#ifdef WIN32
		if (fVideoWnd != NULL)
		{
			InvalidateRect((HWND)fVideoWnd, NULL, true);
			//ShowWindow((HWND)fVideoWnd, SW_SHOW);
		}
#endif
	}

	if (fout_buffer != NULL)
	{
		av_free(fout_buffer);
		fout_buffer = NULL;
	}

	if (fYUVFrame != NULL)
	{
		av_free(fYUVFrame);
		fYUVFrame = NULL;
	}

	if (fsws_ctx != NULL) 
	{
		sws_freeContext(fsws_ctx);
		fsws_ctx = NULL;
	}

	if (m_pImg2Ctx2 != NULL) 
	{
		sws_freeContext(m_pImg2Ctx2);
		m_pImg2Ctx2 = NULL;
	}

	//≈ƒ’’ π”√µƒ ‘› ±∆¡±Œ≈ƒ’’
	if(m_pRGBData != NULL)
	{
		delete [] m_pRGBData ;
		m_pRGBData = NULL ;
	}
    
	return true;
}



bool CSDLDrawYUV::snap( char *filePathName, long type ,unsigned int snapType,SAVE_BMP_CALLBACK saveBmpCb)
{
	if(filePathName == NULL)
		return false;

	if (m_pPictureCapture == NULL )
		return false;

    if (m_pImg2Ctx2 == NULL)
        return false;

    if (m_pPictureCapture->data[0] == NULL)
        return false;
    
	try
	{
		//◊™ªªŒ™RGB24
		sws_scale(m_pImg2Ctx2,
                  m_pPictureCapture->data,
                  m_pPictureCapture->linesize,
                  0,
                  fHeight,
                  m_pFrameRGB->data ,
                  m_pFrameRGB->linesize);

		switch(type)
		{
		case 1: // bmp
			{
				char * szNewRGBData = NULL;
                if (fWidth > 0 && fHeight >0) {
                    szNewRGBData = new char [fWidth*fHeight*3];
                    
                    for(int i = 0;i < fHeight;i++)
                        memcpy(szNewRGBData+ i * fWidth * 3,m_pRGBData+(fHeight -i - 1) * fWidth * 3,fWidth * 3);
                    
                    bool ret = saveBmpCb? saveBmpCb(szNewRGBData,(int)fWidth,(int)fHeight,(int)m_pFrameRGB->linesize[0],filePathName,snapType,fUserData) : false;
                    
                    delete [] szNewRGBData;
                    
                    return ret;
                }
                
                return false;
				// –¥Œƒº˛
				/*if(m_WriteFile.Open(filePathName, fWidth, fHeight))
				{
					m_WriteFile.Write(szNewRGBData) ;
					m_WriteFile.Close();

					delete [] szNewRGBData ;
					return true;
				}
				else
				{
					delete [] szNewRGBData  ;
				}*/
			}
			break;
		case 2: // jpg
			{
				////ΩªªªRGBŒª÷√
				//JpegFile::BGRFromRGB((BYTE *)m_pRGBData, fWidth, fHeight);

				//// save RGB packed buffer to JPG
				//bRet = JpegFile::RGBToJpegFile(szFileName, 
				//	(BYTE *)m_pRGBData,
				//	m_iWidth,
				//	m_iHeight,
				//	TRUE, 
				//	100);			// quality value 1-100
			}
			break;
		}
	}
	catch(...)
	{
#ifdef _DEBUG
		::OutputDebugString("◊•Õº“Ï≥£\r\n") ;
#endif
	}

	return false; 

}
