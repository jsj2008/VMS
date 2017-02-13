#include "config.h"
#include "net_io.h"
#include "common/vms_log.h"
//#include <vms_log.h>
#include <boost/asio.hpp>
#include <boost/thread/thread.hpp>
#include <boost/asio/deadline_timer.hpp>

using boost::asio::deadline_timer;

boost::asio::io_service* g_client_io_service = new boost::asio::io_service();
boost::thread* g_io_thread = NULL;
bool exit_client_thread = false;
deadline_timer* g_timer = NULL;

#define TIMER_SPAN 60

net_io::net_io(void)
{
}

net_io::~net_io(void)
{
}

net_io& net_io::instance()
{
	static net_io io;
	return io;
}

//call back for g_timer
void handle_timeout(const boost::system::error_code&)
{
	g_timer->expires_from_now(boost::posix_time::seconds(TIMER_SPAN));
	g_timer->async_wait(&handle_timeout);
}


//net io thread 
void client_boost_net_io_thread() 
{ 
	g_timer = new deadline_timer(*g_client_io_service);
	VMS_LOG(VMS_LOG_LEVEL_INFO, "%s", "client_boost_net_io_thread begin");
	while(1)
	{
		try
		{
			//to the thread does not exit, async post a timer. otherwise the g_client_io_service.run() will return
			g_timer->expires_from_now(boost::posix_time::seconds(TIMER_SPAN));
			g_timer->async_wait(&handle_timeout);
			g_client_io_service->run();
		}
		catch (std::exception& e)
		{
			VMS_LOG(VMS_LOG_LEVEL_FATAL, "g_client_io_service.run throw exception,%s", e.what());
		}
		catch (...)
		{
			VMS_LOG(VMS_LOG_LEVEL_FATAL, "%s", "g_client_io_service.run throw unknown exception");
		}
		if(exit_client_thread)
			break;
	} 
	delete g_timer;
	VMS_LOG(VMS_LOG_LEVEL_INFO, "%s", "client_boost_net_io_thread end");
} 


vms_result_t net_io::init()
{
	if(g_io_thread == NULL)
		g_io_thread = new boost::thread(&client_boost_net_io_thread);
	return VMS_SUCCESS;
}

void net_io::uninit()
{
	if(g_io_thread)
	{
		exit_client_thread = true;
		g_client_io_service->stop();
		//g_io_thread->join();
		g_io_thread=NULL;
	}
}

void* net_io::get_io_service()
{
	return g_client_io_service;
}