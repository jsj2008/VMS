//
//  PrivacyCoverEditView.h
//  
//
//  Created by mac_dev on 16/3/29.
//
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, DRAG_OP) {
    DRAG_NONE,
    DRAG_MODIFY_LT,
    DRAG_MODIFY_LB,
    DRAG_MODIFY_RT,
    DRAG_MODIFY_RB,
    DRAG_MOVE,
    DRAG_CREATE,
};


////////////////////////////////////////////////////////////////////////////////
@protocol AnchorClip <NSObject>

@optional
- (NSRect)clipRect :(NSRect)rc opration :(DRAG_OP)op;
@end
//纪录拖拽时，抛锚时的状态
@interface Anchor : NSObject

@property(nonatomic,assign) id<AnchorClip> delegate;
@property(nonatomic,assign) NSPoint location;
@property(nonatomic,assign) NSRect rc;
@property(nonatomic,assign) DRAG_OP op;

- (instancetype)initWithLocation :(NSPoint)location
                            rect :(NSRect)rc
                       operation :(DRAG_OP)op;
- (NSRect)modifyToLocation :(NSPoint)location;

@end

////////////////////////////////////////////////////////////////////////////////
@protocol PrivacyCoverEditViewDelegate <NSObject>

- (void)selectedAreaDidChange :(NSNotification *)aNotific;
@end

@interface PrivacyCoverEditView : NSView<AnchorClip>
@property(nonatomic,assign) id<PrivacyCoverEditViewDelegate> delegate;
@property(nonatomic,assign,readonly) NSInteger indexOfSelectedArea;
@property(nonatomic,assign) NSInteger rcCountLimit;//矩形数量
@property(nonatomic,assign) BOOL needDisplayIndex;


//这里无论是传入的矩形参数还是返回的矩形结果，统一以1为总长宽，进行换算
- (void)removeAreaAtIndex :(NSInteger)index;
- (void)addArea :(NSRect)rc;
- (void)selectAreaAtIndex :(NSInteger)index;
- (NSArray *)allAreas;

@end
