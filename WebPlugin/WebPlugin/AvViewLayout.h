#pragma once

#ifdef __APPLE__
#import "../../VidGridLayer/VidGridLayer/VidGridLayer.h"

#endif

#include "AvView.h"




class AvViewLayoutEvent
{
public:
	virtual void OnViewSelected(int selectIndex) = 0;
};

class AvViewLayout
{
public:
    AvViewLayout(AvViewLayoutEvent* event);
	AvViewLayout(AvViewLayoutEvent* event,void *pluginLayer);
	virtual ~AvViewLayout(void);
	AvView* GetViewByIndex(int index);
	AvView* GetView(int id);
	AvView* GetSelectedView();
	AvView* GetFreeView();
	
	void selectView(int index);
	void Relayout(int count);
	void Relayout(int hcount, int vcount);
	int GetHCount(){return horizontalCount;};
	int GetVCount(){return verticalCount;};
	int GetViewCount(){return horizontalCount*verticalCount;};
    
#ifdef __APPLE__
    void setPluginLayer(void *pluginLayer);
    void *pluginLayer();
#endif
    
#ifdef _WIN32
    LRESULT OnCreate(HWND wnd);
    LRESULT OnPaint();
#endif
private:
	AvView* views;

	int horizontalCount;
	int verticalCount;
	int selectIndex;


    void *_pluginLayer;

    
#ifdef _WIN32
    HWND pluginWnd;
    HPEN gridLinePen;
    HPEN selectedFrameLinePen;
#endif
	AvViewLayoutEvent* avViewLayoutEvent;
};
