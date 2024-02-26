#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#import <Cocoa/Cocoa.h>
#include <QuickLook/QuickLook.h>
#import "Apple2Graphic.h"
#import "Apple2Graphic_DoubleHires.h"
#import "Apple2Graphic_Hires.h"
#include "UserDefines.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface,
							   QLPreviewRequestRef preview,
							   CFURLRef url,
							   CFStringRef contentTypeUTI,
							   CFDictionaryRef options)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//NSString *path = [(NSURL *)url path];
	//NSLog(@"path to file:%@", (NSURL *)url);
	GenerateBaseOffsets();
	GenerateColorTables();
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *outErr = nil;
	NSDictionary *attr = [fm attributesOfItemAtPath:[(NSURL *)url path]
											  error:&outErr];

	if (outErr == nil) {
		// Only plain (uncompressed) files supported.
		CompressionAlgorithm method = kNoCompression;
		unsigned long long fileLen = [[attr objectForKey:NSFileSize] unsignedLongLongValue];
		GraphicType type;
		if (fileLen >= minDoubleHiResFileSize &&
            fileLen <= maxDoubleHiResFileSize) {
			type = kDoubleHiRes;
		}
		else {
			type = kStdHiRes;
		}

		NSData *fileData = [NSData dataWithContentsOfURL:(NSURL *)url];
        if (fileData != nil) {
            Apple2Graphic *graphic = [[[Apple2Graphic alloc] initWithData:fileData
                                                              graphicType:type
                                                        compressionMethod:method] autorelease];
            if (graphic != nil) {
                CGImageRef image;
                if (graphic.subGraphicType == kStdHiResColor ||
                    graphic.subGraphicType == kDoubleHiResColor) {
                    image = [graphic colorCGImage];
                }
                else {
                    image = [graphic bwCGImage];
                }

                CGSize size = CGSizeMake(CGImageGetWidth(image)/2,
                                         CGImageGetHeight(image)/2);
                CGContextRef ctxt = QLPreviewRequestCreateContext(preview, size, true, nil);
                CGContextDrawImage(ctxt,
                                   CGRectMake(0, 0,
                                              size.width, size.height), image);
                QLPreviewRequestFlushContext(preview, ctxt);
                CGContextRelease(ctxt);
            } // graphic not nil
        } // fileData not nil
	}
	[pool drain];
	return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
