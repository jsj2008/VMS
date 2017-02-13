
#ifndef __VMS_NET_SOCKET__
#define __VMS_NET_SOCKET__

#include <boost/asio.hpp>
#include <boost/enable_shared_from_this.hpp>
#include <boost/thread/recursive_mutex.hpp>
#include <boost/bind.hpp>
#include "../common/vms_error.h"
//#include <vms_error.h>
#include "../common/vms_command.h"
//#include <vms_command.h>
#include "../common/vms_log.h"
//#include <vms_log.h>

using boost::asio::ip::tcp;

template<typename type>
class net_socket: public boost::enable_shared_from_this<type>
{
public:
	net_socket(boost::asio::io_service& io_service)
		:socket_(io_service)
	{
		recv_buffer_= (char*)malloc(VMS_RECV_BUFFER_LEN);
		cmd_buffer_ = (char*)malloc(MAX_VMS_CMD_LEN+1);
		cmd_buffer_len_ = 0;
	}

	virtual ~net_socket()
	{
		free(cmd_buffer_);
		free(recv_buffer_);
	}

	virtual void async_read()
	{
		//async read net data
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
		socket_.async_read_some(boost::asio::buffer(recv_buffer_, VMS_RECV_BUFFER_LEN),
			boost::bind(&net_socket::handle_read, this->shared_from_this(),
			boost::asio::placeholders::error,
			boost::asio::placeholders::bytes_transferred));
	}

	void send_cmd(VMS_CMD_HEADER* cmd)
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
		VMS_LOG(VMS_LOG_LEVEL_TRACE, "%p net_socket::send_cmd called, command count %d, %ld", 
			this, 
			send_cmd_list_.size(),
			get_net_command_total_length(cmd));

		//if send list has command,then don't send, cache it 
		if(send_cmd_list_.size() == 0) 
		{
			boost::asio::async_write(socket_,
				boost::asio::buffer(cmd, get_net_command_total_length(cmd)),
				boost::bind(&net_socket::handle_write, this->shared_from_this(), boost::asio::placeholders::error));
		}
		send_cmd_list_.push_back(cmd);
		VMS_LOG(VMS_LOG_LEVEL_TRACE, "%p net_socket::send_cmd end, command count %d", this, send_cmd_list_.size());
	}

	boost::recursive_mutex& get_lock(){return recursive_mutex_;};

	tcp::socket& socket(){return socket_;}

	virtual vms_result_t process_command() = 0;
protected:
	virtual void on_net_close() = 0;
private:
	void handle_read(const boost::system::error_code& error, size_t bytes_transferred)
	{
		VMS_LOG(VMS_LOG_LEVEL_TRACE, 
			"%p net_socket::handle_read called, error is %d, bytes_transferred %d, cmd_buffer_len_ %d", 
			this, error.value(), bytes_transferred, cmd_buffer_len_);

		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
		if (!error)
		{
			vms_result_t result = vms_process_recved_data(recv_buffer_, bytes_transferred, cmd_buffer_, cmd_buffer_len_, this);

			if(result == VMS_SUCCESS)
				socket_.async_read_some(boost::asio::buffer(recv_buffer_, VMS_RECV_BUFFER_LEN),
				boost::bind(&net_socket::handle_read, this->shared_from_this(),
				boost::asio::placeholders::error,
				boost::asio::placeholders::bytes_transferred));
			else
			{
				on_net_close();
				socket_.close();
			}
		}
		else
		{
			switch (error.value())
			{
				case 10054:   //closed by remote host
				case 1236:  //
				case 2: // End of file
					on_net_close();
					socket_.close();
			}
		}
	}

	void handle_write(const boost::system::error_code& error)
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);

		VMS_LOG(VMS_LOG_LEVEL_TRACE, "%p net_socket::handle_write called, error is %d, command count %d",
			this,
			error.value(), 
			send_cmd_list_.size());
		//the command is sent, free it
		destory_vms_command(send_cmd_list_.front()); 
		send_cmd_list_.pop_front();

		if (!error)
		{
			if(send_cmd_list_.size())//send other command
			{
				VMS_CMD_HEADER* header = send_cmd_list_.front();
				boost::asio::async_write(socket_,
					boost::asio::buffer(header, get_net_command_total_length(header)),
					boost::bind(&net_socket::handle_write, this->shared_from_this(), boost::asio::placeholders::error));
			}
		}
		else
		{
			on_net_close();
			socket_.close();
		}
	}

protected:
	tcp::socket socket_;

	char* recv_buffer_;
	char* cmd_buffer_;
	size_t cmd_buffer_len_;

	boost::recursive_mutex recursive_mutex_;
	boost::recursive_mutex recursive_mutex_cmd_; //only be locked for precess command

	std::list<VMS_CMD_HEADER*> send_cmd_list_;
};

#endif
