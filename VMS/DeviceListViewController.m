//
//  DeviceListViewController.m
//  VMS
//
//  Created by mac_dev on 15/6/1.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

/*#import "DeviceListViewController.h"
#import "BaseNode.h"
#import "ChildNode.h"
#import "ImageAndTextCell.h"
#import "Image+Clip.h"

#define COLUMNID_NAME                   @"video devices column"	// the single column name in our outline view
#define INITIAL_INFODICT                @"Outline"		// name of the dictionary file to populate our outline view
#define HEAD_INPUT_DEVICE_NAME          @"InputDevice"
#define TREE_LIST_ICONS                 @"TREE_LIST"

#define kIconImageSize                  16.0

#define kNodesPBoardType		@"myNodesPBoardType"	// drag and drop pasteboard type

// keys in our disk-based dictionary representing outr outline view's data
#define KEY_NAME                @"name"
#define KEY_GROUP               @"group"
#define KEY_FOLDER              @"folder"
#define KEY_ENTRIES             @"entries"
// -------------------------------------------------------------------------------
//	TreeAdditionObj
//
//	This object is used for passing data between the main and secondary thread
//	which populates the outline view.
// -------------------------------------------------------------------------------
@interface TreeAdditionObj : NSObject

@property (unsafe_unretained, readonly) NSIndexPath *indexPath;
@property (unsafe_unretained, readonly) NSString *nodeName;
@property (readonly) BOOL selectItsParent;


@end


#pragma mark -

@implementation TreeAdditionObj

// -------------------------------------------------------------------------------
//  initWithURL:url:name:select
// -------------------------------------------------------------------------------
- (instancetype)initWithName:(NSString *)name
             selectItsParent:(BOOL)select
{
    self = [super init];
    _nodeName = name;
    _selectItsParent = select;
    return self;
}
@end



@interface DeviceListViewController ()<NSOutlineViewDelegate,NSMenuDelegate>
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSTreeController *treeController;
@property (strong,nonatomic) NSMutableArray *contents; // used to keep track of dragged nodes
@property (strong,nonatomic) NSImage *inputHead;
@property (strong,nonatomic) NSImage *device;
@property (strong,nonatomic) NSImage *point;
@end

@implementation DeviceListViewController

- (void)awakeFromNib
{
    // apply our custom ImageAndTextCell for rendering the first column's cells
    NSTableColumn *tableColumn = [self.outlineView tableColumnWithIdentifier:COLUMNID_NAME];
    ImageAndTextCell *imageAndTextCell = [[ImageAndTextCell alloc] initTextCell:@""];
    [imageAndTextCell setEditable:YES];
    [tableColumn setDataCell:imageAndTextCell];
    
    // add our content
    [self populateOutlineContents];
    
    // scroll to the top in case the outline contents is very long
    [[[self.outlineView enclosingScrollView] verticalScroller] setFloatValue:0.0];
    [[[self.outlineView enclosingScrollView] contentView] scrollToPoint:NSMakePoint(0,0)];
    
    // make our outline view appear with gradient selection, and behave like the Finder, iTunes, etc.
    [self.outlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
    
    // drag and drop support
    [self.outlineView registerForDraggedTypes:@[kNodesPBoardType,			// our internal drag type
                                                NSURLPboardType,			// single url from pasteboard
                                                NSFilenamesPboardType,		// from Safari or Finder
                                                NSFilesPromisePboardType]];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - oulline view datasource from tree controller
- (void)populateOutlineContents
{
    // hide the outline view - don't show it as we are building the content
    [self.outlineView setHidden:YES];
    
    //[self addVideoOutputDeviceSection];
    [self populateOutline];
    // remove the current selection
    NSArray *selection = [self.treeController selectionIndexPaths];
    [self.treeController removeSelectionIndexPaths:selection];
    
    [self.outlineView setHidden:NO];	// we are done populating the outline view content, show it again
}


- (void)addChildWithName :(NSString *)deviceName
             selectParent:(BOOL)select
{
    TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithName:deviceName
                                                         selectItsParent:select];
    [self performAddChild :treeObjInfo];
}


- (void)performAddChild :(TreeAdditionObj *)treeObjInfo
{
    ///首先检查是否是在叶子节点上增加节点
    if ([[self.treeController selectedObjects] count] > 0) {
        // wo have a selection
        if ([[self.treeController selectedObjects][0] isLeaf]) {
            [self selectParentFromSelection];
        }
    }
    
    //find the selection to insert our node
    NSIndexPath *indexPath;
    if ([[self.treeController selectedObjects] count] > 0) {
        //we have a selection,insert at the end of the selection
        indexPath = [self.treeController selectionIndexPath];
        indexPath = [indexPath indexPathByAddingIndex:[[[self.treeController selectedObjects][0] children] count]];
    } else {
        //no selection,insert at the end of the content array
        indexPath = [NSIndexPath indexPathWithIndex:self.contents.count];
    }
    
    ///make a child node
    ChildNode *node;
    node = [[ChildNode alloc] initLeaf];
    node.nodeTitle = treeObjInfo.nodeName;
    
    // the user is adding a child node, tell the controller directly
    [self.treeController insertObject:node atArrangedObjectIndexPath:indexPath];
    
    // adding a child automatically becomes selected by NSOutlineView, so keep its parent selected
    if ([treeObjInfo selectItsParent])
    {
        [self selectParentFromSelection];
    }
}


- (void)addFolder:(NSString *)folderName
{
    TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithName:folderName
                                                         selectItsParent:NO];
    [self performAddFolder :treeObjInfo];
}


- (void)performAddFolder:(TreeAdditionObj *)treeAddition
{
    // NSTreeController inserts objects using NSIndexPath, so we need to calculate this
    NSIndexPath *indexPath = nil;
    
    // if there is no selection, we will add a new group to the end of the contents array
    if ([[self.treeController selectedObjects] count] == 0)
    {
        // there's no selection so add the folder to the top-level and at the end
        indexPath = [NSIndexPath indexPathWithIndex:self.contents.count];
    }
    else
    {
        // get the index of the currently selected node, then add the number its children to the path -
        // this will give us an index which will allow us to add a node to the end of the currently selected node's children array.
        //
        indexPath = [self.treeController selectionIndexPath];
        if ([[self.treeController selectedObjects][0] isLeaf])
        {
            // user is trying to add a folder on a selected child,
            // so deselect child and select its parent for addition
            [self selectParentFromSelection];
        }
        else
        {
            indexPath = [indexPath indexPathByAddingIndex:[[[self.treeController selectedObjects][0] children] count]];
        }
    }
    
    ChildNode *node = [[ChildNode alloc] init];
    node.nodeTitle = [treeAddition nodeName];
    
    // the user is adding a child node, tell the controller directly
    [self.treeController insertObject:node atArrangedObjectIndexPath:indexPath];
    
}

- (void)populateOutline
{
    // add the "Bookmarks" section
    
    NSDictionary *initData = [NSDictionary dictionaryWithContentsOfFile:
                              [[NSBundle mainBundle] pathForResource:INITIAL_INFODICT ofType:@"plist"]];
    NSDictionary *entries = initData[KEY_ENTRIES];
    
    [self addEntries:entries discloseParent:YES];
    
    [self selectParentFromSelection];
}

- (void)addEntries:(NSDictionary *)entries discloseParent:(BOOL)discloseParent
{
    for (id entry in entries)
    {
        if ([entry isKindOfClass:[NSDictionary class]])
        {
            if (entry[KEY_GROUP]) {
                // it's a generic container
                NSString *folderName = entry[KEY_GROUP];
                [self addFolder:folderName];
                
                // add its children
                NSDictionary *newChildren = entry[KEY_ENTRIES];
                [self addEntries:newChildren discloseParent:NO];
                
                [self selectParentFromSelection];
            } else {
                // it's just a leaf
                NSString *nameStr = entry[KEY_NAME];
                [self addChildWithName:nameStr selectParent:YES];
            }
        }
    }
    
    if (!discloseParent)
    {
        // inserting children automatically expands its parent, we want to close it
        if ([[self.treeController selectedNodes] count] > 0)
        {
            NSTreeNode *lastSelectedNode = [self.treeController selectedNodes][0];
            [self.outlineView collapseItem:lastSelectedNode];
        }
    }
}

- (void)selectParentFromSelection
{
    if ([[self.treeController selectedNodes] count] > 0)
    {
        NSTreeNode *firstSelectedNode = [self.treeController selectedNodes][0];
        NSTreeNode *parentNode = [firstSelectedNode parentNode];
        if (parentNode)
        {
            // select the parent
            NSIndexPath *parentIndex = [parentNode indexPath];
            [self.treeController setSelectionIndexPath:parentIndex];
        }
        else
        {
            // no parent exists (we are at the top of tree), so make no selection in our outline
            NSArray *selectionIndexPaths = [self.treeController selectionIndexPaths];
            [self.treeController removeSelectionIndexPaths:selectionIndexPaths];
        }
    }
}

- (NSMutableArray *)contents
{
    if (!_contents) {
        _contents = [[NSMutableArray alloc] init];
    }
    return _contents;
}

#pragma mark - NSOutlineViewDelegate
- (BOOL)outlineView:(NSOutlineView *)outlineView
   shouldSelectItem:(id)item
{
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
shouldEditTableColumn:(NSTableColumn *)tableColumn
               item:(id)item
{
    return NO;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView
 dataCellForTableColumn:(NSTableColumn *)tableColumn
                   item:(id)item
{
    NSCell *returnCell = [tableColumn dataCell];
    return returnCell;
}

- (void)outlineView:(NSOutlineView *)outlineView
    willDisplayCell:(id)cell
     forTableColumn:(NSTableColumn *)tableColumn
               item:(id)item
{
    //we care the single and only column
    if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
        // check for the cell to display
        if ([cell isKindOfClass:[ImageAndTextCell class]]) {
            //提取果实
            item = [item representedObject];
            if (item) {
//                NSImage *iconImage = [NSImage imageNamed:[item nodeIcon]];
//                [iconImage setSize:NSMakeSize(kIconImageSize, kIconImageSize)];
                ImageAndTextCell *myCell = (ImageAndTextCell *)cell;
//                myCell.myImage = iconImage;
                myCell.title = [item nodeTitle];
            }
        }
    }
}


#pragma mark - NSOutlineView context menu
- (void)menuNeedsUpdate:(NSMenu *)menu
{
    ///移除所有菜单项
    [menu removeAllItems];
    
    NSInteger clickedRow = [self.outlineView clickedRow];
    
    if (clickedRow != -1) {
        ///如果我们选中了某一行
        NSArray *selectedNodes = [self.treeController selectedNodes];
        if ([selectedNodes count] > 0) {
            ///用户有选中某个节点
            if ([selectedNodes[0] isKindOfClass:[NSTreeNode class]]) {
                NSTreeNode *firstObj = selectedNodes[0];
                BaseNode *node = firstObj.representedObject;
                
                if ([node isLeaf]) {
                    NSMenuItem *removeMonitoryPoint = [NSMenuItem alloc];
                    removeMonitoryPoint.title = @"移除监控点";
                    removeMonitoryPoint.target = self;
                    removeMonitoryPoint.action = @selector(outlineViewContextMenuItemClicked:);
                    [menu addItem:removeMonitoryPoint];
                } else {
                    NSMenuItem *addMonitoryPoint = [NSMenuItem alloc];
                    addMonitoryPoint.title = @"增加监控点";
                    addMonitoryPoint.target = self;
                    addMonitoryPoint.action = @selector(outlineViewContextMenuItemClicked:);
                    [menu addItem:addMonitoryPoint];
                    
                    if ([self.contents containsObject:node]) {
                        ///如果选择的是“输入设备”节点
                        NSMenuItem *addDevice = [NSMenuItem alloc];
                        addDevice.title = @"增加设备";
                        addDevice.target = self;
                        addDevice.action = @selector(outlineViewContextMenuItemClicked:);
                        [menu addItem:addDevice];
                    } else {
                        NSMenuItem *removeDevice = [NSMenuItem alloc];
                        removeDevice.title = @"移除设备";
                        removeDevice.target = self;
                        removeDevice.action = @selector(outlineViewContextMenuItemClicked:);
                        [menu addItem:removeDevice];
                    }
                }
            }
        }
    }
}

- (void)outlineViewContextMenuItemClicked :(NSMenuItem *)item
{
    if ([item.title isEqualToString:@"增加设备"]) {
        [self addChildWithName:@"Unkown Device" selectParent:NO];
    } else if ([item.title isEqualToString:@"增加监控点"]) {
        [self addChildWithName:@"UnKown monitory point" selectParent:YES];
    } else if ([item.title isEqualToString:@"移除监控点"] || [item.title isEqualToString:@"移除设备"]) {
        [self.treeController remove:self];
    }
}

- (NSImage *)inputHead
{
    if (!_inputHead) {
        NSImage *treeListIcons = [NSImage imageNamed:TREE_LIST_ICONS];
        NSSize imageSize = treeListIcons.size;
        _inputHead = [treeListIcons imageClipedWithRect:CGRectMake(imageSize.width / 24.0, 0, imageSize.width / 24.0, imageSize.height)];
    }
    
    return _inputHead;
}

- (NSImage *)device
{
    if (!_device) {
        NSImage *treeListIcons = [NSImage imageNamed:TREE_LIST_ICONS];
        NSSize imageSize = treeListIcons.size;
        _device = [treeListIcons imageClipedWithRect:CGRectMake(imageSize.width * 5/ 24.0, 0, imageSize.width / 24.0, imageSize.height)];
    }
    
    return _device;
}

- (NSImage *)point
{
    if (!_point) {
        NSImage *treeListIcons = [NSImage imageNamed:TREE_LIST_ICONS];
        NSSize imageSize = treeListIcons.size;
        _point = [treeListIcons imageClipedWithRect:CGRectMake(imageSize.width * 4/ 24.0, 0, imageSize.width / 24.0, imageSize.height)];
    }
    return _point;
}
@end*/
