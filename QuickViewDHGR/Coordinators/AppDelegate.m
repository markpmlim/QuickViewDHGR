//
//  AppDelegate.m
//  QuickViewDHGR
//
//  Created by mark lim on 2/13/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import "AppDelegate.h"
#import "Apple2Graphic.h"
#import "MainWindowController.h"
#import "SlideshowWindowController.h"
#include "UserDefines.h"

@implementation AppDelegate
@synthesize tempWorkingDir;
@synthesize mainWinController;
@synthesize slideshowWinController;
@synthesize fileTypeView;
@synthesize changeFileTypeTag;

- (id)init
{
	//NSLog(@"min version:%d", __MAC_OS_X_VERSION_MIN_REQUIRED);
	if (NSAppKitVersionNumber < 1038) 
    {
		// Pop up a warning dialog, 
		NSRunAlertPanel(@"Sorry, this program requires Mac OS X 10.6 or later", @"You are running %@", 
						@"OK", nil, nil, [[NSProcessInfo processInfo] operatingSystemVersionString]);

		// then quit the program
		[NSApp terminate:self]; 
	}

	self = [super init];
	if (self)
    {
		// These 2 functions must be called before the method application:openFiles:
		GenerateBaseOffsets();
		GenerateColorTables();
		mainWinController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"];
	}
	return self;
}

- (void)dealloc
{
	if (fileTypeView != nil)
    {
		[fileTypeView release];
		fileTypeView = nil;
	}
	if (mainWinController != nil)
    {
		[mainWinController release];
		mainWinController = nil;
	}
	if (slideshowWinController != nil)
    {
		[slideshowWinController release];
		slideshowWinController = nil;
	}
	if (tempWorkingDir != nil)
    {
		[tempWorkingDir release];
		tempWorkingDir = nil;
	}
	[super dealloc];
}


// Our working directory for promised files.
- (NSString *)uniqueTemporaryDirectory
{
    NSString *basePath = NSTemporaryDirectory();
    NSString *tempDir = [basePath stringByAppendingPathComponent:@"QuickViewDHGR"];
	NSFileManager *fmgr = [NSFileManager defaultManager];
	NSError *outErr;
	BOOL isDir;
	BOOL exists = [fmgr fileExistsAtPath:tempDir
							 isDirectory:&isDir];
	if (!exists)
    {
		[fmgr createDirectoryAtPath:tempDir
		withIntermediateDirectories:YES
						 attributes:nil
							  error:&outErr];
	}
	else
    {
		// Remove any leftover files and sub-directories from previous runs.
		NSDirectoryEnumerator *dirEnum = [fmgr enumeratorAtPath: tempDir];
		NSString *name;
		while (name = [dirEnum nextObject]) 
        {
			// No need to remove the leaves first!
			NSString *itemPath = [tempDir stringByAppendingPathComponent:name];
			//NSLog(@"removing:%@", itemPath);
			[fmgr removeItemAtPath:itemPath
							 error:&outErr];
		}
	}
	return tempDir;
}

/*
 The application is now running.
 */
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	[self.mainWinController showWindow:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.changeFileTypeTag = 2;			// FOT/$4000
	self.tempWorkingDir = [self uniqueTemporaryDirectory];
	self.slideshowWinController = [[[SlideshowWindowController alloc] initWithWindowNibName:@"SlideshowWindow"] autorelease];
}

/*
 If the user started up the application by double-clicking a file, the 
 application delegate will receive the message application:openFile:  
 before receiving the message applicationDidFinishLaunching:.
 On the other hand, the method applicationWillFinishLaunching: will be
 called before the method application:openFile:.
 */
- (void)application:(NSApplication *)sender
          openFiles:(NSArray *)filenames
{
	NSString *filename = [filenames objectAtIndex:0];
	NSURL *url = [NSURL fileURLWithPath:filename];
	// Note: GenerateBaseOffsets & GenerateColorTables must be called before
	// the method below.
	GraphicType type;
	CompressionAlgorithm method;
	BOOL success = [self isApple2GraphicAtURL:url
								  graphicType:&type
							compressionMethod:&method];
	if (success) 
    {
		success = [self.mainWinController displayImageAtURL:url
												graphicType:type
										  compressionMethod:method];
	}
	[NSApp replyToOpenOrPrint:success ? NSApplicationDelegateReplySuccess : NSApplicationDelegateReplyFailure];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
    return YES;
}

// This method is called after `applicationShouldTerminateAfterLastWindowClosed`
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Delete the temporary directory.
    NSError *err = nil;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    [fileMgr removeItemAtPath:self.tempWorkingDir
                        error:&err];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)menuItem
{
	BOOL result = NO;
	SEL theAction = [menuItem action];
	if (theAction == @selector(openSlideshowWindow:)) 
    {
		result = YES;
	}
	else if (theAction == @selector(changeFileType:)) 
    {
		result = YES;
	}
	else if (theAction == @selector(openHelpWindow:)) 
    {
		result = YES;
	}
	return result;
}

/*
 Launch TextEdit and show the contents of Readme.rtf
 */
- (IBAction)openHelpWindow:(id)sender
{
	NSString *fullPathname;
	fullPathname = [[NSBundle mainBundle] pathForResource:@"Readme"
												   ofType:@"rtfd"];
	[[NSWorkspace sharedWorkspace] openFile:fullPathname];
}

- (IBAction)openSlideshowWindow:(id)sender
{
	NSWindow *win = [self.slideshowWinController window];
	if (![win isVisible])
    {
		[self.slideshowWinController showWindow:self];
	}
}


- (BOOL)validateHiresSize:(NSUInteger)size
{
	return (size >= minHiResFileSize && size <= maxHiResFileSize);
}

- (BOOL)validateDoubleHiresSize:(NSUInteger)size
{
	return (size >= minDoubleHiResFileSize && size <= maxDoubleHiResFileSize);
}



/*
 Note: if returned result is YES, the type is set.
 */
- (BOOL)isApple2GraphicAtURL:(NSURL *)url
                 graphicType:(GraphicType *)type
           compressionMethod:(CompressionAlgorithm *)algorithm
{
	BOOL result = NO;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *outErr = nil;
	NSDictionary *attr = [fm attributesOfItemAtPath:url.path
											  error:&outErr];
	unsigned long long fileSize = [attr fileSize];
	OSType typeCode = [attr fileHFSTypeCode];
	OSType creatorCode = [attr fileHFSCreatorCode];
	uint16_t fileType = (typeCode & 0x00ff0000) >> 16;
	uint16_t auxType = typeCode & 0x0000ffff;

	// For A2FC, DHGR and HGR w/o Finder Info
	if (creatorCode == 0x00000000) 
    {
		NSData *fileContents = [NSData dataWithContentsOfURL:url];
		NSUInteger fileSize = [fileContents length];
		//printf("No Creator Code\n");
		// This checks for files which don't have any ProDOS file type info.
		// If LZ4 file has no assigned ProDOS file/aux types, then it does not have
		// any FinderInfo.
		if ([self validateHiresSize:fileSize])
        {
			*type = kStdHiRes;
			*algorithm = kNoCompression;
			result = YES;
			goto bailOut;
		}
		else if ([self validateDoubleHiresSize:fileSize])
        {
			*type = kDoubleHiRes;
			*algorithm = kNoCompression;
			result = YES;
			goto bailOut;
		}
		else if ([Apple2Graphic isHires:fileContents
					  compressionMethod:algorithm])
        {
			*type = kStdHiRes;
			result = YES;
			goto bailOut;
		}
		else if ([Apple2Graphic isDoubleHires:fileContents
							compressionMethod:algorithm])
        {
			*type = kDoubleHiRes;
			result = YES;
			goto bailOut;
		}
		else
        {
			goto bailOut;
		}
	}

	// For files created by ProDOS, the file type must either be FOT or BIN.
	// FOT files must have their aux types set correctly.
	// The aux type of BIN files can take any value $0000-$FFFF.
	if (creatorCode == 'pdos')
    {
		// Files that have ProDOS file type FOT($08).
		// If the files have been compressed with LZ4 or PackBytes, further checks
		// must be made since these files need to be inflated first.
		// This code here assumes the aux type of such files are correctly set.
		if (fileType == kTypeFOT)
        {
			if (auxType == kFOTPackedHGR)
            {
				*algorithm = kPakCompression;
				*type = kStdHiRes;
				result = YES;
			}
			else if (auxType == kFOTPackedDHGR)
            {
				*algorithm = kPakCompression;
				*type = kDoubleHiRes;
				result = YES;
			}
			else if (auxType == kFOTLZ4HGR)
            {
                // KIV: to remove ProDOS auxtype for LZ4
				*algorithm = kLZ4Compression;
				*type = kStdHiRes;
				result = YES;
			}
			else if (auxType == kFOTLZ4DHGR)
            {
                // KIV: to remove ProDOS auxtype for LZ4
				*algorithm = kLZ4Compression;
				*type = kDoubleHiRes;
				result = YES;
			}
            else if (auxType == kFOTLZ4FH) 
            {
				*algorithm = kLZ4FHCompression;
				*type = kStdHiRes;
				result = YES;
			}
			else if (auxType < kFOTPackedHGR) 
            {
				// $0000..$3FFF: these are uncompressed files so we can do
				// a simple check on their file size.
				if ([self validateHiresSize:fileSize]) 
                {
					*algorithm = kNoCompression;
					*type = kStdHiRes;
					result = YES;
				}
				else if ([self validateDoubleHiresSize:fileSize])
                {
					*algorithm = kNoCompression;
					*type = kDoubleHiRes;
					result = YES;
				}
				else 
                {
					// The file size is invalid.
					goto bailOut;
				}
			}
		}
		else if (fileType == kTypeBIN) 
        {
			NSData *fileContents = [NSData dataWithContentsOfURL:url];
			if ([self validateHiresSize:fileSize])
            {
				*algorithm = kNoCompression;
				*type = kStdHiRes;
				result = YES;
			}
			else if ([self validateDoubleHiresSize:fileSize])
            {
				*algorithm = kNoCompression;
				*type = kDoubleHiRes;
				result = YES;
			}
			else if ([Apple2Graphic isHires:fileContents
						  compressionMethod:algorithm])
            {
                // KIV: support for compressed BIN files? 
				*type = kStdHiRes;
				result = YES;
				goto bailOut;
			}
			else if ([Apple2Graphic isDoubleHires:fileContents
								compressionMethod:algorithm])
            {
                // KIV: support for compressed BIN files?
				*type = kDoubleHiRes;
				result = YES;
				goto bailOut;
			}
			else
            {
				goto bailOut;
			}
		}
	}
	// For files which have creator codes but are not created by ProDOS,
	// the returned result should be NO.
bailOut:
	return result;
}

/*
 Bug in 10.10.x - NSTabView can not unregister ALL drag types.
 Workaround: Sub-class of NSTabView must declare it can accept file drops.

 Bug in 10.12.x - sub-class of NSTabView can not register drag types.
 Underlying window must be declared as able to accept file drops.
 */
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	MainWindowController *wc = self.mainWinController;
	BOOL result;
	NSPasteboard *pb = [sender draggingPasteboard];
	if ([[pb types] containsObject:NSURLPboardType])
    {
		NSURL *fileURL = [NSURL URLFromPasteboard:pb];
		GraphicType type;
		CompressionAlgorithm method;
		result = [self isApple2GraphicAtURL:fileURL
								graphicType:&type
						  compressionMethod:&method];
		if (result == YES) {
			result = [wc displayImageAtURL:fileURL
							   graphicType:type
						 compressionMethod:method];
		}
	}
	else if ([[pb types] containsObject:NSFilesPromisePboardType]) 
    {
		AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
		NSString *tempDir = [appDelegate tempWorkingDir];
		NSURL *tmpURL = [NSURL fileURLWithPath:tempDir];
		wc.promisedFiles = [sender namesOfPromisedFilesDroppedAtDestination:tmpURL];

        // Slight delay so the promised files are copied to temp dir.
		NSRunLoop *currRunLoop = [NSRunLoop currentRunLoop];
		NSDate *limitDate = [[[NSDate alloc] initWithTimeIntervalSinceNow:0.05] autorelease];
		[currRunLoop runUntilDate:limitDate];

		if (wc.promisedFiles == nil)
        {
			// Handles the case where the another Application is slow returning the promisedFiles array.
			NSFileManager *fmgr = [NSFileManager defaultManager];
			NSError *outErr = nil;
			NSArray *filesOrFolders = [fmgr contentsOfDirectoryAtPath:tempDir
																error:&outErr];
			if (outErr != nil || [filesOrFolders count] == 0)
            {
				// Either an error encountered or nothing there
				result = NO;
			}
			wc.promisedFiles = filesOrFolders;
		}

		if ([wc.promisedFiles count] == 1) 
        {
			// Only interested in 1 file.
			// Anything further todo with the names of the promised files
			// which are the last component of their pathnames/URLs?
			result = YES;
		}
	}
	else 
    {
		result = NO;
	}
	return result;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
	MainWindowController *wc = self.mainWinController;
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSArray *types = [pboard types];
	if ([types containsObject:NSFilesPromisePboardType]) 
    {
		NSString *name = [wc.promisedFiles objectAtIndex:0];
		AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
		NSString *tempDir = [appDelegate tempWorkingDir];
		NSString *itemPath = [tempDir stringByAppendingPathComponent:name];

		// Hopefully, there is something at the drop location.
		NSFileManager *fmgr = [NSFileManager defaultManager];
		NSError *outErr;
		BOOL isDir;
		BOOL exists = [fmgr fileExistsAtPath:itemPath
								 isDirectory:&isDir];
		if (!exists)
        {
			//NSLog(@"%@ had not been copied", itemPath);
			NSRunAlertPanel(@"File Reading Error", 
							@"Sorry, the file is not available yet",
							nil, nil, nil);
			return;
		}

		// Ensure it's not a folder
		if (exists && isDir)
        {
			// Remove the dir!
			NSLog(@"Remove the dir item:");
			NSRunAlertPanel(@"File Reading Error", 
							@"Sorry, you must dropped a file not a folder",
							nil, nil, nil);
		}
		else 
        {
			NSURL *fileURL = [NSURL fileURLWithPath:itemPath];
			GraphicType type;
			CompressionAlgorithm method;
			BOOL result = [self isApple2GraphicAtURL:fileURL
										 graphicType:&type
								   compressionMethod:&method];
			if (result == YES)
            {
				result = [wc displayImageAtURL:fileURL
								   graphicType:type
							 compressionMethod:method];
			}
		}
		[fmgr removeItemAtPath:itemPath
						 error:&outErr];
	}
}

/*
 Perform on secondary thread. 
 Put up a progress window?
 */
- (IBAction)changeFileType:(id)sender
{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setCanChooseFiles:YES];
	[oPanel setCanChooseDirectories:NO];
	[oPanel setAllowsMultipleSelection:YES];
	[oPanel setAccessoryView:self.fileTypeView];
	[oPanel setTitle:@"Change"];
    [oPanel setPrompt:@"Proceed"];    
	NSInteger buttonID = [oPanel runModal];
	if (buttonID == NSFileHandlingPanelOKButton)
    {
		NSArray *urls = [oPanel URLs];
		uint16_t fileType = 0;
		uint16_t auxType = 0;
		switch (self.changeFileTypeTag)
        {
            case 0:
                fileType = kTypeBIN;
                break;
            case 1:
                fileType = kTypeFOT;
                break;
            case 2:
                fileType = kTypeFOT;
                auxType  = kFOTPackedHGR;
                break;
            case 3:
                fileType = kTypeFOT;
                auxType  = kFOTPackedDHGR;
                break;
            case 4:
                fileType = kTypeFOT;
                auxType  = kFOTLZ4HGR;
                break;
            case 5:
                fileType = kTypeFOT;
                auxType  = kFOTLZ4DHGR;
                break;
            case 6:
                fileType = kTypeFOT;
                auxType  = kFOTLZ4FH;
                break;
            default:
                // typeless
                break;
		}

		OSType creatorCode  = 'pdos';
		OSType fileTypeCode = 0x70000000 + (fileType<<16) + auxType;
		NSFileManager *fileManager = [NSFileManager defaultManager];

        // Requires macOS 10.6 or later. 
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        size_t count = urls.count;
        // Instead of a for-loop, use a GCD dispatch queue.
        dispatch_apply(count, queue, ^(size_t index) {
            //KIV. Should a progress window controller be added?
            // Changing the file and auxilliary types is not time-consuming.
            NSError *errOut = nil;
            NSURL *url = [urls objectAtIndex:index];
			NSString *path = [url path];
			NSDictionary *fileAttr = [fileManager attributesOfItemAtPath:path
																   error:&errOut];
			NSMutableDictionary *newFileAttr = [NSMutableDictionary dictionary];
			[newFileAttr addEntriesFromDictionary:fileAttr];
			[newFileAttr setObject:[NSNumber numberWithUnsignedInt:fileTypeCode]
							forKey:NSFileHFSTypeCode];
			[newFileAttr setObject:[NSNumber numberWithUnsignedInt:creatorCode]
							forKey:NSFileHFSCreatorCode];
			[fileManager setAttributes:newFileAttr
						  ofItemAtPath:path
								 error:&errOut];
        });
	}
}
@end
