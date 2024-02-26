//
//  AppDelegate.h
//  QuickViewDHGR
//
//  Created by mark lim on 2/13/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import <AppKit/AppKit.h>
#include "UserDefines.h"

@class MainWindowController;
@class SlideshowWindowController;

@interface AppDelegate : NSObject
{
	NSString					*tempWorkingDir;
	MainWindowController		*mainWinController;
	SlideshowWindowController	*slideshowWinController;
	NSView						*fileTypeView;

    unsigned int				changeFileTypeTag;
}

@property (copy)   NSString						*tempWorkingDir;
@property (retain) MainWindowController			*mainWinController;
@property (retain) SlideshowWindowController	*slideshowWinController;
@property (retain) IBOutlet NSView				*fileTypeView;

// The property below is bind to Matrix selectedTag (under Value Selection Section)
@property (assign, readwrite) unsigned int		changeFileTypeTag;

- (IBAction)openHelpWindow:(id)sender;
- (IBAction)openSlideshowWindow:(id)sender;
- (IBAction)changeFileType:(id)sender;

// Drag-And-Drop handler methods.
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id<NSDraggingInfo>)sender;

- (BOOL)isApple2GraphicAtURL:(NSURL *)url
                 graphicType:(GraphicType *)type
           compressionMethod:(CompressionAlgorithm *)algorithm;

@end
