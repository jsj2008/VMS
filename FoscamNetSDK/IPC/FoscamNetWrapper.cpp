#include "FoscamNetWrapper.h"

int	TIME_OUT = 1000;

CFoscamNetWrapper::CFoscamNetWrapper(void)
{
}

CFoscamNetWrapper::~CFoscamNetWrapper(void)
{
	for (int i = 0; i < MAX_CLIENT; i++)
	{
		logout(i);
	}
}

CFoscamNetWrapper& CFoscamNetWrapper::instance()
{
	static CFoscamNetWrapper f;
	return f;
}

bool CFoscamNetWrapper::init()
{
	for (int i = 0; i < MAX_CLIENT; i++)
	{
		CFoscamNetWrapper::instance().fIPCClient[i].UserID(i);
	}

    FosSdk_SetLogLevel(0);
    FosSdk_SetYHLogLevel(0);
	return FosSdk_Init();
}

bool CFoscamNetWrapper::cleanup()
{
	FosSdk_DeInit();
	return true;
}

//long CFoscamNetWrapper::login1(long dev_id,int chn_id,FOSDEV_TYPE dev_type,LOGIN_DATA login_data,int *chn_cnt)
//{
//    long user_id = -1;
//    CFoscamSdker *sdker = NULL;
//    
//    {
//        pthread_auto_lock lk(&_mutex);
//        //查找空闲客户端
//        for (int i = 0; i < MAX_CLIENT; i++) {
//            if (!_clients[i].IsLogin() && !_clients[i].isRetain()) {
//                user_id = i;
//                _clients[i].setRetain(true);
//                break;
//            }
//        }
//        
//        //查找sdker
//        if (user_id >= 0) {
//            //添加IPC,NVR默认SDK
//            if (_devices.size() == 0) {
//                _devices.push_back(new CFoscamIPCSdker(INVALID_IPC));
//                _devices.push_back(new CFoscamNVRSdker(INVALID_NVR));
//            }
//            
//            std::vector<CFoscamSdker *>::iterator iter;
//            for (iter = _devices.begin();iter != _devices.end();++iter) {
//                //相同devId,并且对应通道未占用
//                if (((*iter)->devId() == dev_id) &&
//                    !((*iter)->chnStates() & (1 << 0))) {
//                    sdker = *iter;
//                    break;
//                }
//            }
//            
//            if (sdker == NULL) {
//                switch (dev_type) {
//                    case FOSIPC_H264:
//                    case FOSIPC_MJ:
//                        sdker = new CFoscamIPCSdker(dev_id);
//                        break;
//                    case FOSNVR:
//                        sdker = new CFoscamNVRSdker(dev_id);
//                        break;
//                    case FOS_UNKNOW:
//                    default:
//                        break;
//                }
//                
//                if (sdker) {
//                    _devices.push_back(sdker);
//                }
//            }
//        }
//    }
//    
//    if (user_id >= 0 && sdker) {
//        if (_clients[user_id].login(sdker, chn_id, login_data, chn_cnt)) {
//            _clients[user_id].setRetain(false);
//            printf("success login!\n");
//            return user_id;
//        } else {
//            _clients[user_id].setRetain(false);
//            return -1;
//        }
//    } else {
//        printf("没有合适的user_id可供分配");
//    }
//    
//    return user_id;
//}


long CFoscamNetWrapper::login(LOGIN_DATA *loginData )
{
	long userID = -1;
    
    //安全区，同一时刻，只有一个线程可以访问
    {
        pthread_auto_lock lk(&_mutex);
        for (int i = 0; i < MAX_CLIENT; i++)
        {
            if (!fIPCClient[i].IsLogin() && !fIPCClient[i].retain())
            {
                userID = i;
                fIPCClient[i].retain(true);
                break;
            }
        }
    }

	if (userID == -1)
	{
		return -1;
	}

	if (fIPCClient[userID].login(loginData))
	{
		fIPCClient[userID].retain(false);
		return userID;
	}
	else
	{
		fIPCClient[userID].retain(false);
		return -1;
	}
}

//void CFoscamNetWrapper::logout1(long user_id)
//{
//    if (user_id >= 0 && user_id < MAX_CLIENT) {
//        stopRealPlay1(user_id);
//        _clients[user_id].logout();
//    }
//}

bool CFoscamNetWrapper::logout( long userID )
{
	if (userID < 0 || userID >= MAX_CLIENT)
	{
		return -1;
	}

	stopRealPlay(userID);

	return fIPCClient[userID].logout();
}


bool CFoscamNetWrapper::modifyLoginInfo(long userID,char *newName,char* newPwd)
{
    if (userID >= 0 || userID < MAX_CLIENT)
    {
        return fIPCClient[userID].modifyLoginInfo(newName, newPwd);
    }
  
    return false;
}

//bool CFoscamNetWrapper::realPlay1(long user_id, LPPREVIEW_INFO preview_info, NET_DataCallBack data_callback, void* user_info)
//{
//    if (user_id >= 0 && user_id < MAX_CLIENT)
//    {
//        return _clients[user_id].realPlay(preview_info, data_callback, user_info);
//    }
//
//    return false;
//}

//void CFoscamNetWrapper::stopRealPlay1(long userID)
//{
//    if (userID >= 0 && userID < MAX_CLIENT)
//    {
//        _clients[userID].stopRealPlay();
//    }
//}


long CFoscamNetWrapper::realPlay(long userID, LPPREVIEW_INFO previewInfo, NET_DataCallBack avnetDataCB, void* user)
{
	if (userID < 0 || userID >= MAX_CLIENT)
	{
		return -1;
	}
	
	return fIPCClient[userID].realPlay(previewInfo, avnetDataCB, user);
}

bool CFoscamNetWrapper::stopRealPlay( long userID )
{
	if (userID < 0 || userID >= MAX_CLIENT)
	{
		return -1;
	}

	return fIPCClient[userID].stopRealPlay();
}

int CFoscamNetWrapper::ptz( long userID, PTZ_CMD ptz )
{
	if (userID < 0 || userID >= MAX_CLIENT)
	{
		return -1;
	}

	return fIPCClient[userID].ptz(ptz);
}

bool CFoscamNetWrapper::search( void* node, long* size )
{
	if(FosSdk_Discovery((FOSDISCOVERY_NODE*)node, (int*)size, 1500) == FOSCMDRET_OK)
		return true;

	return false;
}

bool CFoscamNetWrapper::getConfig( long userID, long type, void *config )
{
	if (userID < 0 || userID >= MAX_CLIENT)
	{
		return -1;
	}

	return fIPCClient[userID].getConfig(type, config);	
}

bool CFoscamNetWrapper::setConfig( long userID, long type, void *config )
{
	if (userID < 0 || userID >= MAX_CLIENT)
	{
		return -1;
	}

	return fIPCClient[userID].setConfig(type, config);	
}

bool CFoscamNetWrapper::setEventCB( long userID, NET_Event_CallBack cbNetEvent, void *userData )
{
	if (userID < 0 || userID >= MAX_CLIENT)
	{
		return -1;
	}

	return fIPCClient[userID].setEventCB(cbNetEvent, userData);	
}

bool CFoscamNetWrapper::getEventData( long userID, FOSCAM_IPC_NET_EVENT_DATA* eventData )
{
	if (userID < 0 || userID >= MAX_CLIENT)
	{
		return -1;
	}

	return fIPCClient[userID].getEventData(eventData);	
}

bool CFoscamNetWrapper::talk( long userID, char* data, int dataLen )
{
    if (userID < 0 || userID >= MAX_CLIENT)
    {
        return false;
    }
    
    return fIPCClient[userID].talk(data, dataLen);
}

bool CFoscamNetWrapper::openTalk( long userID )
{
    if (userID < 0 || userID >= MAX_CLIENT)
    {
        return false;
    }
    
    //仅支持一路对讲，开启前先关闭所有
    for (int i = 0; i < MAX_CLIENT; i++) {
        fIPCClient[i].closeTalk();
    }
    
    return fIPCClient[userID].openTalk();
}

bool CFoscamNetWrapper::closeTalk( long userID )
{
    if (userID < 0 || userID >= MAX_CLIENT)
    {
        return false;
    }
    
    return fIPCClient[userID].closeTalk();
}


