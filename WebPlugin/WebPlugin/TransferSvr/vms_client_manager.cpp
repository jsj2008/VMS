#include <config.h>
#include "vms_client_manager.h"
#include <vms_log.h>
#include <boost/bind.hpp>
#include <vector>
#include "net_module.h"

unsigned int vms_client_manager::client_id_ = 1;

vms_client_manager::vms_client_manager(boost::asio::io_service& service)
	:timer_(service)
{
	//timer for watch all client
	timer_.expires_from_now(boost::posix_time::seconds(VMS_CLIENT_HEART_SPAN));
	timer_.async_wait( boost::bind( &vms_client_manager::handle_heart_timer, this ) ) ;
}

vms_client_manager::~vms_client_manager(void)
{

}

vms_client_manager& vms_client_manager::instance()
{
	static vms_client_manager manager(
		*(boost::asio::io_service*)net_module::instance().get_io_service() 
		);
	return manager;
}
//watch all client,if client invalid, remove it from clients map
void vms_client_manager::handle_heart_timer()
{
	std::vector< boost::shared_ptr<vms_client_business> > invalid_clients;
	do 
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
		for(CLIENT_MAP::iterator it = clients_map_.begin(); it!=clients_map_.end();)
		{
			if(!it->second->check_valid())
			{
				invalid_clients.push_back(it->second);
				VMS_LOG(VMS_LOG_LEVEL_INFO, "client heart timeout, id=%d", it->second->id());
				clients_map_.erase(it++);
			}
			else
			{
				it++;
			}
		}
	} while (0);

	for(std::vector< boost::shared_ptr<vms_client_business> >::iterator it=invalid_clients.begin(); it!=invalid_clients.end(); it++)
	{
		(*it)->close_net_connection();
	}

	timer_.expires_from_now(boost::posix_time::seconds(VMS_CLIENT_HEART_SPAN));
	timer_.async_wait( boost::bind( &vms_client_manager::handle_heart_timer, this ) ) ;
}

void vms_client_manager::add_vms_client(boost::shared_ptr<vms_client_business> business)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	long id = client_id_++;
	business->set_id(id);
	clients_map_[id] = business;
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_manager add client,id=%d", id);
}

void vms_client_manager::remove_vms_client(unsigned int id)
{
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_manager remove client, id=%d", id);
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	clients_map_.erase(id);
}

void vms_client_manager::send_data_to_client(unsigned int cid, VMS_CMD_HEADER* header)
{
	boost::shared_ptr<vms_client_business> client_business;

	do 
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
		CLIENT_MAP::iterator it = clients_map_.find(cid);
		if(it == clients_map_.end())
			return;
		client_business = it->second;
	} while (0);
	client_business->send_data_to_client(header);
}