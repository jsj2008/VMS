//
//  FoscamSdker.cpp
//  
//
//  Created by mac_dev on 16/4/25.
//
//

#include "FoscamSdker.h"

CFoscamSdker::CFoscamSdker(long dev_id):
_fos_handle(FOSHANDLE_INVALID),
_timeout(500),
_retain_cnt(0),
_dev_id(dev_id),
_chn_states(0),
_chn_cnt(0)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&_mutex, &attr);
}

CFoscamSdker::~CFoscamSdker(void)
{}


const char *CFoscamSdker::errMsg(FOSCMD_RESULT code)
{
    switch (code) {
        case FOSCMDRET_FAILD:
            return "failed";
        case FOSUSRRET_USRNAMEORPWD_ERR:
            return "username or password error";
        case FOSCMDRET_EXCEEDMAXUSR:
            return "exceed max user number";
        case FOSCMDRET_NO_PERMITTION:
            return "no permit";
        case FOSCMDRET_UNSUPPORT:
            return "not support.";
        case FOSCMDRET_BUFFULL:
            return "buf is full";
        case FOSCMDRET_ARGS_ERR:
            return "args error";
        case FOSCMDRET_NOLOGIN:
            return "no login";
        case FOSCMDRET_NOONLINE:
            return "not on line";
        case FOSCMDRET_ACCESSDENY:
            return "the access deny.";
        case FOSCMDRET_DATAPARSEERR:
            return "parse data failed";
        case FOSCMDRET_USRNOTEXIST:
            return "user not exist";
        case FOSCMDRET_SYSBUSY:
            return "system busy";
        case FOSCMDRET_APITIMEERR:
            return "api time err";
        case FOSCMDRET_INTERFACE_CANCEL_BYUSR:
            return "interface cancel byusr";
        case FOSCMDRET_TIMEOUT:
            return "time out";
        case FOSCMDRET_HANDLEERR:
            return "handel error";
        case FOSCMDRET_UNKNOW:
        default:
            return "unknow error";
    }
}

#pragma mark - setter & getter
void CFoscamSdker::setChnState(int chn_states)
{
    _chn_states = chn_states;
}

int CFoscamSdker::chnStates()
{
    return _chn_states;
}

long CFoscamSdker::devId()
{
    return _dev_id;
}

int CFoscamSdker::timeout()
{
    return _timeout;
}

void CFoscamSdker::setTimeout(int t)
{
    if (t > 0) {
        _timeout = t;
    }
}

FOSHANDLE CFoscamSdker::fosHandle()
{
    return _fos_handle;
}

void CFoscamSdker::setFosHandle(FOSHANDLE h)
{
    _fos_handle = h;
}

int CFoscamSdker::channelCounts()
{
    return _chn_cnt;
}

void CFoscamSdker::setChannelCounts(int cnt)
{
    if (cnt >= 0) {
        _chn_cnt = cnt;
    }
}