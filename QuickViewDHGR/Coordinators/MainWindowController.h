//
//  MainWindowController.h
//  QuickViewDHGR
//
//  Created by mark lim on 2/23/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "UserDefines.h"

@class QVTabView;

@interface MainWindowController : NSWindowController
{
	QVTabView	*tabView;
	NSTextView	*colorView;
	NSTextView	*monoView;
	NSButton	*doubleSizeButton;
	NSArray		*promisedFiles;
	BOOL		isApple2Graphic;
	NSImage		*colorImage1x;
	NSImage		*monoChromeImage1x;
	NSImage		*colorImage2x;
	NSImage		*monoChromeImage2x;
}

// The IBOutlets are connected in IB to File's Owner (which is MainWindowController
// There is also a property IBOutlet `window`
@property (assign) IBOutlet QVTabView	*tabView;
@property (assign) IBOutlet NSTextView	*colorView;
@property (assign) IBOutlet NSTextView	*monoView;
@property (assign) IBOutlet NSButton	*doubleSizeButton;

@property (copy)			NSArray		*promisedFiles;
@property (assign)			BOOL		isApple2Graphic;
@property (retain)			NSImage		*colorImage1x;
@property (retain)			NSImage		*monoChromeImage1x;
@property (retain)			NSImage		*colorImage2x;
@property (retain)			NSImage		*monoChromeImage2x;

// public methods
- (BOOL)displayImageAtURL:(NSURL *)url
              graphicType:(GraphicType)graphicType
        compressionMethod:(CompressionAlgorithm)algorithm;

- (IBAction)doubleSizeImage:(id)sender;
@end
