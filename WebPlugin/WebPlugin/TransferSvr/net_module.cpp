#include <config.h>
#include "net_module.h"
#include <vms_log.h>
#include <boost/thread/thread.hpp> 
#include <boost/asio.hpp>
#include "net_server.h"

boost::asio::io_service g_io_service;
boost::thread** g_io_thread = NULL;
bool exit_thread = false;

net_module::net_module(void)
{
	thread_count_ = DEFAULT_THREAD_COUNT;
}

net_module::~net_module(void)
{
}

net_module& net_module::instance()
{
	static net_module io;
	return io;
}

void boost_net_io_thread() 
{ 
	VMS_LOG(VMS_LOG_LEVEL_INFO, "boost_net_io_thread begin");
	while(!exit_thread)
	{
		try
		{
			g_io_service.run();
		}
		catch (std::exception&)
		{
			VMS_LOG(VMS_LOG_LEVEL_FATAL, "g_io_service.run throw exception,%s", e.what());
		}
		catch (...)
		{
			VMS_LOG(VMS_LOG_LEVEL_FATAL, "g_io_service.run throw unknown exception");
		}
	}
	VMS_LOG(VMS_LOG_LEVEL_INFO, "boost_net_io_thread end");
} 


vms_result_t net_module::init(unsigned short port, int thread_count)
{
	try
	{
		static net_server s(g_io_service, port);
		thread_count_ = thread_count;
		g_io_thread = new boost::thread*[thread_count];
		for(int i=0; i<thread_count; i++)
		{
			g_io_thread[i] = new boost::thread(&boost_net_io_thread);
		}
		return VMS_SUCCESS;
	}
	catch(...)
	{
		return VMS_NET_INIT_FAILED;
	}
}

void net_module::uninit()
{
	if(g_io_thread)
	{
		exit_thread = true;
		g_io_service.stop();

		for(int i=0; i<thread_count_; i++)
		{
			g_io_thread[i]->join();
		}
		delete[] g_io_thread;
	}
}

void* net_module::get_io_service()
{
	return &g_io_service;
}

