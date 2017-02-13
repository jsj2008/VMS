//
//  NVRPTZCruiseViewController.h
//  
//
//  Created by mac_dev on 16/5/30.
//
//

#import "PTZCruiseViewController.h"

@interface NVRPTZCruiseViewController : PTZCruiseViewController


- (void)fetchCruiseMode;
- (void)fetchPresetPointAndCruiseMapList;
- (void)fetchCruiseInfo :(NSString *)name;
- (void)performSaveCruiseMap:(NSString *)name;
- (void)performRemoveCruiseMap :(NSString *)mapName;
- (void)push;

- (NSString *)description;
- (BOOL)enableCruiseModeOption;
- (BOOL)enableCruiseMapPrepointLingerTime;

@end
