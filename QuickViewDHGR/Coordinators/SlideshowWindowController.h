//
//  SlideshowWindowController.h
//  QuickViewDHGR
//
//  Created by mark lim on 2/23/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "UserDefines.h"

@class SlideshowView;

@interface SlideshowWindowController : NSWindowController 
{
	SlideshowView		*slideshowView;
	NSSegmentedControl	*mediaControls;
	NSButton			*openFilesButton;
	NSSlider			*delaySlider;

	NSTimeInterval		currentDelayAmount;
	NSTimer				*slideshowTimer;
	NSArray				*urls;
	NSURL				*currentSlide;
	NSUInteger			currentSlideNumber; 
	BOOL				isSlideshowRunning;

	NSImage				*noPic;
}

// The IBOutlets are connected in IB to File's Owner (which is SlideshowWindowController)
// There is also a property IBOutlet `window`
@property (assign) IBOutlet SlideshowView		*slideshowView;
@property (assign) IBOutlet NSSegmentedControl	*mediaControls;
@property (assign) IBOutlet NSButton			*openFilesButton;
@property (assign) IBOutlet NSSlider			*delaySlider;
@property (assign)			NSTimeInterval		currentDelayAmount;
@property (retain)			NSTimer				*slideshowTimer;
@property (copy)			NSArray				*urls;
@property (retain)			NSURL				*currentSlide;
@property (assign)			NSUInteger			currentSlideNumber; 
@property (assign)			BOOL				isSlideshowRunning;

// Public methods
- (IBAction)handleMediaControls:(id)sender;
- (IBAction)handleOpen:(id)sender;
- (NSTimeInterval)slideshowInterval;;
- (void)setSlideshowInterval:(NSTimeInterval)newSlideshowInterval;

// Internal methods - declare to suppress the warnings emitted by XCode.
- (void) stopSlideshowTimer;

@end
