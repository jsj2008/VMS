#ifndef __VIDEO_DECODE_H__
#define __VIDEO_DECODE_H__


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

class CVideoDecode  
{
public:
	CVideoDecode();
	virtual ~CVideoDecode();

	void	StopDecode();
	bool StartDecode(int nVideoCode, int iChannel);

	int		Decode(unsigned char *szImage, int nImageLen, AVFrame** ppAVFrame);

	void	GetRect(int& iWidth, int& iHeight);
	AVPixelFormat	GetPixFmt();
	bool IsStarted();
private:
	int					m_iDecodeErrorCount ; // 解码出错次数
	bool				m_bInitDecode ;

 	AVCodec*			m_pDCodec ;
	AVCodecContext*		m_pDCodecCtx ;
	AVFrame*			m_pDPicture ;
	AVCodecParserContext* m_pParser;
    
	int					m_iChannel;

	CBaseSDLMutex		fBaseSDLMutex;
};

#endif
