/*
* Copyright (c) 2014,foscam
* All rights reserved.
*
* File Name: fossdk.h
* Abstract: FosSdk Interface File
*
* Current Version: 1.0
* Author: FosCam
*
* Completion Date: 2014-09-22
*/

#ifndef __FOSSDK_SRC_INCLUDE_FOSSDK__
#define __FOSSDK_SRC_INCLUDE_FOSSDK__
#include "FosDef.h"

#define FOSDECODERHANDLE	void*
#define PLAYERHADLE			void*
#define FOSSDK_IPC_VERSION  "2.2.1.3621"
#ifdef __cplusplus
extern "C" {
#endif
	
	/*
	@Name: FosSdk_SetLoglevel.
	@Description: set Level of log.
	@param loglevel: see LogLevel in FosCom.h
	*/
	FOSSDK void FOSAPI FosSdk_SetLogLevel(int level);

	/*
	@Name: FosSdk_SetYHLoglevel.
	@Description: set Level of log for YH.
	*/
	FOSSDK void FOSAPI FosSdk_SetYHLogLevel(int level);

	/*
	@Name: FosSdk_SetLogPath.
	@Description: Set the print log file storage path for windows.
	*/
	FOSSDK void FOSAPI FosSdk_SetLogPath(char *path, int b_print);

	/*
	@Name: FosSdk_GetSdkVersion.
	@param version: save version.
	@Description: Get the current version number of  foscam SDK
	*/
	FOSSDK void FOSAPI FosSdk_GetSdkVersion(char *version);

	/*
	@Name: FosSdk_Init.
	@Description: Initialization FosSdk,initialize some things that use FosSdk need,must use this function first.
	@return: 1 is succeed;zero is failed.
	*/
	FOSSDK int FOSAPI FosSdk_Init();

	/*
	@Name: FosSdk_DeInit.
	@Description: Delete Initialization,release the resources which throw initialization to get at the last.
	@return: void.
	*/
	FOSSDK void FOSAPI FosSdk_DeInit();
    FOSSDK int FOSAPI FosSdk_ReInitP2P();

	/*
	@Name: FosSdk_Create.
	@Description: Create a connection to the ipc.
	@param url: The url of IPC.
	@param uid: p2p uid.
	@param usr: user name to login ipc.
	@param pwd: password to login ipc.
	@param webPort: Web port.
	@param mediaPort: Media port.
	@param type: IPC type,FOSIPC_H264 or FOSIPC_MJ or FOSIPC_UNKNOW.
	@param connectType: Connect type,is FOSCNTYPE_P2P or FOSCNTYPE_IP.
	@return: handle,this handle is that ipc connection identifier.
	*/
	FOSSDK FOSHANDLE FOSAPI FosSdk_Create(char *url, char *uid, char *usr, char *pwd, unsigned short webPort, unsigned short mediaPort, FOSDEV_TYPE type, FOSIPC_CONNECTTION_TYPE connectType);

	FOSSDK FOSHANDLE FOSAPI FosSdk_Create2(char *ip, char* ddns, char *uid, char *usr, char *pwd, unsigned short webPort, unsigned short mediaPort, unsigned short ddnsWebPort, unsigned short ddnsMediaPort, char *mac, FOSDEV_TYPE type, FOSIPC_CONNECTTION_TYPE connectType);
    
	FOSSDK FOSHANDLE FOSAPI FosSdk_Create3(char *ip, char* ddns, char *uid, char *usr, char *pwd, unsigned short webPort, unsigned short mediaPort, unsigned short ddnsWebPort, unsigned short ddnsMediaPort, char *mac, FOSDEV_TYPE type, FOSIPC_CONNECTTION_TYPE connectType, FOSSTREAM_TYPE streamType);

    FOSSDK FOS_HANDLE_STATE FOSAPI FosSdk_RetainHandle(FOSHANDLE handle, int *usrRight);
    FOSSDK FOS_HANDLE_STATE FOSAPI FosSdk_CheckHandle(FOSHANDLE handle, int *usrRight);
    FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetHandleInfo(FOSHANDLE handle, char *usr, char *pwd);
	/*
	@Name: FosSdk_Release.
	@Description: Release the connection of ipc.
	@param handle: the handle of current connection information.
	@return: void.
	*/
	FOSSDK void FOSAPI FosSdk_Release(FOSHANDLE handle);
	
	/*About NetWork*/

	/*
	@Name: FosSdk_Login.
	@Description: Login work,user login,create ctrl thread and media thread.
	@param handle: the handle of current connection information.
	@param usrPrivilege: the privilege of user.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_Login(FOSHANDLE handle, int *usrPrivilege, int timeOutMS);

	/*
	@Name: FosSdk_Logout.
	@Description: Logout,user quit and exit thread.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return: void.
	*/
	FOSSDK void FOSAPI FosSdk_Logout(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_OpenVideo.
	@Description: Send command to IPC,let IPC send video data to FosSdk,FosSdk can get video data to do somethings.
	@param handle: the handle of current connection information.
	@param streamType: Stream type,is FOSSTREAM_MAIN or FOSSTREAM_SUB.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_OpenVideo(FOSHANDLE handle, FOSSTREAM_TYPE streamType, int timeOutMS);

	/*
	@Name: FosSdk_CloseVideo.
	@Description: Send command to IPC,let IPC not send video data to FosSdk,FosSdk don't get video data.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_CloseVideo(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_OpenPBVideo.
	@Description: Send command to IPC,let IPC send video data to FosSdk,FosSdk can get video data to do somethings.
	@param handle: the handle of current connection information.
	@param filePath: 0-sdcard 2-ftp.
	@param fileName: file name.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_OpenPBVideo(FOSHANDLE handle, int filePath ,char *fileName, int timeOutMS);

	/*
	@Name: FosSdk_ClosePBVideo.
	@Description: Send command to IPC,let IPC not send video data to FosSdk,FosSdk don't get video data.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ClosePBVideo(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_PausePBVideo.
	@Description: Send command to IPC,let IPC not send video data to FosSdk,FosSdk don't get video data.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PausePBVideo(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_ResumePBVideo.
	@Description: Send command to IPC,let IPC not send video data to FosSdk,FosSdk don't get video data.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ResumePBVideo(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_SeekPBVideo.
	@Description: Send command to IPC,let IPC not send video data to FosSdk,FosSdk don't get video data.
	@param handle: the handle of current connection information.
	@param seekTime: seek time.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SeekPBVideo(FOSHANDLE handle, unsigned int seekTime, int timeOutMS);

	/*
	@Name: FosSdk_GetPBFrameSize.
	@Description: Send command to IPC,let IPC not send video data to FosSdk,FosSdk don't get video data.
	@param handle: the handle of current connection information.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK int FOSAPI FosSdk_GetPBFrameSize(FOSHANDLE handle);

	/*
	@Name: FosSdk_OpenAudio.
	@Description: Send command to IPC,let IPC send audio data to FosSdk,FosSdk can get audio data to do somethings.
	@param handle: the handle of current connection information.
	@param streamType: Stream type,is FOSSTREAM_MAIN or FOSSTREAM_SUB.
	@param timeOutMS: Time limits of timeout.
	@return: the size of video frame int buffer.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_OpenAudio(FOSHANDLE handle, FOSSTREAM_TYPE streamType, int timeOutMS);

	/*
	@Name: FosSdk_CloseAudio.
	@Description: Send command to IPC,let IPC not send audio data to FosSdk,FosSdk don't get audio data.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_CloseAudio(FOSHANDLE handle, int timeOutMS);


	/*
	@Name: FosSdk_OpenTalk.
	@Description: Open the talk which IPC.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_OpenTalk(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_CloseTalk.
	@Description: Close talk which IPC.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_CloseTalk(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_SendTalkData.
	@Description: Send the data of talk.
	@param handle: the handle of current connection information.
	@param data: The data need to send.
	@param len: Len of data.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SendTalkData(FOSHANDLE handle, char *data, int len);

	/*
	@Name: FosSdk_CallCGIRaw.
	@Description: Send CGI command to IPC and get the return raw data.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param data: CGI command.
	@param raw: CGI command return raw data.
	@param rawLen: the length of CGI command return raw data.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_CallCGIRaw(FOSHANDLE handle, char *data, char* raw, int* rawLen, int timeOutMS);

	/*
	@Name: FosSdk_CallCGIRawAndEncode.
	@Description: Send CGI command to IPC and get the return raw data.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param data: CGI command which SDK had URL encoding.
	@param raw: CGI command return raw data.
	@param rawLen: the length of CGI command return raw data.
	@return£ºPlease refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_CallCGIRawAndEncode(FOSHANDLE handle, char *data, char* raw, int* rawLen, int timeOutMS);

	/*
	@Name: FosSdk_NetSnapPicture.
	@Description: Manual snap picture.
	@param mjpegPath: the path of mjpeg-picture.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_NetSnapPicture(FOSHANDLE handle, int timeOutMS, char *mjpegPath);

	/*
	@Name: FosSdk_NetSnap.
	@Description: Manual snap picture.
	@param snapPicBuff: the buffer of picture data.
	@param snapPicBuffSize: the size of buffer.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_NetSnap(FOSHANDLE handle, int timeOutMS, char *snapPicBuff,int *snapPicBuffSize);

	/*
	@Name: FosSdk_NetSnapScale.
	@Description: Manual snap picture.
	@param snapPicBuff: the buffer of picture data.
	@param snapPicBuffSize: the size of buffer.
	@param width: destination width of picture after scaled.
	@param height: destination height of picture after scaled.
	@param type: destination type of picture after scaled.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_NetSnapScale(FOSHANDLE handle, int timeOutMS, char *snapPicBuff,int *snapPicBuffSize, int width, int height, FOSDECFMT type);

	/*
	@Name: FosSdk_LocalScalePicture.
	@Description: Manual snap picture.
	@param filePath: the path of local picture file.
	@param dataSize: the bytes of local picture data.
	@param width: destination width of picture after scaled.
	@param height: destination height of picture after scaled.
	@param type: destination type of picture after scaled.
	@param outputPicBuff: the buffer of output picture.
	@param outputPicBuffSize: the buffer size of output picture.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_LocalScalePicture(char *filePath, int dataSize, int width, int height, FOSDECFMT type, char *outputPicBuff,int *outputPicBuffSize);

	/*
	@Name: FosSdk_ImportConfig.
	@Description: Send CGI importConfig to import config file.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param filePath: the path of imported file.
	@param importResult: the import Result.0 successfully ;-1 failed.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ImportConfig(FOSHANDLE handle, int timeOutMS, char *filePath, int *importResult);
	/*
	@Name: FosSdk_FwUpgrade.
	@Description: Send CGI fwUpgrade to upgrade firmware.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param upgradeResult(out):  0-Upgrade success  1-Upgrade fail.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_FwUpgrade(FOSHANDLE handle, int timeOutMS, char *filePath, int *upgradeResult);

	/************************************************************************/
	/*                          User Account                                */
	/************************************************************************/
	/*
	@Name: FosSdk_LogInCGI.
	@Description: Send login CGI, log in to camera and receive result,saved in param of logInResult.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param logInResult(out): result information of login action with usrName and pwd.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_LogInCGI(FOSHANDLE handle, int timeOutMS, FOS_LOGINRESULT* logInResult);
	/*
	@Name: FosSdk_LogOutCGI.
	@Description: Send logout CGI ,log out to camera.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_LogOutCGI(FOSHANDLE handle, int timeOutMS);


		/*
	@Name: FosSdk_GetProductAllInfo.
	@Description: Send CGI getProductAllInfo to get get camera Information.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param productAllInfo: a struct pointer to save the address of camera Information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductAllInfo(FOSHANDLE handle, int timeOutMS, FOS_PRODUCTALLINFO* productAllInfo);


#ifndef WEB_PLUGIN

	/*
	@Name: FosSdk_GetP2PMode.
	@Description: Get the  P2P connection mode
	@Return //!< 0: P2P mode, 1: Relay mode, 2: LAN mode
	*/
	FOSSDK int FOSAPI FosSdk_GetP2PMode(FOSHANDLE handle,FOS_P2PMODE *p2pmode);
	/************************************************************************/
	/*                               PTZ                                    */
	/************************************************************************/

	/*
	@Name: FosSdk_PtzCmd.
	@Description: ptz move control.
	@param cmd: direction enumeration.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PtzCmd(FOSHANDLE handle, FOSPTZ_CMD cmd, int timeOutMS);

	/*
	@Name: FosSdk_PTZSetSpeed.
	@Description: ptz move speed.
	@param cmd: speed enumeration.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetSpeed(FOSHANDLE handle, FOSPTZ_SPEED cmd, int timeout); //ptzSpeed

	/*
	@Name: FosSdk_PTZGetSpeed.
	@Description: get the speed of ptz.
	@param speed: speed.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetSpeed(FOSHANDLE handle, int timeout, int *speed); 

	/*
	@Name: FosSdk_PTZGetPresetPointList.
	@Description: get the list of preset point.
	@param presetPointList: the list of preset point.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetPresetPointList(FOSHANDLE handle, int timeout, FOS_RESETPOINTLIST *presetPointList);

	/*
	@Name: FosSdk_PTZAddPresetPoint.
	@Description: add preset point.
	@param pointName: the name of preset point.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZAddPresetPoint(FOSHANDLE handle, char* pointName, int timeout ,FOS_RESETPOINTLIST *presetPointList);

	/*
	@Name: FosSdk_PTZDelPresetPoint.
	@Description: delete preset point.
	@param pointName: the name of preset point.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZDelPresetPoint(FOSHANDLE handle, char* pointName, int timeout ,FOS_RESETPOINTLIST *presetPointList);

	/*
	@Name: FosSdk_PTZSetGuardPosition.
	@Description: set guard position.
	@param positionName: the name of guard position.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetGuardPosition(FOSHANDLE handle, char* positionName, int timeout);

	/*
	@Name: FosSdk_PTZGetGuardPosition.
	@Description: Get guard position.
	@param positionName: the name of guard position.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetGuardPosition(FOSHANDLE handle, char* positionName, int timeout);

	/*
	@Name: FosSdk_PTZSetGuardPositionBackTime.
	@Description: Set the minutes of position back time.
	@param minutes: the minutes of position back time.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetGuardPositionBackTime(FOSHANDLE handle, int minutes, int timeout);

	/*
	@Name: FosSdk_PTZGetGuardPositionBackTime.
	@Description: Get the minutes of position back time.
	@param minutes: the minutes of position back time.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetGuardPositionBackTime(FOSHANDLE handle, int *minutes, int timeout);

	/*
	@Name: FosSdk_PTZGoToPresetPoint.
	@Description: go to preset point.
	@param pointName: the name of preset point. 
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGoToPresetPoint(FOSHANDLE handle, char* pointName, int timeout);

	/*
	@Name: FosSdk_PTZGetCruiseMapList.
	@Description: get the list of cruise map.
	@param cruiseMapList: the list of cruise map. 
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetCruiseMapList(FOSHANDLE handle, int timeout, FOS_CRUISEMAPLIST *cruiseMapList);

	/*
	@Name: FosSdk_PTZGetCruiseMapInfo.
	@Description: get the information of cruise map.
	@param cruiseMapName: the name of cruise map. 
	@param cruiseMapInfo: the information of cruise map. 
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetCruiseMapInfo(FOSHANDLE handle, char* cruiseMapName, int timeout, FOS_CRUISEMAPINFO *cruiseMapInfo);

	/*
	@Name: FosSdk_PTZSetCruiseMap.
	@Description: set cruise map.
	@param cruiseMapInfo: the information of cruise map.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetCruiseMap(FOSHANDLE handle, FOS_CRUISEMAPINFO *cruiseMapInfo, int timeout);

	/*
	@Name: FosSdk_PTZDelCruiseMap.
	@Description: delete a cruise map.
	@param cruiseMapName: the name of cruise map.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZDelCruiseMap(FOSHANDLE handle, char* cruiseMapName, int timeout);

	/*
	@Name: FosSdk_PTZStartCruise.
	@Description: start a cruise map.
	@param cruiseMapName: the name of cruise map.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZStartCruise(FOSHANDLE handle, char* cruiseMapName, int timeout);

	/*
	@Name: FosSdk_PTZStopCruise.
	@Description: stop cruise.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZStopCruise(FOSHANDLE handle, int timeout);

	/*
	@Name: FosSdk_PTZSetCruiseTime.
	@Description: set the time of cruise.
	@param time: the time of cruise.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetCruiseTime(FOSHANDLE handle, unsigned int time,  int timeout);

	/*
	@Name: FosSdk_PTZGetCruiseTime.
	@Description: get the time of cruise.
	@param time: the time of cruise.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetCruiseTime(FOSHANDLE handle, unsigned int *time,  int timeout);

	/*
	@Name: FosSdk_PTZSetCruiseTimeCustomed.
	@Description: set the time and coustomed of cruise.
	@param cruiseTimeCustomed: the struct of time and coustomed.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetCruiseTimeCustomed(FOSHANDLE handle, FOS_CRUISETIMECUSTOMED *cruiseTimeCustomed, int timeout);

	/*
	@Name: FosSdk_PTZGetCruiseTimeCustomed.
	@Description: get the time and customed of cruise.
	@param cruiseTimeCustomed: the struct of time and customed.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetCruiseTimeCustomed(FOSHANDLE handle, FOS_CRUISETIMECUSTOMED *cruiseTimeCustomed, int timeout);

	/*
	@Name: FosSdk_PTZZoom.
	@Description: set the zoom.
	@param cmd: zoom in,zoom out, zoom stop.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZZoom(FOSHANDLE handle, FOS_PTZ_ZOOM cmd, int timeout);

	/*
	@Name: FosSdk_PTZFocus.
	@Description: set the focus.
	@param cmd: focusNear,focusFar,focusStop.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZFocus(FOSHANDLE handle, FOS_PTZ_FOCUS cmd, int timeout);

	/*
	@Name: FosSdk_PTZSetZoomSpeed.
	@Description: set the speed of zoom.
	@param cmd: the speed.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetZoomSpeed(FOSHANDLE handle, FOSPTZZOOM_SPEED cmd, int timeout);

	/*
	@Name: FosSdk_PTZGetZoomSpeed.
	@Description: get the speed of zoom.
	@param cmd: the speed.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetZoomSpeed(FOSHANDLE handle, int timeout, int *speed);

	/*
	@Name: FosSdk_PTZSetCruiseLoopCnt.
	@Description: set the count of CruiseLoop.
	@param count: the count of CruiseLoop.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetCruiseLoopCnt(FOSHANDLE handle, int count, int timeout);

	/*
	@Name: FosSdk_PTZGetCruiseLoopCnt.
	@Description: get the count of CruiseLoop.
	@param count: the count of CruiseLoop.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetCruiseLoopCnt(FOSHANDLE handle, int timeout,int *count);

	/*
	@Name: FosSdk_PTZSetCruiseCtrlMode.
	@Description: set the mode of CruiseControl.
	@param mode: the mode of CruiseControl.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetCruiseCtrlMode(FOSHANDLE handle, FOS_CRUISECTRLMODE mode, int timeout);

	/*
	@Name: FosSdk_PTZGetCruiseCtrlMode.
	@Description: get the mode of CruiseControl.
	@param mode: the mode of CruiseControl.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetCruiseCtrlMode(FOSHANDLE handle, int timeout, int *mode);

	/*
	@Name: FosSdk_PTZSetCruisePrePointLingerTime.
	@Description: set the LingerTime of CruisePresetPoint.
	@param cruisePrePointLingerTime: the LingerTime of CruisePresetPoint.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetCruisePrePointLingerTime(FOSHANDLE handle, FOS_CRUISEMAPPREPOINTLINGERTIME *cruisePrePointLingerTime, int timeout);
	
	/*
	@Name: FosSdk_PTZGetCruisePrePointLingerTime.
	@Description: get the LingerTime of CruisePresetPoint.
	@param cruisePrePointLingerTime: the LingerTime of CruisePresetPoint.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetCruisePrePointLingerTime(FOSHANDLE handle, char* cruiseMapName, int timeout,FOS_CRUISEMAPPREPOINTLINGERTIME *cruisePrePointLingerTime);
	
	/*
	@Name: FosSdk_PTZSetSelfTestMode.
	@Description: set the mode of self test.
	@param mode: the mode of self test.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetSelfTestMode(FOSHANDLE handle, FOS_PTZSELFTESTMODE mode, int timeout);
	
	/*
	@Name: FosSdk_PTZGetSelfTestMode.
	@Description: get the mode of self test.
	@param mode: the mode of self test.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetSelfTestMode(FOSHANDLE handle, int timeout,int *mode);

	/*
	@Name: FosSdk_PTZSetPrePointForSelfTest.
	@Description: set the preset point for self test.
	@param prepointName: the name of preset point.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSetPrePointForSelfTest(FOSHANDLE handle, char *prepointName, int timeout);

	/*
	@Name: FosSdk_PTZGetPrePointForSelfTest.
	@Description: get the preset point for self test.
	@param prepointName: the name of preset point.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGetPrePointForSelfTest(FOSHANDLE handle, int timeout,char *prepointName);

	/*
	@Name: FosSdk_PTZSet85Info.
	@Description: set the information of 485 device.
	@param _485Info: the information of 485 device.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZSet85Info(FOSHANDLE handle, FOS_485INFO *_485Info, int timeout);

	/*
	@Name: FosSdk_PTZGet85Info.
	@Description: get the information of 485 device.
	@param _485Info: the information of 485 device.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PTZGet85Info(FOSHANDLE handle, int timeout, FOS_485INFO* _485Info);

	/*
	@Name: FosSdk_AddAccount.
	@Description: Send AddAcount CGI to add a new account.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param newusrName: user name. 
	@param newusrPwd: user password.
	@param privilege: user privilege(0 : Visitors 1: Operator 2: Administrator).
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_AddAccount(FOSHANDLE handle, int timeOutMS, char *newusrName, char* newusrPwd, int privilege);
	/*
	@Name: FosSdk_ChangePassword.
	@Description: Send ChangePassword CGI to change user's password.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param usrName: user's name. 
	@param oldPwd: current user's password.
	@param newPwd: new password.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ChangePassword(FOSHANDLE handle, int timeOutMS, char *usrName, char* oldPwd, char* newPwd);
	/*
	@Name: FosSdk_ChangeUsrName.
	@Description: Send CGI  ChangeUsrName to change user's name.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param usrName: user's name.
	@param newUsrName: new username.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ChangeUsrName(FOSHANDLE handle, int timeOutMS, char *usrName, char* newUsrName);
	/*
	@Name: FosSdk_ChangeUserNameAndPwdTogether.
	@Description: Send CGI ChangeUserNameAndPwdTogether to change user's name and password.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param usrName: user's name.
	@param newName: new username.
	@param oldPwd: user's password.
	@param newPwd: new password.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ChangeUserNameAndPwdTogether(FOSHANDLE handle, int timeOutMS, char *usrName, char *newName, char* oldPwd, char* newPwd);
	/*
	@Name: FosSdk_DelAccount.
	@Description: Send CGI delAccount to delete user Account.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param usrName: user's name to delete.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_DelAccount(FOSHANDLE handle, int timeOutMS, char *usrName);
	/*
	@Name: FosSdk_GetUserList.
	@Description: Send CGI getUserList to Get user account list of the camera saved in param userList.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param userList: a struct pointer to save the address of user Account information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetUserList(FOSHANDLE handle, int timeOutMS, FOS_USERLIST* userList);
	/*
	@Name: FosSdk_GetSessionList.
	@Description: Send CGI getSessionList to get current session list of the camera.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param sessionList(out): a struct pointer to save the address of session information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetSessionList(FOSHANDLE handle, int timeOutMS, FOS_SESSIONLIST* sessionList);
	
#if 0
    /*
	@Name: FosSdk_UsrBeatHeart.
	@Description: Send CGI usrBeatHeart, user checks connection with camera.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param usrName: user name.
	@param remoteIp: ip address of camera.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_UsrBeatHeart(FOSHANDLE handle, int timeOutMS, char *usrName, char* remoteIp);
#endif
	/************************************************************************/
	/*                          Dev Manage                                  */
	/************************************************************************/
	//anba

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetHDRMode(FOSHANDLE handle, int timeOutMS, int hdrMode);

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetHDRMode(FOSHANDLE handle, int timeOutMS, int* hdrMode);
	/*
	@Name: FosSdk_GetSystemTime.
	@Description: Send CGI getSystemTime to get system time of camera, saved in param devSystemTime.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param devSystemTime(out): a struct pointer to save the address of system time information.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetSystemTime(FOSHANDLE handle, int timeOutMS, FOS_DEVSYSTEMTIME *devSystemTime);
	/*
	@Name: FosSdk_SetSystemTime.
	@Description: Send CGI setSystemTime to set system time of camera.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param devSystemTime(in): a struct pointer to save the address of System time information.
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetSystemTime(FOSHANDLE handle, int timeOutMS, FOS_DEVSYSTEMTIME *devSystemTime);
	/*
	@Name: FosSdk_OpenInfraLed.
	@Description: Send CGI openInfraLed,force open infra led.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param ctrlResult(out): result of openInfraLed(0: success 1: fail).
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_OpenInfraLed(FOSHANDLE handle, int timeOutMS, int* ctrlResult);
	/*
	@Name: FosSdk_CloseInfraLed.
	@Description: Send CGI closeInfraLed,force close infra led.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param ctrlResult(out): result of closeInfraLed(0: success 1: fail).
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_CloseInfraLed(FOSHANDLE handle, int timeOutMS, int* ctrlResult);
	/*
	@Name: FosSdk_GetInfraLedConfig.
	@Description: Send CGI getInfraLedConfig to get infra led config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param mode(out): the mode of infraLed(0: Auto mode 1: Manual mode).
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetInfraLedConfig(FOSHANDLE handle, int timeOutMS, int* mode);
	/*
	@Name: FosSdk_SetInfraLedConfig.
	@Description: Send CGI setInfraLedConfig to set infra led mode.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param mode(in): the mode of infraLed(0: Auto mode 1: Manual mode).
	@return: Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetInfraLedConfig(FOSHANDLE handle, int timeOutMS, int mode);
	/*
	@Name: FosSdk_GetScheduleInfraLedConfig.
	@Description: Send CGI getScheduleInfraLedConfig to Get config for infra led switch schedule.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param ledConfig(out): a struct to save schedule infra led config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetScheduleInfraLedConfig(FOSHANDLE handle, int timeOutMS, FOS_SCHEDULEINFRALEDCONFIG *ledConfig);
	/*
	@Name: FosSdk_GetScheduleInfraLedConfig.
	@Description: Send CGI getScheduleInfraLedConfig to set config for infra led switch schedule.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param ledConfig(in): a struct pointer to save the address of schedule infra led config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetScheduleInfraLedConfig(FOSHANDLE handle, int timeOutMS, FOS_SCHEDULEINFRALEDCONFIG *ledConfig);
	/*
	@Name: FosSdk_GetDevState.
	@Description: Send CGI getDevState to get all device state.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param devState(out): a struct pointer to save the address of device state.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetDevState(FOSHANDLE handle, int timeOutMS, FOS_DEVSTATE* devState);
	/*
	@Name: FosSdk_GetDevInfo.
	@Description: Send CGI getDevInfo to get camera information.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param devInfo(out): a struct pointer to save the address of camera information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetDevInfo(FOSHANDLE handle, int timeOutMS, FOS_DEVINFO* devInfo);
	/*
	@Name: FosSdk_GetDevName.
	@Description: Send CGI getDevName to get camera name.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param devName: save devName.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetDevName(FOSHANDLE handle, int timeOutMS, char* devName);
	/*
	@Name: FosSdk_SetDevName.
	@Description: Send CGI setDevName to set camera name.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param devName: save devName.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetDevName(FOSHANDLE handle, int timeOutMS, char* devName);
	/*
	@Name: FosSdk_GetProductModel.
	@Description: Send CGI getProductModel to get camera model number.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param model(out): save camera model number.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductModel(FOSHANDLE handle, int timeOutMS, int* model);
	/*
	@Name: FosSdk_GetProductModelName.
	@Description: Send CGI getProductModelName to get camera model name.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param modelName: save camera model name.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductModelName(FOSHANDLE handle, int timeOutMS, char* modelName);
	/*
	@Name: FosSdk_GetProductLanguage.
	@Description: Send CGI getProductLanguage to get camera main language.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param language(out): save camera main language.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductLanguage(FOSHANDLE handle, int timeOutMS, int* language);
	/*
	@Name: FosSdk_GetProductSensorType.
	@Description: Send CGI getProductSensorType to get camera sensor type number.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param sensorType(out): save camera sensor type number.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductSensorType(FOSHANDLE handle, int timeOutMS, int* sensorType);
	/*
	@Name: FosSdk_GetProductWifiType.
	@Description: Send CGI getProductWifiType to get camera wifi type number.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param wifiType(out): save camera wifi type number.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductWifiType(FOSHANDLE handle, int timeOutMS, int* wifiType);
	/*
	@Name: FosSdk_GetProductSdFlag.
	@Description: Send CGI getProductSdFlag to test Whether camera support sd card.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param sdFlag(out): Camera flag to support sdcard-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductSdFlag(FOSHANDLE handle, int timeOutMS, int* sdFlag);
	/*
	@Name: FosSdk_GetProductOutdoorFlag.
	@Description: Send CGI getProductOutdoorFlag to test Whether camera is outdoor machine.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param outdoorFlag(out): Whether camera is outdoor machine-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductOutdoorFlag(FOSHANDLE handle, int timeOutMS, int* outdoorFlag);
	/*
	@Name: FosSdk_GetProductPtFlag.
	@Description: Send CGI getProductPtFlag to test Whether camera is pt machine.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param ptFlag(out): Whether camera is pt machine-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductPtFlag(FOSHANDLE handle, int timeOutMS, int* ptFlag);
	/*
	@Name: FosSdk_GetProductZoomFlag.
	@Description: Send CGI getProductZoomFlag to test Whether camera is zoom machine.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param zoomFlag(out): Whether camera is pt machine-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductZoomFlag(FOSHANDLE handle, int timeOutMS, int* zoomFlag);
	/*
	@Name: FosSdk_GetProductRs485Flag.
	@Description: Send CGI getProductRs485Flag to test Whether camera support rs485.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param rs485Flag(out): Whether camera support rs485-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductRs485Flag(FOSHANDLE handle, int timeOutMS, int* rs485Flag);
	/*
	@Name: FosSdk_GetProductIoAlarmFlag.
	@Description: Send CGI getProductIoAlarmFlag to test Whether camera support IO alarm.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param ioAlarmFlag(out): Whether camera support IO alarm-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductIoAlarmFlag(FOSHANDLE handle, int timeOutMS, int* ioAlarmFlag);
	/*
	@Name: FosSdk_GetProductOnvifFlag.
	@Description: Send CGI getProductOnvifFlag to test Whether camera support Onvif.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param onvifFlag(out): Whether camera support onvif-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductOnvifFlag(FOSHANDLE handle, int timeOutMS, int* onvifFlag);
	/*
	@Name: FosSdk_GetProductP2pFlag.
	@Description: Send CGI getProductP2pFlag to test Whether camera support P2p.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param p2pFlag(out): Whether camera support p2p-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductP2pFlag(FOSHANDLE handle, int timeOutMS, int* p2pFlag);
	/*
	@Name: FosSdk_GetProductWpsFlag.
	@Description: Send CGI getProductWpsFlag to test Whether camera support Wps.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param wpsFlag(out): Whether camera support wps-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductWpsFlag(FOSHANDLE handle, int timeOutMS, int* wpsFlag);
	/*
	@Name: FosSdk_GetProductAudioFlag.
	@Description: Send CGI getProductAudioFlag to test Whether camera support audio-speak.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param audioFlag(out): Whether camera support audio for speak-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductAudioFlag(FOSHANDLE handle, int timeOutMS, int* audioFlag);
	/*
	@Name: FosSdk_GetProductTalkFlag.
	@Description: Send CGI getProductTalkFlag to test Whether camera support audio-talk.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param talkFlag(out): Whether camera support audio for talk-0: no,1: yes.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductTalkFlag(FOSHANDLE handle, int timeOutMS, int* talkFlag);
	/*
	@Name: FosSdk_GetProductAppVer.
	@Description: Send CGI getProductAppVer to get camera application version.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param appVer: save camera application version.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetProductAppVer(FOSHANDLE handle, int timeOutMS, char* appVer);
	/*
	@Name: FosSdk_GetGeneratePubKey.
	@Description: Send CGI getGeneratePubKey to get public key generated by camera for software reset.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param pubKey: a struct pointer to save the address of key Information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetGeneratePubKey(FOSHANDLE handle, int timeOutMS, FOS_GENERATEPUBKEY* pubKey);
	/*
	@Name: FosSdk_ToolResetToFactory.
	@Description: Send CGI toolResetToFactory to set camera reset to factory by software.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param codeLen: Code length for camera reset.
	@param code: Code for camera reset.
	@param restoreResult: The result that camera reset.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ToolResetToFactory(FOSHANDLE handle, int timeOutMS, int codeLen, char* code, int *restoreResult);
	// fosbaby
	/*
	@Name: FosSdk_GetTemperatureAlarmConfig.
	@Description: Send CGI getTemperatureAlarmConfig to get Temperature Alarm Config.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param tempAlarmConfig(out): a struct pointer to save the address of Temperature Alarm Config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetTemperatureAlarmConfig(FOSHANDLE handle, int timeOutMS, FOS_TEMPRATUREALARMCONFIG *tempAlarmConfig);
	/*
	@Name: FosSdk_SetTemperatureAlarmConfig.
	@Description: Send CGI setTemperatureAlarmConfig to set Temperature Alarm Config.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param tempAlarmConfig(in): a struct pointer to save the address of Temperature Alarm Config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetTemperatureAlarmConfig(FOSHANDLE handle, int timeOutMS, FOS_TEMPRATUREALARMCONFIG *tempAlarmConfig);
	/*
	@Name: FosSdk_GetTemperatureState.
	@Description: Send CGI getTemperatureState to get temperature Degree.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param degree(out): Temperature ℃！
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetTemperatureState(FOSHANDLE handle, int timeOutMS, int *degree);
	/*
	@Name: FosSdk_GetHumidityAlarmConfig.
	@Description: Send CGI getHumidityAlarmConfig to get Humidity Alarm Config.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param humidityAlarmConfig(out): a struct pointer to save the address of Humidity Alarm Config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetHumidityAlarmConfig(FOSHANDLE handle, int timeOutMS, FOS_HUMIDITYALARMCONFIG *humidityAlarmConfig);
	/*
	@Name: FosSdk_SetHumidityAlarmConfig.
	@Description: Send CGI setHumidityAlarmConfig to set Humidity Alarm Config.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param humidityAlarmConfig(in): a struct pointer to save the address of Humidity Alarm Config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetHumidityAlarmConfig(FOSHANDLE handle, int timeOutMS, FOS_HUMIDITYALARMCONFIG *humidityAlarmConfig);
	/*
	@Name: FosSdk_GetHumidityState.
	@Description: Send CGI getHumidityState to get Humidity Value.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param humidity(out): Humidity %！
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetHumidityState(FOSHANDLE handle, int timeOutMS, int *humidity);
	/*
	@Name: FosSdk_SetNightLightState.
	@Description: Send CGI setNightLightState to set Night Light State.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param state: 0-Nightlight Off  1-Nightlight On.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetNightLightState(FOSHANDLE handle, int timeOutMS, int state);

	/*
	@Name: FosSdk_GetNightLightState.
	@Description: Get Night Light State.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param state: 0-Nightlight Off  1-Nightlight On.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetNightLightState(FOSHANDLE handle, int timeOutMS, int *state);

	/*
	@Name: FosSdk_SetLedEnableState.
	@Description: Set Led enable or not.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param state: 0-enable  1-disnable.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetLedEnableState(FOSHANDLE handle, int timeOutMS, int enable);

	/*
	@Name: FosSdk_GetLedEnableState.
	@Description: Get Led enable state.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param state: 0-enable  1-disnable.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetLedEnableState(FOSHANDLE handle, int timeOutMS, int *enable);

	/*
	@Name: FosSdk_SetOneKeyAlarmConfig.
	@Description: Set one key alarm Config.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param oneKeyAlarmconfig: config information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetOneKeyAlarmConfig(FOSHANDLE handle, int timeOutMS, FOS_ONEKEYALARMCONFIG *oneKeyAlarmconfig);

	/*
	@Name: FosSdk_GetOneKeyAlarmConfig.
	@Description: Get one key alarm Config.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param oneKeyAlarmconfig: config information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetOneKeyAlarmConfig(FOSHANDLE handle, int timeOutMS, FOS_ONEKEYALARMCONFIG *oneKeyAlarmconfig);

	/*
	@Name: FosSdk_GetTimingRebootConfig.
	@Description: Get timing reboot config.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param timingRebootConfig: config information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetTimingRebootConfig(FOSHANDLE handle, int timeOutMS, FOS_TIMINGREBOOTCONFIG *timingRebootConfig);

	/*
	@Name: FosSdk_SetTimingRebootConfig.
	@Description: Set timing reboot config.
	@param handle: the handle of current connection information. 
	@param timeOutMS: Time limits of timeout.
	@param timingRebootConfig: config information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetTimingRebootConfig(FOSHANDLE handle, int timeOutMS, FOS_TIMINGREBOOTCONFIG *timingRebootConfig);

	/************************************************************************/
	/*                           System                                     */
	/************************************************************************/
	/*
	@Name: FosSdk_RebootSystem.
	@Description: Send CGI rebootSystem to reboot camera.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_RebootSystem(FOSHANDLE handle, int timeOutMS);
	/*
	@Name: FosSdk_RestoreToFactorySetting.
	@Description: Send CGI restoreToFactorySetting to restore camera to factory setting.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_RestoreToFactorySetting(FOSHANDLE handle, int timeOutMS);
	/*
	@Name: FosSdk_ExportConfig.
	@Description: Send CGI exportConfig to export config file.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param fileName(out): The config file name.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ExportConfig(FOSHANDLE handle, int timeOutMS, char* fileName);
	
	/*
	@Name: FosSdk_RemovePatch.
	@Description: Send CGI to Remove Patch.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_RemovePatch(FOSHANDLE handle, int timeOutMS);

	/************************************************************************/
	/*                          AV function                                 */
	/************************************************************************/
	/*
	@Name: FosSdk_GetMirrorAndFlipSetting.
	@Description: get the mirror and flip.
	@param isMirror: enable or not.
	@param isFlip: enable or not.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMirrorAndFlipSetting(FOSHANDLE handle, int timeOutMS, int *isMirror, int *isFlip);

	/*
	@Name: FosSdk_MirrorVideo.
	@Description: set the mirror.
	@param isMirror: enable or not.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_MirrorVideo(FOSHANDLE handle, int isMirror, int timeOutMS);

	/*
	@Name: FosSdk_FlipVideo.
	@Description: set the Flip.
	@param isFlip: enable or not.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_FlipVideo(FOSHANDLE handle, int isFlip, int timeOutMS);

	/*
	@Name: FosSdk_GetRatio.
	@Description: get the ratio.
	@param ratio: ratio.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetRatio(FOSHANDLE handle, int timeOutMS, int *ratio);

	/*
	@Name: FosSdk_SetRatio.
	@Description: set the ratio.
	@param ratio: ratio.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetRatio(FOSHANDLE handle, int ratio, int timeOutMS);

	/*
	@Name: FosSdk_GetH264FrmRefMode.
	@Description: get the mode of h264-frame-reference.
	@param mode: mode.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetH264FrmRefMode(FOSHANDLE handle, int timeOutMS, int *mode);

	/*
	@Name: FosSdk_SetH264FrmRefMode.
	@Description: set the mode of h264-frame-reference.
	@param mode: 
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetH264FrmRefMode(FOSHANDLE handle, int mode, int timeOutMS);

	/*
	@Name: FosSdk_GetScheduleRecordStreamChn.
	@Description: get the channel ScheduleRecordStream.
	@param chn: channel.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetScheduleRecordStreamChn(FOSHANDLE handle, int timeOutMS, int *chn);

	/*
	@Name: FosSdk_SetScheduleRecordStreamChn.
	@Description: set the channel ScheduleRecordStream.
	@param chn: channel.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetScheduleRecordStreamChn(FOSHANDLE handle, int chn, int timeOutMS);

	/*
	@Name: FosSdk_SetPwrFreq.
	@Description: Set power freq of sensor.
	@param freq: power freq.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetPwrFreq(FOSHANDLE handle, int freq, int timeOutMS);

	/*
	@Name: FosSdk_GetVideoStreamParam.
	@Description: Get video stream param.
	@param videoStreamListParam: the struct of videoStreamListParam.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetVideoStreamParam(FOSHANDLE handle, int timeOutMS, FOS_VIDEOSTREAMLISTPARAM *videoStreamListParam);
	
	/*
	@Name: FosSdk_SetVideoStreamParam.
	@Description: Set the video stream param of stream N.
	@param videoStreamParam: the struct of videoStreamParam.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetVideoStreamParam(FOSHANDLE handle, FOS_VIDEOSTREAMPARAM *videoStreamParam, int timeOutMS);

	/*
	@Name: FosSdk_GetSubVideoStreamParam.
	@Description: Get sub video stream param.
	@param videoStreamListParam: the struct of videoStreamListParam.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetSubVideoStreamParam(FOSHANDLE handle, int timeOutMS, FOS_VIDEOSTREAMLISTPARAM *videoStreamListParam);
	
	/*
	@Name: FosSdk_SetSubVideoStreamParam.
	@Description: Set the sub video stream param of stream N.
	@param videoStreamParam: the struct of videoStreamParam.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetSubVideoStreamParam(FOSHANDLE handle, FOS_VIDEOSTREAMPARAM *videoStreamParam, int timeOutMS);

	/*
	@Name: FosSdk_GetMainVideoStreamType.
	@Description: Get the stream type of main stream.
	@param streamType: the type of stream.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMainVideoStreamType(FOSHANDLE handle, int timeOutMS, int *streamType);

	/*
	@Name: FosSdk_GetSubVideoStreamType.
	@Description: Get the stream type of sub stream.
	@param streamType: the type of stream.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetSubVideoStreamType(FOSHANDLE handle, int timeOutMS, int *streamType);

	/*
	@Name: FosSdk_SetMainVideoStreamType.
	@Description: set the stream type of main stream.
	@param streamType: the type of stream.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMainVideoStreamType(FOSHANDLE handle, int streamType, int timeOutMS);

	/*
	@Name: FosSdk_SetSubVideoStreamType.
	@Description: set the stream type of sub stream.
	@param streamType: the type of stream.
	@return£ºPlease refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetSubVideoStreamType(FOSHANDLE handle, int streamType, int timeOutMS);

	/*
	@Name: FosSdk_SetSubStreamFormat.
	@Description: Set the stream format of sub stream.
	@param streamFormat: H264 or MotionJpeg.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetSubStreamFormat(FOSHANDLE handle, FOS_STREAMFORMAT streamFormat, int timeOutMS);

	/*
	@Name: FosSdk_GetMJStream.
	@Description: Get motion jpeg stream.
	@param mjStreamPath: the path of motion jpeg stream.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMJStream(FOSHANDLE handle, int timeOutMS, char *mjStreamPath);

	/*
	@Name: FosSdk_GetOSDSetting.
	@Description: Get OSD config.
	@param OSDSetting: the setting of OSD.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetOSDSetting(FOSHANDLE handle, int timeOutMS, FOS_OSDSETTING *OSDSetting);

	/*
	@Name: FosSdk_SetOSDSetting.
	@Description: Set OSD config.
	@param OSDSetting: the setting of OSD.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetOSDSetting(FOSHANDLE handle, FOS_OSDSETTING *OSDSetting, int timeOutMS);

	/*
	@Name: FosSdk_GetOsdMaskArea.
	@Description: Get OSD mask area info.
	@param osdMaskArea: the struct of OSD mask area info.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetOsdMaskArea(FOSHANDLE handle, int timeOutMS, FOS_OSDMASKAREA *osdMaskArea);

	/*
	@Name: FosSdk_SetOsdMaskArea
	@Description: Set OSD mask area info
	@param osdMaskArea: the struct of OSD mask area info
	@return：Please refer to the enum of FOSCMD_RESULT to get more information
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetOsdMaskArea(FOSHANDLE handle, FOS_OSDMASKAREA *osdMaskArea, int timeOutMS);

	/*
	@Name: FosSdk_GetOSDMask.
	@Description: Get OSD mask.
	@param isEnableOSDMask: enable or not.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetOSDMask(FOSHANDLE handle, int timeOutMS, int *isEnableOSDMask);

	/*
	@Name: FosSdk_SetOSDMask.
	@Description: Set OSD mask.
	@param isEnableOSDMask: enable or not.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetOSDMask(FOSHANDLE handle, int isEnableOSDMask, int timeOutMS);

	/*
	@Name: FosSdk_GetMotionDetectConfig.
	@Description: Get motion detect config.
	@param motionDetectConfig: the struct of motion detect config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMotionDetectConfig(FOSHANDLE handle, int timeOutMS, FOS_MOTIONDETECTCONFIG *motionDetectConfig);

	/*
	@Name: FosSdk_SetMotionDetectConfig.
	@Description: Set motion detect config.
	@param motionDetectConfig: the struct of motion detect config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMotionDetectConfig(FOSHANDLE handle, FOS_MOTIONDETECTCONFIG *motionDetectConfig, int timeOutMS);

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetAudioAlarmConfig(FOSHANDLE handle, FOS_AudioAlarmSetting *audioAlarmConfig, int timeOutMS);

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetAudioAlarmConfig(FOSHANDLE handle, int timeOutMS, FOS_AudioAlarmSetting *audioAlarmConfig);

	//anba
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMotionDetectConfig1(FOSHANDLE handle, int timeOutMS, FOS_MOTIONDETECTCONFIG1 *motionDetectConfig);

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMotionDetectConfig1(FOSHANDLE handle, FOS_MOTIONDETECTCONFIG1 *motionDetectConfig, int timeOutMS);
	/*
	@Name: FosSdk_GetLocalAlarmRecordConfig.
	@Description: Get local alarm-record config.
	@param localAlarmRecordConfig: the struct of localAlarmRecordConfig.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetLocalAlarmRecordConfig(FOSHANDLE handle, int timeOutMS, FOS_LOCALALARMRECORDCONFIG *localAlarmRecordConfig);
	
	/*
	@Name: FosSdk_SetLocalAlarmRecordConfig.
	@Description: Set local alarm-record config.
	@param localAlarmRecordConfig: the struct of localAlarmRecordConfig.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetLocalAlarmRecordConfig(FOSHANDLE handle, FOS_LOCALALARMRECORDCONFIG *localAlarmRecordConfig, int timeOutMS);
	
	/*
	@Name: FosSdk_GetSnapConfig.
	@Description: Get snap config.
	@param snapConfig: the struct of snap config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetSnapConfig(FOSHANDLE handle, int timeOutMS, FOS_SNAPCONFIG *snapConfig);

	/*
	@Name: FosSdk_SetSnapConfig.
	@Description: Set snap config.
	@param snapConfig: the struct of snap config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetSnapConfig(FOSHANDLE handle, FOS_SNAPCONFIG *snapConfig, int timeOutMS);

	/*
	@Name: FosSdk_GetScheduleSnapConfig.
	@Description: Get schedule snap config.
	@param scheduleSnapConfig: the struct of scheduleSnapConfig.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetScheduleSnapConfig(FOSHANDLE handle, int timeOutMS, FOS_SCHEDULESNAPCONFIG *scheduleSnapConfig);
	
	/*
	@Name: FosSdk_SetScheduleSnapConfig.
	@Description: Set schedule snap config.
	@param scheduleSnapConfig: the struct of scheduleSnapConfig.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetScheduleSnapConfig(FOSHANDLE handle, FOS_SCHEDULESNAPCONFIG *scheduleSnapConfig, int timeOutMS);

	/*
	@Name: FosSdk_GetRecordList.
	@Description: Get record list.
	@param searchRecordPara: the information for search.
	@param recordList: the recordList.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetRecordList(FOSHANDLE handle, FOS_SEARCHRECORDPARA *searchRecordPara, int timeOutMS, FOS_RECORDLIST *recordList);
	
	/*
	@Name: FosSdk_GetRecordList2.
	@Description: Get record list, recommended using this function.
	@param searchRecordPara: the information for search.
	@param recordList: the recordList.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetRecordList2(FOSHANDLE handle, FOS_SEARCHRECORDPARA *searchRecordPara, int timeOutMS, FOS_RECORDLIST *recordList);
	
	/*
	@Name: FosSdk_ReloadRecordindex.
	@Description: Synchronization of record index for Play.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ReloadRecordindex(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_GetAlarmRecordConfig.
	@Description: Get alarm record config.
	@param alarmRecordConfig: the alarm-record-config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetAlarmRecordConfig(FOSHANDLE handle, int timeOutMS, FOS_ALARMRECORDCONFIG *alarmRecordConfig);

	/*
	@Name: FosSdk_SetAlarmRecordConfig.
	@Description: Set alarm record config.
	@param alarmRecordConfig: the alarm-record-config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetAlarmRecordConfig(FOSHANDLE handle, FOS_ALARMRECORDCONFIG *alarmRecordConfig ,int timeOutMS);

	/*
	@Name: FosSdk_GetRecordPath.
	@Description: Get record path for storage.
	@param recordPath: the record path.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetRecordPath(FOSHANDLE handle, int timeOutMS, FOS_RECORDPATH *recordPath);

	/*
	@Name: FosSdk_SetRecordPath.
	@Description: Get record path for storage.
	@param path: the record path.
	@param recordPath: about the record path message.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetRecordPath(FOSHANDLE handle, int timeOutMS, int path, FOS_RECORDPATH *recordPath);

	/*
	@Name: FosSdk_GetScheduleRecordConfig.
	@Description: Get config for schedule recording.
	@param scheduleRecordCofig: the config for schedule recording.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetScheduleRecordConfig(FOSHANDLE handle, int timeOutMS, FOS_SCHEDULERECORDCONFIG *scheduleRecordCofig);
	
	/*
	@Name: FosSdk_SetScheduleRecordConfig.
	@Description: Set config for schedule recording.
	@param scheduleRecordCofig: the config for schedule recording.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetScheduleRecordConfig(FOSHANDLE handle, FOS_SCHEDULERECORDCONFIG *scheduleRecordCofig, int timeOutMS);
	
	/*
	@Name: FosSdk_GetIOAlarmConfig.
	@Description: Get IO alarm config.
	@param scheduleRecordCofig: the struct of IO alarm config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetIOAlarmConfig(FOSHANDLE handle, int timeOutMS, FOS_IOALARMCONFIG *iOalarmConfig);

	/*
	@Name: FosSdk_SetIOAlarmConfig.
	@Description: Set IO alarm config.
	@param scheduleRecordCofig: the struct of IO alarm config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetIOAlarmConfig(FOSHANDLE handle, FOS_IOALARMCONFIG *iOalarmConfig, int timeOutMS);

	/*
	@Name: FosSdk_ClearIOAlarmOutput.
	@Description: Clean IO alarm output.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ClearIOAlarmOutput(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_GetPCAudioAlarmCfg.
	@Description: Get audio alarm config for PC(web live video).
	@param isEnablePCAudioAlarm: enable or not.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetPCAudioAlarmCfg(FOSHANDLE handle, int timeOutMS, int *isEnablePCAudioAlarm);

	/*
	@Name: FosSdk_SetPCAudioAlarmCfg.
	@Description: Set audio alarm config for PC(web live video).
	@param isEnablePCAudioAlarm: enable or not.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetPCAudioAlarmCfg(FOSHANDLE handle, int isEnablePCAudioAlarm, int timeOutMS);

	/*
	@Name: FosSdk_SetAudioVolume.
	@Description: Set Audio Volume.
	@param volume: volume.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetAudioVolume(FOSHANDLE handle, int timeOutMS, int volume);

	/*
	@Name: FosSdk_GetAudioVolume.
	@Description: Get Audio Volume.
	@param volume: volume.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetAudioVolume(FOSHANDLE handle, int timeOutMS, int *volume);

	/*
	@Name: FosSdk_GetMultiDevList.
	@Description: Get multi Device List.
	@param deviceList: devices List.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMultiDevList(FOSHANDLE handle, int timeOutMS,FOS_DEVICELIST *deviceList);

	/*
	@Name: FosSdk_GetMultiDevDetailInfo.
	@Description: Get multi device detail information.
	@param multiDeviceInfo: multi devices information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMultiDevDetailInfo(FOSHANDLE handle, int timeOutMS,int chnnl,FOS_MULTIDEVICE *multiDeviceInfo);

	/*
	@Name: FosSdk_AddMultiDev.
	@Description: add multi device.
	@param mutilDevice: multi devices.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_AddMultiDev(FOSHANDLE handle, int timeOutMS,FOS_MULTIDEVICE *mutilDevice);

	/*
	@Name: FosSdk_DelMultiDev.
	@Description: delete multi device.
	@param chnnl: channel.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_DelMultiDev(FOSHANDLE handle, int timeOutMS,int chnnl);

	/*
	@Name: FosSdk_SetDeFrameLevel.
	@Description: Set status to	enhance	night vision definition.
	@param level: status of enhance night vision definition.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetDeFrameLevel(FOSHANDLE handle, int timeOutMS,int level);

	/*
	@Name: FosSdk_GetDeFrameLevel.
	@Description: Get status of	enhance	night vision definition.
	@param level: status of enhance night vision definition.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetDeFrameLevel(FOSHANDLE handle, int timeOutMS,int *level);

	/************************************************************************/
	/*                           NetWork                                    */
	/************************************************************************/

	/*
	@Name: FosSdk_GetPortInfo.
	@Description: Get IP Info.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param portinfo: The pointer of struct FOS_PORTINFO,use to save port info.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetPortInfo(FOSHANDLE handle, int timeOutMS, FOS_PORTINFO *portinfo);

	/*
	@Name: FosSdk_SetPortInfo.
	@Description: Set port info.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newPortInfo: The pointer of struct FOS_PORTINFO,use to change port info.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetPortInfo(FOSHANDLE handle, int timeOutMS, FOS_PORTINFO *newPortInfo);

	/*
	@Name: FosSdk_GetIpInfo.
	@Description: Get ip info.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param ipinfo: The pointer of struct FOS_IPINFO,use to save ip info.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetIpInfo(FOSHANDLE handle, int timeOutMS, FOS_IPINFO *ipinfo);

	/*
	@Name: FosSdk_SetIpInfo.
	@Description: Set ip info.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param ipinfo: The pointer of struct FOS_IPINFO,use to change ip info.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetIpInfo(FOSHANDLE handle, int timeOutMS, FOS_IPINFO *newIpInfo);

	/*
	@Name: FosSdk_RefreshWifiList.
	@Description: Refresh wifi list.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_RefreshWifiList(FOSHANDLE handle,  int timeOutMS);

	/*
	@Name: FosSdk_GetWifiList.
	@Description: Get wifi list.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param startNo: The start NO of the ap list you want to get.
	@param wifilist: The pointer of struct FOS_WIFILIST,use to save wifi list.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetWifiList(FOSHANDLE handle,  int timeOutMS,int startNo, FOS_WIFILIST *wifilist);

	/*
	@Name: FosSdk_GetWifiConfig.
	@Description: Get wifi config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param wificonfig: The pointer of struct FOS_WIFICONFIG,use to save wifi config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetWifiConfig(FOSHANDLE handle,  int timeOutMS, FOS_WIFICONFIG *wificonfig);

	/*
	@Name: FosSdk_SetWifiSetting.
	@Description: Set wifi config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newWifiSetting: The pointer of struct FOS_WIFISETTING,use to change wifi config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetWifiSetting(FOSHANDLE handle,  int timeOutMS, FOS_WIFISETTING *newWifiSetting);

	/*
	@Name: FosSdk_GetUPnPConfig.
	@Description: Get upnp config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param upnpconfig: The pointer of struct FOS_UPNPCONFIG,use to save upnp config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetUPnPConfig(FOSHANDLE handle,  int timeOutMS, FOS_UPNPCONFIG *upnpconfig);

	/*
	@Name: FosSdk_SetUPnPConfig.
	@Description: Set upnp config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newUPnPConfig: The pointer of struct FOS_UPNPCONFIG,use to change upnp config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetUPnPConfig(FOSHANDLE handle,  int timeOutMS, FOS_UPNPCONFIG *newUPnPConfig);

	/*
	@Name: FosSdk_GetDDNSConfig.
	@Description: Get ddns config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param ddnsconfig: The pointer of struct FOS_DDNSCONFIG,use to save ddns config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetDDNSConfig(FOSHANDLE handle,  int timeOutMS, FOS_DDNSCONFIG *ddnsconfig);

	/*
	@Name: FosSdk_SetDDNSConfig.
	@Description: Set ddns config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newDDNSConfig: The pointer of struct FOS_DDNSCONFIG,use to change ddns config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetDDNSConfig(FOSHANDLE handle,  int timeOutMS, FOS_DDNSCONFIG *newDDNSConfig);

	/*
	@Name: FosSdk_GetFtpConfig.
	@Description: Get ftp config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param ftpconfig: The pointer of struct FOS_FTPCONFIG,use to save ddns config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetFtpConfig(FOSHANDLE handle,  int timeOutMS, FOS_FTPCONFIG *ftpconfig);

	/*
	@Name: FosSdk_SetFtpConfig.
	@Description: Set ftp config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newFtpConfig: The pointer of struct FOS_FTPCONFIG,use to change ddns config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetFtpConfig(FOSHANDLE handle,  int timeOutMS, FOS_FTPCONFIG *newFtpConfig);

	/*
	@Name: FosSdk_TestFtpServer.
	@Description: Test FTP server.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newFtpConfig: The pointer of struct FOS_FTPCONFIG,use to change ddns config.
	@param testftpserver: The pointer of struct FOS_TESTFTPSERVER,use to save test result.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_TestFtpServer(FOSHANDLE handle,  int timeOutMS, FOS_FTPCONFIG *newFtpConfig, FOS_TESTFTPSERVER *testftpserver);

	/*
	@Name: FosSdk_GetSMTPConfig.
	@Description: Get smtp config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param smtpconfig: The pointer of struct FOS_SMTPCONFIG,use to save smtp config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetSMTPConfig(FOSHANDLE handle,  int timeOutMS, FOS_SMTPCONFIG *smtpconfig);

	/*
	@Name: FosSdk_SetSMTPConfig.
	@Description: Set smtp config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newSmtpConfig: The pointer of struct FOS_SMTPCONFIG,use to change smtp config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetSMTPConfig(FOSHANDLE handle,  int timeOutMS, FOS_SMTPCONFIG *newSmtpConfig);

	/*
	@Name: FosSdk_SmtpTest.
	@Description: Test mail setting.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newSmtpConfig: The pointer of struct FOS_SMTPCONFIG,use to change smtp config.
	@param smtptest: The pointer of struct FOS_SMTPTEST,use to save test result.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SmtpTest(FOSHANDLE handle,  int timeOutMS, FOS_SMTPCONFIG *newSmtpConfig, FOS_SMTPTEST *smtptest);

	/*
	@Name: FosSdk_GetP2PEnable.
	@Description: Get p2p status.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param p2penable: The pointer of struct FOS_P2PENABLE,use to save p2p status.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetP2PEnable(FOSHANDLE handle,  int timeOutMS, FOS_P2PENABLE *p2penable);

	/*
	@Name: FosSdk_SetP2PEnable.
	@Description: Set p2p status.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newP2pEnable: The pointer of struct FOS_P2PENABLE,use to change p2p status.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetP2PEnable(FOSHANDLE handle,  int timeOutMS, FOS_P2PENABLE *newP2pEnable);

	/*
	@Name: FosSdk_GetP2PPort.
	@Description: Get p2p port.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param p2pport: The pointer of struct FOS_P2PPORT,use to save p2p port.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetP2PPort(FOSHANDLE handle,  int timeOutMS, FOS_P2PPORT *p2pport);

	/*
	@Name: FosSdk_SetP2PPort.
	@Description: Set p2p port.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newP2PPort: The pointer of struct FOS_P2PPORT,use to change p2p port.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetP2PPort(FOSHANDLE handle,  int timeOutMS, FOS_P2PPORT *newP2PPort);

	/*
	@Name: FosSdk_GetP2PInfo.
	@Description: Get p2p info.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param p2pinfo: The pointer of struct FOS_P2PPORT,use to save p2p info.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetP2PInfo(FOSHANDLE handle,  int timeOutMS, FOS_P2PINFO *p2pinfo);


	/*
	@Name: FosSdk_GetPPPoEConfig.
	@Description: Get pppoe config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param pppoeconfig: The pointer of struct FOS_PPPOECONFIG,use to save pppoe config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetPPPoEConfig(FOSHANDLE handle,  int timeOutMS, FOS_PPPOECONFIG *pppoeconfig);

	/*
	@Name: FosSdk_SetPPPoEConfig.
	@Description: Set pppoe config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newPppoeConfig: The pointer of struct FOS_PPPOECONFIG,use to change pppoe config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetPPPoEConfig(FOSHANDLE handle,  int timeOutMS, FOS_PPPOECONFIG *newPppoeConfig);

	/*
	@Name: FosSdk_GetWifiMode.
	@Description: Get wifi mode.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param wifimode: The pointer of struct FOS_WIFIMODE,use to save wifi mode.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetWifiMode(FOSHANDLE handle,  int timeOutMS, FOS_WIFIMODE *wifimode);

	/*
	@Name: FosSdk_GetSoftApConfig.
	@Description: Get softap config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param softapconfig: The pointer of struct FOS_SOFTAPCONFIG,use to save softap config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetSoftApConfig(FOSHANDLE handle,  int timeOutMS, FOS_SOFTAPCONFIG *softapconfig);

	/*
	@Name: FosSdk_SetSoftApConfig.
	@Description: Set softap config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newSoftApConfig: The pointer of struct FOS_SOFTAPCONFIG,use to change softap config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetSoftApConfig(FOSHANDLE handle,  int timeOutMS, FOS_SOFTAPCONFIG *newSoftApConfig);

	/*
	@Name: FosSdk_SetFoscamRtmp.
	@Description: Activation cloud storage service on IPC
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newBaiduRtmpConfig: The pointer of struct FOS_BAIDURTMPCONFIG,use to change baidu rtmp config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetFoscamRtmp(FOSHANDLE handle,  int timeOutMS, FOS_BAIDURTMPCONFIG *newBaiduRtmpConfig);

	/*
	@Name: FosSdk_GetFoscamRtmp.
	@Description: Get baidu rtmp config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param baiduRtmpConfig: The pointer of struct FOS_BAIDURTMPCONFIG,use to save baidu rtmp config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetFoscamRtmp(FOSHANDLE handle,  int timeOutMS, FOS_BAIDURTMPCONFIG *baiduRtmpConfig);

	/*
	@Name: FosSdk_ChangeNetMode.
	@Description: Change Net Mode.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param newChangeNetMode: The pointer of struct FOS_CHANGENETMODE,use to change net mode.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ChangeNetMode(FOSHANDLE handle,  int timeOutMS, FOS_CHANGENETMODE *newChangeNetMode);


	/*
	@Name: FosSdk_ImageCmd.
	@Description: set image attribute.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param cmd: image para type,such as the hue of image.
	@param value: image para value.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ImageCmd(FOSHANDLE handle, FOSIMAGE_CMD cmd, int value, int timeOutMS);

	/*
	@Name: FosSdk_GetImageSetting.
	@Description: get image attribute.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param img: image para,such as the hue of image.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetImageSetting(FOSHANDLE handle, FOSIMAGE* img, int timeOutMS);

	//music
	/*
	@Name: FosSdk_SetMusicDefaultListRefresh.
	@Description: Refresh default list.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMusicDefaultListRefresh(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_GetMusicListsName.
	@Description: Get music lists Name.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param musicListList: the music lists Name.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMusicListsName(FOSHANDLE handle, int timeOutMS,FOS_MUSICLISTNAMELIST *musicListList);

	/*
	@Name: FosSdk_GetMusicsNameOfList.
	@Description: Get musics Name of a music list.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param musicInfo: Music list information.
	@param musicList: the musics  Name list.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMusicsNameOfList(FOSHANDLE handle, int timeOutMS,FOS_MUSICINFO *musicInfo,FOS_MUSICLIST *musicList);

	/*
	@Name: FosSdk_AddMusicList.
	@Description: add music list.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param musicList: music list.
	@param curListInfo: current music lists info.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_AddMusicList(FOSHANDLE handle, int timeOutMS,FOS_MUSICLIST *musicList,FOS_CURLISTINFO *curListInfo);

	/*
	@Name: FosSdk_DelMusicList.
	@Description: delete music list.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param listName: music list name.
	@param curListInfo: current music lists info.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_DelMusicList(FOSHANDLE handle, int timeOutMS,char *listName,FOS_CURLISTINFO *curListInfo);

	/*
	@Name: FosSdk_SetMusicPlayMode.
	@Description: set mode of playing music.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param mode:mode of playing music.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMusicPlayMode(FOSHANDLE handle, int timeOutMS,int mode);

	/*
	@Name: FosSdk_GetMusicPlayMode.
	@Description: get mode of playing music.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param mode:mode of playing music.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMusicPlayMode(FOSHANDLE handle, int timeOutMS,int *mode);

	/*
	@Name: FosSdk_SetMusicPlayNext.
	@Description: play next music.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMusicPlayNext(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_SetMusicPlayPre.
	@Description: play preview music.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMusicPlayPre(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_GetMusicPlayState.
	@Description: get state of playing music.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param musicPlayState: state of playing music.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMusicPlayState(FOSHANDLE handle, int timeOutMS,FOS_MUSICPLAYSTARTINFO *musicPlayState);

	/*
	@Name: FosSdk_SetMusicPlayState.
	@Description: Set state of playing music.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param musicPlayState: state of playing music.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMusicPlayStart(FOSHANDLE handle, int timeOutMS,FOS_MUSICPLAYSTARTINFO *musicPlayState);

	/*
	@Name: FosSdk_SetMusicPlayStop.
	@Description: stop playing music.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMusicPlayStop(FOSHANDLE handle, int timeOutMS);

	/*
	@Name: FosSdk_SetMusicPlayPath.
	@Description: set music storage path.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param musicPath: music storage path.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMusicPlayPath(FOSHANDLE handle, int timeOutMS,FOS_MUSICPATH musicPath);

	/*
	@Name: FosSdk_GetMusicPlayPath.
	@Description: Get music storage path.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param musicPath: music storage path.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMusicPlayPath(FOSHANDLE handle, int timeOutMS,FOS_MUSICPATH *musicPath);

	/*
	@Name: FosSdk_SetMusicDormantTime.
	@Description: Set music dormant time.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param time: dormant time.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetMusicDormantTime(FOSHANDLE handle, int timeOutMS,int time);

	/*
	@Name: FosSdk_GetMusicDormantTime.
	@Description: Get music dormant time.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param time: dormant time.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetMusicDormantTime(FOSHANDLE handle, int timeOutMS,int *time);
	//cloud

	/*
	@Name: FosSdk_GetCloudConfig.
	@Description: get cloud config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param cloudConfig: cloud config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetCloudConfig(FOSHANDLE handle, int timeOutMS,FOS_CLOUDCONFIG *cloudConfig);

	/*
	@Name: FosSdk_SetCloudConfig.
	@Description: Set cloud config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param cloudConfig: cloud config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetCloudConfig(FOSHANDLE handle, int timeOutMS,FOS_CLOUDCONFIG *cloudConfig);

	/*
	@Name: FosSdk_SelectCloudServer.
	@Description: select cloud server.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param cloudServerInfo: cloud server info.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SelectCloudServer(FOSHANDLE handle, int timeOutMS,FOS_CLOUDSERVERINFO *cloudServerInfo);

	/*
	@Name: FosSdk_GetCloudToken.
	@Description: get cloud token.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param cloudConfig: cloud config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetCloudToken(FOSHANDLE handle, int timeOutMS,FOS_CLOUDCONFIG *cloudConfig);

	/*
	@Name: FosSdk_GetCloudQuota.
	@Description: get cloud quota.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param cloudConfig: cloud config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetCloudQuota(FOSHANDLE handle, int timeOutMS,FOS_CLOUDCONFIG *cloudConfig);

	/*
	@Name: FosSdk_TestCloudServer.
	@Description: test cloud server.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param cloudConfig: cloud config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_TestCloudServer(FOSHANDLE handle, int timeOutMS,FOS_CLOUDCONFIG *cloudConfig);

	/*
	@Name: FosSdk_GetPushConfig.
	@Description: get push config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param pushConfig: push config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetPushConfig(FOSHANDLE handle, int timeOutMS,FOS_PUSHCONFIG *pushConfig);

	/*
	@Name: FosSdk_SetPushConfig.
	@Description: Set push config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param pushConfig: push config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetPushConfig(FOSHANDLE handle, int timeOutMS,FOS_PUSHCONFIG *pushConfig);

	/*
	@Name: FosSdk_TestPushServer.
	@Description: test push config.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param pushConfig: push config.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_TestPushServer(FOSHANDLE handle, int timeOutMS,FOS_PUSHCONFIG *pushConfig);

	/*
	@Name: FosSdk_PushOperate.
	@Description: push operate info.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param pushOperateInfo: push operate info.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_PushOperate(FOSHANDLE handle, int timeOutMS,FOS_PUSHOPERATEINFO *pushOperateInfo);
	//MISC

	/*
	@Name: FosSdk_GetLog.
	@Description: get log information.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@param logInfo: search condition.
	@param getLogInfo: log information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetLog(FOSHANDLE handle, int timeOutMS,FOS_LOGINFO *logInfo,FOS_GETLOGINFO *getLogInfo);

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_CheckDuplexVoice(FOSHANDLE handle, int timeOutMS, int *isEnable);
	/*
	@Name: FosSdk_CancelAllNetCmd.
	@Description: cancel all net command.
	@param handle: the handle of current connection information.
	@param timeOutMS: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
#endif
	FOSSDK void FOSAPI FosSdk_CancelAllNetCmd(FOSHANDLE handle);

	/*
	@Name: FosSdk_Discovery.
	@Description: Use to discovery IPC.
	@param node: the information of IPC.
	@param size: the numbers of IPC.
	@param time: Time limits of timeout.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_Discovery(FOSDISCOVERY_NODE* node, int* size, int time);

	/*
	@Name: FosSdk_StopDiscovery.
	@Description: stop discovery IPC.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_StopDiscovery();

	/*
	@Name: FosSdk_RestartDiscovery.
	@Description: restart discovery IPC.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_RestartDiscovery();

	/*
	@Name: FosSdk_GetDiscoveryState.
	@Description: Get the discovery state.
	@return：1 is stop searching;zero is searching.
	*/
	FOSSDK int FOSAPI FosSdk_GetDiscoveryState();

	/*Local About*/

	/*
	@Name: FosSdk_StartRecord.
	@Description: Start Record.
	@param handle: the handle of current connection information.
	@param type: Record type.
	@param filename: Save file name.
	@param RecordErrorCallBack: Call back function,which use to get record error code.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/	
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_StartRecord(FOSHANDLE handle,FOSRECORDTYPE type,const char *filename);

	/*
	@Name: FosSdk_StartRecord2.
	@Description: Start Record.
	@param handle: the handle of current connection information.
	@param type: Record type.
	@param filename: Save file name.
	@param spaceSize: Remaining storage space(unit:KB).
	@param RecordErrorCallBack: Call back function,which use to get record error code.
	@return£ºPlease refer to the enum of FOSCMD_RESULT to get more information.
	*/	
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_StartRecord2(FOSHANDLE handle,FOSRECORDTYPE type,const char *filename, long long spaceSize);
	
	
	/*
	@Name: FosSdk_StopRecord.
	@Description: Stop Record.
	@param handle: the handle of current connection information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_StopRecord(FOSHANDLE handle);

	/*
	@Name: FosSdk_SetDecodeFormat.
	@Description: Set audio and video decode format.
	@param handle: the handle of current connection information.
	@param videoFmt: Video format.
	@param audioFmt: Audio format.
	@return: void.
	*/
	//FOSSDK void FOSAPI FosSdk_SetDecodeFormat(FOSHANDLE handle, FOSDECFMT videoFmt, FOSDECFMT audioFmt);

	/*
	@Name: FosSdk_GetVideoData.
	@Description: Get the data which decoded, the function is used to live view play mode.
	@param handle: the handle of current connection information.
	@param data: Buffer,use to save data which get.
	@param len: Size of buf.
	@param outLen: The size of the data which get.
	@param videoFmt: Video format.
	@param audioFmt: Audio format.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetVideoData(FOSHANDLE handle, char **data, int *outLen, FOSDECFMT videoFmt);

	/*
	@Name: FosSdk_GetVideoData2.
	@Description: Get the data which decoded, the function is used to live view play mode.
	@param handle: the handle of current connection information.
	@param data: Buffer,use to save data which get.
	@param len: Size of buf.
	@param outLen: The size of the data which get.
	@param videoFmt: Video format.
	@param mediaSpeed: The speed of the media data which get(bytes/s).
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetVideoData2(FOSHANDLE handle, char **data, int *outLen, FOSDECFMT videoFmt, int* mediaSpeed);

	/*
	@Name: FosSdk_GetVideoPBData.
	@Description: Get the data which decoded, the function is used to play back mode.
	@param handle: the handle of current connection information.
	@param data: Buffer,use to save data which get.
	@param len: Size of buf.
	@param outLen: The size of the data which get.
	@param videoFmt: Video format.
	@param mediaSpeed: The speed of the media data which get(bytes/s).
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetVideoPBData(FOSHANDLE handle, char **data, int *outLen, FOSDECFMT videoFmt, int* mediaSpeed);

	/*
	@Name: FosSdk_GetAudioData.
	@Description: Get the data which decoded, the function is used to live view play mode.
	@param handle: the handle of current connection information.
	@param data: Buffer,use to save data which get.
	@param len: Size of buf.
	@param outLen: The size of the data which get.
	@param videoFmt: Video format.
	@param audioFmt: Audio format.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SetWebRtcState(FOSHANDLE handle, int  enable);

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetAudioData(FOSHANDLE handle, char **data, int *outLen);

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetAudioData2(FOSHANDLE handle, char **data, int *outLen, int *mediaSpeed);

	/*
	@Name: FosSdk_GetAudioPBData.
	@Description: Get the data which decoded, the function is used to play back mode..
	@param handle: the handle of current connection information.
	@param data: Buffer,use to save data which get.
	@param len: Size of buf.
	@param outLen: The size of the data which get.
	@param videoFmt: Video format.
	@param audioFmt: Audio format.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetAudioPBData(FOSHANDLE handle, char **data, int *outLen, int *mediaSpeed);
	/*
	@Name: FosSdk_GetRawData
	@Description: Get raw data.
	@param handle: the handle of current connection information.
	@param data: Buffer,use to save data which get.
	@param len: Size of buf.
	@param outLen: The size of the data which get.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetRawData(FOSHANDLE handle, char *data, int len, int* outLen);

	/*
	@Name: FosSdk_GetRawData2
	@Description: Get raw data.
	@param handle: the handle of current connection information.
	@param data: Buffer,use to save data which get.
	@param len: Size of buf.
	@param outLen: The size of the data which get.
	@param mediaSpeed: The speed of the media data which get(bytes/s).
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetRawData2(FOSHANDLE handle, char *data, int len, int* outLen, int* mediaSpeed);

	/*
	@Name: FosSdk_GetRawData3.
	@Description: Get raw data.
	@param handle: the handle of current connection information.
	@param data: Buffer,use to save data which get.
	@param len: Size of buf.
	@param outLen: The size of the data which get.
	@param mediaSpeed: The speed of the media data which get(bytes/s).
	@return£ºPlease refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetRawData3(FOSHANDLE handle, char **data, int len, int *outLen, int* mediaSpeed);

	/*
	@Name: FosSdk_DecSnapPic.
	@Description: Snap picture from decoder,save the picture as file.
	@param handle: the handle of current connection information.
	@param filePathName: File path name,use to save picture.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_DecSnapPic(FOSHANDLE handle, char *filePathName);


	/*
	@Name: FosSdk_DecSnap.
	@Description: Snap picture from decoder,save the picture on buffer.
	@param handle: the handle of current connection information.
	@param data: buffer,use to save picture.
	@param len: Size of data.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_DecSnap(FOSHANDLE handle, char *data, int *len);

	/*
	@Name: FosSdk_DecSnapScale.
	@Description: Snap picture from decoder,save the picture on buffer.
	@param handle: the handle of current connection information.
	@param data: buffer,use to save picture.
	@param len: Size of data.
	@param width: destination width of picture after scaled.
	@param height: destination height of picture after scaled.
	@param type: destination type of picture after scaled.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_DecSnapScale(FOSHANDLE handle, char *data, int *len, int width, int height, FOSDECFMT type);

	/*
	@Name: FosSdk_GetEvent.
	@Description: Get event of IPC.
	@param handle: the handle of current connection information.
	@param data: Use to save event of IPC which get.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetEvent(FOSHANDLE handle, FOSEVET_DATA *data);

	/*
	@Name: FosSdk_GetConnectInfo.
	@Description: Get connection Information.
	@param handle: the handle of current connection information.
	@param usr: User connection information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetConnectInfo(FOSHANDLE handle, FOS_UserInfo* usr) ;

   /*
	@Name: FosSdk_GetStreamParamInfo.
	@Description: Get stream information..
	@param handle: the handle of current connection information.
	@param streamframeInfo: User stream	category.
	@param streamInfo: sensor type and model information.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetStreamParamInfo(FOSHANDLE handle, int timeOutMS,FOS_STREAMFRAMEPARAMINFO *streamframeInfo,FOS_STREAMINFO* streamInfo) ;

	/*
	@Name: FosSdk_GetIPCProfile.
	@Description: Get IPC known parameters.
	@param handle: the handle of current connection information.
	@param ipcprofile: Use to save known parameters of IPC which get.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_GetIPCProfile(FOSHANDLE handle, FOS_IpcProfileMsg* ipcprofile) ;
	
	/*
	@Name: FOS_UIDParse.
	@Description: parse UID.
	@param src: the data contains UID.
	@param srclen: data len.
	@return：Please refer to the enum of FOSCMD_RESULT to get more information.
	*/
	FOSSDK FOSCMD_RESULT FOSAPI FOS_UIDParse(char *src,int srclen);

	/*
		MTK smart connection Interface
	*/
	
	FOSSDK FOSCMD_RESULT FOSAPI FOS_StartEZlink(char* uid, char *ssid, char *password,
					FOSDISCOVERY_NODE *getNode, unsigned int timeOut10MS);
	// Ezlinktype  0:auto 1:MTK 2:broadCom  
	FOSSDK FOSCMD_RESULT FOSAPI FOS_StartEZlink2(char* uid, char *ssid, char *password, unsigned int phoneIP,
		FOSDISCOVERY_NODE *getNode, unsigned int timeOut10MS,int Ezlinktype);

	FOSSDK FOSCMD_RESULT FOSAPI FOS_StopEZlink();

	FOSSDK FOSDECODERHANDLE	FOSAPI FOS_CreateDecoder(FOSDEV_TYPE type);

	FOSSDK void	FOSAPI FOS_ReleaseDecoder(FOSDECODERHANDLE decoderHandle);

	FOSSDK FOSCMD_RESULT FOSAPI FOS_Decode(FOSDECODERHANDLE decoderHandle, unsigned char *inBuffer,
		unsigned int inBufsize,unsigned char **outBuffer,unsigned int* outBufferSize,unsigned int *width,
		unsigned int *height,FOSDECFMT pixelFormat);
	FOSSDK FOSCMD_RESULT FOSAPI FOS_CapturePicture(FOSDECODERHANDLE decoderHandle, char *filePathName);

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SnapFile(FOSHANDLE handle, int timeOutMS, char *filePath);

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SnapFile2(FOSHANDLE handle, int timeOutMS, char *fileData, int len, int *size, FOS_GetSnapFileMsg *fileInfo);

	FOSSDK FOSCMD_RESULT FOSAPI FosSdk_SnapFileNew(FOSHANDLE handle, int timeOutMS, char *fileData, int len, int *size, FOS_GetSnapFileNewMsg *fileInfo);

	FOSSDK PLAYERHADLE FOSAPI FosPlayer_CreatePlayer(const char *filename);
	FOSSDK void FOSAPI FosPlayer_ReleasePlayer(PLAYERHADLE playerHandle);
	FOSSDK FOSCMD_RESULT FOSAPI FosPlayer_OpenFile(PLAYERHADLE playerHandle, const char *filename);
	FOSSDK void FOSAPI FosPlayer_CloseFile(PLAYERHADLE playerHandle);
	FOSSDK FOSCMD_RESULT FOSAPI FosPlayer_GetVideoData(PLAYERHADLE playerHandle, unsigned char **outBuffer, 
		int *outBufferSize, FOSDECFMT pixelFormat);
    FOSSDK FOSCMD_RESULT FOSAPI FosPlayer_GetRawVideoData(PLAYERHADLE playerHandle, unsigned char *outBuffer,
                                                       int *outBufferSize);
	FOSSDK FOSCMD_RESULT FOSAPI FosPlayer_CapturePictureSaveByName(PLAYERHADLE playerHandle, const char* filename);
	FOSSDK FOSCMD_RESULT FOSAPI FosPlayer_CaputrePicture(PLAYERHADLE playerHandle, int width, int height, FOSDECFMT type, char *outputPicBuff,int *outputPicBuffSize);
	FOSSDK FOSCMD_RESULT FOSAPI FosPlayer_GetAudioData(PLAYERHADLE playerHandle, char *data, int *outLen);
	FOSSDK int FOSAPI FosPlayer_SetPlayPosition(PLAYERHADLE playerHandle, double relativePosition);
	FOSSDK int FOSAPI FosPlayer_GetPlayInfo(PLAYERHADLE playerHandle, FOS_PlaybackInfo *playInfo);
#ifdef __cplusplus
}
#endif
#endif
