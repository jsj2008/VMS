#ifdef WIN32
#include "StdAfx.h"
#endif

#include "VMSLivePluginImpl.h"
#include "PluginXml.h"
#include "common/vms_error.h"
#include "common/ptz_xml_parser.h"
//#include "../../../libplay/libplay/avplay_sdk.h"
#include "../../libplay/libplay/avplay_sdk.h"
void PluginInit()
{
    static bool init = true;
    if(init)
    {
        net_io::instance().init();
        AVPLAY_Init();
        init = false;
    }
}

VMSLivePluginImpl::VMSLivePluginImpl(VMSLivePluginEvent* event)
	:avViewLayout(this)
{
	PluginInit();

	vmsPluginLiveEvent = event;
	boost::asio::io_service& service = *(boost::asio::io_service*)net_io::instance().get_io_service();
	vmsNetClient = boost::shared_ptr<vms_net_client>( new vms_net_client(service) );
	vmsClientCb = boost::shared_ptr<VmsClientCallback>( new VmsClientCallback(this) );
	vmsNetClient->add_client_cb(vmsClientCb->shared_from_this());
}

VMSLivePluginImpl::VMSLivePluginImpl(VMSLivePluginEvent* event,void *pluginLayer)
    :avViewLayout(this,pluginLayer)
{
    PluginInit();
    
    vmsPluginLiveEvent = event;
    boost::asio::io_service& service = *(boost::asio::io_service*)net_io::instance().get_io_service();
    vmsNetClient = boost::shared_ptr<vms_net_client>( new vms_net_client(service) );
    vmsClientCb = boost::shared_ptr<VmsClientCallback>( new VmsClientCallback(this) );
    vmsNetClient->add_client_cb(vmsClientCb->shared_from_this());
}

VMSLivePluginImpl::~VMSLivePluginImpl(void)
{
	CloseAllVideo();
	vmsNetClient->logoff();
	vmsNetClient.reset();
}

vms_result_t VMSLivePluginImpl::login(const std::string& server, short port, const std::string& name, const std::string& pwd)
{
	//two thread in plugin, windows message loop thread and net io thread
	//so use mutex to lock the plugin
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	return vmsNetClient->login(server, port, name, pwd);
}

void VMSLivePluginImpl::logoff()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	vmsNetClient->logoff();
}

#ifdef _WIN32
LRESULT VMSLivePluginImpl::OnCreate(HWND wnd)
{
    boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
    avViewLayout.OnCreate(wnd);
    return S_OK;
}

LRESULT VMSLivePluginImpl::OnPaint()
{
    boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
    avViewLayout.OnPaint();
    return S_OK;
}

LRESULT VMSLivePluginImpl::OnSize(WPARAM wparam, LPARAM lparam)
{
    boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
    avViewLayout.Relayout(avViewLayout.GetHCount(), avViewLayout.GetVCount());
    return S_OK;
}
#endif


void VMSLivePluginImpl::Relayout(int hcount, int vcount)
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(avViewLayout.GetHCount() == hcount &&
		avViewLayout.GetVCount() == vcount)
		return;
	avViewLayout.Relayout(hcount, vcount);
}

void VMSLivePluginImpl::FullScreen()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || view->IsFullScreen())
		return;
	view->FullScreen(true);
}
void VMSLivePluginImpl::CancelFullSrceen()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || !view->IsFullScreen())
		return;
	view->FullScreen(false);
}

void VMSLivePluginImpl::PtzControll(const std::string& xml)
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(vmsNetClient->status() != VMS_LOGIN)
		return ;

	ptz_xml_parser parser(xml);
	if(!parser.valid)
		return;

	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)//video is not playing
		return ;

	vmsNetClient->PtzControll(view->GetId(), xml);
}


std::string VMSLivePluginImpl::OpenVideo(const std::string& xml)
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(vmsNetClient->status() != VMS_LOGIN)
		return create_simple_response_xml(VMS_CLIENT_OFFLINE);
	AvView* view;
	int vid;
	if(xml.length() != 0)
	{
		boost::property_tree::ptree xml_tree;
		bool result = get_parse_xml(xml, xml_tree);
		if(!result)
			return create_simple_response_xml(XML_INVALID);
		try
		{
			vid = xml_tree.get<int>(PLUGIN_XML_PATH_VID);
		}
		catch (const boost::property_tree::ptree_error&)
		{
			return create_simple_response_xml(XML_INVALID);
		}
		//check video is playing
		view = avViewLayout.GetView(vid);
		if(view && view->GetVideoStatus() != VIDEO_STATUS_CLOSE)
			return create_simple_response_xml(VIDEO_IS_OPENED);

		view = avViewLayout.GetFreeView();
		if(view == NULL)//if all view is playing, than close current view video
		{
			view = avViewLayout.GetSelectedView();
			int id = view->GetId();
			view->CloseVideo();
			vmsNetClient->close_video(id);
		}
		
		view->SetId(vid);
	}
	else
	{
		view = avViewLayout.GetSelectedView();
		if(view && view->GetVideoStatus() != VIDEO_STATUS_CLOSE)
			return create_simple_response_xml(VIDEO_IS_OPENED);
		vid = view->GetId();
	}

	view->OpenVideo();
	vmsNetClient->open_video(vid);
	return create_simple_response_xml(VMS_SUCCESS);
}

std::string VMSLivePluginImpl::CloseVideo()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(vmsNetClient->status() != VMS_LOGIN)
		return create_simple_response_xml(VMS_CLIENT_OFFLINE);

	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || view->GetVideoStatus() == VIDEO_STATUS_CLOSE)
		return create_simple_response_xml(VIDEO_IS_CLOSE);

	int id = view->GetId();
	vmsNetClient->close_video(id);
	view->CloseVideo();
	return create_simple_response_xml(VMS_SUCCESS);
}

void VMSLivePluginImpl::CloseAllVideo()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	for(int i=0; i<avViewLayout.GetViewCount(); i++)
	{
		AvView* view = avViewLayout.GetViewByIndex(i);
		view->CloseVideo();
		if(vmsNetClient->status() == VMS_LOGIN)
		{
			int id = view->GetId();
			vmsNetClient->close_video(id);
		}
	}
	vmsNetClient->remove_client_cb(vmsClientCb);
}

std::string VMSLivePluginImpl::Snapshot(const std::string& xml)
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)//video is not playing
		return create_simple_response_xml(VIDEO_IS_CLOSE);

	boost::property_tree::ptree xml_tree;
	bool successed = get_parse_xml(xml, xml_tree);
	if(!successed)
		return create_simple_response_xml(XML_INVALID);

	std::string filePath;
	try
	{
		filePath = xml_tree.get<std::string>(PLUGIN_XML_PATH_FILE_PATH);
	}
	catch (const boost::property_tree::ptree_error& )
	{
		return create_simple_response_xml(XML_INVALID);
	}
	int result = view->Snapshot(filePath);

	return create_simple_response_xml(result);
}

std::string VMSLivePluginImpl::OpenAudio()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(vmsNetClient->status() != VMS_LOGIN)
		return create_simple_response_xml(VMS_CLIENT_OFFLINE);

	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)//video is not playing
		return create_simple_response_xml(VIDEO_IS_CLOSE);

	if(view->GetAudioStatus() != AUDIO_STATUS_CLOSE)
		return create_simple_response_xml(AUDIO_IS_OPENED);

	vmsNetClient->open_audio(view->GetId(), VMS_CMD_OPEN_AUDIO);
	view->OpenAudio();

	return create_simple_response_xml(VMS_SUCCESS);
}	

std::string VMSLivePluginImpl::CloseAudio()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(vmsNetClient->status() != VMS_LOGIN)
		return create_simple_response_xml(VMS_CLIENT_OFFLINE);

	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)//video is not playing
		return create_simple_response_xml(VIDEO_IS_CLOSE);

	if(view->GetAudioStatus() != AUDIO_STATUS_OPEN)
		return create_simple_response_xml(AUDIO_IS_CLOSE);

	vmsNetClient->close_audio(view->GetId(), VMS_CMD_CLOSE_AUDIO);
	view->CloseAudio();

	return create_simple_response_xml(VMS_SUCCESS);
}

std::string VMSLivePluginImpl::GetCurViewInfo()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL)
		return "";
	
	char xml[256];
	sprintf(xml, "<vms_plugin><vid>%d</vid><video_status>%d<video_status><audio_status>%d<audio_status></vms_plugin>", 
		view->GetId(), view->GetVideoStatus(), view->GetAudioStatus());

	return xml;
}

void VMSLivePluginImpl::VmsClientCallback::on_login_completed(vms_result_t error)
{
	//do not lock,because net_socket::handle_read already locked
    VMSLivePluginEvent *event = vmsPluginLiveImpl->vmsPluginLiveEvent;
    if (event) {
        event->OnLoginCompleted(error);
        int count = vmsPluginLiveImpl->avViewLayout.GetViewCount();
        for(int i=0; i<count; i++)
        {
            AvView* view = vmsPluginLiveImpl->avViewLayout.GetViewByIndex(i);
            if(view->GetVideoStatus() == VIDEO_STATUS_OPEN)
            {
                vmsPluginLiveImpl->vmsNetClient->open_video(view->GetId());
            }
            
            if(view->GetAudioStatus() == AUDIO_STATUS_OPEN)
            {
                vmsPluginLiveImpl->vmsNetClient->open_audio(view->GetId(), VMS_CMD_OPEN_AUDIO);
            }
        }
    }
}
void VMSLivePluginImpl::VmsClientCallback::on_net_disconnect()
{
	//do not lock,because net_socket::handle_read already locked
    VMSLivePluginEvent *event = vmsPluginLiveImpl->vmsPluginLiveEvent;
    if (event) {
        event->OnNetDisconnect();
    }
}

void VMSLivePluginImpl::VmsClientCallback::on_open_video(unsigned int vid, unsigned int result)
{
	//do not lock,because net_socket::handle_read already locked
	if(result == VMS_SUCCESS)
	{
		AvView* view = vmsPluginLiveImpl->avViewLayout.GetView(vid);
		if(view  && view->GetVideoStatus() == VIDEO_STATUS_CONNECTING)
			view->OnOpenVideo(result, PLUGIN_VIDEO_LIVE, AVPLAY_TYPE_STREAM);
	}
    VMSLivePluginEvent *event = vmsPluginLiveImpl->vmsPluginLiveEvent;
    if (event) {
        event->OnOpenVideo(vid, result);
    }
}

void VMSLivePluginImpl::VmsClientCallback::on_open_audio(unsigned int vid, unsigned int result)
{
	//do not lock,because net_socket::handle_read already locked
	if(result == VMS_SUCCESS)
	{
		AvView* view = vmsPluginLiveImpl->avViewLayout.GetView(vid);
		if(view  && view->GetAudioStatus() == AUDIO_STATUS_CONNECTING)
			view->OnOpenAudio(result);
	}
    VMSLivePluginEvent *event = vmsPluginLiveImpl->vmsPluginLiveEvent;
    if (event) {
        event->OnOpenAudio(vid, result);
    }
}

void VMSLivePluginImpl::VmsClientCallback::on_recv_av_data(VMS_COMMAND* cmd)
{
	//do not lock,because net_socket::handle_read already locked
	VMS_BINARY_COMMAND* bin_cmd = (VMS_BINARY_COMMAND*)cmd;
	VMS_AV_DATA* av_data = (VMS_AV_DATA*)bin_cmd->data;

	AvView* view = vmsPluginLiveImpl->avViewLayout.GetView(av_data->device_id);
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)
		return;
	view->on_recv_av_data(av_data->cmd, bin_cmd->data+sizeof(VMS_AV_DATA), bin_cmd->len-sizeof(VMS_AV_DATA), av_data->timestamp);
}

void VMSLivePluginImpl::OnViewSelected(int selectIndex)
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
}