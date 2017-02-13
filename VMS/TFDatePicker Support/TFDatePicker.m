//
//  DatePickerTextField.m
//  ShootStudio
//
//  Created by Tom Fewster on 16/06/2010.
//  Copyright 2010 Tom Fewster. All rights reserved.
//

#import "TFDatePicker.h"
#import "TFDatePickerPopoverController.h"

NSInteger buttonPadding = 3;
NSInteger buttonSize = 16;

@interface TFDatePicker ()
@property (strong) NSLayoutConstraint *widthConstraint;
@property (strong) TFDatePickerPopoverController *datePickerViewController;

- (void)performClick:(id)sender;
@end

@implementation TFDatePicker

@synthesize widthConstraint = _widthConstraint;
@synthesize datePickerViewController = _datePickerViewController;

- (void)awakeFromNib {
//	for (NSLayoutConstraint *constraint in self.constraints) {
//		if (constraint.firstAttribute == NSLayoutAttributeWidth && constraint.relation ==  NSLayoutRelationEqual) {
//			[self removeConstraint:constraint];
//		}
//	}
//
//	[self sizeToFit];
//	NSDictionary *views = NSDictionaryOfVariableBindings(self);
//	_widthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:self.frame.size.width];
//	[self addConstraint:_widthConstraint];

	NSButton *showPopoverButton = [[NSButton alloc] initWithFrame:NSZeroRect];
	showPopoverButton.buttonType = NSMomentaryChangeButton;
	showPopoverButton.bezelStyle = NSInlineBezelStyle;
	showPopoverButton.bordered = NO;
	showPopoverButton.imagePosition = NSImageOnly;

	//NSBundle *frameworkBundle = [NSBundle bundleWithIdentifier:@"com.wannabegeek.TFDatePicker"];
	//showPopoverButton.image = [frameworkBundle imageForResource:@"calendar"];
    showPopoverButton.image = [NSImage imageNamed:@"calendar"];
	[showPopoverButton.cell setHighlightsBy:NSContentsCellMask];
	showPopoverButton.target = self;
	showPopoverButton.action = @selector(performClick:);
	[self addSubview:showPopoverButton];

//	views = NSDictionaryOfVariableBindings(showPopoverButton);
	
    [showPopoverButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSDictionary *popoverButtonDict = @{@"showPopoverButton":showPopoverButton};
    [showPopoverButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[showPopoverButton(16)]"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:popoverButtonDict]];
    [showPopoverButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[showPopoverButton(16)]"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:popoverButtonDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[showPopoverButton]-(3)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:popoverButtonDict]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:showPopoverButton
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0.0]];
//	[self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:showPopoverButton attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];

//	[[self window] visualizeConstraints:self.constraints];
}

- (void)setDatePickerElements:(NSDatePickerElementFlags)elementFlags {
	[super setDatePickerElements:elementFlags];

	[self sizeToFit];
	if (_widthConstraint) {
		[self removeConstraint:_widthConstraint];
	}
	
	_widthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:self.frame.size.width];
	[self addConstraint:_widthConstraint];
}

- (void)sizeToFit {
	[super sizeToFit];
	CGRect frame = self.frame;
	frame.size.width += 22.0f;
	self.frame = frame;
}

- (void)performClick:(id)sender {
	if (!_datePickerViewController) {
		_datePickerViewController = [[TFDatePickerPopoverController alloc] init];
	}

	if (self.isEnabled) {
		[_datePickerViewController.datePicker setDateValue:self.dateValue];
		[_datePickerViewController.datePicker setDatePickerElements:self.datePickerElements];
		_datePickerViewController.datePicker.delegate = self;
		
		[_datePickerViewController showDatePickerRelativeToRect:[sender bounds] inView:sender completionHander:^(NSDate *selectedDate) {
			// if we have bindings, update the bound "value", otherwise just update the value in the datePicker
			NSDictionary *bindingInfo = [self infoForBinding:@"value"];
			if (bindingInfo) {
				NSString *keyPath = [bindingInfo valueForKey:NSObservedKeyPathKey];
				[[bindingInfo objectForKey:NSObservedObjectKey] setValue:selectedDate forKeyPath:keyPath];
			} else {
				self.dateValue = selectedDate;
			}
		}];
	}
}

- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell validateProposedDateValue:(NSDate **)proposedDateValue timeInterval:(NSTimeInterval *)proposedTimeInterval {
	if (self.delegate) {
		[self.delegate datePickerCell:aDatePickerCell validateProposedDateValue:proposedDateValue timeInterval:proposedTimeInterval];
	}
}

@end
