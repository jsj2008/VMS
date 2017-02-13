#pragma once

#include "common/vms_error.h"
//#include <vms_error.h>

class net_io
{
public:
	static net_io& instance();
	virtual ~net_io(void);
	virtual vms_result_t init();
	virtual void uninit();
	virtual void* get_io_service();
private:
	net_io(void);
};
