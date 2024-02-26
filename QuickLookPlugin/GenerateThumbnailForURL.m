#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import "Apple2Graphic.h"
//#import "Apple2HiresGraphic.h"
//#import "Apple2DoubleHiresGraphic.h"
#include "UserDefines.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface,
								 QLThumbnailRequestRef thumbnail,
								 CFURLRef url,
								 CFStringRef contentTypeUTI,
								 CFDictionaryRef options,
								 CGSize maxSize)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
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
	/*
		Apple2Graphic *graphic;
		if (fileLen >= minDoubleHiResFileSize && fileLen <= maxDoubleHiResFileSize) {
			graphic = [[[Apple2DoubleHiresGraphic alloc] initWithURL:(NSURL *)url] autorelease];
		}
		else if (fileLen >= 8184 && fileLen <= 8193) {
			graphic = [[[Apple2HiresGraphic alloc] initWithURL:(NSURL *)url] autorelease];
		}
		else {
			graphic = nil;
		}
	*/
		GraphicType type;
		if (fileLen >= minDoubleHiResFileSize && fileLen <= maxDoubleHiResFileSize) {
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
 
                if (graphic.subGraphicType == kStdHiResColor || graphic.subGraphicType == kDoubleHiResColor) {
                    image = [graphic colorCGImage];
                }
                else {
                    image = [graphic bwCGImage];
                }

                CGSize size = CGSizeMake(CGImageGetWidth(image)/2,
                                         CGImageGetHeight(image)/2);
                CGContextRef ctxt = QLThumbnailRequestCreateContext(thumbnail,
                                                                    size,
                                                                    true,		// isBitmap
                                                                    nil);		// properties (dict)
                
                CGContextDrawImage(ctxt,
                                   CGRectMake(0, 0,
                                              size.width, size.height), image);
                QLThumbnailRequestFlushContext(thumbnail, ctxt);
                CGContextRelease(ctxt);
            }
        }
	}

	[pool drain];
	return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
