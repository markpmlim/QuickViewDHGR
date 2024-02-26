/*

    SlideshowView.h
    QuickViewDHGR

    Created by mark lim on 3/13/18.
    Copyright 2018 Incremental Innovation. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
typedef enum {
    // Core Animation's four built-in transition types
    SlideshowViewFadeTransitionStyle,
    SlideshowViewMoveInTransitionStyle,
    SlideshowViewPushTransitionStyle,
    SlideshowViewRevealTransitionStyle,

    // Core Image's standard set of transition filters
    SlideshowViewCopyMachineTransitionStyle,
    SlideshowViewDisintegrateWithMaskTransitionStyle,
    SlideshowViewDissolveTransitionStyle,
    SlideshowViewFlashTransitionStyle,
    SlideshowViewModTransitionStyle,
    SlideshowViewPageCurlTransitionStyle,
    SlideshowViewRippleTransitionStyle,
    SlideshowViewSwipeTransitionStyle,

    NumberOfSlideshowViewTransitionStyles
} SlideshowViewTransitionStyle;


@interface SlideshowView : NSView
{
    NSImageView		*currentImageView;
}


- (void)updateSubviewsTransition:(NSTimeInterval)duration;

- (void)transitionToImage:(NSImage *)newImage;
@end
