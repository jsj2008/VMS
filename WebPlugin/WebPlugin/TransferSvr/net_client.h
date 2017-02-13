#pragma once
#include <net_socket.h>
#include "vms_client_business.h"

class net_client: public net_socket<net_client>
{
public:
	net_client(boost::asio::io_service& io_service);
	virtual ~net_client(void);

	void start();
	virtual vms_result_t process_command();
	virtual void on_net_close();
	void close();
private:
	bool closed_;
	boost::shared_ptr<vms_client_business> vms_business_;
};
