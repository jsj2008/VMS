//
//  NVRDeviceInfoViewController.m
//  
//
//  Created by mac_dev on 16/5/25.
//
//

#import "NVRDeviceInfoViewController.h"
#import "../TBXML/TBXML-Headers/TBXML.h"

@interface NVRDeviceInfoViewController ()

@end

@implementation NVRDeviceInfoViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NVR_CONFIG config;
        char result[OUT_BUFFER_LENGTH] = {0};
        config.output = result;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        FOS_DEVINFO devInfo;
        FOS_NVR_P2PINFO p2pInfo;
        FOSCAM_NVR_CONFIG_TYPE cfgTypes[2] = {FOSCAM_NVR_CONFIG_DEVICE_INFO,FOSCAM_NVR_CONFIG_USER_P2P_INFO};
        void *configs[] = {&devInfo,&p2pInfo};
        
        BOOL success[2] = {NO,NO};
        for (int i = 0; i < 2; i++) {
            memset(result, 0, OUT_BUFFER_LENGTH);
            if ([[DispatchCenter sharedDispatchCenter] getConfig:&config forType:cfgTypes[i] fromDevice:self.device]) {
                NSError *err = nil;
                NSString *rawString = [NSString stringWithCString:result encoding:NSASCIIStringEncoding];
                NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
                
                if (DEBUG_CGI) {
                    NSLog(@"%@",rawString);
                }
                
                success[i] = [self getConfig:configs[i] type:cfgTypes[i] fromDict:dict];
            }
        }
        
        BOOL isDevInfo = success[0];
        BOOL isP2PInfo = success[1];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (isDevInfo) {
                [self setDeviceInfo :devInfo];
                
                if (isP2PInfo) {
                    [self setP2pInfo:p2pInfo];
                }
            }
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out",nil)];
            
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    [self.view.window endEditingFor:nil];
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        char devName[COMMSIZE] = {0};
        char xml[OUT_BUFFER_LENGTH] = {0};
        [self.devName.stringValue getCString:devName maxLength:COMMSIZE encoding:NSASCIIStringEncoding];
        
        FOSCAM_NVR_CONFIG config;
        config.input = devName;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_DEVICE_INFO
                                                    toDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err) {
                NSNumber *result = [values valueForKey:KEY_XML_RESULT];
                success = result && (result.intValue == 0);
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success)
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out",nil)];
            
            [self setActivity:NO];
        });
    });
}

- (SVC_OPTION)option
{
    return SVC_SAVE | SVC_REFRESH;
}

- (NSString *)description
{
    return NSLocalizedString(@"Device Information",nil);
}


#pragma mark - private 
- (BOOL)getConfig :(void *)cfg
             type :(int)type
         fromDict :(NSDictionary *)dict
{
    if ([[dict valueForKey:@"result"] intValue] == 0) {
        switch (type) {
            case FOSCAM_NVR_CONFIG_DEVICE_INFO: {
                FOS_DEVINFO *devInfo = (FOS_DEVINFO *)cfg;
                
                [[dict valueForKey:@"productType"] getCString:devInfo->productName maxLength:NAMESIZE encoding:NSASCIIStringEncoding];
                [[dict valueForKey:@"devName"] getCString:devInfo->devName maxLength:COMMSIZE encoding:NSASCIIStringEncoding];
                [[dict valueForKey:@"firmwareVersion"] getCString:devInfo->firmwareVer maxLength:COMMSIZE encoding:NSASCIIStringEncoding];
                [[dict valueForKey:@"hardwareVersion"] getCString:devInfo->hardwareVer maxLength:COMMSIZE encoding:NSASCIIStringEncoding];
            }
                break;
                
            case FOSCAM_NVR_CONFIG_USER_P2P_INFO:{
                FOS_NVR_P2PINFO *p2pInfo = (FOS_NVR_P2PINFO *)cfg;
                
                [[dict valueForKey:@"uid"] getCString:p2pInfo->uid maxLength:UID_LEN encoding:NSASCIIStringEncoding];
                p2pInfo->type = [[dict valueForKey:@"type"] intValue];
                p2pInfo->enable = [[dict valueForKey:@"isEnable"] intValue];
                p2pInfo->port = [[dict valueForKey:@"Port"] intValue];
            }
                break;
            default:
                break;
        }
        
        return YES;
    }
    
    return NO;
}

- (NSImage *)genQRCodeWithMessage :(NSString *)msg size:(CGSize)size
{
    if (msg) {
        
        NSImage *img = nil;
        @try {
            CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
            
            [filter setDefaults];
            
            NSData *data = [msg dataUsingEncoding:NSASCIIStringEncoding];
            [filter setValue:data forKey:@"inputMessage"];
            
            CIImage *outputImage = [filter outputImage];
            
            img = [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:size];
        } @catch (NSException *exception) {
            img = nil;
            NSLog(@"生成二维码失败! :%@",exception);
        }
        
        return img;
    }
    
    return  nil;
}

- (NSImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGSize)size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size.width/CGRectGetWidth(extent), size.height/CGRectGetHeight(extent));
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    return [[NSImage alloc] initWithCGImage:scaledImage size:size];
}
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.mac setHidden:YES];
    [self.deviceTime setHidden:YES];
    [self.macL setHidden:YES];
    [self.deviceTimeL setHidden:YES];
    [self.devName setEditable:YES];
    [self.p2pZone setHidden:YES];
}

#pragma mark - update ui
- (void)updateP2pInfoUI
{
    self.p2pZone.hidden = NO;
    
    if (self.p2pInfo.enable > 0) {
        [self.p2pZone setHidden:NO];
        
        NSString *uid = [NSString stringWithCString:self.p2pInfo.uid encoding:NSASCIIStringEncoding];
        [self.uidTF setStringValue:uid];
        
        if (![uid isEqualToString:@""]) {
            NSImage *img = [self genQRCodeWithMessage:uid size:self.codeImgView.frame.size];
            
            [self.codeImgView setImage:img];
        }
    }
}

#pragma mark - setter & getter
- (void)setP2pInfo:(FOS_NVR_P2PINFO)p2pInfo
{
    _p2pInfo = p2pInfo;
    [self updateP2pInfoUI];
}

@end
