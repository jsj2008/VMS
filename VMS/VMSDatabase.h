//
//  VMSDatabase.h
//  VMS
//
//  Created by mac_dev on 15/7/6.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "CDevice.h"
#import "Group.h"
#import "Poll.h"
#import "ScheduledRecordTask.h"
#import "NSDate + SRAdditions.h"
#import "VMSUser.h"
#import "UserGroup.h"
#import "Log.h"
#import "AlarmLink.h"
#import "ScheduledTask.h"
#import "VMSPathManager.h"


#define TIME_FORMATTER                  @"HH:mm:ss"
#define DATABASE_CHANGED_NOTIFICATION   @"database changed notification"
#define NOTIFI_KEY_DEVICE               @"notification key device"
#define NOTIFI_KEY_CHANNEL              @"notification key channel"
#define NOTIFI_KEY_DB_OP                @"notification key database operation"

typedef NS_ENUM(NSUInteger, VMS_DATABASE_OP) {
    VMS_ALARM_UPDATE,
    VMS_SHEDULE_RECORD_UPDATE,
    VMS_DISCARD,
    VMS_DEVICE_ADD,
    VMS_DEVICE_REMOVE,
    VMS_DEVICE_UPDATE,
};

enum {
    CHANNEL = 0,
    NORMAL_GROUP = 1,
    PATROL_GROUP = 2,//轮巡组
    ROOT_GROUP = 3,
    IPC_DEVICE  = 0,
    NVR_DEVICE = 9,
};typedef NSInteger DeviceInfoType;


//singleton_interface
@protocol VMSDatabaseProtocol <NSObject>
- (void)deviceTableDidChange;
@end

@interface VMSDatabase : NSObject {
    sqlite3 *_database;
}

+ (VMSDatabase *)sharedVMSDatabase;

//数据库迁徙
- (void)migration;
- (void)disconnect;

//Fetch
- (int)fetchChannelIdWithDeviceId :(int)devId logicId :(int)logicId;
- (int)fetchEntityCount :(NSString *)entity;
- (NSArray *)fetchLogsFromDate :(NSString *)begin toDate :(NSString *)date;
- (UserGroup *)fetchUserGroupWithUniqueId :(int)uniqueId;
- (NSArray *)fetchUserGroups;
- (NSArray *)fetchUsers;
- (VMSUser *)fetchUserWithUniqueId :(int)uniqueId;
- (VMSUser *)fetchUserWithUserName :(NSString *)name;
- (VMSUser *)fetchUserWithUserName :(NSString *)name password :(NSString *)psw;
- (Group *)fetchGroupWithUniqueId :(int)uniqueId;
- (NSArray *)fetchGroups;
- (CDevice *)fetchDeviceWithEntity :(NSString *)entity value :(NSString *)value;
- (NSArray *)fetchDevicesWithGroup :(Group *)group;
- (NSArray *)fetchDevices;
- (NSArray *)fetchDevicesWithType :(int)type;
- (NSArray *)fetchScheduledRecordTasksWithChannel :(Channel *)channel;
- (NSArray *)fetchChannelsWithDevice :(CDevice *)device;
- (NSArray *)fetchPollsWithGroup :(Group *)group;
- (AlarmLink *)fetchAlarmLinkWithChannelId :(int)channelId;
- (NSArray *)fetchScheduledTasksWithWeekday :(int)weekday entity :(NSString *)entity;
- (NSArray *)fetchScheduledTasksWithChannel :(Channel *)channel entity :(NSString *)entity;

//Delete
- (BOOL)deleteUser :(VMSUser *)user;
- (BOOL)deleteGroup :(Group *)group;
- (BOOL)cancelGroup :(Group *)group;
- (BOOL)deleteDevice :(CDevice *)device;
- (BOOL)deleteAllRecordTasks;
- (BOOL)deleteAllFromEntity :(NSString *)entity;

//Insert
- (int)insertLog :(NSString *)opt type :(NSString *)type event :(NSString *)event;
- (int)insertUser :(VMSUser *)user;
- (int)insertChannel :(Channel *)channel;
- (int)insertDevice :(CDevice *)device;
- (int)insertGroup :(Group *)group;
- (int)insertPoll :(Poll *)poll;
- (int)insertScheduledTaskWithChannelId :(int)cId data :(long long)data weekday :(int)weekday withEntity:(NSString *)entity;
- (int)insertAlarmLinkage :(AlarmLink *)alarmLink;

//Update
- (BOOL)updateUser :(VMSUser *)user;
- (BOOL)updateChannelName :(NSString *)newName uniquelId :(int)uniqueID;
- (BOOL)updateDevice :(CDevice *)device;
- (BOOL)updateGroup :(Group *)group;
- (BOOL)updateScheduledData :(long long)data chnId :(int)chnId weekday :(int)weekday withEntity :(NSString *)entitiy;
- (BOOL)updateAlarmLink :(VMS_ALARM_LINKAGE)link alarmType :(int)alarmType withChannelId :(int)chnId;

@end
