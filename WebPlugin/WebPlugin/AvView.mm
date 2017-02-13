//#include "StdAfx.h"
#include "AvView.h"
#include "AvViewLayout.h"
//#include "../../../libplay/libplay/avplay_sdk.h"
#include "../../libplay/libplay/avplay_sdk.h"
//#include "avplay_sdk.h"
#include "config.h"
#include "common/vms_command.h"
//#include "vms_command.h"



#define AV_WINDOW_CLASS _T("AV_WINDOW_CLASS")
#define MAX_LIVE_PLAY_SDK_CHANNEL		198
#define MAX_BACK_PLAY_SDK_CHANNEL		(MAX_LIVE_PLAY_SDK_CHANNEL-MAX_VIDEO_VIEW_COUNT)


#ifdef _WIN32
extern HINSTANCE g_hInstance;
#endif



#ifdef __APPLE__

static bool shouldEnterFullScreen(void *userData,void *mouseDownLayer)
{
    AvView *view = (AvView *)userData;
    if (view) {
        void *layer = NULL;
        if (view->GetLayer(&layer) >= 0)
            return (layer == mouseDownLayer) && (view->IsVideoOpen());
    }
    
    return false;
}

static bool saveAsBmpWithName(NSImage *img,NSString *fileName)
{
    NSData *imageData = [img TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSBMPFileType properties:imageProps];
    return [imageData writeToFile:fileName atomically:NO];
}

static void flipImageVertically(NSImage *img)
{
    NSAffineTransform *flipper = [NSAffineTransform transform];
    NSSize dimensions = img.size;
    [img lockFocus];
    
    [flipper scaleXBy:1.0 yBy:-1.0];
    [flipper set];
    
    [img drawAtPoint:NSMakePoint(0,-dimensions.height)
             fromRect:NSMakeRect(0,0, dimensions.width, dimensions.height)
            operation:NSCompositeCopy fraction:1.0];
    
    [img unlockFocus];
}

static void render(const void *data,
                   int lineSize,
                   int port,
                   int videoW,
                   int videoH,
                   void *userData)
{
    AvView *view = (AvView *)userData;
    if (view) {
        void *temp = NULL;
        if (view->GetLayer(&temp) >= 0) {
            OpenGLVidGridLayer *layer = (__bridge OpenGLVidGridLayer *)temp;
           
            dispatch_async(dispatch_get_main_queue(), ^{
                [layer setNeedsDisplay];
            });
            
            //通知全屏窗口控制器渲染全屏窗口
            PluginFullScreenWindowController *pfswc = view->pfswc();
            [pfswc renderWithData:data
                         lineSize:lineSize
                           videoW:videoW
                           videoH:videoH];
        }
    }
}

static bool saveBmp(const void *data,
                    int videoW,
                    int videoH,
                    int lineSize,
                    const char *path,
                    unsigned int snapType,
                    void *userData)
{
    AvView *view = (AvView *)userData;
    
    if (view) {
        //转换为NSImage
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CFDataRef imgData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
                                                        (const UInt8 *)data,
                                                        lineSize*videoH,
                                                        kCFAllocatorNull);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(imgData);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGImageRef cgImage = CGImageCreate(videoW,
                                           videoH,
                                           8,
                                           24,
                                           lineSize,
                                           colorSpace,
                                           bitmapInfo,
                                           provider,
                                           NULL,
                                           NO,
                                           kCGRenderingIntentDefault);
        CGColorSpaceRelease(colorSpace);
        NSImage *img = [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(videoW, videoH)];
        CGImageRelease(cgImage);
        CGDataProviderRelease(provider);
        CFRelease(imgData);
        
        flipImageVertically(img);
        
        NSString *pathName = [NSString stringWithUTF8String:path];
        NSString *dir = [pathName stringByDeletingLastPathComponent];
        NSFileManager *manager = [NSFileManager defaultManager];
        
        NSLog(@"path=%@,dir=%@",pathName,dir);
        if (![manager fileExistsAtPath:dir]) {
            NSError *error;
            [manager createDirectoryAtPath:dir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
            
            if (error) {
                NSLog(@"Errpr:%@",error);
                return false;
            }
        } else {
            NSLog(@"抓拍目录已存在");
        }
        
        return saveAsBmpWithName(img, pathName);
    }
    
    return false;
}


#endif



AvView::AvView(void)
{
	//wnd = NULL;
	id = INVALID_DEVICE_ID;
	isFullScreen = false;
	videoStatus = VIDEO_STATUS_CLOSE;
	audioStatus = AUDIO_STATUS_CLOSE;
	videoType = PLUGIN_VIDEO_LIVE;
}

AvView::~AvView(void)
{
}


#ifdef __APPLE__
void AvView::SetLayer(void *layer,int index)
{
    _layer = layer;
    layoutIndex = index;
    if (!_pfswc) {
        _pfswc = [[PluginFullScreenWindowController alloc] init];
        [_pfswc registCallback:shouldEnterFullScreen userData:this];
    }
}

int AvView::GetLayer(void**pLayer)
{
    if (_layer) {
        *pLayer = _layer;
        return layoutIndex;
    }
    
    return -1;
}

PluginFullScreenWindowController *AvView::pfswc(void)
{
    return _pfswc;
}
#endif

bool AvView::IsVideoOpen()
{
    return videoStatus == VIDEO_STATUS_OPEN;
}

void AvView::FullScreen(bool fullScreen)
{
#ifdef _WIN32
    if(isFullScreen && fullScreen == false)
    {
        SetWindowPlacement(wnd, &windowPlacement);
        ::SetParent(wnd,parentWnd);
        isFullScreen = false;
    }
    else
    {
        if(videoStatus != VIDEO_STATUS_OPEN)
            return;
        
        GetWindowPlacement(wnd, &windowPlacement);
        ::SetParent(wnd,::GetDesktopWindow());
        
        int cx = ::GetSystemMetrics(SM_CXSCREEN);
        int cy = ::GetSystemMetrics(SM_CYSCREEN);
        
        WINDOWPLACEMENT	 wp;
        ZeroMemory(&wp, sizeof(WINDOWPLACEMENT));
        wp.length	 =	sizeof(WINDOWPLACEMENT);
        wp.showCmd	 =	SHOW_FULLSCREEN;
        wp.rcNormalPosition.left	=	0;
        wp.rcNormalPosition.top	=	0;
        wp.rcNormalPosition.right	=	cx;
        wp.rcNormalPosition.bottom =	cy;
        SetWindowPlacement(wnd, &wp);
        
        MoveWindow(wnd, 0, 0, cx, cy, TRUE);
        ::SetWindowPos(wnd, HWND_TOPMOST, 0, 0, cx, cy, SWP_FRAMECHANGED|SWP_DEFERERASE); 
        isFullScreen = true;
        
        SetActiveWindow(wnd);
    }
#endif
    
#ifdef __APPLE__
    [this->_pfswc toggleFullScreen];
    //this->isFullScreen = [this->_pfswc isInFullScreenMode];
#endif
}



#ifdef _WIN32
void AvView::LeftBtnDBClick(WPARAM wParam, LPARAM lParam)
{
    FullScreen(!isFullScreen);
}

void AvView::LeftBtnDown(WPARAM wParam, LPARAM lParam)
{
	avViewLayout->selectView(layoutIndex);
}

LRESULT CALLBACK AvWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_LBUTTONDOWN:
        {
            AvView* v = (AvView*)::GetWindowLong(hWnd, GWL_USERDATA);//SetWindowLong in CreateWnd
            v->LeftBtnDown(wParam, lParam);
        }
            break;
        case WM_LBUTTONDBLCLK:
        {
            AvView* v = (AvView*)::GetWindowLong(hWnd, GWL_USERDATA);//SetWindowLong in CreateWnd
            v->LeftBtnDBClick(wParam, lParam);
        }
            break;
        case WM_ERASEBKGND:
        {
            RECT rect;
            GetClientRect(hWnd, &rect);
            
            HDC dc = GetDC(hWnd);
            static HBRUSH hbrBackground = CreateSolidBrush(RGB(0, 0, 0));
            HBRUSH odlBrush = (HBRUSH)SelectObject(dc, hbrBackground);
            Rectangle(dc, rect.left, rect.top, rect.right, rect.bottom);
            SelectObject(dc, odlBrush);
            ReleaseDC(hWnd, dc);
        }
            return 1;
        default:
            return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

ATOM AvView::RegisterWndClass()
{
    WNDCLASSEX wcex;
    
    wcex.cbSize = sizeof(WNDCLASSEX);
    
    wcex.style			= CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS;
    wcex.lpfnWndProc	= AvWndProc;
    wcex.cbClsExtra		= 0;
    wcex.cbWndExtra		= 0;
    wcex.hInstance		= g_hInstance;
    wcex.hIcon			= NULL;
    wcex.hCursor		= LoadCursor(NULL, IDC_ARROW);
    wcex.hbrBackground	= NULL;
    wcex.lpszMenuName	= NULL;
    wcex.lpszClassName	= AV_WINDOW_CLASS;
    wcex.hIconSm		= NULL;
    
    return RegisterClassEx(&wcex);
}

void AvView::CreateWnd(AvViewLayout* layout, int index,HWND parent, int x, int y, int w, int h)
{
    avViewLayout = layout;
    layoutIndex = index;
    parentWnd = parent;
    
    RegisterWndClass();
    wnd = CreateWindow(AV_WINDOW_CLASS, _T(""), WS_CHILD|WS_VISIBLE, x, y, w, h, parent, NULL, g_hInstance,	NULL);
    ::SetWindowLong(wnd, GWL_USERDATA, (LONG)this);
    
    ::InvalidateRect(wnd, NULL, TRUE);
    ::UpdateWindow(wnd);
}
#endif


void AvView::SetId(int id)
{
	this->id = id;
}

void AvView::OpenAudio()
{
	if(audioStatus == AUDIO_STATUS_CLOSE)
	{
		audioStatus = AUDIO_STATUS_CONNECTING;
	}
}
void AvView::CloseAudio()
{
	if(audioStatus == AUDIO_STATUS_CONNECTING || audioStatus == AUDIO_STATUS_OPEN)
	{
		audioStatus = AUDIO_STATUS_CLOSE;
	}
}
void AvView::OnOpenAudio(int result)
{
	if(audioStatus == AUDIO_STATUS_CONNECTING)
	{
		if(result == VMS_SUCCESS)
			audioStatus = AUDIO_STATUS_OPEN;
		else
			videoStatus = VIDEO_STATUS_CLOSE;
	}
}

void AvView::OpenVideo()
{
	if(videoStatus == VIDEO_STATUS_CLOSE)
	{
		videoStatus = VIDEO_STATUS_CONNECTING;
	}
}

int AvView::GetPlayPort()
{
	if(videoType == PLUGIN_VIDEO_LIVE)
		return MAX_LIVE_PLAY_SDK_CHANNEL - layoutIndex;
	else
		return MAX_BACK_PLAY_SDK_CHANNEL - layoutIndex;
}

void AvView::OnOpenVideo(int result, PLUGIN_VIDEO_TYPE video_type, int play_type)
{
	if(videoStatus == VIDEO_STATUS_CONNECTING)
	{
		if(result == VMS_SUCCESS)
		{	
			videoType = video_type;
			videoStatus = VIDEO_STATUS_OPEN;
#ifdef _WIN32
            AVPLAY_Play(GetPlayPort(), wnd);
#endif
            
#ifdef __APPLE__
            AVPLAY_Play(GetPlayPort(), NULL, NULL,NULL,this);
#endif
            
			AVPLAY_SetPlayType(GetPlayPort(), play_type);
		}
		else
		{
			videoStatus = VIDEO_STATUS_CLOSE;
			id = INVALID_DEVICE_ID;
		}
	}
}

void AvView::CloseVideo()
{
	if(videoStatus == VIDEO_STATUS_CONNECTING || videoStatus == VIDEO_STATUS_OPEN)
	{
		audioStatus = AUDIO_STATUS_CLOSE;
		videoStatus = VIDEO_STATUS_CLOSE;
		id = INVALID_DEVICE_ID;
		AVPLAY_Stop(GetPlayPort());
#ifdef __APPLE__
        void *temp = NULL;
        if (this->GetLayer(&temp) >= 0) {
            OpenGLVidGridLayer *gridLayer = (__bridge OpenGLVidGridLayer *)temp;
            [gridLayer clear];
        }
#endif
	}
}

void AvView::on_recv_av_data(int cmd, const char* data, int data_len, double timestamp)
{
	if(videoStatus == VIDEO_STATUS_OPEN)
	{
		if(cmd == VMS_CMD_VIDEO_DATA)
			AVPLAY_InputVideoData(GetPlayPort(), (unsigned char*)data, data_len, timestamp);
		else if(cmd == VMS_CMD_AUDIO_DATA)
			AVPLAY_InputAudioData(GetPlayPort(), (unsigned char*)data, data_len, timestamp);
	}
}

vms_result_t AvView::Snapshot(const std::string& filePath)
{
	if(AVPLAY_Snap(GetPlayPort(), (char*)filePath.c_str(), 1,0))
		return VMS_SUCCESS;
	else
		return VMS_SNAPSHOT_FAILED;
}

void AvView::initWithView(AvView* view)
{
	id = view->GetId();
	videoStatus = view->GetVideoStatus();
	audioStatus = view->GetAudioStatus();
	videoType = view->videoType;
#if _WIN32
    if(videoStatus == VIDEO_STATUS_OPEN) //reset the video play window
        AVPLAY_SetPlayWnd(GetPlayPort(), wnd);
#endif
}
