//
//  MainWindowController.m
//  QuickViewDHGR
//
//  Created by mark lim on 2/23/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import "MainWindowController.h"
#import "AppDelegate.h"
#import "Apple2Graphic.h"
#import "QVTabView.h"

@implementation MainWindowController
@synthesize tabView;
@synthesize colorView;
@synthesize monoView;
@synthesize doubleSizeButton;
@synthesize promisedFiles;
@synthesize isApple2Graphic;
@synthesize colorImage1x;
@synthesize monoChromeImage1x;
@synthesize colorImage2x;
@synthesize monoChromeImage2x;


- (id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self)
    {
        // Init instance vars
	}
	return self;
}


- (void)dealloc
{
	//printf("Deallocating drag win controller\n");
	if (promisedFiles != nil) {
		[promisedFiles release];
		promisedFiles = nil;
	}
	if (monoChromeImage1x != nil) {
		[monoChromeImage1x release];
		monoChromeImage1x = nil;
	}
	if (colorImage1x != nil) {
		[colorImage1x release];
		colorImage1x = nil;
	}
	if (monoChromeImage2x != nil) {
		[monoChromeImage2x release];
		monoChromeImage2x = nil;
	}
	if (colorImage2x != nil) {
		[colorImage2x release];
		colorImage2x = nil;
	}
	[super dealloc];
}

// Refer to the AppDelegate.m file for further details.
- (void)awakeFromNib
{
	[monoView unregisterDraggedTypes];
	[colorView unregisterDraggedTypes];
	NSArray *draggedTypes = [NSArray arrayWithObjects:
							 NSURLPboardType,			// Drag from Finder
							 NSFilesPromisePboardType,	// Drag from any application that supports this type
							 nil];

	// Register for all the types that the underlying window object supports.
	[[self window] registerForDraggedTypes:draggedTypes];

	NSBundle *mainBndl = [NSBundle mainBundle];
	NSString *path = [mainBndl pathForResource:@"DropImage"
										ofType:@"png"];
	NSString *path2 = [mainBndl pathForResource:@"DropImage2x"
										 ofType:@"png"];
	NSImage *dropImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
	NSImage *dropImage2 = [[[NSImage alloc] initWithContentsOfFile:path2] autorelease];
	self.monoChromeImage1x = dropImage;
	self.colorImage1x = dropImage;
	self.monoChromeImage2x = dropImage2;
	self.colorImage2x = dropImage2;
	NSTextAttachmentCell *attachmentCell = [[[NSTextAttachmentCell alloc] initImageCell:dropImage] autorelease];
	NSTextAttachment *attachment = [[[NSTextAttachment alloc] init] autorelease];
	[attachment setAttachmentCell:attachmentCell];
	NSAttributedString *attributedString = [NSAttributedString attributedStringWithAttachment:attachment];
	[[[self colorView] textStorage] setAttributedString:attributedString];
	[[[self monoView] textStorage] setAttributedString:attributedString];
	self.isApple2Graphic = NO;
}

- (BOOL)displayImageAtURL:(NSURL *)url
              graphicType:(GraphicType)graphicType
        compressionMethod:(CompressionAlgorithm)algorithm
{
	BOOL result = NO;
    Apple2Graphic *graphic;
    NSData *fileData = [NSData dataWithContentsOfURL:url];
    graphic = [[[Apple2Graphic alloc] initWithData:fileData
                                       graphicType:graphicType
                                 compressionMethod:algorithm] autorelease];
    if (graphic != nil) 
    {
        NSInteger state = [self.doubleSizeButton state];
        NSImage *colorImage;
        NSImage *monoChromeImage;
        self.colorImage2x = [graphic colorImage2x];
        self.monoChromeImage2x  = [graphic monoChromeImage2x];
        self.colorImage1x = [graphic colorImage];
        self.monoChromeImage1x  = [graphic monoChromeImage];
        if (state == NSOnState)
        {
            colorImage = self.colorImage2x;
            monoChromeImage = self.monoChromeImage2x;
        }
        else 
        {
            colorImage = self.colorImage1x;
            monoChromeImage = self.monoChromeImage1x;
        }
        if (colorImage != nil && monoChromeImage != nil)
        {
            self.isApple2Graphic = YES;
            NSTextAttachmentCell *attachmentCell = [[[NSTextAttachmentCell alloc] initImageCell:colorImage] autorelease];
            NSTextAttachment *attachment = [[[NSTextAttachment alloc] init] autorelease];
            [attachment setAttachmentCell:attachmentCell];
            NSAttributedString *attributedString = [NSAttributedString attributedStringWithAttachment:attachment];
            [[[self colorView] textStorage] setAttributedString:attributedString];

            attachmentCell = [[[NSTextAttachmentCell alloc] initImageCell:monoChromeImage] autorelease];
            attachment = [[[NSTextAttachment alloc] init] autorelease];
            [attachment setAttachmentCell:attachmentCell];
            attributedString = [NSAttributedString attributedStringWithAttachment:attachment];
            [[[self monoView] textStorage] setAttributedString:attributedString];

            NSString *name = [url.path lastPathComponent];
            [[self window] setTitle: url != NULL ? name : @"(no name)"];
            result = YES;
        }
    }
bailOut:
	return result;
}

/*
 Not used.
 */
- (void)resizeSuperviewsOfView:(NSView *)view
{
	while (view.superview)
    {
		CGRect cgRect = NSRectToCGRect(view.frame);
		CGFloat maxY = CGRectGetMaxY(cgRect);
		CGFloat maxX = CGRectGetMaxX(cgRect);
		CGFloat minY = CGRectGetMinY(cgRect);
		CGFloat minX = CGRectGetMinX(cgRect);
		CGRect superViewFrame = NSRectToCGRect(view.superview.frame);
		if (superViewFrame.size.height < maxY) {
			superViewFrame.size.height = maxY;
		}
		if (superViewFrame.size.width < maxX)
        {
			superViewFrame.size.width = maxX;
		}
	
		if (superViewFrame.size.height > minY) 
        {
			superViewFrame.size.height = minY;
		}
		if (superViewFrame.size.width > minX)
        {
			superViewFrame.size.width = minX;
		}

		view.superview.frame = NSRectFromCGRect(superViewFrame);
		view = view.superview;
	}
}

- (IBAction)doubleSizeImage:(id)sender
{

	NSRect winFrame = [[self window] frame];
	NSSize newWinSize;
	NSImage *colorImage = nil;
	NSImage *monoChromeImage = nil;

	NSInteger state = [self.doubleSizeButton state];
	if (state == NSOnState)
    {
        // We have to hard-code the following values to give the appearance
        // of a smooth transition from the normal to double sized window.
		newWinSize.width = 633;
		newWinSize.height = 530;
		winFrame.size = newWinSize;

		winFrame.origin.x -= winFrame.size.width;
		winFrame.origin.x += newWinSize.width;
		winFrame.origin.y -= winFrame.size.height;
		winFrame.origin.y += newWinSize.height; // add the new height
		colorImage = self.colorImage2x;
		monoChromeImage  = self.monoChromeImage2x;
	}
	else if (state == NSOffState)
    {
        // We have to hard-code the following values to give the appearance
        // of a smooth transition from the double to normal sized window.
		newWinSize.width = 350.0;
		newWinSize.height = 330.0;
		winFrame.size = newWinSize;
		winFrame.origin.x -= winFrame.size.width;
		winFrame.origin.x += newWinSize.width;
		winFrame.origin.y -= winFrame.size.height;
		winFrame.origin.y += newWinSize.height; // add the new height
		colorImage = self.colorImage1x;
		monoChromeImage  = self.monoChromeImage1x;
	}

	[[self window] setFrame:winFrame
                    display:YES];

	if (colorImage != nil && monoChromeImage != nil)
    {
		self.isApple2Graphic = YES;
		NSTextAttachmentCell *attachmentCell = [[[NSTextAttachmentCell alloc] initImageCell:colorImage] autorelease];
		NSTextAttachment *attachment = [[[NSTextAttachment alloc] init] autorelease];
		[attachment setAttachmentCell:attachmentCell];
		NSAttributedString *attributedString = [NSAttributedString attributedStringWithAttachment:attachment];
		[[[self colorView] textStorage] setAttributedString:attributedString];

		attachmentCell = [[[NSTextAttachmentCell alloc] initImageCell:monoChromeImage] autorelease];
		attachment = [[[NSTextAttachment alloc] init] autorelease];
		[attachment setAttachmentCell:attachmentCell];
		attributedString = [NSAttributedString attributedStringWithAttachment:attachment];
		[[[self monoView] textStorage] setAttributedString:attributedString];
	}
}


/*
 Connect window's delegate outlet to File Owner's widget.
 macOS 10.12.x: sub-class of NSTabView can not receive file drops.
 We pass the information to the Application's delegate.
 */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return NSDragOperationGeneric;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	return [appDelegate performDragOperation:sender];
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate concludeDragOperation:sender];
}

@end
