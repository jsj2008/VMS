//
//  FoscamNVRSdker.h
//  
//
//  Created by mac_dev on 16/4/25.
//
//

#ifndef ____FoscamNVRSdker__
#define ____FoscamNVRSdker__

#include <stdio.h>
#include "FoscamSdker.h"
#include "fosnvrsdk.h"

class CFoscamNVRSdker : public CFoscamSdker {
public:
    CFoscamNVRSdker(long);
    virtual bool login(int chn,LOGIN_DATA,int *);
    virtual void logout(int chn);
    virtual bool getRawData(int chn, char *data, int len, int *outLen);
    virtual bool getAudioData(int chn, char **data, int *outLen) ;
    virtual bool getEvent(FOSEVET_DATA *data);
    virtual bool openAV(int,LPPREVIEW_INFO,bool *);
    virtual void closeAV(int);
};
#endif /* defined(____FoscamNVRSdker__) */
