//
//  QVTabView.m
//  QuickViewDHGR
//
//  Created by mark lim on 3/13/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
// Have to use a sub-class of NSTabView as it does not work properly in 10.12.x

#import "QVTabView.h"
#import "AppDelegate.h"
#import "MainWindowController.h"

@implementation QVTabView

// Refer to the source code of AppDelegate for more info.
- (void)awakeFromNib
{
	NSArray *draggedTypes = [NSArray arrayWithObjects:
							 NSURLPboardType,			// Drag from Finder
							 NSFilesPromisePboardType,	// Drag from any application that supports this type
							 nil];

	// Register for all the types that the tab view object supports.
	[self registerForDraggedTypes:draggedTypes];
}

/*
 This method is only called if the drop is onto the label of the TabView
 */
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
	return NSDragOperationGeneric;
}

// These 2 calls seems necessary for sub-classes of NSTabView
- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
	return NSDragOperationGeneric;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
	return YES;
}

// We have to let the Application's delegate handle the operation.
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
