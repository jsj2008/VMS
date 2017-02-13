#pragma once
#include <boost/shared_ptr.hpp>
#include <boost/thread/recursive_mutex.hpp>
#include <boost/asio/deadline_timer.hpp>
#include <map>
#include "vms_client_business.h"

class vms_client_manager
{
private:
	vms_client_manager(boost::asio::io_service& service);
public:
	virtual ~vms_client_manager(void);

	static vms_client_manager& instance();

	void add_vms_client(boost::shared_ptr<vms_client_business> business);
	void remove_vms_client(unsigned int id);

	void send_data_to_client(unsigned int cid, VMS_CMD_HEADER* header);
private:
	void handle_heart_timer();
private:
	boost::recursive_mutex recursive_mutex_;
	
	typedef std::map<unsigned int, boost::shared_ptr<vms_client_business> > CLIENT_MAP;
	CLIENT_MAP clients_map_; //client id map to user

	static unsigned int client_id_;

	//heart to check and remove invalid client 
	boost::asio::deadline_timer timer_;
};
