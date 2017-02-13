#include "Faaddec.h"
#include <memory.h>


#ifndef NULL
#define  NULL 0
#endif

/**
* fetch one ADTS frame
*/
//int get_one_ADTS_frame(unsigned char* buffer, size_t buf_size, unsigned char* data ,size_t* data_size)
//{
//	size_t size = 0;
//
//	if(!buffer || !data || !data_size )
//	{
//		return -1;
//	}
//
//	while(1)
//	{
//		if(buf_size  < 7 )
//		{
//			return -1;
//		}
//
//		if((buffer[0] == 0xff) && ((buffer[1] & 0xf0) == 0xf0) )
//		{
//			size |= ((buffer[3] & 0x03) <<11);     //high 2 bit
//			size |= buffer[4]<<3;                //middle 8 bit
//			size |= ((buffer[5] & 0xe0)>>5);        //low 3bit
//			break;
//		}
//		--buf_size;
//		++buffer;
//	}
//
//	if(buf_size < size)
//	{
//		return -1;
//	}
//
//	memcpy(data, buffer, size);
//	*data_size = size;
//
//	return 0;
//}

//long get_frame_length(unsigned char *aac_header) 
//{
//	unsigned long len = *(unsigned long *)(aac_header + 3);
//	len = ntohl(len); //Little Endian
//	len = len << 6;
//	len = len >> 19;
//	return len;
//}

CFaaddec::CFaaddec(void):
fDecoder(NULL),
fSamplerate(0),
fChannels(0)
{
}

CFaaddec::~CFaaddec(void)
{
}

bool CFaaddec::init( unsigned char* buffer, long bufferLen )
{
	/*unsigned long cap = */NeAACDecGetCapabilities();
	fDecoder = NeAACDecOpen();
	if (!fDecoder) {
		free();
		return false;
	}

	NeAACDecConfigurationPtr conf = NeAACDecGetCurrentConfiguration(fDecoder);
	if (!conf) {
		free();
		return false;
	}
	NeAACDecSetConfiguration(fDecoder, conf);

	long res = NeAACDecInit(fDecoder, (unsigned char *)buffer, bufferLen, &fSamplerate, &fChannels);
	if (res < 0) 
	{
		free();
		return false;
	}

	return true;
}

bool CFaaddec::free()
{
	if (fDecoder != NULL)
	{
		NeAACDecClose(fDecoder);
		fDecoder = NULL;
	}

	return true;
}


long CFaaddec::decoder( unsigned char* buffer, long bufferLen, unsigned char* decBuffer )
{
	if (buffer == NULL || (bufferLen <= 4))
	{
		return -1;
	}

	if (!fDecoder) 
	{
		if (init(buffer, bufferLen) == false) 
		{
			return -1;
		}
	}

	mp4AudioSpecificConfig c;
	/*char r = */NeAACDecAudioSpecificConfig(buffer, bufferLen, &c);

	NeAACDecFrameInfo frameInfo;
	
	// unsigned char* pcm_data = (unsigned char*)NeAACDecDecode(fDecoder, &frameInfo, buffer, bufferLen); 
	
	unsigned char* pcm_data = (unsigned char*)NeAACDecDecode2(fDecoder, &frameInfo, buffer, bufferLen, (void**)&decBuffer, AAC_BUFFER_SIZE); 

	if (pcm_data && frameInfo.error == 0 && frameInfo.samples > 0) 
	{
		long tmplen = frameInfo.samples * frameInfo.channels;
		//memcpy(decBuffer, pcm_data, tmplen);

		return tmplen;

		//if (frameInfo.samplerate == 44100) 
		//{
		//	//44100Hz
		//	//src: 2048 samples, 4096 bytes
		//	//dst: 2048 samples, 4096 bytes
		//	uint32_t tmplen = frameInfo.samples * fFrameInfo.channels;
		//	memcpy(decBuffer, pcm_data, tmplen);

		//	return tmplen;
		//} 
		//else if (info.samplerate == 22050) 
		//{
		//	//22050Hz
		//	//src: 1024 samples, 2048 bytes
		//	//dst: 2048 samples, 4096 bytes
		//	short *ori = (short*)pcm_data;
		//	short tmpbuf[frameInfo.samples * frameInfo.channels];
		//	uint32_t tmplen = frameInfo.samples * 16 / 8 * 2;
		//	for (int32_t i = 0, j = 0; i < info.samples; i += 2) 
		//	{
		//		tmpbuf[j++] = ori[i];
		//		tmpbuf[j++] = ori[i + 1];
		//		tmpbuf[j++] = ori[i];
		//		tmpbuf[j++] = ori[i + 1];
		//	}
		//}
	} 

	return -1;
}