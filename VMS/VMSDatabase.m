//  VMSDatabase.m
//  VMS
//
//  Created by mac_dev on 15/7/6.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VMSDatabase.h"
#define PRAGMA_FOREIGN_KEYS_ON      "pragma foreign_keys = on"
@interface VMSDatabase()
@property (strong,nonatomic) NSString *path;
@property (strong,nonatomic) NSMutableArray *observers;
@property (strong,nonatomic) NSLock *lock;
@end


static VMSDatabase *sharedVMSDatabase = nil;
static dispatch_once_t pred;

@implementation VMSDatabase
+ (VMSDatabase *)sharedVMSDatabase
{
    dispatch_once(&pred, ^{
        sharedVMSDatabase = [[super allocWithZone:NULL] init];
    });
    return sharedVMSDatabase;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedVMSDatabase];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}


- (id)init
{
    if (self = [super init]) {
        [self initDatabase];
    }
    
    return self;
}


- (void)disconnect
{
    if (_database) {
        sqlite3_close(_database);
    }
}

- (void) initDatabase {
    NSString        *dbPath         = self.path;
    
    if (_database) return;//已经建立了数据库连接
    if (sqlite3_open(dbPath.UTF8String, &_database) == SQLITE_OK) {
        
        char        *errMsg   = NULL;
        NSString    *sql_stmt = nil;
        do {
            //create t_device
            sql_stmt = @"create table if not exists t_device (";
            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"ip TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"port INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"user_name TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"user_psw TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"type INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"isenable INTEGER DEFAULT 1,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"rtsp_port INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"mac_address TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"serial_number TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"decoder_type INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"channel_count INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"device_name TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"group_id INTEGER DEFAULT -1)"];
            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) break;
            
            
            //create t_channel
            sql_stmt = @"create table if not exists t_channel (";
            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"logic_id INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"device_id INTEGER REFERENCES t_device(id) on delete cascade on update cascade,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"channel_name TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"type INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"group_id INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"unused1 INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"unused2 INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"isenable INTEGER DEFAULT 1,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"map_x TEXT DEFAULT -1,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"map_y TEXT DEFAULT -1)"];
            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) break;
            
            //create t_group
            sql_stmt = @"create table if not exists t_group (";
            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"group_name TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"type INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"remark TEXT)"];
            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) break;
            
            //create t_poll
            sql_stmt = @"create table if not exists t_poll (";
            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"group_id INTEGER REFERENCES t_group(id) on delete cascade on update cascade,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"channel_id INTEGER REFERENCES t_channel(id) on delete cascade on update cascade,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"wait_sec INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"sequence_num INTEGER)"];
            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) break;
            
            //create t_alarm_link
            sql_stmt = @"create table if not exists t_alarm_link (";
            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"channel_id INTEGER REFERENCES t_channel(id) on delete cascade on update cascade,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"alarm_type INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"is_record INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"is_play_sound INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"is_snap INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"is_show_video INTEGER)"];
            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) break;
            
            //create t_alarm_plan
            sql_stmt = @"create table if not exists t_alarm_plan (";
            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"channel_id INTEGER REFERENCES t_channel(id) on delete cascade on update cascade,"];
            //sql_stmt = [sql_stmt stringByAppendingString:@"start_time TEXT,"];
            //sql_stmt = [sql_stmt stringByAppendingString:@"end_time TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"data INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"week INTEGER)"];
            //sql_stmt = [sql_stmt stringByAppendingString:@"id_select INTEGER)"];
            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) break;
            
            //create t_rec_plan
            sql_stmt = @"create table if not exists t_rec_plan (";
            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"channel_id INTEGER REFERENCES t_channel(id) on delete cascade on update cascade,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"data INTEGER,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"week INTEGER)"];
            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) break;
            
            //create t_user_group
            sql_stmt = @"create table if not exists t_user_group (";
            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"name TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"remark TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"right TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"level INTEGER)"];
            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) break;
            
            //create t_user
            sql_stmt = @"create table if not exists t_user (";
            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"user_name TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"psw TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"remark TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"group_id INTEGER)"];
            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) break;
            
            
            //create t_log
            sql_stmt = @"create table if not exists t_log (";
            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"operator TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"date_time TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"type TEXT,"];
            sql_stmt = [sql_stmt stringByAppendingString:@"event TEXT)"];
            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) break;
        } while (0);
        
        if (!errMsg) {
            //TODO:zhe li yi ming zi wei zhu jian
            //insert user group
            int adminGroupId = [self insertUserGroup:@"admin" remark:@"" right:@"" level:0];
            [self insertUserGroup:@"guest" remark:@"" right:@"" level:1];
            [self insertUserGroup:@"operator" remark:@"" right:@"" level:2];
            
            //insert root
            [self insertUser:[[VMSUser alloc] initWithUniqueId:-1
                                                      userName:ROOT
                                                      password:@""
                                                        remark:@""
                                                       gorupId:adminGroupId]];
        } else {
            NSLog(@"Err occured when create table:%@",[NSString stringWithUTF8String:errMsg]);
            sqlite3_close(_database);
            exit(0);
        }
    } else {
        NSLog(@"Failed to create connection to database");
        exit(0);
    }
}



//v0.0.5
- (void)migration
{
    //Update user group
    NSString        *update1 = @"update t_user_group set name = 'guest' where id = 3";
    NSString        *update2 = @"update t_user_group set name = 'operator' where id = 2";
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[update1 UTF8String],-1,&statement,nil);
        sqlite3_step(statement);
        sqlite3_prepare_v2(_database,[update2 UTF8String],-1,&statement,nil);
        sqlite3_step(statement);
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
}


//v0.0.3
//- (void)migration
//{
//    NSFileManager *filemgr = [NSFileManager defaultManager];
//    NSError *err;
//    //the file will not be there when we load the application for the first time
//    //so this will create the database table
//    if ([filemgr fileExistsAtPath: self.path] == YES)
//    {
//        [filemgr removeItemAtPath:self.path error:&err];
//        [self initDatabase];
//    }
//}


//- (void)migration
//{
//    NSFileManager *filemgr = [NSFileManager defaultManager];
//    
//    //the file will not be there when we load the application for the first time
//    //so this will create the database table
//    if ([filemgr fileExistsAtPath: self.path] == NO)
//    {
//        const char *dbpath = [self.path UTF8String];
//        if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
//        {
//            char *tables[3] = {"t_alarm_link","t_alarm_plan","t_rec_plan"};
//            char *errMsg;
//            NSString *sql_stmt;
//            //移除t_alarm_plan,t_alarm_link,t_rec_plan
//            for (int idx = 0;idx < 3; idx++) {
//                NSString *table = [NSString stringWithUTF8String:tables[idx]];
//                sql_stmt = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@",table];
//                if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK)
//                {
//                    NSLog(@"Failed to create t_log table");
//                }
//            }
//            
//            //重新创建这三张表
//            //create t_alarm_link
//            sql_stmt = @"create table if not exists t_alarm_link (";
//            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"channel_id INTEGER REFERENCES t_channel(id) on delete cascade on update cascade,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"alarm_type INTEGER,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"is_record INTEGER,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"is_play_sound INTEGER,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"is_snap INTEGER,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"is_show_video INTEGER)"];
//            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK)
//            {
//                NSLog(@"Failed to create alarm_link table");
//            }
//            
//            //create t_alarm_plan
//            sql_stmt = @"create table if not exists t_alarm_plan (";
//            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"channel_id INTEGER REFERENCES t_channel(id) on delete cascade on update cascade,"];
//            //sql_stmt = [sql_stmt stringByAppendingString:@"start_time TEXT,"];
//            //sql_stmt = [sql_stmt stringByAppendingString:@"end_time TEXT,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"data INTEGER,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"week INTEGER)"];
//            //sql_stmt = [sql_stmt stringByAppendingString:@"id_select INTEGER)"];
//            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK)
//            {
//                NSLog(@"Failed to create alarm_plan table");
//            }
//            
//            //create t_rec_plan
//            sql_stmt = @"create table if not exists t_rec_plan (";
//            sql_stmt = [sql_stmt stringByAppendingString:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"channel_id INTEGER REFERENCES t_channel(id) on delete cascade on update cascade,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"data INTEGER,"];
//            sql_stmt = [sql_stmt stringByAppendingString:@"week INTEGER)"];
//            if (sqlite3_exec(_database, [sql_stmt UTF8String], NULL, NULL, &errMsg) != SQLITE_OK)
//            {
//                NSLog(@"Failed to create rec_plan table");
//            }
//            
//            sqlite3_close(_database);
//        }
//    }
//}

- (NSInteger)fetchChannelIdWithDeviceId :(NSInteger)devId logicId :(NSInteger)logicId
{
    NSString *query = [NSString stringWithFormat:@"select id from t_channel where device_id = %ld and logic_id = %ld",devId,logicId];
    sqlite3_stmt    *statement;
    int channelId = -1;
    
    [self.lock lock];
    if (_database) {
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            channelId   = sqlite3_column_int(statement, 0);
        }
        
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    
    return channelId;
}

- (NSArray *)fetchLogsFromDate :(NSString *)begin toDate :(NSString *)end
{
    NSMutableArray  *logs       = [[NSMutableArray alloc] init];
    NSString        *field      = @"id,operator,date_time,type,event";
    NSString        *condition  = [NSString stringWithFormat:@"datetime(date_time) >= '%@' and datetime(date_time) <= '%@'",begin,end];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_log where %@",field,condition];
    sqlite3_stmt    *statement;
    
    [self.lock lock];
    if (_database) {
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     uniqueId    = sqlite3_column_int(statement, 0);
            char    *operator   = (char *)sqlite3_column_text(statement, 1);
            char    *date_time  = (char *)sqlite3_column_text(statement, 2);
            char    *type       = (char *)sqlite3_column_text(statement, 3);
            char    *event      = (char *)sqlite3_column_text(statement, 4);
            
            [logs addObject:[[Log alloc] initWithUniqueId:uniqueId
                                                 operator:[NSString stringWithUTF8String:operator]
                                                     date:[NSString stringWithUTF8String:date_time]
                                                     type:[NSString stringWithUTF8String:type]
                                                    event:[NSString stringWithUTF8String:event]]];
            
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return logs;
}


- (UserGroup *)fetchUserGroupWithUniqueId :(NSInteger)uniqueId
{
    UserGroup       *group      = nil;
    NSString        *field      = @"name,remark,'right',level";
    NSString        *condition  = [NSString stringWithFormat:@"id == %ld",uniqueId];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_user_group where %@",field,condition];
    sqlite3_stmt    *statement;
    
    [self.lock lock];
    if (_database) {
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *name      = (char *)sqlite3_column_text(statement, 0);
            char *remark    = (char *)sqlite3_column_text(statement, 1);
            char *right     = (char *)sqlite3_column_text(statement, 2);
            int level = sqlite3_column_int(statement, 3);
            
            if (!remark) remark = "";
            if (!right) remark = "";
            group = [[UserGroup alloc] initWithUniqueId:uniqueId
                                              groupName:[NSString stringWithUTF8String:name]
                                                 remark:[NSString stringWithUTF8String:remark]
                                                  right:[NSString stringWithUTF8String:right]
                                                  level:level];
        }
        
        
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return group;
}

- (NSArray *)fetchUserGroups
{
    NSMutableArray  *userGroups = [[NSMutableArray alloc] init];
    NSString        *field      = @"id,name,remark,'right',level";
    NSString        *query      = [NSString stringWithFormat :@"select %@ from t_user_group",field];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     groupId = sqlite3_column_int(statement, 0);
            char    *name   = (char *)sqlite3_column_text(statement, 1);
            char    *remark = (char *)sqlite3_column_text(statement, 2);
            char *right = (char *)sqlite3_column_text(statement, 3);
            int level = sqlite3_column_int(statement, 4);
            
            remark = !remark? "" : remark;
            right = !right? "" : right;
            UserGroup *group = [[UserGroup alloc] initWithUniqueId:groupId
                                                         groupName:[NSString stringWithUTF8String:name]
                                                            remark:[NSString stringWithUTF8String:remark]
                                                             right:[NSString stringWithUTF8String:right]
                                                             level:level];
            [userGroups addObject:group];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return userGroups;
}

- (NSArray *)fetchUsers
{
    NSMutableArray  *vmsUsers   = [[NSMutableArray alloc] init];
    NSString        *field      = @"id,user_name,psw,remark,group_id";
    NSString        *query      = [NSString stringWithFormat :@"select %@ from t_user",field];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     userId      = sqlite3_column_int(statement, 0);
            char    *userName   = (char *)sqlite3_column_text(statement, 1);
            char    *password   = (char *)sqlite3_column_text(statement, 2);
            char    *remark     = (char *)sqlite3_column_text(statement, 3);
            int     groupId     = sqlite3_column_int(statement, 4);
            
            remark = !remark? "" : remark;
            VMSUser *vmsUser = vmsUser = [[VMSUser alloc] initWithUniqueId :userId
                                                                  userName :[NSString stringWithUTF8String:userName]
                                                                  password :[NSString stringWithUTF8String:password]
                                                                    remark :[NSString stringWithUTF8String:remark]
                                                                   gorupId :groupId];
            [vmsUsers addObject:vmsUser];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    
    return vmsUsers;
}

- (VMSUser *)fetchUserWithUniqueId :(NSInteger)uniqueId
{
    VMSUser         *vmsUser    = nil;
    NSString        *field      = @"id,user_name,psw,remark,group_id";
    NSString        *condition  = [NSString stringWithFormat:@"id == %ld",uniqueId];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_user where %@",field,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        if (sqlite3_step(statement) == SQLITE_ROW) {
            int     userId      = sqlite3_column_int(statement, 0);
            char    *userName   = (char *)sqlite3_column_text(statement, 1);
            char    *password   = (char *)sqlite3_column_text(statement, 2);
            char    *remark     = (char *)sqlite3_column_text(statement, 3);
            int groupId = sqlite3_column_int(statement, 4);
            
            if (!remark) remark = "";
            vmsUser = [[VMSUser alloc] initWithUniqueId :userId
                                               userName :[NSString stringWithUTF8String:userName]
                                               password :[NSString stringWithUTF8String:password]
                                                 remark :[NSString stringWithUTF8String:remark]
                                                gorupId :groupId];
        }
        sqlite3_finalize(statement);
    }

    [self.lock unlock];
    
    return vmsUser;
}

- (VMSUser *)fetchUserWithUserName :(NSString *)name
{
    VMSUser         *vmsUser    = nil;
    NSString        *field      = @"id,user_name,psw,remark,group_id";
    NSString        *condition  = [NSString stringWithFormat:@"user_name == '%@'",name];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_user where %@",field,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        if (sqlite3_step(statement) == SQLITE_ROW) {
            int     userId      = sqlite3_column_int(statement, 0);
            char    *userName   = (char *)sqlite3_column_text(statement, 1);
            char    *password   = (char *)sqlite3_column_text(statement, 2);
            char    *remark     = (char *)sqlite3_column_text(statement, 3);
            int     groupId     = sqlite3_column_int(statement, 4);
            
            if (!remark) remark = "";
            vmsUser = [[VMSUser alloc] initWithUniqueId :userId
                                               userName :[NSString stringWithUTF8String:userName]
                                               password :[NSString stringWithUTF8String:password]
                                                 remark :[NSString stringWithUTF8String:remark]
                                                gorupId :groupId];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    
    return vmsUser;
}


- (VMSUser *)fetchUserWithUserName :(NSString *)name password :(NSString *)psw
{
    VMSUser         *vmsUser = nil;
    NSString        *field = @"id,user_name,psw,remark,group_id";
    NSString        *condition = [NSString stringWithFormat:@"user_name == '%@' and psw == '%@'",name,psw];
    NSString        *query = [NSString stringWithFormat:@"select %@ from t_user where %@",field,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        if (sqlite3_step(statement) == SQLITE_ROW) {
            int     userId      = sqlite3_column_int(statement, 0);
            char    *userName   = (char *)sqlite3_column_text(statement, 1);
            char    *password   = (char *)sqlite3_column_text(statement, 2);
            char    *remark     = (char *)sqlite3_column_text(statement, 3);
            int groupId = sqlite3_column_int(statement, 4);
            
            if (!remark) remark = "";
            vmsUser = [[VMSUser alloc] initWithUniqueId :userId
                                               userName :[NSString stringWithUTF8String:userName]
                                               password :[NSString stringWithUTF8String:password]
                                                 remark :[NSString stringWithUTF8String:remark]
                                                gorupId :groupId];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    
    return vmsUser;
}

- (Group *)fetchGroupWithUniqueId :(NSInteger)uniqueId
{
    Group           *group      = nil;
    NSString        *field      = @"id,type,group_name,remark";
    NSString        *condition  = [NSString stringWithFormat:@"id == %ld",uniqueId];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_group where %@ order by id",field,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        if (sqlite3_step(statement) == SQLITE_ROW) {
            int     groupId = sqlite3_column_int(statement, 0);
            int     type    = sqlite3_column_int(statement, 1);
            char    *name   = (char *)sqlite3_column_text(statement, 2);
            char    *remark = (char *)sqlite3_column_text(statement, 3);
            
            group = [[Group alloc] initWithUniqueId:groupId
                                               name:[NSString stringWithUTF8String:name]
                                               type:type
                                             remark:[NSString stringWithUTF8String:remark]];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return group;
}

- (CDevice *)fetchDeviceWithUID :(NSString *)uid
{
    return nil;
}

- (CDevice *)fetchDeviceWithMacAddr :(NSString *)macAddr
{
    CDevice         *device     = nil;
    char sql[1024] = {0};
    sprintf(sql, "select a.*,b.* from t_device a left join t_group b on \
            a.group_id = b.id where a.isenable=1 and mac_address == '%s'",macAddr.UTF8String);
    sqlite3_stmt    *statement;
    char            *errMsg;
    
 
   
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,sql,-1,&statement,nil);
        if (sqlite3_step(statement) == SQLITE_ROW) {
            int     devId           = sqlite3_column_int(statement, 0);
            char    *ip             = (char *)sqlite3_column_text(statement, 1);
            int     port            = sqlite3_column_int(statement,2);
            char    *user_name      = (char *)sqlite3_column_text(statement, 3);
            char    *user_psw       = (char *)sqlite3_column_text(statement, 4);
            int     type            = sqlite3_column_int(statement, 5);
            int     rtsp_port       = sqlite3_column_int(statement, 7);
            char    *mac_address    = (char *)sqlite3_column_text(statement, 8);
            char    *serial_number  = (char *)sqlite3_column_text(statement, 9);
            int     decoder_type    = sqlite3_column_int(statement, 10);
            int     channel_count   = sqlite3_column_int(statement, 11);
            char    *device_name    = (char *)sqlite3_column_text(statement, 12);
            int     groupId         = sqlite3_column_int(statement, 13);
            char    *group_name     = (char *)sqlite3_column_text(statement, 15);
            int     group_type      = sqlite3_column_int(statement, 16);
            char    *remark         = (char *)sqlite3_column_text(statement, 17);
            
            Group *group = (groupId < 0)? nil : [[Group alloc] initWithUniqueId:groupId
                                                                           name:[NSString stringWithUTF8String:group_name]
                                                                           type:group_type
                                                                         remark:[NSString stringWithUTF8String:remark]];
            device = [[CDevice alloc] initWithUniqueId:devId
                                                  name:[NSString stringWithUTF8String:device_name]
                                                  type:type
                                                    ip:[NSString stringWithUTF8String:ip]
                                                  port:port
                                              userName:[NSString stringWithUTF8String:user_name]
                                               userPsw:[NSString stringWithUTF8String:user_psw]
                                              rtspPort:rtsp_port
                                            macAddress:[NSString stringWithUTF8String:mac_address]
                                          serialNumber:[NSString stringWithUTF8String:serial_number]
                                          decorderType:decoder_type
                                          channelCount:channel_count
                                                 Group:group];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    
    return device;
}

- (CDevice *)fetchDeviceWithUniqueId :(NSInteger)uniqueId
{
    CDevice         *device     = nil;
    char sql[1024] = {0};
    char    *errMsg;
    sqlite3_stmt    *statement;
    
    sprintf(sql, "select a.*,b.* from t_device a left join t_group b on \
            a.group_id = b.id where a.isenable=1 and a.id == '%ld'",uniqueId);
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,sql,-1,&statement,nil);
        if (sqlite3_step(statement) == SQLITE_ROW) {
            int     uniqueId        = sqlite3_column_int(statement, 0);
            char    *ip             = (char *)sqlite3_column_text(statement, 1);
            int     port            = sqlite3_column_int(statement,2);
            char    *user_name      = (char *)sqlite3_column_text(statement, 3);
            char    *user_psw       = (char *)sqlite3_column_text(statement, 4);
            int     type            = sqlite3_column_int(statement, 5);
            int     rtsp_port       = sqlite3_column_int(statement, 7);
            char    *mac_address    = (char *)sqlite3_column_text(statement, 8);
            char    *serial_number  = (char *)sqlite3_column_text(statement, 9);
            int     decoder_type    = sqlite3_column_int(statement, 10);
            int     channel_count   = sqlite3_column_int(statement, 11);
            char    *device_name    = (char *)sqlite3_column_text(statement, 12);
            int     groupId         = sqlite3_column_int(statement, 13);
            char    *group_name     = (char *)sqlite3_column_text(statement, 15);
            int     group_type      = sqlite3_column_int(statement, 16);
            char    *remark         = (char *)sqlite3_column_text(statement, 17);
            
            
            Group *group = (groupId < 0)? nil : [[Group alloc] initWithUniqueId:groupId
                                                                           name:[NSString stringWithUTF8String:group_name]
                                                                           type:group_type
                                                                         remark:[NSString stringWithUTF8String:remark]];
            device = [[CDevice alloc] initWithUniqueId:uniqueId
                                                  name:[NSString stringWithUTF8String:device_name]
                                                  type:type
                                                    ip:[NSString stringWithUTF8String:ip]
                                                  port:port
                                              userName:[NSString stringWithUTF8String:user_name]
                                               userPsw:[NSString stringWithUTF8String:user_psw]
                                              rtspPort:rtsp_port
                                            macAddress:[NSString stringWithUTF8String:mac_address]
                                          serialNumber:[NSString stringWithUTF8String:serial_number]
                                          decorderType:decoder_type
                                          channelCount:channel_count
                                                 Group:group];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return device;
}

- (NSArray *)fetchGroups
{
    NSMutableArray  *groups = [[NSMutableArray alloc] init];
    NSString        *field  = @"id,type,group_name,remark";
    NSString        *query  = [NSString stringWithFormat :@"select %@ from t_group order by id",field];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     groupId = sqlite3_column_int(statement, 0);
            int     type    = sqlite3_column_int(statement, 1);
            char    *name   = (char *)sqlite3_column_text(statement, 2);
            char    *remark = (char *)sqlite3_column_text(statement, 3);
            Group   *group  = [[Group alloc] initWithUniqueId:groupId
                                                         name:[NSString stringWithUTF8String:name]
                                                         type:type
                                                       remark:[NSString stringWithUTF8String:remark]];
            [groups addObject:group];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return groups;
}

- (int)fetchRootId
{
    int             unique_id = -1;
    NSString        *query = [NSString stringWithFormat:@"select id from t_user where user_name = '%@'",ROOT];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            unique_id = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    
    return unique_id;
}

- (int)fetchUserGroupIdWithName :(NSString *)name
{
    int             unique_id = -1;
    NSString        *query = [NSString stringWithFormat:@"select id from t_user_group where name = '%@'",name];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1, &statement, nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            unique_id = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return unique_id;
}

- (int)fetchLatestIdFromTable :(NSString *)table
{
    int             unique_id = -1;
    NSString        *field = @"max(id)";
    NSString        *querey_sql = [NSString stringWithFormat:@"select %@ from %@",field,table];
    sqlite3_stmt    *statement;
    
    //[self.lock lock];
    if (_database) {
        sqlite3_prepare_v2(_database,[querey_sql UTF8String],-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW)
            unique_id = sqlite3_column_int(statement, 0);
        sqlite3_finalize(statement);
    }
    //[self.lock unlock];
    
    return unique_id;
}


- (NSArray *)fetchDevices
{
    NSMutableArray  *devices    = [[NSMutableArray alloc] init];
    
    char *errMsg;
    //char *sql = "select a.*,b.* from t_device a left join t_group b on a.group_id = b.id where a.isenable=1";
    char *sql = "select * from t_device where isenable=1";
    sqlite3_stmt    *statement;
    

    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,sql,-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     devId           = sqlite3_column_int(statement, 0);
            char    *ip             = (char *)sqlite3_column_text(statement, 1);
            int     port            = sqlite3_column_int(statement,2);
            char    *user_name      = (char *)sqlite3_column_text(statement, 3);
            char    *user_psw       = (char *)sqlite3_column_text(statement, 4);
            int     type            = sqlite3_column_int(statement, 5);
            int     rtsp_port       = sqlite3_column_int(statement, 7);
            char    *mac_address    = (char *)sqlite3_column_text(statement, 8);
            char    *serial_number  = (char *)sqlite3_column_text(statement, 9);
            int     decoder_type    = sqlite3_column_int(statement, 10);
            int     channel_count   = sqlite3_column_int(statement, 11);
            char    *device_name    = (char *)sqlite3_column_text(statement, 12);
//            int     groupId         = sqlite3_column_int(statement, 13);
//            char    *group_name     = (char *)sqlite3_column_text(statement, 15);
//            int     group_type      = sqlite3_column_int(statement, 16);
//            char    *remark         = (char *)sqlite3_column_text(statement, 17);
        
//            Group *group = (groupId < 0)? nil : [[Group alloc] initWithUniqueId:groupId
//                                                                           name:[NSString stringWithUTF8String:group_name]
//                                                                           type:group_type
//                                                                         remark:[NSString stringWithUTF8String:remark]];
            CDevice *device = [[CDevice alloc] initWithUniqueId:devId
                                                           name:[NSString stringWithUTF8String:device_name]
                                                           type:type
                                                             ip:[NSString stringWithUTF8String:ip]
                                                           port:port
                                                       userName:[NSString stringWithUTF8String:user_name]
                                                        userPsw:[NSString stringWithUTF8String:user_psw]
                                                       rtspPort:rtsp_port
                                                     macAddress:[NSString stringWithUTF8String:mac_address]
                                                   serialNumber:[NSString stringWithUTF8String:serial_number]
                                                   decorderType:decoder_type
                                                   channelCount:channel_count
                                                          Group:nil];
            
            [devices addObject:device];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return devices;
}

- (NSArray *)fetchDevicesWithType :(int)type
{
    NSMutableArray  *devices    = [[NSMutableArray alloc] init];
    char *errMsg;
    char sql[1024] = {0};
    sprintf(sql, "select * from t_device where isenable=1 and type='%d'",type);
    //char *sql = "select * from t_device where isenable=1";
    sqlite3_stmt    *statement;
    
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,sql,-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     devId           = sqlite3_column_int(statement, 0);
            char    *ip             = (char *)sqlite3_column_text(statement, 1);
            int     port            = sqlite3_column_int(statement,2);
            char    *user_name      = (char *)sqlite3_column_text(statement, 3);
            char    *user_psw       = (char *)sqlite3_column_text(statement, 4);
            int     type            = sqlite3_column_int(statement, 5);
            int     rtsp_port       = sqlite3_column_int(statement, 7);
            char    *mac_address    = (char *)sqlite3_column_text(statement, 8);
            char    *serial_number  = (char *)sqlite3_column_text(statement, 9);
            int     decoder_type    = sqlite3_column_int(statement, 10);
            int     channel_count   = sqlite3_column_int(statement, 11);
            char    *device_name    = (char *)sqlite3_column_text(statement, 12);
            CDevice *device = [[CDevice alloc] initWithUniqueId:devId
                                                           name:[NSString stringWithUTF8String:device_name]
                                                           type:type
                                                             ip:[NSString stringWithUTF8String:ip]
                                                           port:port
                                                       userName:[NSString stringWithUTF8String:user_name]
                                                        userPsw:[NSString stringWithUTF8String:user_psw]
                                                       rtspPort:rtsp_port
                                                     macAddress:[NSString stringWithUTF8String:mac_address]
                                                   serialNumber:[NSString stringWithUTF8String:serial_number]
                                                   decorderType:decoder_type
                                                   channelCount:channel_count
                                                          Group:nil];
            
            [devices addObject:device];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return devices;
}

//- (NSArray *)fetchDevices
//{
//    NSMutableArray  *devices    = [[NSMutableArray alloc] init];
//    NSString        *field      = @"id,ip,port,user_name,user_psw,type,rtsp_port,\
//    mac_address,serial_number,decoder_type,channel_count,device_name,group_id";
//    NSString        *condition  = [NSString stringWithFormat:@"isenable"];
//    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_device where %@",field,condition];
//    sqlite3_stmt    *statement;
//    char            *errMsg;
//    
//    BOOL success = NO;
//    int groupId = -1;
//    [self.lock lock];
//    if (_database) {
//        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
//        sqlite3_prepare_v2(_database,[query UTF8String],-1,&statement,nil);
//        while (sqlite3_step(statement) == SQLITE_ROW) {
//            int     uniqueId        = sqlite3_column_int(statement, 0);
//            char    *ip             = (char *)sqlite3_column_text(statement, 1);
//            int     port            = sqlite3_column_int(statement,2);
//            char    *user_name      = (char *)sqlite3_column_text(statement, 3);
//            char    *user_psw       = (char *)sqlite3_column_text(statement, 4);
//            int     type            = sqlite3_column_int(statement, 5);
//            int     rtsp_port       = sqlite3_column_int(statement, 6);
//            char    *mac_address    = (char *)sqlite3_column_text(statement, 7);
//            char    *serial_number  = (char *)sqlite3_column_text(statement, 8);
//            int     decoder_type    = sqlite3_column_int(statement, 9);
//            int     channel_count   = sqlite3_column_int(statement, 10);
//            char    *device_name    = (char *)sqlite3_column_text(statement, 11);
//            groupId         = sqlite3_column_int(statement, 12);
//            success         = YES;
//            
//            if (!serial_number) serial_number = "";
//            Group *group = [self fetchGroupWithUniqueId:groupId];
//            CDevice *device = [[CDevice alloc] initWithUniqueId:uniqueId
//                                                           name:[NSString stringWithUTF8String:device_name]
//                                                           type:type
//                                                             ip:[NSString stringWithUTF8String:ip]
//                                                           port:port
//                                                       userName:[NSString stringWithUTF8String:user_name]
//                                                        userPsw:[NSString stringWithUTF8String:user_psw]
//                                                       rtspPort:rtsp_port
//                                                     macAddress:[NSString stringWithUTF8String:mac_address]
//                                                   serialNumber:[NSString stringWithUTF8String:serial_number]
//                                                   decorderType:decoder_type
//                                                   channelCount:channel_count
//                                                          Group:group];
//            
//            [devices addObject:device];
//        }
//        sqlite3_finalize(statement);
//    }
//    [self.lock unlock];
//    
//    return devices;
//}

- (NSArray *)fetchDevicesWithGroup :(Group *)group
{
    NSMutableArray  *devices    = [[NSMutableArray alloc] init];
    NSString        *field      = @"id,ip,port,user_name,user_psw,type,rtsp_port,\
    mac_address,serial_number,decoder_type,channel_count,device_name";
    NSString        *condition  = [NSString stringWithFormat:@"isenable and group_id == '%ld'",group?group.uniqueId : -1];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_device where %@ order by id",field,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     uniqueId        = sqlite3_column_int(statement, 0);
            char    *ip             = (char *)sqlite3_column_text(statement, 1);
            int     port            = sqlite3_column_int(statement,2);
            char    *user_name      = (char *)sqlite3_column_text(statement, 3);
            char    *user_psw       = (char *)sqlite3_column_text(statement, 4);
            int     type            = sqlite3_column_int(statement, 5);
            int     rtsp_port       = sqlite3_column_int(statement, 6);
            char    *mac_address    = (char *)sqlite3_column_text(statement, 7);
            char    *serial_number  = (char *)sqlite3_column_text(statement, 8);
            int     decoder_type    = sqlite3_column_int(statement, 9);
            int     channel_count   = sqlite3_column_int(statement, 10);
            char    *device_name    = (char *)sqlite3_column_text(statement, 11);
            
            if (!serial_number) serial_number = "";
            CDevice *device = [[CDevice alloc] initWithUniqueId:uniqueId
                                                           name:[NSString stringWithUTF8String:device_name]
                                                           type:type
                                                             ip:[NSString stringWithUTF8String:ip]
                                                           port:port
                                                       userName:[NSString stringWithUTF8String:user_name]
                                                        userPsw:[NSString stringWithUTF8String:user_psw]
                                                       rtspPort:rtsp_port
                                                     macAddress:[NSString stringWithUTF8String:mac_address]
                                                   serialNumber:[NSString stringWithUTF8String:serial_number]
                                                   decorderType:decoder_type
                                                   channelCount:channel_count
                                                          Group:group];
            [group addChildren:[NSArray arrayWithObject:device]];
            [devices addObject:device];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return devices;
}


/*- (Channel *)fetchChannelWithUniqueId :(NSInteger)uniqueId
{
    Channel         *channel    = nil;
    char sql[1024] = {0};
    sqlite3_stmt    *statement;
    sprintf(sql, "select a.*,b.* from t_channel a left join t_device b on \
            a.device_id = b.id where a.isenable=1 and a.id == '%ld'",uniqueId);
    
    
    
//    NSString        *field      = @"";
//    
//    field = [field stringByAppendingString:@"logic_id,"];
//    field = [field stringByAppendingString:@"device_id,"];
//    field = [field stringByAppendingString:@"channel_name,"];
//    field = [field stringByAppendingString:@"type,"];
//    field = [field stringByAppendingString:@"group_id,"];
//    field = [field stringByAppendingString:@"unused1,"];
//    field = [field stringByAppendingString:@"unused2,"];
//    field = [field stringByAppendingString:@"map_x,"];
//    field = [field stringByAppendingString:@"map_y"];
//    
//    NSString        *condition  = [NSString stringWithFormat:@"isenable = 1 and id = %ld",uniqueId];
//    NSString        *querey_sql = [NSString stringWithFormat:@"select %@ from t_channel where %@",field,condition];
    
    
    [self.lock lock];
    if (_database) {
        sqlite3_prepare_v2(_database,sql,-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     logic_id        = sqlite3_column_int(statement, 1);
            int     device_id       = sqlite3_column_int(statement, 2);
            char    *channel_name   = (char *)sqlite3_column_text(statement, 3);
            int     type            = sqlite3_column_int(statement, 4);
            int     group_id        = sqlite3_column_int(statement, 5);
            int     unused1         = sqlite3_column_int(statement, 6);
            int     unused2         = sqlite3_column_int(statement, 7);
            char    *map_x          = (char *)sqlite3_column_text(statement, 9);
            char    *map_y          = (char *)sqlite3_column_text(statement, 10);
            char    *ip             = (char *)sqlite3_column_text(statement, 12);
            int     port            = sqlite3_column_int(statement, 13);
            char    *username       = (char *)sqlite3_column_text(statement, 14);
            char    *password       = (char *)sqlite3_column_text(statement, 15);
            CDevice *device = [self fetchDeviceWithUniqueId:device_id];
            channel = [[Channel alloc] initWithUniqueId:uniqueId
                                                   name:[NSString stringWithUTF8String:channel_name]
                                                   type:type
                                                logicId:logic_id
                                                unused1:unused1
                                                unused2:unused2
                                                   mapX:[NSString stringWithUTF8String:map_x]
                                                   mapY:[NSString stringWithUTF8String:map_y]
                                          patrolGroupId:group_id
                                                CDevice:device];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return channel;
}*/

//取回一个设备下的一组通道.
- (NSArray *)fetchChannelsWithDevice :(CDevice *)device
{
    NSMutableArray  *channels   = [[NSMutableArray alloc] init];
    NSString        *field      = @"";
    
    field = [field stringByAppendingString:@"id,"];
    field = [field stringByAppendingString:@"logic_id,"];
    field = [field stringByAppendingString:@"channel_name,"];
    field = [field stringByAppendingString:@"type,"];
    field = [field stringByAppendingString:@"group_id,"];
    field = [field stringByAppendingString:@"unused1,"];
    field = [field stringByAppendingString:@"unused2,"];
    field = [field stringByAppendingString:@"map_x,"];
    field = [field stringByAppendingString:@"map_y"];
    
    NSString        *condition  = [NSString stringWithFormat:@"isenable and device_id == %ld",device.uniqueId];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_channel where %@ order by logic_id",field,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     unique_id       = sqlite3_column_int(statement, 0);
            int     logic_id        = sqlite3_column_int(statement, 1);
            char    *channel_name   = (char *)sqlite3_column_text(statement, 2);
            int     type            = sqlite3_column_int(statement, 3);
            int     group_id        = sqlite3_column_int(statement, 4);
            int     unused1         = sqlite3_column_int(statement, 5);
            int     unused2         = sqlite3_column_int(statement, 6);
            char    *map_x          = (char *)sqlite3_column_text(statement, 7);
            char    *map_y          = (char *)sqlite3_column_text(statement, 8);
            Channel *channel        = [[Channel alloc] initWithUniqueId:unique_id
                                                                   name:[NSString stringWithUTF8String:channel_name]
                                                                   type:type
                                                                logicId:logic_id
                                                                unused1:unused1
                                                                unused2:unused2
                                                                   mapX:[NSString stringWithUTF8String:map_x]
                                                                   mapY:[NSString stringWithUTF8String:map_y]
                                                          patrolGroupId:group_id
                                                                CDevice:device];
            [device addChildren:[NSArray arrayWithObject:channel]];
            [channels addObject:channel];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return channels;
}

/*- (NSArray *)fetchScheduledRecordTasksWithWeekday :(NSInteger)weekday
{
    NSMutableArray  *tasks      = [[NSMutableArray alloc] init];
    NSString        *field      = @"";
    
    field = [field stringByAppendingString:@"id,"];
    field = [field stringByAppendingString:@"channel_id,"];
    field = [field stringByAppendingString:@"start_time,"];
    field = [field stringByAppendingString:@"end_time"];
    
    NSString        *condition  = [NSString stringWithFormat:@"week == '%ld'",weekday];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_rec_plan where %@ order by start_time",field,condition];
    sqlite3_stmt    *statement;
    
    [self.lock lock];
    if (_database) {
        sqlite3_prepare_v2(_database,[query UTF8String],-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     unique_id   = sqlite3_column_int(statement, 0);
            int     channel_id  = sqlite3_column_int(statement, 1);
            char    *start_time = (char *)sqlite3_column_text(statement, 2);
            char    *end_time   = (char *)sqlite3_column_text(statement, 3);
            NSDate  *start      = [[NSDate dateFromString:[NSString stringWithUTF8String:start_time]
                                            withFormatter:TIME_FORMATTER] time];
            NSDate  *end        = [[NSDate dateFromString:[NSString stringWithUTF8String:end_time]
                                            withFormatter:TIME_FORMATTER] time];
            
            [tasks addObject:[[ScheduledRecordTask alloc] initWithUniqueId:unique_id
                                                                     start:start
                                                                       end:end
                                                                   weekday:weekday
                                                                   channel:[self fetchChannelWithUniqueId:channel_id]]];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return tasks;
}*/

- (NSArray *)fetchScheduledRecordTasksWithChannel :(Channel *)channel
{
    NSMutableArray  *tasks      = [[NSMutableArray alloc] init];
    int             channelId   = (int)channel.uniqueId;
    NSString        *field      = @"";
    
    field = [field stringByAppendingString:@"id,"];
    field = [field stringByAppendingString:@"start_time,"];
    field = [field stringByAppendingString:@"end_time,"];
    field = [field stringByAppendingString:@"week"];
    
    NSString        *condition  = [NSString stringWithFormat:@"channel_id = %d",channelId];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_rec_plan where %@",field,condition];
    sqlite3_stmt    *statement;
    
    [self.lock lock];
    if (_database) {
        sqlite3_prepare_v2(_database,[query UTF8String],-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     unique_id   = sqlite3_column_int(statement, 0);
            char    *start_time = (char *)sqlite3_column_text(statement, 1);
            char    *end_time   = (char *)sqlite3_column_text(statement, 2);
            int     weekday     = sqlite3_column_int(statement, 3);
            NSDate  *start      = [[NSDate dateFromString :[NSString stringWithUTF8String:start_time]
                                            withFormatter :TIME_FORMATTER] time];
            NSDate  *end        = [[NSDate dateFromString :[NSString stringWithUTF8String:end_time]
                                            withFormatter :TIME_FORMATTER] time];
            
            [tasks addObject:[[ScheduledRecordTask alloc] initWithUniqueId:unique_id
                                                                     start:start
                                                                       end:end
                                                                   weekday:weekday
                                                                   channel:channel]];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return tasks;
}




- (NSArray *)fetchScheduledTasksWithChannel :(Channel *)channel entity :(NSString *)entity
{
    NSMutableArray  *tasks      = [[NSMutableArray alloc] init];
    int             channelId   = (int)channel.uniqueId;
    NSString        *field      = @"";
    
    field = [field stringByAppendingString:@"id,"];
    field = [field stringByAppendingString:@"data,"];
    field = [field stringByAppendingString:@"week"];
    
    NSString        *condition  = [NSString stringWithFormat:@"channel_id = %d",channelId];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from %@ where %@ order by week",field,entity,condition];
    sqlite3_stmt    *statement;
    
    [self.lock lock];
    if (_database) {
        sqlite3_prepare_v2(_database,[query UTF8String],-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int         unique_id   = sqlite3_column_int(statement, 0);
            long long   data        = sqlite3_column_int64(statement, 1);
            int         weekday     = sqlite3_column_int(statement, 2);
            [tasks addObject:[[ScheduledTask alloc] initWithUniqueId:unique_id
                                                             weekday:weekday
                                                           channelId:channelId
                                                                data:data]];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return tasks;
}


- (NSArray *)fetchScheduledTasksWithWeekday :(NSInteger)weekday entity :(NSString *)entity
{
    NSMutableArray  *tasks      = [[NSMutableArray alloc] init];
    NSString        *field      = @"";
    
    field = [field stringByAppendingString:@"id,"];
    field = [field stringByAppendingString:@"channel_id,"];
    field = [field stringByAppendingString:@"data"];
    
    NSString        *condition  = [NSString stringWithFormat:@"week == '%ld'",weekday];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from %@ where %@",field,entity,condition];
    sqlite3_stmt    *statement;
    
    [self.lock lock];
    if (_database) {
        sqlite3_prepare_v2(_database,[query UTF8String],-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int         unique_id   = sqlite3_column_int(statement, 0);
            int         channel_id  = sqlite3_column_int(statement, 1);
            long long   data        = sqlite3_column_int64(statement, 2);
            
            [tasks addObject:[[ScheduledTask alloc] initWithUniqueId:unique_id
                                                             weekday:weekday
                                                           channelId:channel_id
                                                                data:data]];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return [NSArray arrayWithArray:tasks];
}



- (NSArray *)fetchPollsWithGroup :(Group *)group
{
    NSMutableArray  *polls      = [[NSMutableArray alloc] init];
    NSString        *field      = @"";
    
    field = [field stringByAppendingString:@"id,"];
    field = [field stringByAppendingString:@"channel_id,"];
    field = [field stringByAppendingString:@"wait_sec,"];
    field = [field stringByAppendingString:@"sequence_num"];
    
    NSString        *condition  = [NSString stringWithFormat:@"group_id == %ld",group.uniqueId];
    NSString        *query      = [NSString stringWithFormat:@"select %@ from t_poll where %@ order by sequence_num",field,condition];
    sqlite3_stmt    *statement;
    char *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[query UTF8String],-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int     unique_id       = sqlite3_column_int(statement, 0);
            int     channel_id      = sqlite3_column_int(statement, 1);
            int     wait_sec        = sqlite3_column_int(statement, 2);
            int     sequence_num    = sqlite3_column_int(statement, 3);
            Poll    *poll = [[Poll alloc] initWithUniqueId :unique_id
                                                     group :group
                                                 channelId :channel_id
                                                   waitSec :wait_sec
                                               sequenceNum :sequence_num];
            
            [polls addObject:poll];
        }
        [group addChildren :polls];
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return polls;
}

- (AlarmLink *)fetchAlarmLinkWithChannelId :(NSInteger)channelId
{
    
    AlarmLink       *alarmLink  = nil;
    NSString        *field      = @"";
    
    field = [field stringByAppendingString:@"id,"];
    field = [field stringByAppendingString:@"channel_id,"];
    field = [field stringByAppendingString:@"alarm_type,"];
    field = [field stringByAppendingString:@"is_record,"];
    field = [field stringByAppendingString:@"is_play_sound,"];
    field = [field stringByAppendingString:@"is_snap,"];
    field = [field stringByAppendingString:@"is_show_video"];
    
    NSString        *condition  = [NSString stringWithFormat:@"channel_id = %ld",channelId];
    NSString        *querey_sql = [NSString stringWithFormat:@"select %@ from t_alarm_link where %@",field,condition];
    sqlite3_stmt    *statement;
    
    [self.lock lock];
    if (_database) {
        sqlite3_prepare_v2(_database,[querey_sql UTF8String],-1,&statement,nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int uniqueId        = sqlite3_column_int(statement, 0);
            int channelId       = sqlite3_column_int(statement, 1);
            int alarmType       = sqlite3_column_int(statement, 2);
            int is_reord        = sqlite3_column_int(statement, 3);
            int is_ring         = sqlite3_column_int(statement, 4);
            int is_snap         = sqlite3_column_int(statement, 5);
            //int is_show_video   = sqlite3_column_int(statement, 6);
            
            VMS_ALARM_LINKAGE linkage = 0;
            if (is_reord) linkage = linkage | VMS_ALARM_IS_RECORD;
            if (is_ring) linkage = linkage | VMS_ALARM_IS_RING;
            if (is_snap) linkage = linkage | VMS_ALARM_IS_SNAP;
            
            alarmLink = [[AlarmLink alloc] initWithUniqueId:uniqueId
                                                  alarmType:alarmType
                                                    linkage:linkage
                                                  channelId:channelId];
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    return alarmLink;
}



- (BOOL)updateGroup :(Group *)group
{
    BOOL            success         = NO;
    NSInteger       uniqueId        = group.uniqueId;
    NSString        *field_value    = @"";
    
    field_value = [field_value stringByAppendingFormat:@"group_name = '%@',",group.name];
    field_value = [field_value stringByAppendingFormat:@"type = %ld,",group.type];
    field_value = [field_value stringByAppendingFormat:@"remark = '%@'",group.remark];
    
    NSString        *condition      = [NSString stringWithFormat:@"id = %ld",uniqueId];
    NSString        *update         = [NSString stringWithFormat:@"update t_group set %@ where %@",field_value,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[update UTF8String],-1,&statement,nil);
        if (SQLITE_DONE == sqlite3_step(statement)) {
            success = YES;
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return success;
}

- (BOOL)updateScheduledData :(long long)data
                      chnId :(NSInteger)chnId
                    weekday :(NSInteger)weekday
                 withEntity :(NSString *)entitiy
{
    BOOL            success         = NO;
    NSString        *field_value    = [NSString stringWithFormat:@"data = '%lld'",data];
    NSString        *condition      = [NSString stringWithFormat:@"channel_id = %ld and week = %ld",chnId,weekday];
    NSString        *update         = [NSString stringWithFormat:@"update %@ set %@ where %@",entitiy,field_value,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[update UTF8String],-1,&statement,nil);
        if (SQLITE_DONE == sqlite3_step(statement)) {
            success = YES;
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return success;
}

- (BOOL)updateAlarmLink :(VMS_ALARM_LINKAGE)link
              alarmType :(NSInteger)alarmType
          withChannelId :(NSInteger)chnId;
{
    BOOL            success         = NO;
    NSString        *field_value    = @"";
    
    field_value = [field_value stringByAppendingFormat:@"is_record = %ld,",link & VMS_ALARM_IS_RECORD];
    field_value = [field_value stringByAppendingFormat:@"is_play_sound = %ld,",link & VMS_ALARM_IS_RING];
    field_value = [field_value stringByAppendingFormat:@"is_snap = %ld,",link & VMS_ALARM_IS_SNAP];
    field_value = [field_value stringByAppendingFormat:@"is_show_video = %ld",link & VMS_ALARM_IS_SHOW_VIDIO];
    
    NSString        *condition      = [NSString stringWithFormat:@"channel_id = %ld and alarm_type = %ld",chnId,alarmType];
    NSString        *update         = [NSString stringWithFormat:@"update t_alarm_link set %@ where %@",field_value,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[update UTF8String],-1,&statement,nil);
        if (SQLITE_DONE == sqlite3_step(statement)) {
            success = YES;
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return success;
}

- (int)insertUserGroup :(NSString *)name
                remark :(NSString *)remark
                 right :(NSString *)right
                 level :(NSInteger)level
{
    NSString        *insert     = [NSString stringWithFormat:@"insert into t_user_group(name,remark,[right],level) values('%@','%@','%@',%ld)",name,remark,right,level];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    BOOL success = NO;
    if ([self fetchUserGroupIdWithName:name] < 0) {
        [self.lock lock];
        if (_database) {
            sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
            sqlite3_prepare_v2(_database,[insert UTF8String],-1,&statement,nil);
            success = (SQLITE_DONE == sqlite3_step(statement));
            sqlite3_finalize(statement);
        }
        [self.lock unlock];
    }
    
    return success? [self fetchLatestIdFromTable:@"t_user_group"] : -1;
}

- (NSInteger)insertGroup :(Group *)group
{
    NSInteger       uniqueId = -1;
    NSString        *insert = [NSString stringWithFormat:@"insert into t_group(group_name,type,remark) values('%@',%ld,'%@')",[group name],[group type],[group remark]];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[insert UTF8String],-1,&statement,nil);
        if (SQLITE_DONE == sqlite3_step(statement)) {
            uniqueId = sqlite3_last_insert_rowid(_database);
        }
        sqlite3_finalize(statement);
    }
    [self.lock unlock];
    
    return uniqueId;
}

- (BOOL)deleteUser :(VMSUser *)user
{
    BOOL            success     = NO;
    NSString        *delete_sql = [NSString stringWithFormat:@"delete from t_user where id = %ld",user.uniqueId];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [delete_sql UTF8String], -1, &statement, NULL );
        if ((sqlite3_step(statement) == SQLITE_DONE)) {
            delete_sql = [NSString stringWithFormat:@"delete from t_user where id = %ld",user.uniqueId];
            
            sqlite3_prepare_v2(_database, [delete_sql UTF8String], -1, &statement, NULL);
            success = (SQLITE_DONE == sqlite3_step(statement));
        }
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    
    return success;
}

- (BOOL)deleteGroup :(Group *)group
{
    BOOL        success = NO;
    
    switch (group.type) {
        case NORMAL_GROUP: {
            NSString        *delete_sql = [NSString stringWithFormat:@"delete from t_device where group_id = %ld",group.uniqueId];
            sqlite3_stmt    *statement;
            char            *errMsg;
            
            [self.lock lock];
            if (_database) {
                sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
                sqlite3_prepare_v2(_database, [delete_sql UTF8String], -1, &statement, NULL );
                if ((sqlite3_step(statement) == SQLITE_DONE)) {
                    delete_sql = [NSString stringWithFormat:@"delete from t_group where id = %ld",group.uniqueId];
                    sqlite3_prepare_v2(_database, [delete_sql UTF8String], -1, &statement, NULL);
                    success = (SQLITE_DONE == sqlite3_step(statement));
                }
                sqlite3_finalize(statement);//release statement
            }
            [self.lock unlock];
        }
            break;
        case PATROL_GROUP:
            [self cancelGroup:group];
            break;
        default:
            break;
    }
   
    return success;
}

- (BOOL)cancelGroup :(Group *)group
{
    BOOL            success = NO;
    sqlite3_stmt    *statement;
    NSString        *table = (NORMAL_GROUP == group.type)? @"t_device" : @"t_channel";
    NSString        *update = [NSString stringWithFormat:@"update %@ set group_id = -1 where group_id = %ld",table,group.uniqueId];
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database,[update UTF8String],-1,&statement,nil);
        if(SQLITE_DONE == sqlite3_step(statement)) {
            //Delete the logical grouping
            NSString *delete = [NSString stringWithFormat:@"delete from t_group where id = %ld",group.uniqueId];
            sqlite3_prepare_v2(_database,[delete UTF8String],-1,&statement,nil);
            success = (SQLITE_DONE == sqlite3_step(statement));
        }
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    
    return success;
}

- (BOOL)deleteAllFromEntity :(NSString *)entity
{
    BOOL            success = NO;
    NSString        *delete_sql = [NSString stringWithFormat:@"delete from %@",entity];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [delete_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    
    return success;
}


- (BOOL)deleteDevice :(CDevice *)device
{
    BOOL            success = NO;
    NSString        *delete_sql = [NSString stringWithFormat:@"delete from t_device where id = %ld",device.uniqueId];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [delete_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    

    return success;
}

- (BOOL)deleteAllRecordTasks
{
    BOOL            success = NO;
    NSString        *delete_sql = [NSString stringWithFormat:@"delete from t_rec_plan"];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [delete_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    
    return success;
}

#pragma mark - Insert
- (int)insertLog :(NSString *)opt
            type :(NSString *)type
           event :(NSString *)event
{
    //获取当前时间
    NSString        *now        = [[NSDate date] stringWithFormatter:@"yyyy-MM-dd HH:mm:ss"];
    int             unique_id   = -1;
    NSString        *fields     = @"";
    NSString        *values     = @"";
    
   
    fields = [fields stringByAppendingString:@"operator,"];
    values = [values stringByAppendingFormat:@"'%@',",opt];
    fields = [fields stringByAppendingString:@"date_time,"];
    values = [values stringByAppendingFormat:@"'%@',",now];
    fields = [fields stringByAppendingString:@"type,"];
    values = [values stringByAppendingFormat:@"'%@',",type];
    fields = [fields stringByAppendingString:@"event"];
    values = [values stringByAppendingFormat:@"'%@'",event];
    
    NSString        *insert_sql = [NSString stringWithFormat:@"insert into t_log(%@) values(%@)",fields,values];
    sqlite3_stmt    *statement;
    char            *errMsg;
    BOOL            success = NO;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [insert_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    
    
    return success? [self fetchLatestIdFromTable:@"t_log"] : -1;
}

//插入设备(遇见相同mac 地址的设备，插入失败)

- (int)insertDevice :(CDevice *)device
{
    NSString        *fields = @"";
    NSString        *values = @"";
   
    fields = [fields stringByAppendingString:@"ip,"];
    values = [values stringByAppendingFormat:@"'%@',",device.ip];
    fields = [fields stringByAppendingString:@"port,"];
    values = [values stringByAppendingFormat:@"%ld,",device.port];
    fields = [fields stringByAppendingString:@"user_name,"];
    values = [values stringByAppendingFormat:@"'%@',",device.userName];
    fields = [fields stringByAppendingString:@"user_psw,"];
    values = [values stringByAppendingFormat:@"'%@',",device.userPsw];
    fields = [fields stringByAppendingString:@"type,"];
    values = [values stringByAppendingFormat:@"%ld,",device.type];
    fields = [fields stringByAppendingString:@"rtsp_port,"];
    values = [values stringByAppendingFormat:@"%ld,",device.rtspPort];
    fields = [fields stringByAppendingString:@"mac_address,"];
    values = [values stringByAppendingFormat:@"'%@',",device.macAddress];
    fields = [fields stringByAppendingString:@"serial_number,"];
    values = [values stringByAppendingFormat:@"'%@',",device.serialNumber];
    fields = [fields stringByAppendingString:@"decoder_type,"];
    values = [values stringByAppendingFormat:@"%ld,",device.decoderType];
    fields = [fields stringByAppendingString:@"channel_count,"];
    values = [values stringByAppendingFormat:@"%ld,",device.channelCount];
    fields = [fields stringByAppendingString:@"device_name"];
    values = [values stringByAppendingFormat:@"'%@'",device.name];
    
    NSString        *insert_sql = [NSString stringWithFormat:@"insert into t_device(%@) values(%@)",fields,values];
    sqlite3_stmt    *statement;
    char            *errMsg;
    BOOL            success = NO;
    
    [self.lock lock];
    if (_database) {
        
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [insert_sql UTF8String], -1, &statement, nil);
        
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
        if (errMsg) {
            NSLog(@"Exception raised in insertDevice:%@",[NSString stringWithUTF8String:errMsg]);
            exit(0);
        }
    }
    [self.lock unlock];
  
    return success? [self fetchLatestIdFromTable:@"t_device"] : -1;
}


- (int)insertUser :(VMSUser *)user
{
    NSString        *fields = @"";
    NSString        *values = @"";
    
    fields = [fields stringByAppendingString:@"user_name,"];
    values = [values stringByAppendingFormat:@"'%@',",user.userName];
    fields = [fields stringByAppendingString:@"psw,"];
    values = [values stringByAppendingFormat:@"'%@',",user.password];
    fields = [fields stringByAppendingString:@"remark,"];
    values = [values stringByAppendingFormat:@"'%@',",user.remark];
    fields = [fields stringByAppendingString:@"group_id"];
    values = [values stringByAppendingFormat:@"%ld",user.groupId];
    
    NSString        *insert_sql = [NSString stringWithFormat:@"insert into t_user(%@) values(%@)",fields,values];
    sqlite3_stmt    *statement;
    char            *errMsg;
    BOOL            success = NO;
    
    //考虑重复插入根用户情况
    if ([user.userName isEqualToString:ROOT] && ([self fetchRootId] > 0)) {
        return -1;
    }
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [insert_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    
    return success? [self fetchLatestIdFromTable:@"t_user"] : -1;
}

- (int)insertChannel :(Channel *)channel
{
    CDevice         *device     = channel.device;
    NSString        *fields = @"";
    NSString        *values = @"";
    
    assert(device);
    
    fields = [fields stringByAppendingString:@"logic_id,"];
    values = [values stringByAppendingFormat:@"%ld,",channel.logicId];
    fields = [fields stringByAppendingString:@"device_id,"];
    values = [values stringByAppendingFormat:@"%ld,",device.uniqueId];
    fields = [fields stringByAppendingString:@"channel_name,"];
    values = [values stringByAppendingFormat:@"'%@',",channel.name];
    fields = [fields stringByAppendingString:@"type,"];
    values = [values stringByAppendingFormat:@"%ld,",channel.type];
    fields = [fields stringByAppendingString:@"group_id,"];
    values = [values stringByAppendingFormat:@"%ld,",channel.patrolGroupId];
    fields = [fields stringByAppendingString:@"unused1,"];
    values = [values stringByAppendingFormat:@"%ld,",channel.unused1];
    fields = [fields stringByAppendingString:@"unused2,"];
    values = [values stringByAppendingFormat:@"%ld,",channel.unused2];
    fields = [fields stringByAppendingString:@"map_x,"];
    values = [values stringByAppendingFormat:@"'%@',",channel.mapX];
    fields = [fields stringByAppendingString:@"map_y"];
    values = [values stringByAppendingFormat:@"'%@'",channel.mapY];
    
    NSString        *insert_sql = [NSString stringWithFormat:@"insert into t_channel(%@) values(%@)",fields,values];
    sqlite3_stmt    *statement;
    char            *errMsg;
    BOOL            success = NO;
    
    [self.lock lock];
    if (_database) {
        
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [insert_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
        
        if (errMsg) {
            NSLog(@"Exception raised in insertChannel:%@",[NSString stringWithUTF8String:errMsg]);
            exit(0);
        }
    }
    [self.lock unlock];
    
    return success? [self fetchLatestIdFromTable:@"t_channel"] : -1;
}


- (int)insertScheduledTaskWithChannelId :(NSInteger)channelId
                                   data :(long long)data
                                weekday :(NSInteger)weekday
                              withEntity:(NSString *)entity
{
    NSString        *fields = @"";
    NSString        *values = @"";
    
    fields = [fields stringByAppendingString:@"channel_id,"];
    values = [values stringByAppendingFormat:@"'%ld',",channelId];
    fields = [fields stringByAppendingString:@"data,"];
    values = [values stringByAppendingFormat:@"%lld,",data];
    fields = [fields stringByAppendingString:@"week"];
    values = [values stringByAppendingFormat:@"%ld",weekday];
    
    NSString        *insert_sql = [NSString stringWithFormat:@"insert into %@(%@) values(%@)",entity,fields,values];
    sqlite3_stmt    *statement;
    char            *errMsg;
    BOOL insert_success = NO;
    
    [self.lock lock];
    if (_database) {
        
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [insert_sql UTF8String], -1, &statement, nil);
        insert_success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement

        if (errMsg) {
            NSLog(@"Exception raised in insertScheduledTaskWithChannelId:%@",[NSString stringWithUTF8String:errMsg]);
            exit(0);
        }
    }
    [self.lock unlock];
    
    return insert_success? [self fetchLatestIdFromTable:entity] : -1;
}

- (int)insertAlarmLinkage :(AlarmLink *)alarmLink
{
    int             unique_id   = -1;
    NSString        *fields     = @"";
    NSString        *values     = @"";
   
    fields = [fields stringByAppendingString:@"channel_id,"];
    values = [values stringByAppendingFormat:@"'%ld',",alarmLink.channelId];
    fields = [fields stringByAppendingString:@"alarm_type,"];
    values = [values stringByAppendingFormat:@"%ld,",alarmLink.alarmType];
    fields = [fields stringByAppendingString:@"is_record,"];
    values = [values stringByAppendingFormat:@"%ld,",alarmLink.linkage & VMS_ALARM_IS_RECORD];
    fields = [fields stringByAppendingString:@"is_play_sound,"];
    values = [values stringByAppendingFormat:@"%ld,",alarmLink.linkage & VMS_ALARM_IS_RING];
    fields = [fields stringByAppendingString:@"is_snap,"];
    values = [values stringByAppendingFormat:@"%ld,",alarmLink.linkage & VMS_ALARM_IS_SNAP];
    fields = [fields stringByAppendingString:@"is_show_video"];
    values = [values stringByAppendingFormat:@"%ld",alarmLink.linkage & VMS_ALARM_IS_SHOW_VIDIO];
    
    NSString        *insert_sql = [NSString stringWithFormat:@"insert into t_alarm_link(%@) values(%@)",fields,values];
    sqlite3_stmt    *statement;
    char            *errMsg;
    BOOL            success = NO;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [insert_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    
    return success? [self fetchLatestIdFromTable:@"t_alarm_link"] : -1;
}

- (int)insertScheduledRecordTaskWithChannelId :(NSInteger)channelId
                                    startTime :(NSString *)startTime
                                      endTime :(NSString *)endTime
                                      weekday :(NSInteger)weekday
{
    int             unique_id = -1;
    NSString        *fields = @"";
    NSString        *values = @"";
    
    fields = [fields stringByAppendingString:@"channel_id,"];
    values = [values stringByAppendingFormat:@"'%ld',",channelId];
    fields = [fields stringByAppendingString:@"start_time,"];
    values = [values stringByAppendingFormat:@"'%@',",startTime];
    fields = [fields stringByAppendingString:@"end_time,"];
    values = [values stringByAppendingFormat:@"'%@',",endTime];
    fields = [fields stringByAppendingString:@"week"];
    values = [values stringByAppendingFormat:@"%ld",weekday];
    
    NSString        *insert_sql = [NSString stringWithFormat:@"insert into t_rec_plan(%@) values(%@)",fields,values];
    sqlite3_stmt    *statement;
    char            *errMsg;
    BOOL            success = NO;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [insert_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    
    return success? [self fetchLatestIdFromTable:@"t_rec_plan"] : -1;
}

- (int)insertPoll :(Poll *)poll
{
    Group       *group = poll.group;
    BOOL            success = NO;
    
    if (group.uniqueId >= 0) {
        NSString    *fields = @"";
        NSString    *values = @"";
        
        fields = [fields stringByAppendingString:@"group_id,"];
        values = [values stringByAppendingFormat:@"%ld,",poll.group.uniqueId];
        fields = [fields stringByAppendingString:@"channel_id,"];
        values = [values stringByAppendingFormat:@"%d,",poll.channelId];
        fields = [fields stringByAppendingString:@"wait_sec,"];
        values = [values stringByAppendingFormat:@"%d,",poll.waitSec];
        fields = [fields stringByAppendingString:@"sequence_num"];
        values = [values stringByAppendingFormat:@"%d",poll.sequenceNum];
        
        
        NSString        *insert_sql = [NSString stringWithFormat:@"insert into t_poll(%@) values(%@)",fields,values];
        sqlite3_stmt    *statement;
        char            *errMsg;
        
        
        [self.lock lock];
        if (_database) {
            sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
            sqlite3_prepare_v2(_database, [insert_sql UTF8String], -1, &statement, nil);
            success = (SQLITE_DONE == sqlite3_step(statement));
            
            sqlite3_finalize(statement);//release statement
        }
        [self.lock unlock];
    }
    
    return success? [self fetchLatestIdFromTable:@"t_poll"] : -1;
}

- (BOOL)updateUser :(VMSUser *)user
{
    BOOL            success = NO;
    NSInteger       uniqueId = user.uniqueId;
    NSString        *field_value = @"";
    
    field_value = [field_value stringByAppendingFormat:@"user_name = '%@',",user.userName];
    field_value = [field_value stringByAppendingFormat:@"psw = '%@',",user.password];
    field_value = [field_value stringByAppendingFormat:@"remark = '%@',",user.remark];
    field_value = [field_value stringByAppendingFormat:@"group_id = %ld",user.groupId];
    
    NSString        *condition = [NSString stringWithFormat:@"id == %ld",uniqueId];
    NSString        *update_sql = [NSString stringWithFormat:@"update t_user set %@ where %@",field_value,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [update_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_ROW == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statemen
    }
    [self.lock unlock];
    
    return success;
}

- (BOOL)updateChannelName :(NSString *)newName uniquelId :(NSInteger)uniqueID
{
    BOOL            success = NO;
    NSString        *field_value = [NSString stringWithFormat:@"channel_name = '%@'",newName];
    NSString        *condition = [NSString stringWithFormat:@"id = %ld",uniqueID];
    NSString        *update_sql = [NSString stringWithFormat:@"update t_channel set %@ where %@",field_value,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [update_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    
    return success;
}

- (BOOL)updateDevice :(CDevice *)device
{
    BOOL            success         = NO;
    NSInteger       uniqueId        = device.uniqueId;
    NSString        *field_value    = @"";
    NSInteger       groupId         = device.group? device.group.uniqueId : -1;
    
    field_value = [field_value stringByAppendingFormat:@"ip = '%@',",device.ip];
    field_value = [field_value stringByAppendingFormat:@"port = %ld,",device.port];
    field_value = [field_value stringByAppendingFormat:@"user_name = '%@',",device.userName];
    field_value = [field_value stringByAppendingFormat:@"user_psw = '%@',",device.userPsw];
    field_value = [field_value stringByAppendingFormat:@"type = %ld,",device.type];
    field_value = [field_value stringByAppendingFormat:@"rtsp_port = %ld,",device.rtspPort];
    field_value = [field_value stringByAppendingFormat:@"mac_address = '%@',",device.macAddress];
    field_value = [field_value stringByAppendingFormat:@"serial_number = '%@',",device.serialNumber];
    field_value = [field_value stringByAppendingFormat:@"decoder_type = %ld,",device.decoderType];
    field_value = [field_value stringByAppendingFormat:@"channel_count = %ld,",device.channelCount];
    field_value = [field_value stringByAppendingFormat:@"device_name = '%@',",device.name];
    field_value = [field_value stringByAppendingFormat:@"group_id = '%ld'",groupId];
    
    NSString        *condition      = [NSString stringWithFormat:@"id = %ld",uniqueId];
    NSString        *update_sql     = [NSString stringWithFormat:@"update t_device set %@ where %@",field_value,condition];
    sqlite3_stmt    *statement;
    char            *errMsg;
    
    [self.lock lock];
    if (_database) {
        sqlite3_exec(_database, PRAGMA_FOREIGN_KEYS_ON, NULL, NULL, &errMsg);
        sqlite3_prepare_v2(_database, [update_sql UTF8String], -1, &statement, nil);
        success = (SQLITE_DONE == sqlite3_step(statement));
        sqlite3_finalize(statement);//release statement
    }
    [self.lock unlock];
    
    return success;
}

#pragma mark - setter and getter
- (NSString *)path
{
    if (!_path) {
        _path = [VMSPathManager vmsDatabasePath:YES];
    }
    
    return _path;
}

- (NSLock *)lock
{
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    
    return _lock;
}
@end

