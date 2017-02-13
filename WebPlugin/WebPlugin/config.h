#ifndef __VMS_CONFIG__
#define __VMS_CONFIG__

#include <time.h>

#ifdef _MSC_VER
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0501
#endif
#endif

typedef int	vms_result_t;

#define DEFAULT_HORIZONTAL_COUNT 1 
#define DEFAULT_VERTICAL_COUNT 1

#ifdef _WIN32
#define WM_VMS_EVENT (WM_USER+101)

#define VMS_LOGIN_EVENT 0
#define VMS_DISCONNECT_EVENT 1
#define VMS_OPEN_VIDEO_EVENT 2
#define VMS_OPEN_AUDIO_EVENT 3
#define VMS_ON_VIEW_SELECTED 4
#define VMS_ON_PLAY_PROGRESS 5

typedef struct OpenResultMsgParam 
{
	unsigned int vid;
	unsigned int result;
}OpenResultMsgParam;

typedef struct PlayProgressMsgParam 
{
	unsigned int vid;
	time_t cur_tm;
}PlayProgressMsgParam;

#endif


#endif