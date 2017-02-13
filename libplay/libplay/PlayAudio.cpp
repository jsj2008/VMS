#include "PlayAudio.h"

//Buffer:
//|-----------|-------------|
//chunk-------pos---len-----|
static  Uint8  *audio_chunk; 
static  Uint32  audio_len; 
static  Uint8  *audio_pos; 
/* Audio Callback
* The audio function callback takes the following parameters: 
* stream: A pointer to the audio buffer to be filled 
* len: The length (in bytes) of the audio buffer 
* 
*/ 
void  fill_audio(void *udata,Uint8 *stream,int len){ 
	//SDL 2.0
	SDL_memset(stream, 0, len);
	if(audio_len==0)		/*  Only  play  if  we  have  data  left  */ 
		return; 
	len=(len>audio_len?audio_len:len);	/*  Mix  as  much  data  as  possible  */ 

	SDL_MixAudio(stream,audio_pos,len,SDL_MIX_MAXVOLUME);
	audio_pos += len; 
	audio_len -= len; 
} 


CPlayAudio::CPlayAudio():
fDataCount(0),
fStarted(false),
fChannel(1),
fSampleRate(8000),
fSamplebit(16),
fSample(480)
{
}

CPlayAudio::~CPlayAudio()
{
	Stop() ;
}

/*
int channel                通道      1,2 
int bitrate             波特率    8000 11025 22050 44100 等等
int samplebit          采样精度  8 ,16 ,24 ,32
*/
bool CPlayAudio::Start( int channel, int bitrate,int samplebit, int sample )
{
	CAutoLockSDLMutex lock(&fAudioBaseSDLMutex);

	if(fStarted)
		return false ;

	wanted_spec.format = AUDIO_S16SYS;
	switch(samplebit)
	{
	case 8:
		wanted_spec.format = AUDIO_S8;
		break;
	case 16:
		wanted_spec.format = AUDIO_S16SYS;
		break;
	}
	//SDL_AudioSpec
	wanted_spec.freq = bitrate;//44100; 
	wanted_spec.channels = channel; // 2
	wanted_spec.silence = 0; 
	wanted_spec.samples = sample;//1024; 
	//wanted_spec.size = sample*channel;
	wanted_spec.callback = fill_audio; 

	if (SDL_OpenAudio(&wanted_spec, NULL)<0){ 
		//printf("can't open audio.\n");
		return false; 
	} 

	fChannel = channel;
	fSamplebit = samplebit;
	fSampleRate = bitrate;
	fSample = sample;

	fStarted = true ;

	return true ;
}

/*
功能: 往播放句柄加入声音数据块
unsigned char *szSound    音频数据块
int           nSoundLen   该数据块长度      
*/
void CPlayAudio::Play(unsigned char *buffer, int bufferLen)
{
	if(buffer == NULL || bufferLen <= 0)
		return;

	CAutoLockSDLMutex lock(&fAudioBaseSDLMutex);
	
	if(!fStarted)
		return ;

	fDataCount += bufferLen;
	//Set audio buffer (PCM data)
	audio_chunk = (Uint8 *)buffer; 
	//Audio buffer length
	audio_len = bufferLen;
	audio_pos = audio_chunk;
	//Play
	SDL_PauseAudio(0);
	while(audio_len>0)//Wait until finish
		SDL_Delay(1); 
}

void CPlayAudio::Stop()
{
	CAutoLockSDLMutex lock(&fAudioBaseSDLMutex);

	if(!fStarted)
		return ;

	SDL_CloseAudio();

	fStarted = false ;
}

bool CPlayAudio::IsStart()
{
	CAutoLockSDLMutex lock(&fAudioBaseSDLMutex);

	return fStarted;
}