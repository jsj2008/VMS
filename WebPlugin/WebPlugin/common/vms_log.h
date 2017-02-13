#ifndef __VMS_LOG__
#define __VMS_LOG__

#include <string>

#define VMS_LOG_LEVEL_FATAL 6
#define VMS_LOG_LEVEL_ERROR 5
#define VMS_LOG_LEVEL_WARN  4
#define VMS_LOG_LEVEL_INFO  3
#define VMS_LOG_LEVEL_DEBUG 2
#define VMS_LOG_LEVEL_TRACE 1

void vms_log(const char* file, int line, int level, const char *format, ...);
//#define VMS_LOG(level,format,...)  vms_log(__FILE__, __LINE__, level, format, __VA_ARGS__);
#define VMS_LOG(level,format,...)

#endif

