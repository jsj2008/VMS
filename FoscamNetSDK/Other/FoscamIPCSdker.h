//
//  FoscamIPCSdker.h
//  
//
//  Created by mac_dev on 16/4/25.
//
//

#ifndef ____FoscamIPCSdker__
#define ____FoscamIPCSdker__

#include <stdio.h>
#include "FoscamSdker.h"
#include "fossdk.h"

class CFoscamIPCSdker : public CFoscamSdker {
public:
    CFoscamIPCSdker(long);
    virtual bool login(int chn,LOGIN_DATA,int *);
    virtual void logout(int chn);
    virtual bool getRawData(int chn, char *data, int len, int *outLen);
    virtual bool getAudioData(int chn, char **data, int *outLen) ;
    virtual bool getEvent(FOSEVET_DATA *data);
    virtual bool openAV(int chn,LPPREVIEW_INFO preview_info,bool *is_audio);
    virtual void closeAV(int chn);
};

#endif /* defined(____FoscamIPCSdker__) */
