#pragma once

#include "config.h"
#include <string>

#ifdef __APPLE__
#import <Cocoa/Cocoa.h>
#import "../../VidGridLayer/VidGridLayer/VidGridLayer.h"
#import "NSImage+Flip.h"
#import "PluginFullScreenWindowController.h"
#endif


#define INVALID_DEVICE_ID -1

#define VIDEO_STATUS_CLOSE 0
#define VIDEO_STATUS_CONNECTING 1
#define VIDEO_STATUS_OPEN 2

#define AUDIO_STATUS_CLOSE 0
#define AUDIO_STATUS_CONNECTING 1
#define AUDIO_STATUS_OPEN 2

class AvViewLayout;

typedef enum PLUGIN_VIDEO_TYPE
{
	PLUGIN_VIDEO_LIVE,
	PLUGIN_VIDEO_BACK,
}PLUGIN_VIDEO_TYPE;

#define MAX_VIDEO_VIEW_COUNT 16

class AvView
{
public:
	AvView(void);
	virtual ~AvView(void);

	int GetId(){return id;};
	void SetId(int id);
	void initWithView(AvView* view);
	int GetVideoStatus(){return videoStatus;};
	int GetAudioStatus(){return audioStatus;};
	void OpenVideo();
	void CloseVideo();
	void OnOpenVideo(int result, PLUGIN_VIDEO_TYPE video_type, int play_type);
	void OpenAudio();
	void CloseAudio();
	void OnOpenAudio(int result);
	vms_result_t Snapshot(const std::string& filePath);
	void on_recv_av_data(int cmd, const char* data, int data_len, double timestamp);
	bool IsFullScreen(){return isFullScreen;};
	void FullScreen(bool fullScreen);
    bool IsVideoOpen();
#ifdef __APPLE__
    void SetLayer(void *layer,int index);
    int GetLayer(void**);
    PluginFullScreenWindowController *pfswc(void);
#endif
#ifdef _WIN32
    HWND GetWnd(){return wnd;};
    void CreateWnd(AvViewLayout* layout, int index, HWND parent, int x, int y, int w, int h);
    void LeftBtnDown(WPARAM wParam, LPARAM lParam);
    void LeftBtnDBClick(WPARAM wParam, LPARAM lParam);
#endif
    int GetPlayPort();
private:
	int id;
#ifdef _WIN32
    HWND wnd;
    WINDOWPLACEMENT windowPlacement;
    HWND parentWnd;
#endif
    
#ifdef __APPLE__
    void *_layer;
    PluginFullScreenWindowController *_pfswc;
#endif
    int layoutIndex;
    AvViewLayout* avViewLayout;
	bool isFullScreen;
	int videoStatus;
	int audioStatus;

	PLUGIN_VIDEO_TYPE videoType;
private:
#ifdef _WIN32
    ATOM AvView::RegisterWndClass();
#endif
	
};
