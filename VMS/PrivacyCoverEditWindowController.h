//
//  PrivacyCoverEditWindowController.h
//  
//
//  Created by mac_dev on 16/3/30.
//
//

#import <Cocoa/Cocoa.h>
#import "VideoViewProtocol.h"
#import "AVPLAYLayer.h"
#import "PrivacyCoverEditView.h"
#import "Channel.h"

@interface PrivacyCoverEditWindowController : NSWindowController<VideoViewProtocol>

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
                            channelId:(int)chnId
                                areas:(FOS_OSDMASKAREA)areas;

@property(nonatomic,assign) int chnId;
@property(nonatomic,assign) FOSSTREAM_TYPE streamType;
@property(nonatomic,assign) FOS_OSDMASKAREA areas;
@property(nonatomic,assign) int port;
@end
