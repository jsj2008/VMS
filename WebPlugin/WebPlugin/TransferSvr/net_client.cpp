#include <config.h>
#include "net_client.h"

net_client::net_client(boost::asio::io_service& io_service) : net_socket(io_service)
{
	closed_ = false;
}

net_client::~net_client(void)
{

}

void net_client::start()
{
	VMS_LOG(VMS_LOG_LEVEL_INFO, "accept net client %s:%d", 
		socket_.remote_endpoint().address().to_string().c_str(),
		socket_.remote_endpoint().port());


	async_read();
}

vms_result_t net_client::process_command()
{
	bool new_business = false; 
	if(closed_)
		return VMS_SUCCESS;

	vms_result_t result = VMS_SUCCESS;
	if(result != VMS_SUCCESS)
		return result;

	cmd_buffer_[cmd_buffer_len_] = '\0';
	
	VMS_COMMAND* cmd = decode_vms_command(cmd_buffer_, result);
	if(cmd && result == VMS_SUCCESS)
	{
		boost::shared_ptr<vms_client_business> business = vms_business_;
		recursive_mutex_.unlock(); //net_socket::handle_read lock,so unlock,*****************
		do 
		{
			boost::recursive_mutex::scoped_lock lock_cmd(recursive_mutex_cmd_);
			if(!business)
			{
				business = boost::shared_ptr<vms_client_business>(new vms_client_business);
				//business will manage this net_client
				//if business be destroyed,this object also be destroyed
				business->init_with_net_client(this->shared_from_this());
				new_business = true;
			}
			business->process_command(cmd);
		} while (0);


		recursive_mutex_.lock(); //for recursive_mutex_.unlock();,***************** 
		if(new_business)
			vms_business_ = business;
	}
	else
	{
		VMS_LOG(VMS_LOG_LEVEL_ERROR , "net_client::process_command decode_vms_command result is %d", result);
	}

	//if return result is not VMS_SUCCESS, the net_socket::handle_read will close socket and call on_net_close
	return result; 
}

void net_client::on_net_close()
{
	if(!closed_)
	{
		recursive_mutex_.unlock(); //net_socket::handle_read lock,so unlock,*****************

		do 
		{
			boost::recursive_mutex::scoped_lock lock_cmd(recursive_mutex_cmd_);
			if(vms_business_)
			{
				vms_business_->on_net_close();
				vms_business_.reset();
			}
		}while(0);

		recursive_mutex_.lock();//for recursive_mutex_.unlock();,***************** 
		closed_ = true;
	}
}

void net_client::close()
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if(!closed_)
	{
		socket_.close();
		vms_business_.reset();
		closed_ = true;
	}
}
