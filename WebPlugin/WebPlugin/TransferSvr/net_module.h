#pragma once
#define DEFAULT_THREAD_COUNT 8
#include <config.h>
class net_module
{
public:
	virtual ~net_module(void);
	static net_module& instance();
	virtual vms_result_t init(unsigned short port,
                              int thread_count=DEFAULT_THREAD_COUNT);
	virtual void uninit();
	void* get_io_service();
private:
	net_module(void);
	int thread_count_;
};

