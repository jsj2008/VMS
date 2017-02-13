//
//  ModifyLoginInfoSheetController.m
//  VMS
//
//  Created by mac_dev on 2016/10/13.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "ModifyLoginInfoSheetController.h"

#define ID_PWD_TF       @"password textfield"
#define USER_MIN_LENTH  0
#define USER_MAX_LENTH  20
#define USER_SYMBOLS    @"_-@$*"
#define PWD_MIN_LENTH   6
#define PWD_MAX_LENTH   12
#define PWD_SYMBOLS     @"~!@#%^*()_+{}:\"|<>?`-;'\\,./"


@implementation ModifyLoginInfo
@end


@interface ModifyLoginInfoSheetController ()

@property(nonatomic,weak) IBOutlet NSTextField *userTF;
@property(nonatomic,weak) IBOutlet NSTextField *pwdTF;
@property(nonatomic,weak) IBOutlet NSTextField *pwdConfirmTF;
@property(nonatomic,weak) IBOutlet NSLevelIndicator *pwdLevelInd;

@end

@implementation ModifyLoginInfoSheetController

#pragma mark - init
- (instancetype)initWithWindowNibName:(NSString *)windowNibName useDefaultUser :(BOOL)useDefaultUser
{
    if (self = [super initWithWindowNibName:windowNibName]) {
        self.useDefaultUser = useDefaultUser;
    }
    
    return self;
}

#pragma mark - action
- (IBAction)done:(id)sender
{
    int check = [self parserUI];
    
    if (0 == check) {
        self.info = [self modifyLoginInfoFromUI];
        //关闭窗口并返回
        [NSApp stopModalWithCode:NSModalResponseOK];
    }
    else {
        NSAlert *alert = [[NSAlert alloc] init];
        
        alert.messageText = NSLocalizedString(@"failed to modify login password", nil);
        alert.informativeText = [self errMsg :check];
        
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert runModal];
    }
}

- (IBAction)cancel:(id)sender
{
    [NSApp stopModalWithCode:NSModalResponseCancel];
}

#pragma mark - parser
typedef NS_ENUM(unsigned char, PWD_LEVEL) {
    PWD_NONE = 0,
    PWD_WEEK,
    PWD_MID,
    PWD_STRONG,
};

typedef NS_OPTIONS(unsigned char, CHAR_TYPE) {
    CHAR_NONE = 0,
    CHAR_NUMBER = 1 << 0,
    CHAR_LETTER = 1 << 1,
    CHAR_SPECIFIC_SYMBOL = 1 << 2,
    CHAR_OTHER_SYMBOL = 1 << 3,
};

- (int)parserUI
{
    NSString *user      = self.userTF.stringValue;
    NSString *pwd       = self.pwdTF.stringValue;
    NSString *confirm   = self.pwdConfirmTF.stringValue;
    
    if (![self parserUser:user])
        return 1;
    
    if (![confirm isEqualToString:pwd])
        return 2;
    
    if (![self parserPwd:confirm level:NULL])
        return 3;
    
    return 0;
}

- (BOOL)parserUser :(NSString *)user
{
    if (user.length > USER_MIN_LENTH && user.length <= USER_MAX_LENTH) {
        NSScanner       *scanner = [NSScanner scannerWithString :user];
        NSCharacterSet  *numbersSet = [NSCharacterSet decimalDigitCharacterSet];
        NSCharacterSet  *lettersSet = [NSCharacterSet letterCharacterSet];
        NSCharacterSet  *symbolsSet = [NSCharacterSet characterSetWithCharactersInString:USER_SYMBOLS];
        
        CHAR_TYPE charType = CHAR_NONE;
        
        while (![scanner isAtEnd]) {
            //分别测试是否包含数字、字母、指定符号、其它符号
            if ([scanner scanCharactersFromSet:numbersSet intoString:nil])
                charType |= CHAR_NUMBER;
            else if ([scanner scanCharactersFromSet:lettersSet intoString:nil])
                charType |= CHAR_LETTER;
            else if ([scanner scanCharactersFromSet:symbolsSet intoString:nil])
                charType |= CHAR_SPECIFIC_SYMBOL;
            else {
                charType |= CHAR_OTHER_SYMBOL;
                break;
            }
        }
        
        if (charType & CHAR_OTHER_SYMBOL) {
            return NO;
        }
        
        return YES;
    }
    
    return NO;
}


- (BOOL)parserPwd :(NSString *)pwd level :(PWD_LEVEL *)level
{
    
    if (pwd.length < PWD_MIN_LENTH) {
        if (level)
            *level = PWD_WEEK;
        
        return NO;
    }
    else {
        NSScanner       *scanner = [NSScanner scannerWithString :pwd];
        NSCharacterSet  *numbersSet = [NSCharacterSet decimalDigitCharacterSet];
        NSCharacterSet  *lettersSet = [NSCharacterSet letterCharacterSet];
        NSCharacterSet  *symbolsSet = [NSCharacterSet characterSetWithCharactersInString:PWD_SYMBOLS];
        
        CHAR_TYPE charType = CHAR_NONE;
        
        while (![scanner isAtEnd]) {
            //分别测试是否包含数字、字母、指定符号、其它符号
            if ([scanner scanCharactersFromSet:numbersSet intoString:nil])
                charType |= CHAR_NUMBER;
            else if ([scanner scanCharactersFromSet:lettersSet intoString:nil])
                charType |= CHAR_LETTER;
            else if ([scanner scanCharactersFromSet:symbolsSet intoString:nil])
                charType |= CHAR_SPECIFIC_SYMBOL;
            else {
                charType |= CHAR_OTHER_SYMBOL;
                break;
            }
        }
        
        //查看密码组成类型种类
        size_t cnt = 0;
        for (int i = 0; i < 4; i++) {
            if (charType & (0x01 << i))
                cnt++;
        }
        
        //判定密码等级
        PWD_LEVEL lv = PWD_NONE;
        if (cnt < 1)
            lv = PWD_NONE;
        else if (cnt < 2)
            lv = PWD_WEEK;
        else if (cnt < 3)
            lv = PWD_MID;
        else
            lv = PWD_STRONG;
        
        if (level)
            *level = lv;
        
        //判定密码是否合法
        if (pwd.length > PWD_MAX_LENTH || charType & CHAR_OTHER_SYMBOL || (lv < PWD_MID))
            return NO;
    }
    
    return  YES;
}

- (NSString *)errMsg :(int)code
{
    switch (code) {
        case 0:
            return NSLocalizedString(@"success", nil);
            
        case 1:
            return NSLocalizedString(@"Username format error! The username can not be null and has a maximum length of 20, supporting numbers, letters, and symbols(support_ - @ $ *)", nil);
            
        case 2:
            return NSLocalizedString(@"Confirm password is not same with new password", nil);
            
        case 3:
            return NSLocalizedString(@"New password format error! Password should be 6-12 numbers, letters, symbols combination(support~ ! @ # % ^ * ( ) _ + { } : \"| < > ? ` - ; ' \\ , . /)", nil);
            
        default:
            return NSLocalizedString(@"unknow error", nil);
    }
}

#pragma mark - update ui
- (void)updatePwdLevelUI
{
    NSString *psw = self.pwdTF.stringValue;
    PWD_LEVEL level = PWD_NONE;
    
    [self parserPwd:psw level:&level];
    
    self.pwdLevelInd.integerValue = level;
}

- (ModifyLoginInfo *)modifyLoginInfoFromUI
{
    ModifyLoginInfo *info = [[ModifyLoginInfo alloc] init];
    
    info.usrName = @"admin";
    info.pwd = @"";
    info.modifiedName = self.userTF.stringValue;
    info.modifiedPwd = self.pwdTF.stringValue;
    
    return info;
}
#pragma mark - textfield delegate
- (void)controlTextDidChange:(NSNotification *)obj
{
    if ([obj.object isKindOfClass:[NSTextField class]]) {
        NSTextField *tf = obj.object;
        
        if ([tf.identifier isEqualToString:ID_PWD_TF]) {
            [self updatePwdLevelUI];
        }
    }
}

#pragma mark - life cycle
- (void)windowDidLoad {
    [super windowDidLoad];
    
    NSButton *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    closeButton.target = self;
    closeButton.action = @selector(cancel:);
}

#pragma mark - setter & getter
- (void)setPwdLevelInd:(NSLevelIndicator *)pwdLevelInd
{
    _pwdLevelInd = pwdLevelInd;
    _pwdLevelInd.integerValue = 0;
}

- (void)setUserTF:(NSTextField *)userTF
{
    _userTF = userTF;
    
    if (self.useDefaultUser) {
        _userTF.stringValue = @"admin";
        _userTF.enabled = NO;
    }
}

- (void)setUseDefaultUser:(BOOL)useDefaultUser
{
    _useDefaultUser = useDefaultUser;
    
    if (_useDefaultUser) {
        self.userTF.stringValue = @"admin";
        self.userTF.enabled = NO;
    }
    else {
        self.userTF.stringValue = @"";
        self.userTF.enabled = YES;
    }
}

@end
