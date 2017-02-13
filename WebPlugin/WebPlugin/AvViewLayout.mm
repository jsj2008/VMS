//#include "StdAfx.h"
#include "AvViewLayout.h"
#include "common/vms_error.h"
//#include "vms_error.h"


#define GRID_LINE_WIDTH 1

#define GRID_LINE_COLOR RGB(255,255,255)

#define SELECTED_LINE_COLOR RGB(255,255,0)
#define DEFAULT_HORIZONTAL_COUNT 2
#define DEFAULT_VERTICAL_COUNT 2


AvViewLayout::AvViewLayout(AvViewLayoutEvent* event)
{
    views = NULL;
    horizontalCount = DEFAULT_HORIZONTAL_COUNT;
    verticalCount = DEFAULT_VERTICAL_COUNT;
    selectIndex = -1;
#ifdef _WIN32
    gridLinePen = CreatePen(PS_SOLID, GRID_LINE_WIDTH, GRID_LINE_COLOR);
    selectedFrameLinePen = CreatePen(PS_SOLID, GRID_LINE_WIDTH, SELECTED_LINE_COLOR);
#endif
    avViewLayoutEvent = event;
}

AvViewLayout::AvViewLayout(AvViewLayoutEvent* event,void *pluginLayer)
{
    views = NULL;
    horizontalCount = DEFAULT_HORIZONTAL_COUNT;
    verticalCount = DEFAULT_VERTICAL_COUNT;
    selectIndex = -1;
    avViewLayoutEvent = event;
    _pluginLayer = pluginLayer;
    
    if (_pluginLayer) {
        VidGridLayer *gridLayer = (__bridge VidGridLayer *)_pluginLayer;
        NSArray *subLayers = gridLayer.sublayers;
        views = new AvView[subLayers.count];
        for (int i = 0 ;i < subLayers.count;i++) {
            OpenGLVidGridLayer *openglVidLayer = subLayers[i];
            views[i].SetLayer((__bridge void *)openglVidLayer,i);
        }
        [gridLayer setPageSize:horizontalCount * verticalCount];
    }
}


AvViewLayout::~AvViewLayout(void)
{
	if(views)
		delete[] views;
	//DeleteObject (gridLinePen);
	//DeleteObject (selectedFrameLinePen);
}

//LRESULT AvViewLayout::OnCreate(HWND wnd)
//{
//	pluginWnd = wnd;
//	selectIndex = 0;
//
//	Relayout(DEFAULT_HORIZONTAL_COUNT, DEFAULT_VERTICAL_COUNT);
//	return S_OK;
//}

void AvViewLayout::Relayout(int count)
{
	if(count == 1)
	{
		Relayout(1, 1);
		return;
	}
	if(count <= 4)
	{
		Relayout(2, 2);
		return;
	}
	if(count <= 9)
	{
		Relayout(3, 3);
		return;
	}
	if(count <= 16)
	{
		Relayout(4, 4);
		return;
	}
}


#ifdef __APPLE__
void AvViewLayout::setPluginLayer(void *pluginLayer)
{
    pluginLayer = pluginLayer;
}

void *AvViewLayout::pluginLayer()
{
    return _pluginLayer;
}
#endif

void AvViewLayout::Relayout(int hcount, int vcount)
{
    horizontalCount = hcount;
    verticalCount = vcount;
#ifdef WIN32
	AvView* oldView = views;
	int oldTotalCount = horizontalCount*verticalCount;
	
	//destroy old view
	if(oldView)
	{
		for(int i=0; i<oldTotalCount; i++)
		{
			int id = oldView[i].GetId();
			if(id != INVALID_DEVICE_ID && i >= horizontalCount*verticalCount )
			{
				oldView[i].CloseAudio();
				oldView[i].CloseVideo();
			}
			//::DestroyWindow(oldView[i].GetWnd());
		}
	}

	//create all child view
	views = new AvView[verticalCount*horizontalCount];

	RECT rect;
	GetClientRect(pluginWnd, &rect);
	int w = rect.right / horizontalCount;
	int h = rect.bottom / verticalCount;

	for(int m=0; m<verticalCount; m++)
	{
		for(int n=0; n<horizontalCount; n++)
		{
			int index = m*verticalCount + n;

			//GRID_LINE_WIDTH is for draw grid line
			int x = w * n + GRID_LINE_WIDTH;
			int y = h * m +GRID_LINE_WIDTH;
			int wndWidth = w-GRID_LINE_WIDTH;
			int wndHeight = h-GRID_LINE_WIDTH;
			if(m == verticalCount-1) //bottom-most
				wndHeight -= GRID_LINE_WIDTH;
			if(n == horizontalCount-1) //right-most
				wndWidth -= GRID_LINE_WIDTH;

			views[index].CreateWnd(this, index, pluginWnd , x, y, wndWidth, wndHeight);
			if(index < oldTotalCount)//set old id to new child view,continue play old video
			{
				int id = oldView[index].GetId();
				if(id != INVALID_DEVICE_ID && oldView[index].GetVideoStatus() == VIDEO_STATUS_OPEN)
					views[index].initWithView(&oldView[index]);				
			}
		}
	}

	delete[] oldView;

	//reset selected view
	if(selectIndex >= horizontalCount*verticalCount)
	{
		selectIndex = 0;
		avViewLayoutEvent->OnViewSelected(selectIndex);
	}

	::InvalidateRect(pluginWnd, NULL, TRUE);
	::UpdateWindow(pluginWnd);
#endif
    
#ifdef __APPLE__
    if (pluginLayer()) {
        VidGridLayer *gridLayer = (__bridge VidGridLayer *)pluginLayer();
        [gridLayer setPageSize:hcount * vcount];
        [gridLayer layout:YES withCompletionBlock:^{
            [gridLayer setNeedsDisplay];
        }];
    }
#endif
}

AvView* AvViewLayout::GetViewByIndex(int index)
{
	return &views[index];
}

AvView* AvViewLayout::GetView(int id)
{
	for(int m=0; m<verticalCount; m++)
	{
		for(int n=0; n<horizontalCount; n++)
		{
			int index = m*verticalCount + n;
			if(views[index].GetId() == id)
				return &views[index];
		}
	}
	return NULL;
}

AvView* AvViewLayout::GetSelectedView()
{

#ifdef __APPLE__
    VidGridLayer *gridLayer = (__bridge VidGridLayer*)_pluginLayer;
    selectIndex = (int)gridLayer.keyPort;
#endif
    
    if(selectIndex == -1)
        return NULL;
    
	return &views[selectIndex];
}

AvView* AvViewLayout::GetFreeView()
{
	//current view is preferred 
	if(views[selectIndex].GetId() == INVALID_DEVICE_ID && views[selectIndex].GetVideoStatus() == VIDEO_STATUS_CLOSE)
		return &views[selectIndex];

	for(int m=0; m<verticalCount; m++)
	{
		for(int n=0; n<horizontalCount; n++)
		{
			int index = m*verticalCount + n;
			if(views[index].GetId() == INVALID_DEVICE_ID && views[index].GetVideoStatus() == VIDEO_STATUS_CLOSE)
				return &views[index];
		}
	}
	return NULL;
}


//void AvViewLayout::selectView(int index)
//{
//	if(selectIndex == index)
//		return;
//	selectIndex = index;
//	avViewLayoutEvent->OnViewSelected(selectIndex);
//	//redraw grid line
//	::InvalidateRect(pluginWnd, NULL, TRUE);
//	::UpdateWindow(pluginWnd);
//}

//LRESULT AvViewLayout::OnPaint()
//{
//	RECT rect;
//	GetClientRect(pluginWnd, &rect);
//	int w = rect.right / horizontalCount;
//	int h = rect.bottom / verticalCount;
//
//	PAINTSTRUCT ps;
//	HDC hdc = BeginPaint(pluginWnd , &ps );
//
//	//draw grid line
//	HPEN oldPen = (HPEN)SelectObject(hdc, gridLinePen);
//	for(int i=0; i<verticalCount; i++)
//	{
//		MoveToEx(hdc, 0, i*h, NULL);
//		LineTo(hdc, rect.right ,i*h);
//	}
//	MoveToEx(hdc, 0, verticalCount*h-1, NULL);
//	LineTo(hdc, rect.right , verticalCount*h-1);
//
//	for(int i=0; i<horizontalCount; i++)
//	{
//		MoveToEx(hdc, i*w, 0, NULL);
//		LineTo(hdc, i*w, rect.bottom);
//	}
//	MoveToEx(hdc, horizontalCount*w-1, 0, NULL);
//	LineTo(hdc, horizontalCount*w-1, rect.bottom);
//
//	//draw selected child view frame line
//	if(selectIndex != -1)
//	{
//		SelectObject(hdc, selectedFrameLinePen);
//		int vertical = selectIndex/horizontalCount;
//		int horizontal = (selectIndex % horizontalCount);
//
//		int x = w * horizontal;
//		int y = h*vertical;
//
//		int selectedWidth = w;
//		int selectedHeight = h;
//
//		if(vertical == verticalCount-1)//bottom-most
//			selectedHeight -= GRID_LINE_WIDTH;
//		if(horizontal == horizontalCount-1)//right-most
//			selectedWidth -= GRID_LINE_WIDTH;
//
//		MoveToEx(hdc, x, y, NULL);
//		LineTo(hdc, x+selectedWidth, y);
//		LineTo(hdc, x+selectedWidth, y+selectedHeight);
//		LineTo(hdc, x, y+selectedHeight);
//		LineTo(hdc, x, y);
//	}
//
//	SelectObject(hdc, oldPen);
//	EndPaint(pluginWnd, &ps);
//	return S_OK;
//}