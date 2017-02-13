#pragma once

#include <boost/enable_shared_from_this.hpp>
#include <boost/thread/recursive_mutex.hpp>
//#include <boost/atomic.hpp>
#include <boost/interprocess/detail/atomic.hpp>
#include "vms_command.h"

class net_client;

class vms_client_business : public boost::enable_shared_from_this<vms_client_business>
{
public:
	vms_client_business(void);
	virtual ~vms_client_business(void);
	virtual void on_net_close();
	virtual vms_result_t process_command(VMS_COMMAND* cmd);

	virtual void init_with_net_client(boost::shared_ptr<net_client> client) ;

	void set_id(int long id){id_=id;};
	unsigned int id(){return id_;};

	bool check_valid();

	void close_net_connection();

	void send_data_to_client(VMS_CMD_HEADER* header);
	
private:
	//client id,
	unsigned int id_;
	std::string user_;
	std::string pwd_;

	time_t last_cmd_time_;

	boost::shared_ptr<net_client> net_client_;

private:
	void do_login(VMS_COMMAND* cmd);
	void do_logoff();
	void do_heart();
	void open_video(VMS_COMMAND* cmd);
	void open_audio(VMS_COMMAND* cmd);
	void open_back_video(VMS_COMMAND* cmd);
	void open_back_audio(VMS_COMMAND* cmd);
};
