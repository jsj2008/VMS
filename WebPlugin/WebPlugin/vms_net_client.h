#pragma once

#include <string>
#include <list>

#include "common/net_socket.h"
//#include <net_socket.h>
#include <boost/shared_ptr.hpp>
#include "common/vms_command.h"
//#include <vms_command.h>

typedef enum _VMS_CLIENT_STATUS
{
	VMS_LOGOFF,
	VMS_CONNECTTING,
	VMS_CONNECTED,
	VMS_LOGIN,
}VMS_CLIENT_STATUS;

class vms_client_cb
{
public:
	virtual void on_login_completed(vms_result_t error) = 0;
	virtual void on_net_disconnect() = 0;
	virtual void on_open_video(unsigned int vid, unsigned int result) = 0; //if play back, vid is -1
	virtual void on_recv_av_data(VMS_COMMAND* cmd) =0;
	virtual void on_open_audio(unsigned int vid, unsigned int result) = 0;
};


class vms_net_client: public net_socket<vms_net_client>
{
public:
	virtual ~vms_net_client(void);
	vms_net_client(boost::asio::io_service& io_service, char keepAlive = 1);

	virtual vms_result_t login(const std::string& server, short port, const std::string& name, const std::string& pwd);
	virtual void logoff();
	virtual void keep_alive();

	virtual void open_video(int vid);
	virtual void close_video(int vid);

	virtual void open_audio(int vid, int cmd);
	virtual void close_audio(int vid, int cmd);

	virtual void open_back_video(const std::string& xml);
	virtual void close_back_video();

	virtual void SetPlaySpeed(int vid, float speed);

	virtual void PtzControll(int vid, const std::string& xml);

	virtual void SetPlayBeginTime(int vid, const std::string& t);

	VMS_CLIENT_STATUS status(){return status_;};
	void add_client_cb(boost::shared_ptr<vms_client_cb> cb);
	void remove_client_cb(boost::shared_ptr<vms_client_cb> cb);

	virtual vms_result_t process_command() ;

protected:
	virtual void on_net_close() ;
	void handle_connect(const boost::system::error_code& error);
	void handle_heart_timer(const boost::system::error_code& error);

	void do_login_response(VMS_COMMAND* cmd);
	void open_video_response(VMS_COMMAND* cmd);
	void on_recv_av_data(VMS_COMMAND* cmd);
	void open_audio_response(VMS_COMMAND* cmd);
		
	void on_login_completed(vms_result_t error);
	void on_net_disconnect();

	void reconnect();
	void reconnect_timer(const boost::system::error_code& error);

private:
	std::string server_;
	short port_;
	std::string user_;
	std::string pwd_;

	VMS_CLIENT_STATUS status_;
	typedef std::list< boost::shared_ptr<vms_client_cb> > vms_client_cb_list;
	vms_client_cb_list client_cb_list_;

	unsigned int cid_;

	//heart to vms
	boost::asio::deadline_timer heart_timer_;
	int heart_span_;
	char keepAlive_;

	//reconnect timer
	boost::asio::deadline_timer reconnect_timer_;
	bool is_reconnect;
};
