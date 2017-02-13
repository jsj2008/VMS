#include <config.h>
#include "net_server.h"
#include <boost/bind.hpp>

net_server::net_server(boost::asio::io_service& io_service, short port)
	:io_service_(io_service),
	acceptor_(io_service, tcp::endpoint(tcp::v4(), port))
{
	//async accept socket client
	boost::shared_ptr<net_client> new_client(new net_client(io_service_));
	acceptor_.async_accept(new_client->socket(),
		boost::bind(&net_server::handle_accept, this, new_client->shared_from_this(),
		boost::asio::placeholders::error));
}

net_server::~net_server(void)
{
}


void net_server::handle_accept(boost::shared_ptr<net_client> new_client, const boost::system::error_code& error)
{
	if (!error)
	{
		new_client->start();

		//again async accept new socket client
		boost::shared_ptr<net_client> new_accept_client(new net_client(io_service_));
		acceptor_.async_accept(new_accept_client->socket(),
			boost::bind(&net_server::handle_accept, this, new_accept_client->shared_from_this(),
			boost::asio::placeholders::error));
	}
	else
	{
		//boost::shared_ptr will auto delete
	}
}