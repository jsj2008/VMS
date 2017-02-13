#pragma once

#include "config.h"
#include "vms_net_client.h"
#include "net_io.h"
#include "AvViewLayout.h"
#include <boost/thread/recursive_mutex.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>

class VMSLivePluginEvent
{
public:
	virtual void OnLoginCompleted(int error) = 0;
	virtual void OnNetDisconnect() = 0;
	virtual void OnOpenVideo(unsigned int vid, unsigned int result) = 0;
	virtual void OnOpenAudio(unsigned int vid, unsigned int result) = 0;
	virtual void OnViewSelected(int selectIndex) = 0;
};

class VMSLivePluginImpl:public AvViewLayoutEvent
{
public:
    VMSLivePluginImpl(VMSLivePluginEvent* event,void *pluginLayer);
	VMSLivePluginImpl(VMSLivePluginEvent* event);
	virtual ~VMSLivePluginImpl(void);

	virtual vms_result_t login(const std::string& server,
                               short port,
                               const std::string& name,
                               const std::string& pwd);
	virtual void logoff();
	virtual void FullScreen();
	virtual void CancelFullSrceen();
	virtual std::string OpenVideo(const std::string& xml);
	virtual std::string CloseVideo();
	virtual std::string Snapshot(const std::string& xml);
	virtual std::string OpenAudio();
	virtual std::string CloseAudio();
	virtual std::string GetCurViewInfo();
	virtual void PtzControll(const std::string& xml);
	virtual void CloseAllVideo();
    void Relayout(int hcount, int vcount);
    virtual void OnViewSelected(int selectIndex);
    
#ifdef _WIN32
    virtual LRESULT OnCreate(HWND wnd);
    virtual LRESULT OnPaint();
    virtual LRESULT OnSize(WPARAM wparam, LPARAM lparam);
#endif
private:
	class VmsClientCallback: public vms_client_cb,
		public boost::enable_shared_from_this<VmsClientCallback>
	{
	public:
		VmsClientCallback(VMSLivePluginImpl* impl)
		{
			vmsPluginLiveImpl = impl;
		}
		virtual void on_login_completed(vms_result_t error);
		virtual void on_net_disconnect();
		virtual void on_open_video(unsigned int vid, unsigned int result);
		virtual void on_recv_av_data(VMS_COMMAND* cmd);
		virtual void on_open_audio(unsigned int vid, unsigned int result);
	private:
		VMSLivePluginImpl* vmsPluginLiveImpl;
	};
private:
	boost::shared_ptr<vms_net_client> vmsNetClient;
	boost::shared_ptr<VmsClientCallback> vmsClientCb;

	AvViewLayout avViewLayout;
	VMSLivePluginEvent* vmsPluginLiveEvent;
};
