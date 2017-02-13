#ifdef _WIN32
#include "StdAfx.h"
#endif

#include "VMSBackPluginImpl.h"
#include "PluginXml.h"
#include "back_xml_parser.h"
#include "../../libplay/libplay/avplay_sdk.h"
//#include "../../../libplay/libplay/avplay_sdk.h"

extern void PluginInit();


VMSBackPluginImpl::VMSBackPluginImpl(VMSBackPluginEvent* event,void *pluginLayer)
    :avViewLayout(this,pluginLayer)
{
    vmsBackPluginEvent = event;
    videoStatus = VIDEO_STATUS_CLOSE;
    PluginInit();
    
    boost::asio::io_service& service = *(boost::asio::io_service*)net_io::instance().get_io_service();
    vmsNetClient = boost::shared_ptr<vms_net_client>( new vms_net_client(service) );
    vmsClientCb = boost::shared_ptr<VmsNetClientCallback>( new VmsNetClientCallback(this) );
    vmsNetClient->add_client_cb(vmsClientCb->shared_from_this());
}


VMSBackPluginImpl::VMSBackPluginImpl(VMSBackPluginEvent* event)
	:avViewLayout(this)
{
	vmsBackPluginEvent = event;
	videoStatus = VIDEO_STATUS_CLOSE;
	PluginInit();

	boost::asio::io_service& service = *(boost::asio::io_service*)net_io::instance().get_io_service();
	vmsNetClient = boost::shared_ptr<vms_net_client>( new vms_net_client(service) );
	vmsClientCb = boost::shared_ptr<VmsNetClientCallback>( new VmsNetClientCallback(this) );
	vmsNetClient->add_client_cb(vmsClientCb->shared_from_this());
}

VMSBackPluginImpl::~VMSBackPluginImpl(void)
{
	CloseVideo();
	vmsNetClient->remove_client_cb(vmsClientCb);
	vmsNetClient->logoff();
	vmsNetClient.reset();
}

vms_result_t VMSBackPluginImpl::login(const std::string& server, short port, const std::string& name, const std::string& pwd)
{
	//two thread in plugin, windows message loop thread and net io thread
	//so use mutex to lock the plugin
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	return vmsNetClient->login(server, port, name, pwd);
}

void VMSBackPluginImpl::logoff()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	vmsNetClient->logoff();
}

#ifdef _WIN32
LRESULT VMSBackPluginImpl::OnCreate(HWND wnd)
{
    boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
    avViewLayout.OnCreate(wnd);
    return S_OK;
}

LRESULT VMSBackPluginImpl::OnPaint()
{
    boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
    avViewLayout.OnPaint();
    return S_OK;
}

LRESULT VMSBackPluginImpl::OnSize(WPARAM wparam, LPARAM lparam)
{
    boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
    avViewLayout.Relayout(avViewLayout.GetHCount(), avViewLayout.GetVCount());
    return S_OK;
}
#endif

void VMSBackPluginImpl::FullScreen()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	AvView* view = avViewLayout.GetSelectedView();
    if(view == NULL || view->IsFullScreen()) {
        NSLog(@"Empty View");
        return;
    }
	view->FullScreen(true);
}
void VMSBackPluginImpl::CancelFullSrceen()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	AvView* view = avViewLayout.GetSelectedView();
    if(view == NULL || !view->IsFullScreen())
        return;
    
	view->FullScreen(false);
}

std::string VMSBackPluginImpl::OpenVideo(const std::string& xml)
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(videoStatus != VIDEO_STATUS_CLOSE)
		return create_simple_response_xml(VIDEO_IS_OPENED);
	
	back_xml_parser parser(xml);
	if(parser.valid == false)
		return create_simple_response_xml(XML_INVALID);

	if(avViewLayout.GetViewCount() < parser.item_count)
		avViewLayout.Relayout(parser.item_count);

	for(int i=0; i<parser.item_count; i++)
	{
		avViewLayout.GetViewByIndex(i)->SetId(parser.items[i].video_id);
		avViewLayout.GetViewByIndex(i)->OpenVideo();
	}

	playProgressMap.clear();
	vmsNetClient->open_back_video(xml);
	videoStatus = VIDEO_STATUS_CONNECTING;
	
	return create_simple_response_xml(VMS_SUCCESS);
}

std::string VMSBackPluginImpl::CloseVideo()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	//stop all back video
	int count = avViewLayout.GetViewCount();
	for(int i=0; i<count; i++)
	{
		avViewLayout.GetViewByIndex(i)->CloseVideo();
		avViewLayout.GetViewByIndex(i)->CloseVideo();
	}

	//notify server to stop play back video
	vmsNetClient->close_back_video();
	videoStatus = VIDEO_STATUS_CLOSE;
	return create_simple_response_xml(VMS_SUCCESS);
}

std::string VMSBackPluginImpl::Snapshot(const std::string& xml)
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)//video is not playing
		return create_simple_response_xml(VIDEO_IS_CLOSE);

	//get file path from xml
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

std::string VMSBackPluginImpl::OpenAudio()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(vmsNetClient->status() != VMS_LOGIN)
		return create_simple_response_xml(VMS_CLIENT_OFFLINE);

	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)//video is not playing
		return create_simple_response_xml(VIDEO_IS_CLOSE);

	if(view->GetAudioStatus() != AUDIO_STATUS_CLOSE)
		return create_simple_response_xml(AUDIO_IS_OPENED);

	vmsNetClient->open_audio(view->GetId(), VMS_CMD_OPEN_BACK_AUDIO);
	view->OpenAudio();

	return create_simple_response_xml(VMS_SUCCESS);
}

std::string VMSBackPluginImpl::CloseAudio()
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(vmsNetClient->status() != VMS_LOGIN)
		return create_simple_response_xml(VMS_CLIENT_OFFLINE);

	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)//video is not playing
		return create_simple_response_xml(VIDEO_IS_CLOSE);

	if(view->GetAudioStatus() != AUDIO_STATUS_OPEN)
		return create_simple_response_xml(AUDIO_IS_CLOSE);

	vmsNetClient->close_audio(view->GetId(), VMS_CMD_CLOSE_BACK_AUDIO);
	view->CloseAudio();

	return create_simple_response_xml(VMS_SUCCESS);
}

void VMSBackPluginImpl::SetPlaySpeed(double speed)
{
	static const float MAX_PLAY_SPEED = 4.0;
	static const float MIN_PLAY_SPEED = 0.25;

	if(speed > MAX_PLAY_SPEED || speed < MIN_PLAY_SPEED)
		return;
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(vmsNetClient->status() != VMS_LOGIN)
		return;

	AvView* view = avViewLayout.GetSelectedView();
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)//video is not playing
		return;
	vmsNetClient->SetPlaySpeed(view->GetId(), speed);
}

void VMSBackPluginImpl::SetPlayBeginTime(long video_id, const std::string& beginTime)
{
	boost::recursive_mutex::scoped_lock lock(vmsNetClient->get_lock());
	if(vmsNetClient->status() != VMS_LOGIN)
		return;

	AvView* view = avViewLayout.GetView(video_id);
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)//video is not playing
		return;
	vmsNetClient->SetPlayBeginTime(view->GetId(), beginTime);
}

void VMSBackPluginImpl::OnViewSelected(int selectIndex)
{

}

void VMSBackPluginImpl::VmsNetClientCallback::on_login_completed(vms_result_t error)
{
	//do not lock,because net_socket::handle_read already locked
	vmsPluginBackImpl->vmsBackPluginEvent->OnLoginCompleted(error);
}
void VMSBackPluginImpl::VmsNetClientCallback::on_net_disconnect()
{
	//do not lock,because net_socket::handle_read already locked
	vmsPluginBackImpl->videoStatus = VIDEO_STATUS_CLOSE;
	vmsPluginBackImpl->vmsBackPluginEvent->OnNetDisconnect();
}
void VMSBackPluginImpl::VmsNetClientCallback::on_open_video(unsigned int vid, unsigned int result)
{
	//do not lock,because net_socket::handle_read already locked
	if(result == VMS_SUCCESS)
		vmsPluginBackImpl->videoStatus = VIDEO_STATUS_OPEN;
	else
		vmsPluginBackImpl->videoStatus = VIDEO_STATUS_CLOSE;

	for(int i=0; i<vmsPluginBackImpl->avViewLayout.GetViewCount(); i++)
	{
		AvView* view = vmsPluginBackImpl->avViewLayout.GetViewByIndex(i);

		if(view->GetId() != INVALID_DEVICE_ID)
			view->OnOpenVideo(result, PLUGIN_VIDEO_BACK, AVPLAY_TYPE_STREAM);
	}

	vmsPluginBackImpl->vmsBackPluginEvent->OnOpenVideo(result);
}

void VMSBackPluginImpl::VmsNetClientCallback::on_open_audio(unsigned int vid, unsigned int result)
{
	//do not lock,because net_socket::handle_read already locked
	if(result == VMS_SUCCESS)
	{
		AvView* view = vmsPluginBackImpl->avViewLayout.GetView(vid);
		if(view  && view->GetAudioStatus() == AUDIO_STATUS_CONNECTING)
			view->OnOpenAudio(result);
	}
	vmsPluginBackImpl->vmsBackPluginEvent->OnOpenAudio(vid, result);
}

void VMSBackPluginImpl::VmsNetClientCallback::on_recv_av_data(VMS_COMMAND* cmd)
{
	//do not lock,because net_socket::handle_read already locked
	VMS_BINARY_COMMAND* bin_cmd = (VMS_BINARY_COMMAND*)cmd;
	VMS_AV_DATA* av_data = (VMS_AV_DATA*)bin_cmd->data;

	AvView* view = vmsPluginBackImpl->avViewLayout.GetView(av_data->device_id);
	if(view == NULL || view->GetVideoStatus() != VIDEO_STATUS_OPEN)
		return;
	if(av_data->cmd == VMS_CMD_VIDEO_DATA)
	{
		time_t progress = (time_t)(av_data->timestamp /1000.0);
		std::map<unsigned int, time_t>::iterator it = vmsPluginBackImpl->playProgressMap.find(av_data->device_id);
		if(it == vmsPluginBackImpl->playProgressMap.end())
		{
			vmsPluginBackImpl->playProgressMap[av_data->device_id] = progress;
			vmsPluginBackImpl->vmsBackPluginEvent->OnPlayProgress(av_data->device_id, progress);
		}
		else
		{
#define PLAY_PROGRESS_EVENT_TIME 60
			if((progress - it->second) > PLAY_PROGRESS_EVENT_TIME || progress < it->second)
			{
				vmsPluginBackImpl->playProgressMap[av_data->device_id] = progress;
				vmsPluginBackImpl->vmsBackPluginEvent->OnPlayProgress(av_data->device_id, progress);
			}
		}
	}
	char* d = bin_cmd->data+sizeof(VMS_AV_DATA);
	int len = bin_cmd->len-sizeof(VMS_AV_DATA);
	char text[256];
	sprintf(text, "%d %d %d %d %d %d\r\n", len, d[0], d[1], d[2], d[3], d[4]);
	

	view->on_recv_av_data(av_data->cmd, bin_cmd->data+sizeof(VMS_AV_DATA), bin_cmd->len-sizeof(VMS_AV_DATA), av_data->timestamp);
}