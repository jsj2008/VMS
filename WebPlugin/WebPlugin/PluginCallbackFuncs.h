//
//  PluginCallbackFuncs.h
//  VMSWebPlugin
//
//  Created by mac_dev on 15/11/8.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#ifndef VMSWebPlugin_PluginCallbackFuncs_h
#define VMSWebPlugin_PluginCallbackFuncs_h

typedef void (*OnLoginCompletedFuc)(void *,int);
typedef void (*OnNetDisconnectFuc)(void*);
typedef void (*OnOpenVideoFuc)(void *,unsigned int vid, unsigned int result);
typedef void (*OnOpenAudioFuc)(void *,unsigned int vid, unsigned int result);
typedef void (*OnViewSelectedFuc)(void *,int selectIndex);
typedef void (*OnPlayProgressFuc)(void *,unsigned int vid, time_t cur_tm);
typedef struct Plugin_Callback_Fucs{
    OnLoginCompletedFuc onLoginCompleted;
    OnNetDisconnectFuc onNetDisconnect;
    OnOpenVideoFuc onOpenVideo;
    OnOpenAudioFuc onOpenAudio;
    OnViewSelectedFuc onViewSelected;
    OnPlayProgressFuc onPlayProgress;
}PluginCallbackFuncs;

#endif
