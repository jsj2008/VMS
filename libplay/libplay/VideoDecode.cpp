/*
实现视频解码 
*/

#include "VideoDecode.h"

static CBaseSDLMutex		gBaseSDLMutex;

CVideoDecode::CVideoDecode()
{
	m_bInitDecode = false ;
	m_pDCodecCtx = NULL ;
	m_pDCodec = NULL;
	m_pDPicture = NULL;
	m_iDecodeErrorCount = 0;
	m_iChannel = -1;
	m_pParser = NULL;
}

CVideoDecode::~CVideoDecode()
{
	StopDecode() ;
}

//启动解码器
bool CVideoDecode::StartDecode( int nVideoCode, int iChannel )
{
	bool bRet = false;

	if(nVideoCode < 1 || nVideoCode > 3)
		return bRet;

	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	if(m_bInitDecode)
		return bRet ;

	m_bInitDecode = false ;
	m_pDCodecCtx = NULL ;
	m_pDCodec = NULL;
	m_pDPicture = NULL;
	m_iDecodeErrorCount = 0;

	//解码
	switch(nVideoCode)
	{
	case 1:
		m_pDCodec = avcodec_find_decoder(AV_CODEC_ID_MPEG4) ;
		break;
	case 2:
		m_pDCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
		break;
	case 3:
		m_pDCodec = avcodec_find_decoder(AV_CODEC_ID_MJPEG) ;
		break;
	}
    
	if(m_pDCodec == NULL) 
		return bRet;

	m_pDPicture  = av_frame_alloc();
	if(m_pDPicture == NULL)
		return bRet;

	m_pDCodecCtx = avcodec_alloc_context3(m_pDCodec);
    

	if(m_pDCodecCtx == NULL)
	{
		if(m_pDPicture != NULL)
		{
			av_free(m_pDPicture) ;
			m_pDPicture = NULL;
		}
		return bRet;
	}

	//avcodec_get_context_defaults3(m_pDCodecCtx, m_pDCodec);
	//m_pDCodecCtx->codec_id = CODEC_ID_H264;
    m_pDCodecCtx->codec_id = AV_CODEC_ID_H264;
	m_pDCodecCtx->thread_count = 2;
	m_pDCodecCtx->width = 1280;
	m_pDCodecCtx->height = 720;
    
	//m_pDCodecCtx->flags |= CODEC_FLAG_EMU_EDGE;
	//m_pDCodecCtx->pix_fmt = PIX_FMT_YUVJ420P;
    m_pDCodecCtx->pix_fmt = AV_PIX_FMT_YUV420P;
	//m_pDCodecCtx->pix_fmt = PIX_FMT_YUV420P;// PIX_FMT_YUV420P;

	//m_pParser = av_parser_init(CODEC_ID_H264);
    
   
	int iRet = -1;
	{
		CAutoLockSDLMutex lock(&gBaseSDLMutex);

		iRet = avcodec_open2(m_pDCodecCtx, m_pDCodec, NULL);
	}

	if( iRet < 0)
	{
		if(m_pDPicture != NULL)
		{
            av_frame_free(&m_pDPicture);
			//av_free(m_pDPicture) ;
			m_pDPicture = NULL;
		}
		if(m_pDCodecCtx != NULL)
		{
            avcodec_free_context(&m_pDCodecCtx);
			// av_free(m_pDCodecCtx);
			m_pDCodecCtx = NULL;
		}
		return bRet;
	}
	
	m_iDecodeErrorCount = 0 ;
	m_iChannel = iChannel;

	m_bInitDecode = true ;
	bRet = true;

#ifdef _DEBUG
	//CLog::Out(__FILE__, __LINE__, "channel %d start decode\r\n", m_iChannel);
#endif

	return bRet;
}

//停止解码器
void CVideoDecode::StopDecode()
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	if(m_bInitDecode) 
	{
		try
		{
			if(m_pDPicture != NULL)
			{
				//av_free(m_pDPicture) ;
                av_frame_free(&m_pDPicture);
				m_pDPicture = NULL;
			}
			if(m_pDCodecCtx != NULL)
			{
				{
					CAutoLockSDLMutex lock(&gBaseSDLMutex);
					avcodec_close(m_pDCodecCtx);
				}
                
				//av_free(m_pDCodecCtx) ;
                avcodec_free_context(&m_pDCodecCtx);
				m_pDCodecCtx = NULL;
			}
			m_pDCodec = NULL;

			m_iDecodeErrorCount = 0;
			m_bInitDecode = false ;
#ifdef _DEBUG
			//CLog::Out(__FILE__, __LINE__, "channel %d stop decode\r\n", m_iChannel);
#endif
			m_iChannel = -1;
		}
		catch(...)
		{
#ifdef _DEBUG
			//CLog::Out(__FILE__, __LINE__, "channel %d stop decode error\r\n", m_iChannel);
#endif
		}
	}
}

int CVideoDecode::Decode(unsigned char *szImage, int nImageLen, AVFrame** ppAVFrame)
{
	int iRet = -1;
    
    static int max_length = 0;
    if (max_length < nImageLen) {
        max_length = nImageLen;
        //printf("maxLength  = %d\n",max_length);
    }
    
    
    
	if(szImage == NULL || nImageLen <= 0 || ppAVFrame == NULL)
		return iRet;

	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	if(!m_bInitDecode)
		return iRet;

	if(m_pDCodecCtx == NULL || m_pDPicture == NULL)
		return iRet;

	*ppAVFrame = NULL;
	try
	{
		// 是否获得一个完整帧
		int frameFinished = 0;
		// 测试帧数据完整性
		//av_parser_parse2
        AVPacket pkt;
        av_init_packet(&pkt);
        pkt.data = szImage;
        pkt.size = nImageLen;
        
        
		iRet = avcodec_decode_video2(m_pDCodecCtx, m_pDPicture, &frameFinished, &pkt);
         
    
        
        //av_free_packet(&pkt);
		//if(frameFinished)
		//{
		//	*ppAVFrame = m_pDPicture;
		//	m_iDecodeErrorCount = 0 ;//解码出错复位
		//}
		//else
		//{
		//	iRet = -1;
		//	m_iDecodeErrorCount++ ;
		//}

		if(iRet > 0)
		{
			if(frameFinished)
			{
				*ppAVFrame = m_pDPicture;
				m_iDecodeErrorCount = 0 ;//解码出错复位
			} 
			else
			{
				iRet = -1;
//				m_iDecodeErrorCount++ ;
//#ifdef _DEBUG
//				//CLog::Out(__FILE__, __LINE__, "decode error data len %d frame type %d\r\n", nImageLen, szImage[4]);
//#endif
			}
		}
		else
		{
#ifdef _DEBUG
			//CLog::Out(__FILE__, __LINE__, "decode error data len %d frame type %d\r\n", nImageLen, szImage[4]);
#endif
			iRet = -1;
			m_iDecodeErrorCount++ ;
		}
	}
	catch(...)
	{
		iRet = -1;
		m_iDecodeErrorCount++ ;  //解码出错

#ifdef _DEBUG
		char szTrace[255] ;
		sprintf(szTrace,"Decodec Video Length %d\r\n", iRet) ;
		//OutputDebugString(szTrace) ;
		//::OutputDebugString("解码异常\r\n") ;
		//CLog::Out(__FILE__, __LINE__, "video decode error data len %d frame type %d\r\n", nImageLen, szImage[4]);
		//int iWidth = 0;
		//int iHeight = 0;
		//GetRect(iWidth, iHeight);
		//CLog::Out(__FILE__, __LINE__, "width %d height %d pix_fmt %d\r\n", iWidth, iHeight, GetPixFmt());
#endif
        
		StopDecode();
	}

	return iRet;
}

void CVideoDecode::GetRect(int& iWidth, int& iHeight)
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	if(!m_bInitDecode || m_pDCodecCtx == NULL)
		return;

	iWidth = m_pDCodecCtx->width;
	iHeight = m_pDCodecCtx->height;
}

AVPixelFormat CVideoDecode::GetPixFmt()
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	if(!m_bInitDecode || m_pDCodecCtx == NULL)
		return AV_PIX_FMT_NONE;

	return m_pDCodecCtx->pix_fmt;
}

bool CVideoDecode::IsStarted()
{
	CAutoLockSDLMutex lock(&fBaseSDLMutex);

	return m_bInitDecode;
}
