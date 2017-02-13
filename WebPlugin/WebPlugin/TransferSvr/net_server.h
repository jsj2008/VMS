#pragma once
#include "net_client.h"
#include <boost/shared_ptr.hpp>

class net_server
{
public:
	net_server(boost::asio::io_service& io_service, short port);
	virtual ~net_server(void);

	void handle_accept(boost::shared_ptr<net_client> new_client, const boost::system::error_code& error);
private:
	boost::asio::io_service& io_service_;
	tcp::acceptor acceptor_;
};
