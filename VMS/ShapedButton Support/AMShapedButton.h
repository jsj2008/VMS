//
//  AMShapedButton.h
//  Mandy
//
//  Created by Andreas on Mon Jul 28 2003.
//  Copyright (c) 2003 Andreas Mayer. All rights reserved.

//  - draws buttons with alpha masks
//  - buttons will not overwrite background where transparent
//  - clickable only where alpha > 0.5
//  - automatically chooses graphite or aqua image (if correctly named)
//  - will automatically tint 'off' image according to system control tint if
//	  no matching 'on' image available
//  - responds to control tint change notification
//
//  Make sure the button is exactly the same size as the image in Interface Builder,
//  or the position in the running app will be different from what you see in IB.
//  To use the automatic image selection, name your
//	aqua tinted image '<some name> Aqua', the graphite version '<some name> Graphite'
//  and set 'alternate image' in IB to '<some name> Aqua'.
//  To use automatic tinting, leave 'alternate image' empty.
//  Automatic tinting works best if 'off' image is 'clear aqua' (i.e. light grey/white)


#import <AppKit/AppKit.h>

@interface JFButtonCell : NSButtonCell
@property (strong,nonatomic) NSImage *hoverImage;
@property (strong,nonatomic) NSImage *alternateHoverImage;
@property (strong,nonatomic) NSImage *disableImage;
@property (strong,nonatomic) NSImage *alternateDisableImage;
@property (assign,getter=isHover) BOOL hover;
@end


@interface AMShapedButton : NSButton
@end
