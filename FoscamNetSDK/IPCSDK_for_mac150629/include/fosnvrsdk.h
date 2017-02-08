#ifndef __FOSSDK_SRC_INCLUDE_FOSNVRSDK__
#define __FOSSDK_SRC_INCLUDE_FOSNVRSDK__
#include "FosNvrDef.h"
#define FOSSDK_NVR_VERSION  "2.1.1.3621"
#ifdef __cplusplus
extern "C" {
#endif

#define SETCHANNEL(val, ch)  val |= (0x1<<ch);
#define CLEANCHANNEL(val, ch) val &= (~(0x1<<ch));
#define SETALLCHANNEL(val)	val = ~0x0;

	//说明:
	//参数定义 channels 表示 多通道， 通道按位表示 使用 SETCHANNEL  CLEANCHANNEL SETALLCHANNEL
	//参数定义 channel 表示 通道， 数值直接代表通道

	/************************************************************************/
	/* common                                                                */
	/************************************************************************/
	/*
	@Name: FosNvr_SetLogLevel.
	@Description: set Level of log.
	@param loglevel: see LogLevel in FosCom.h
	*/
	FOSSDK void FOSAPI FosNvr_SetLogLevel(int loglevel);


    /*
	@Name: FosSdk_SetLogPath.
	@Description: Set the print log file storage path for windows.
	*/
	FOSSDK void FOSAPI FosNvr_SetLogPath(char *path, int b_print);

	
	/*
	@Name: FosNvr_GetSdkVersion.
	@Description: get nvrsdk version.
	*/
	FOSSDK char* FOSAPI FosNvr_GetSdkVersion();

	/************************************************************************/
	/* system                                                                 */
	/************************************************************************/
	/*
	@Name: FosNvr_Init.
	@Description: init some basic SDK params.
	@tips: 此函数与 FosSdk_Init() 函数不能同时使用。
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_Init();
	/*
	@Name: FosNvr_DeInit.
	@Description: deinit.
	@tips: 此函数与 FosSdk_DeInit() 函数不能同时使用。
	*/
	FOSSDK void FOSAPI FosNvr_DeInit();
	/*
	@Name: FosNvr_ReInitP2P.
	@Description: reinit TUTK P2P info.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_ReInitP2P();

	/*
	@Name: FosNvr_SetConnectLev.
	@Description: Set connection level. exp：FosNvr_SetConnectLev(3，2，1)， the biggest is the first way to connect.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_SetConnectLev(unsigned int ipLev, unsigned int p2pLev, unsigned int ddnsLev);

	/*
	@Name: FosNvr_Create.
	@Description: Create a connection to the NVR.
	@param ddns: ddns
	@param ddnsport: ddnsport
	@param ip: ip
	@param ipport: ipport
	@param uid: uid
	@param mac: mac
	@param username: username
	@param pwd: password
	*/
	FOSSDK FOSHANDLE FOSAPI FosNvr_Create(char *ddns, short ddnsport, char *ip, short ipport, 
		char *uid, char *mac, char *username, char *pwd);
	/*
	@Name: FosNvr_Release.
	@Description: release NVR connection by handle.
	@param handle: connection handle
	*/
	FOSSDK void FOSAPI FosNvr_Release(FOSHANDLE handle);
	/*
	@Name: FosNvr_HookStream.
	@Description: hook media data,by callback function.//创建钩子，直接通过回调获取视频信息
	@param handle: connection handle
	@param fun: callback function of type  HOOKSTREAMFUN
	@param usrdata: usrdata
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_HookStream(FOSHANDLE handle, HOOKSTREAMFUN *fun, void *usrdata);
	/*
	@Name: FosNvr_Login.
	@Description: login nvr device.
	@param handle: connection handle
	@param usrRight(out): user privilege
	@param nChannel(out): nvr channels
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_Login(FOSHANDLE handle, int *usrRight, int *nChannel, int timeOutMS);
	/*
	@Name: FosNvr_LogOut.
	@Description: logout nvr device.
	@param handle: connection handle
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_LogOut(FOSHANDLE handle, int timeOutMS);
	/*
	@Name: FosNvr_CheckHandle.
	@Description: Check Ctrl state.
	@param handle: connection handle
	*/
	FOSSDK FOS_HANDLE_STATE FOSAPI FosNvr_CheckHandle(FOSHANDLE handle);
	//预览相关
	/************************************************************************/
	/* Live operation                                                                     */
	/************************************************************************/
	/*
	@Name: FosNvr_OpenVideo.
	@Description: OpenVideo.
	@param handle: connection handle
	@param channels: channels , 0x1111 means channel 1,2,3,4 
	@param streamtype: streamtype 
	@param videoMode: videoMode 
	@param qcMode: qcMode 
	@param chMode: chMode 
	@param reDecChs: channels for recodec video, not use when videoMode is FOSNVRVIDEOMODE_NOMAL.
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_OpenVideo(FOSHANDLE handle, int channels, FOSSTREAM_TYPE streamtype,
												 FOSNVR_VIDEOMODE videoMode, FOSNVR_REDECPQMODE qcMode, 
												 FOSNVR_REDECMODE chMode, int reDecChs, int timeOutMS);
	/*
	@Name: FosNvr_CloseVideo.
	@Description: CloseVideo.
	@param handle: connection handle
	@param channels: channels 
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_CloseVideo(FOSHANDLE handle, int channels, int timeOutMS);
	/*
	@Name: FosNvr_GetVideoData.
	@Description: get decoded video data.
	@param handle: connection handle
	@param channel: video channel
	@param data: data 
	@param outLen: datalen
	@param videoFmt: decode videoFmt
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetVideoData(FOSHANDLE handle, int channel, char **data, int *outLen, 
		                                            FOSDECFMT videoFmt);
	/*
	@Name: FosNvr_GetRawVideoData.
	@Description: get raw video data.
	@param handle: connection handle
	@param channel: video channel
	@param data: data 
	@param len: data space len
	@param outLen: retrurn datalen
	@param videoFmt: decode videoFmt
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetRawVideoData(FOSHANDLE handle, int channel, char *data, int len, int *outLen);

	/*
	@Name: FosNvr_GetRawVideoData2.
	@Description: get raw video data.
	@param handle: connection handle
	@param channel: video channel
	@param data: data 
	@param len: data space len
	@param outLen: retrurn datalen
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetRawVideoData2(FOSHANDLE handle, int channel, char **data, int len, int *outLen);

	/*
	@Name: FosNvr_GetAudioData.
	@Description: get live audio data.
	@param handle: connection handle
	@param channel: data channel
	@param data: data 
	@param outLen: return datalen
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetAudioData(FOSHANDLE handle, int channel, char **data, int *outLen);
	/************************************************************************/
	/* playback                                                                     */
	/************************************************************************/
	/*
	@Name: FosNvr_OpenPlayBack.
	@Description: playback back.
	@param handle: connection handle
	@param channels: channels to open
	@param sTime: record sTime 
	@param eTime: record eTime 
	@param offsetTime: offsetTime 
	@param videoMode: videoMode 
	@param timeOutMS: timeOutMS 
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_OpenPlayBack(FOSHANDLE handle, int channels, unsigned int sTime, unsigned int eTime,
													unsigned int offsetTime, FOSNVR_VIDEOMODE videoMode, int timeOutMS);
	/*
	@Name: FosNvr_PlayBackCmd.
	@Description: cmd for playback.
	@param handle: connection handle
	@param channels: channels to open
	@param cmd: playback cmd
	@param timeOutMS: timeOutMS 
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_PlayBackCmd(FOSHANDLE handle, FOSNVR_PBCMD cmd, int sTime, int value, int timeOutMS);
	/*
	@Name: FosNvr_ClosePlayback.
	@Description: Close playback.
	@param handle: connection handle
	@param timeOutMS: timeOutMS 
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_ClosePlayback(FOSHANDLE handle, int timeOutMS);
	/*
	@Name: FosNvr_GetPBVideoData.
	@Description: get playback videodata.
	@param handle: connection handle
	@param channel: channel
	@param data: data
	@param outLen: data len
	@param videoFmt: decode videoFmt
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetPBVideoData(FOSHANDLE handle, int channel, char **data, 
													  int *outLen, FOSDECFMT videoFmt);
	/*
	@Name: FosNvr_GetPBRawVideoData.
	@Description: get playback raw video data.
	@param handle: connection handle
	@param channel: channel
	@param data: data
	@param len: data space len
	@param outLen(OUT): data len 
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetPBRawVideoData(FOSHANDLE handle, int channel, char *data, int len, int* outLen);
	
	/*
	@Name: FosNvr_GetPBRawVideoData2.
	@Description: get playback raw video data.
	@param handle: connection handle
	@param channel: video channel
	@param data: data 
	@param len: data space len
	@param outLen: return datalen
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetPBRawVideoData2(FOSHANDLE handle, int channel, char **data, int len, int *outLen);

	/*
	@Name: FosNvr_GetPBAudioData.
	@Description: get playback audio data.
	@param handle: connection handle
	@param channel: channel
	@param data: data
	@param outLen(OUT): data len
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetPBAudioData(FOSHANDLE handle, int channel, char **data, int *outLen);
	/*
	@Name: FosNvr_GetPBCacheInfo.
	@Description: get playback streamBuffer information.
	@param handle: connection handle
	@param channels: channels (not use)
	@param cacheInfo: streamBuffer information
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetPBCacheInfo(FOSHANDLE handle, int channels, FOSNVR_CacheInfo *cacheInfo);

	FOSSDK int FOSAPI FosNvr_GetPBSavedMemSize(FOSHANDLE handle, int channels);

	FOSSDK int FOSAPI FosNvr_GetPBFrameSize(FOSHANDLE handle, int channels);
	/************************************************************************/
	/*  download                                                            */
	/************************************************************************/
	/*
	@Name: FosNvr_SetDownLoadPath.
	@Description: get playback streamBuffer information.
	@param handle: connection handle
	@param path: path like "d://testNvrDown//" or "/usr/local/"
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_SetDownLoadPath(FOSHANDLE handle, char *path);
	/*
	@Name: FosNvr_DownLoadRecord.
	@Description: start downLoad record.
	@param handle: connection handle
	@param files: record info for downloading
	@param count: downLoad count
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_DownLoadRecord(FOSHANDLE handle, FOSNVR_RecordNode *files, int count);
	/*
	@Name: FosNvr_DownLoadCancel.
	@Description: stop download.
	@param handle: connection handle
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_DownLoadCancel(FOSHANDLE handle);
	/************************************************************************/
	/* upgrade                                                                 */
	/************************************************************************/
	/*
	@Name: FosNvr_UpgradeNvrByFile.
	@Description: Upgrade Nvr device by file.
	@param handle: connection handle
	@param file: file path
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_UpgradeNvrByFile(FOSHANDLE handle, char* file, int timeOutMS);
	/*
	@Name: FosNvr_UpgradeIpcByFile.
	@Description: Upgrade Ipc device by file.
	@param handle: connection handle
	@param file: file path
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_UpgradeIpcByFile(FOSHANDLE handle, char* file, int chns, int timeOut);
	/*
	@Name: FosNvr_UpgradeNvrByRemote.
	@Description: Remote Upgrade NVR device.
	@param handle: connection handle
	@param url: url
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_UpgradeNvrByRemote(FOSHANDLE handle, char *url, int timeOutMS);
	/*
	@Name: FosNvr_UpgradeIpcByRemote.
	@Description: Remote Upgrade IPC device.
	@param handle: connection handle
	@param url: url
	@param channel: channel
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_UpgradeIpcByRemote(FOSHANDLE handle, char *url, int channel, int timeOutMS);
	/************************************************************************/
	/*  ctrl cmd                                                                    */
	/************************************************************************/
	/*
	@Name: FosNvr_GetCGIResult.
	@Description: send cgi cmd and get result.
	@param handle: connection handle
	@param data: cgi cmd. exp:"cmd=getDevInfo"
	@param raw: cgi result
	@param rawLen(OUT): result len
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetCGIResult(FOSHANDLE handle, char *data, char* raw, int* rawLen, int timeOutMS);

    FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetCGIResult2(FOSHANDLE handle, char *data, char* raw, int* rawLen, int timeOutMS);

	/*
	@Name: FosNvr_GetIPCCGIResult.
	@Description: send cgi cmd to IPC  and get result.
	@param handle: connection handle
	@param channel: channel
	@param data: cgi cmd. exp:"cmd=getDevInfo"
	@param raw: cgi result
	@param rawLen(OUT): result len
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetIPCCGIResult(FOSHANDLE handle, int channel, char *data, char* raw, 
		                                               int rawLen, int timeOutMS);
	/*
	@Name: FosNvr_SearchRecordFiles.
	@Description: serch record.
	@param handle: connection handle
	@param sTime: sTime
	@param eTime: eTime
	@param channels: channels
	@param type: file type
	@param nodeCount(OUT):file Count
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_SearchRecordFiles(FOSHANDLE handle, long long sTime, long long eTime, int channels,FOSNVR_RECORDTYPE type, int *nodeCount, int timeOutMS);
	/*
	@Name: FosNvr_GetRecordNodeInfo.
	@Description: get serched record fileinfo.
	@param handle: connection handle
	@param nodeIndex: nodeIndex
	@param node: array to store fileinfo.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetRecordNodeInfo(FOSHANDLE handle, int nodeIndex, FOSNVR_RecordNode *node);
	/************************************************************************/
	/* device serch                                                                     */
	/************************************************************************/
	/*
	@Name: FosNvr_GetIPCList.
	@Description: get ipclist info.
	@param handle: connection handle
	@param ipcNode: array to store ipc info.
	@param size(OUT): ipc count.
	@param timeOutMS:timeOutMS.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetIPCList(FOSHANDLE handle, FOSNVR_IpcNode* ipcNode, int *size, int timeOutMS);
	/*
	@Name: FosNvr_DiscoveryCurrentNVR.
	@Description: DiscoveryCurrentNVR.
	@param handle: connection handle
	@param ipInfo(OUT): nvr info
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_DiscoveryCurrentNVR(FOSHANDLE handle, FOSDISCOVERY_NODE *ipInfo, int timeOutMS);
	/*
	@Name: FosNvr_Discovery.
	@Description: Discovery NVR device.
	@param nvrNode: array to store nvr info.
	@param size(OUT): nvr count
	@param timeOutMS: timeOutMS
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_Discovery(FOSDISCOVERY_NODE *nvrNode, int *size);
	/*
	@Name: FosNvr_StopDiscovery.
	@Description: StopDiscovery.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_StopDiscovery();
	/*
	@Name: FosNvr_RestartDiscovery.
	@Description: RestartDiscovery.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_RestartDiscovery();
	/************************************************************************/
	/* event                                                                      */
	/************************************************************************/
	/*
	@Name: FosNvr_GetEvent.
	@Description: get timely event message.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_GetEvent(FOSHANDLE handle, FOSNVR_EvetData *data);
	/************************************************************************/
	/* local record                                                                     */
	/************************************************************************/
	/*
	@Name: FosNvr_StartRecord.
	@Description: start record, get videodata by live and save as file.
	@param handle: connection handle
	@param channel: record channel 
	@param file: filepath to save
	@param type: filetype, exp:.mp4, .avi
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_StartRecord(FOSHANDLE handle,int channel, const char *file, FOSRECORDTYPE type);
	/*
	@Name: FosNvr_StopRecord.
	@Description: StopRecord.
	@param handle: connection handle
	@param channel: record channel 
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_StopRecord(FOSHANDLE handle, int channel);
	/************************************************************************/
	/*  snap picture                                                                    */
	/************************************************************************/
	/*
	@Name: FosNvr_SnapPic2File.
	@Description: Snap Picture to File.
	@param filePathName: filePath
	@param channel: channel 
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_SnapPic2File(FOSHANDLE handle, int channel, char *filePathName);
	/*
	@Name: FosNvr_SnapPic2Buffer.
	@Description: StopRecord.
	@param channel: channel 
	@param handle: picture data
	@param len(OUT): data len
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_SnapPic2Buffer(FOSHANDLE handle, int channel, char *data, int *len);

	/************************************************************************/
	/*  snap picture                                                                    */
	/************************************************************************/
	/*
	@Name: FosNvr_SnapPicRawdataFile.
	@Description: Snap Picture to File.
	@param filePathName: filePath
	@param channel: channel 
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_SnapPicRawdataFile(FOSHANDLE handle, int channel, char *filePathName);

	/*
	@Name: SnapPicRawdataBuffer.
	@Description: StopRecord.
	@param channel: channel 
	@param handle: picture data
	@param len(OUT): data len
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosNvr_SnapPicRawdataBuffer(FOSHANDLE handle, int channel, char *data, int *len);
#ifdef __cplusplus
}
#endif
#endif
