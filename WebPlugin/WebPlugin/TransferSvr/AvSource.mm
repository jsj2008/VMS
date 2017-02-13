#ifdef _WIN32
#include "StdAfx.h"
#endif

#include "AvSource.h"
//#include "../../vms/code/VMSClient/AVSourceServer.h"
#include "../../../VMS/AVSourceServerCppWrap.h"

AvSource::AvSource(AvSourceCallBack* cb)
{
	callback = cb;
}

AvSource::~AvSource(void)
{
}

AvSource* create_live_av_source(AvSourceCallBack* cb)
{
	//return /*new AVSourceServer(cb)*/NULL;
    return new AVSourceServerCppWrap(cb);
}