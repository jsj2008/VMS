//
//  PTZCruiseViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

typedef void (^Fetch_PresetPts_CompleteHandle)(BOOL,const FOS_RESETPOINTLIST,const FOS_CRUISEMAPLIST,id owner);


@interface PTZCruiseViewController : SettingViewController<NSTableViewDataSource,NSTableViewDelegate>

@property(nonatomic,assign) FOS_CRUISECTRLMODE cruiseCtrlMode;
@property(nonatomic,assign) unsigned int cruiseTime;
@property(nonatomic,assign) FOS_CRUISETIMECUSTOMED cruiseTimeCustomed;
@property(nonatomic,assign) int cruiseLoopCnt;

@property(nonatomic,assign) FOS_RESETPOINTLIST presetPointList;
@property(nonatomic,assign) FOS_CRUISEMAPPREPOINTLINGERTIME cruiseMapPrepointLingerTime;
@property(nonatomic,assign) FOS_CRUISEMAPLIST cruiseMapList;

@property(nonatomic,assign) FOS_CRUISEMAPINFO cruiseMapInfo;

@property(nonatomic,copy) Fetch_PresetPts_CompleteHandle fetchPresetPtsCompleteHandle;


- (void)fetch;
- (void)fetchCruiseMode;
- (void)fetchPresetPointAndCruiseMapList;
- (void)fetchCruiseInfo :(NSString *)name;
- (void)performSaveCruiseMap :(NSString *)name;
- (void)performRemoveCruiseMap :(NSString *)mapName;
- (void)push;

- (NSString *)description;
- (BOOL)enableCruiseModeOption;
- (BOOL)enableCruiseMapPrepointLingerTime;
@end
