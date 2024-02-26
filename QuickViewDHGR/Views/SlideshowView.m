/*

 SlideshowView.m
 QuickViewDHGR
 
 Created by mark lim on 3/13/18.
 Copyright 2018 Incremental Innovation. All rights reserved.
 */

#import <QuartzCore/CAAnimation.h>
#import "SlideshowView.h"
#import "SlideshowWindowController.h"

@implementation SlideshowView

// This method is only called once i.e. during instantiation of the Slideshow Window Controller object.
- (id)initWithFrame:(NSRect)newFrame 
{
	self = [super initWithFrame:newFrame];
	if (self)
    {
		[self updateSubviewsTransition:1.0];
	}
	return self;
}

/*
 This may not be called on exit.
 */
- (void)dealloc
{
/*
	// May not be necessary because this object is never retained.
	if (currentImageView != nil) {
		[currentImageView release];
		currentImageView = nil;
	}
*/
    [super dealloc];
}

- (BOOL)isOpaque
{
    // We're opaque, since we fill with solid black in our -drawRect: method below.
    return YES;
}

- (void)drawRect:(NSRect)rect
{
    // Draw a solid black background.
    [[NSColor blackColor] set];
    NSRectFill(rect);
}

// -------------------------------------------------------------------------------
//	transitionToImage:newimage
// -------------------------------------------------------------------------------
- (void)transitionToImage:(NSImage *)newImage
{
    // Create a new NSImageView and swap it into the view in place of our previous NSImageView.
	// This will trigger the transition animation we've wired up in -updateSubviewsTransition,
	// which fires on changes in the "subviews" property.
    NSImageView *newImageView = nil;
    if (newImage) 
    {
        newImageView = [[[NSImageView alloc] initWithFrame:[self bounds]] autorelease];
        [newImageView setImage:newImage];
        [newImageView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    }

    if (currentImageView && newImageView) 
    {
		// NSView & its sub-classes adopt the NSAnimatablePropertyContainer Protocol.
        [[self animator] replaceSubview:currentImageView
								   with:newImageView];
    }
	else {
		// In case we are pass a nil newImage pointer or
		// two or more consecutive nil newImage pointers.
        if (currentImageView) 
        {
			[[currentImageView animator] removeFromSuperview];
		}
        if (newImageView)
        {
			[[self animator] addSubview:newImageView];
		}
    }
    currentImageView = newImageView;
}

- (void)updateSubviewsTransition:(NSTimeInterval)duration
{
	// Only one of Core Animation's 4 built-ins will be supported.
	// They are: kCATransitionFade, kCATransitionMoveIn, kCATransitionPush & kCATransitionReveal
    NSString *transitionType = kCATransitionFade;

	// Construct a new CATransition that describes the transition effect we want.
	CATransition *transition = [CATransition animation];

	// We want to specify one of Core Animation's 4 built-in transitions.
	[transition setType:transitionType];
	[transition setSubtype:kCATransitionFromLeft];

	// Specify an explicit duration for the transition.
	[transition setDuration:duration];

	// Associate the CATransition we've just built with the "subviews" key for this SlideshowView instance,
	// so that when we swap ImageView instances in our -transitionToImage: method above (via -replaceSubview:with:).
	[self setAnimations:[NSDictionary dictionaryWithObject:transition
													forKey:@"subviews"]];
}	


@end
