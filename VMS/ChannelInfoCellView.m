//
//  ChannelInfoCellView.m
//  
//
//  Created by mac_dev on 16/6/3.
//
//

#import "ChannelInfoCellView.h"

@interface ChannelInfoCellView()
@property(nonatomic,weak) IBOutlet NSPopUpButton *protocolBtn;
@property(nonatomic,weak) IBOutlet NSTextField *devNameTF;
@property(nonatomic,weak) IBOutlet NSTextField *urlTF;
@property(nonatomic,weak) IBOutlet NSTextField *webPortTF;
@property(nonatomic,weak) IBOutlet NSTextField *usernameTF;
@property(nonatomic,weak) IBOutlet NSTextField *passwordTF;
@property(nonatomic,strong) NSArray *protocols;
@end

@implementation ChannelInfoCellView
@synthesize chnInfo = _chnInfo;

#pragma mark - private api
- (void)updateChannelInfoUI
{
    //-channel name
    if (strcmp(self.chnInfo.chnName, "") == 0)
        [self.textField setStringValue:NSLocalizedString(@"None", nil)];
    else
        [self.textField setStringValue:[NSString stringWithCString:self.chnInfo.chnName encoding:NSASCIIStringEncoding]];
    

    //-protocols
    unsigned char v_1 = self.chnInfo.protocol & (0x01 << 0);
    unsigned char v_2 = self.chnInfo.protocol & (0x01 << 1);
    unsigned char v_3 = self.chnInfo.protocol & (0x01 << 2);
    unsigned char v_4 = self.chnInfo.protocol & (0x01 << 3);
    
    
    [self.protocolBtn removeAllItems];
    if (v_1 != 0) {
        [self.protocolBtn addItemWithTitle:self.protocols[0]];
    }
    
    if (v_2 != 0) {
        [self.protocolBtn addItemWithTitle:self.protocols[1]];
    }
    
    if (v_4 != 0 && v_1 != 1 && v_2 != 1){
        [self.protocolBtn addItemWithTitle:self.protocols[3]];
    }
    
    //-device name
    [self.devNameTF setStringValue:[NSString stringWithCString:self.chnInfo.devName encoding:NSASCIIStringEncoding]];
    
    //-url
    [self.urlTF setStringValue:[NSString stringWithCString:self.chnInfo.url encoding:NSASCIIStringEncoding]];
    
    //-web port
    [self.webPortTF setStringValue:[NSString stringWithFormat:@"%d",self.chnInfo.webPort]];
    
    //-username
    [self.usernameTF setStringValue:[NSString stringWithCString:self.chnInfo.username encoding:NSASCIIStringEncoding]];
}

- (FOS_CHANNEL_INFO)chnInfoFromUI
{
    FOS_CHANNEL_INFO chnInfo = self.chnInfo;
    
    //设置设备类型，即选中的协议类型
    NSString *protocol = self.protocolBtn.selectedItem.title;
    NSInteger index = [self.protocols indexOfObject:protocol];
    
    if (index != NSNotFound) {
        chnInfo.productType = (0x01) << index;
    }
    
    [self.usernameTF.stringValue getCString:chnInfo.username maxLength:128 encoding:NSASCIIStringEncoding];
    [self.passwordTF.stringValue getCString:chnInfo.password maxLength:128 encoding:NSASCIIStringEncoding];
    
    return chnInfo;
}
#pragma mark - setter & getter
- (void)setChnInfo:(FOS_CHANNEL_INFO)chnInfo
{
    _chnInfo = chnInfo;
    [self updateChannelInfoUI];
}

- (void)setDevNameTF:(NSTextField *)devNameTF
{
    _devNameTF = devNameTF;
    _devNameTF.enabled = NO;
}

- (void)setUrlTF:(NSTextField *)urlTF
{
    _urlTF = urlTF;
    _urlTF.enabled = NO;
}

- (void)setWebPortTF:(NSTextField *)webPortTF
{
    _webPortTF = webPortTF;
    _webPortTF.enabled = NO;
}

- (NSArray *)protocols
{
    if (!_protocols) {
        NSURL   *url = [[NSBundle mainBundle] URLForResource:@"Protocols" withExtension:@"plist"];
        _protocols = [NSArray arrayWithContentsOfURL:url];
    }
    
    return _protocols;
}

@end
