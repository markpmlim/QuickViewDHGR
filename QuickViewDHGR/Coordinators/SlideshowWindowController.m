//
//  SlideshowWindowController.h
//  QuickViewDHGR
//
//  Created by mark lim on 2/23/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import "SlideshowWindowController.h"
#import "AppDelegate.h"
#import "Apple2Graphic.h"
#import "SlideshowView.h"
//#import "Apple2HiresGraphic.h"
//#import "Apple2DoubleHiresGraphic.h"

@implementation SlideshowWindowController

static NSTimeInterval minDelayAmount = 0.25;
@synthesize slideshowView;
@synthesize mediaControls;
@synthesize openFilesButton;
@synthesize delaySlider;
@synthesize currentDelayAmount;
@synthesize slideshowTimer;
@synthesize urls;
@synthesize currentSlide;
@synthesize currentSlideNumber; 
@synthesize isSlideshowRunning;

- (id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self) 
    {
		NSString *noPicPath = [[NSBundle mainBundle] pathForResource:@"NoPic"
															  ofType:@"png"];
		noPic = [[NSImage alloc] initWithContentsOfFile:noPicPath];
		currentSlideNumber = 1;
		currentDelayAmount = 1.0;
	}
	return self;
}

/*
 Only called on program exit.
 */
- (void)dealloc
{
	if (noPic != nil)
    {
		[noPic release];
		noPic = nil;
	}
	//printf("Deallocating slide show win controller\n");
	if (urls != nil) 
    {
		[urls release];
		urls = nil;
	}
	if (openFilesButton != nil)
    {
		openFilesButton = nil;
	}
	if (delaySlider != nil) 
    {
		delaySlider = nil;
	}
	if (slideshowTimer != nil)
    {
		[slideshowTimer release];
		slideshowTimer = nil;
	}
	if (currentSlide != nil) 
    {
		[currentSlide release];
		currentSlide = nil;
	}
	if (mediaControls != nil)
    {
		mediaControls = nil;
	}
	if (slideshowView != nil)
    {
		slideshowView = nil;
	}
	[super dealloc];
}

- (void)awakeFromNib
{
	[self.slideshowView setWantsLayer:YES];
	[[self window] setReleasedWhenClosed:NO];	// Don't release window's allocated resources
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self stopSlideshowTimer];
}

- (void)showSlide
{
	self.currentSlide = [self.urls objectAtIndex:currentSlideNumber-1];
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	GraphicType type;
	CompressionAlgorithm method;
	BOOL result = [appDelegate isApple2GraphicAtURL:self.currentSlide
										graphicType:&type
								  compressionMethod:&method];
	if (result == YES) 
    {
		NSData *fileData = [NSData dataWithContentsOfURL:self.currentSlide];
		// The following might return a nil pointer if the file is not an Apple II graphic
		// or it had been assigned the wrong ProDOS file & auxiliary types.
		Apple2Graphic *graphic = [[[Apple2Graphic alloc] initWithData:fileData
														  graphicType:type
													compressionMethod:method] autorelease];
		// This might be nil if Apple2Graphic object was not instantiated.
		NSImage *image = [graphic colorImage];
		// Ask our SlideshowView to transition to the image.
		// if image is nil, a black background will be displayed.
		[self.slideshowView transitionToImage:image];
	}
	else 
    {
		[self.slideshowView transitionToImage:noPic];
	}

	NSUInteger count = [self.urls count];
	NSString *wTitle = [NSString stringWithFormat:@"%u of %u", currentSlideNumber, count];
	[[self window] setTitle:wTitle];
}

/*
 The parameter "timer" is part of the required signature of the selector advanceSlideshow:
 */
- (void)advanceSlideshow:(NSTimer *)timer
{
	NSUInteger count = [self.urls count];
	if (self.urls != nil && count > 0 && [[self window] isVisible])
    {
		if (currentSlideNumber == count)
        {
			currentSlideNumber = 1;
		}
		else
        {
			currentSlideNumber++;
		}
		[self showSlide];
	}
}

- (void)rewindSlideshow:(NSTimer *)timer
{
	NSUInteger count = [self.urls count];
	if (self.urls != nil && count > 0 && [[self window] isVisible]) 
    {
		if (currentSlideNumber == 1) 
        {
			currentSlideNumber = count;
		}
		else
        {
			currentSlideNumber--;
		}
		[self showSlide];
	}
}

- (void)startSlideshowTimer
{
	if (slideshowTimer == nil && [self currentDelayAmount] > 0.0)
    {
		// Schedule an ordinary NSTimer that will invoke -advanceSlideshow: at regular intervals,
		// each time we need to advance to the next slide.
		self.slideshowTimer = [NSTimer scheduledTimerWithTimeInterval:self.currentDelayAmount
															   target:self
															 selector:@selector(advanceSlideshow:)
															 userInfo:nil
															  repeats:YES];
		self.isSlideshowRunning = YES;
		NSImage *newImage = [NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate];
		[self.mediaControls setImage:newImage
						  forSegment:1];
	}
}

- (void)stopSlideshowTimer
{
	if (self.slideshowTimer != nil) 
    {
		// Cancel and release the slideshow advance timer.
		[self.slideshowTimer invalidate];
		self.slideshowTimer = nil;
		self.isSlideshowRunning = NO;
		NSImage *newImage = [NSImage imageNamed:NSImageNameSlideshowTemplate];
		[self.mediaControls setImage:newImage
						  forSegment:1];
	}
}


// NSSlider Value section Bind to File Owner 
- (NSTimeInterval)slideshowInterval
{
	return currentDelayAmount;
}

- (void)setSlideshowInterval:(NSTimeInterval)newSlideshowInterval
{
	if (self.currentDelayAmount != newSlideshowInterval)
    {
		// Stop the slideshow, change the interval as requested, and then restart the slideshow (if it was running already).
		[self stopSlideshowTimer];
		if (newSlideshowInterval == 0.0) 
        {
			newSlideshowInterval = minDelayAmount;
		}
		self.currentDelayAmount = newSlideshowInterval;
		[self.slideshowView updateSubviewsTransition:self.currentDelayAmount];
		[self startSlideshowTimer];
	}
}

/*
 Handle clicks on the segmented control.
 */
- (IBAction)handleMediaControls:(id)sender
{
	NSInteger whichSegment = [self.mediaControls selectedSegment];
	if (whichSegment == 1)
    {
		if (!self.isSlideshowRunning)
        {
			[self startSlideshowTimer];
		}
		else
        {
			[self stopSlideshowTimer];
		}
	}
	else if (whichSegment == 0)
    {
		[self rewindSlideshow:self.slideshowTimer];
	}
	else 
    {
		[self advanceSlideshow:self.slideshowTimer];
	}
}

/*
 Select files for the slide show.
 */
- (IBAction)handleOpen:(id)sender
{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setCanChooseFiles:YES];
	[oPanel setCanChooseDirectories:NO];
	[oPanel setAllowsMultipleSelection:YES];
	[oPanel setTitle:@"Slides"];
	NSInteger buttonID = [oPanel runModal];
	if (buttonID == NSFileHandlingPanelOKButton)
    {
		self.urls = [oPanel URLs];
		currentSlideNumber = 1;
		// We must show the first slide for advance/rewind to work properly.
		[self showSlide];
	}
}

@end
