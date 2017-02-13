//
//  JFPreferenceRootViewController.m
//  JFPreferencePanel
//
//  Created by mac_dev on 2016/10/22.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "JFPreferenceRootViewController.h"

@interface JFPreferenceRootViewController ()

@property(nonatomic,weak) IBOutlet NSCollectionView *collectionView;
@property(nonatomic,strong) NSArray *icons;
@property(nonatomic,strong) JFCVPrototype *collectionViewItem;


@end

@implementation JFPreferenceRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configCollectionView];
    // Do view setup here.
}


#pragma mark - config
- (void)configCollectionView
{
    self.collectionViewItem = [JFCVPrototype new];
    self.collectionViewItem.delegate = self;
    //[[JFCVPrototype alloc] initWithNibName:@"JFCVPrototype" bundle:[NSBundle mainBundle]];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"preference" ofType:@"plist"];
    self.icons = [NSArray arrayWithContentsOfFile:path];
   
    [self.collectionView setItemPrototype:self.collectionViewItem];
    [self.collectionView setContent:self.icons];
}


#pragma mark - segue
- (void)segueToScene :(NSString *)scene
{
    //考虑root panel下一个panel是否已经存在，并且就是将要跳转的场景
    JFPreferenceViewController *destScene = nil;
    
    if ([self.forwardController isKindOfClass:NSClassFromString(scene)]) {
        destScene = self.forwardController;
    }
    else {
        destScene = [[NSClassFromString(scene) alloc] initWithNibName:scene bundle:nil];
    }
    
    if (destScene) {
        if ([self.delegate respondsToSelector:@selector(preferencePanel:willForwardToPanel:)]) {
            [self.delegate preferencePanel:self willForwardToPanel:destScene];
        }
    }
    else {
        NSLog(@"failed to segue :the dest scene is nil");
    }
}

#pragma mark - cvPrototype delegate
- (void)cvPrototype:(NSCollectionViewItem *)item didClickedNotification:(NSNotification *)aNotific
{
    NSString *scene = [(JFCVPrototype *)item scene];
    
    if (scene) {
        [self segueToScene:scene];
    }
    else {
        NSLog(@"failed to segue,the scene is nil");
    }
}

#pragma mark - setter & getter
- (NSString *)panelTitle
{
    return NSLocalizedString(@"Preferences", nil);
}
@end
