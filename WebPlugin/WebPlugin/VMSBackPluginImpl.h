#pragma once

#include "config.h"
#include "vms_net_client.h"
#include "net_io.h"
#include "AvViewLayout.h"
#include <boost/thread/recursive_mutex.hpp>
class VMSBackPluginEvent
{
public:
	virtual void OnLoginCompleted(int error) = 0;
	virtual void OnNetDisconnect() = 0;
	virtual void OnOpenVideo(unsigned int result) = 0;
	virtual void OnOpenAudio(unsigned int vid, unsigned int result) = 0;
	virtual void OnPlayProgress(unsigned int vid, time_t cur_tm) = 0;
};

class VMSBackPluginImpl:public AvViewLayoutEvent
{
public:
    VMSBackPluginImpl(VMSBackPluginEvent* event,void *pluginLayer);
	VMSBackPluginImpl(VMSBackPluginEvent* event);
	~VMSBackPluginImpl(void);

	virtual vms_result_t login(const std::string& server, short port, const std::string& name, const std::string& pwd);
	virtual void logoff();
	virtual void FullScreen();
	virtual void CancelFullSrceen();
	virtual std::string OpenVideo(const std::string& xml);
	virtual std::string CloseVideo();
	virtual std::string Snapshot(const std::string& xml);
	virtual std::string OpenAudio();
	virtual std::string CloseAudio();

	virtual void SetPlaySpeed(double speed);
	virtual void SetPlayBeginTime(long video_id, const std::string& beginTime);

#ifdef _WIN32
    virtual LRESULT OnCreate(HWND wnd);
    virtual LRESULT OnPaint();
    virtual LRESULT OnSize(WPARAM wparam, LPARAM lparam);
#endif
	
	virtual void OnViewSelected(int selectIndex);
private:
	VMSBackPluginEvent* vmsBackPluginEvent;

	class VmsNetClientCallback: public vms_client_cb,
		public boost::enable_shared_from_this<VmsNetClientCallback>
	{
	public:
		VmsNetClientCallback(VMSBackPluginImpl* impl)
		{
			vmsPluginBackImpl = impl;
		}
		virtual void on_login_completed(vms_result_t error);
		virtual void on_net_disconnect();
		virtual void on_open_video(unsigned int vid, unsigned int result);
		virtual void on_recv_av_data(VMS_COMMAND* cmd);
		virtual void on_open_audio(unsigned int vid, unsigned int result);
	private:
		VMSBackPluginImpl* vmsPluginBackImpl;
	};

private:
	boost::shared_ptr<vms_net_client> vmsNetClient;
	boost::shared_ptr<VmsNetClientCallback> vmsClientCb;

	AvViewLayout avViewLayout;

	int videoStatus;

	std::map<unsigned int, time_t> playProgressMap;
};

inline void FormatTime(time_t time1, char *szTime)  
{  
	struct tm tm1;  

#ifdef _WIN32  
	tm1 = *localtime(&time1);  
#else  
	localtime_r(&time1, &tm1 );  
#endif  
	sprintf( szTime, "%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d",  
		tm1.tm_year+1900, tm1.tm_mon+1, tm1.tm_mday,  
		tm1.tm_hour, tm1.tm_min,tm1.tm_sec);  
}  