//
//  Apple2Graphic.h
//  QuickViewDHGR
//
//  Created by mark lim on 3/8/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "UserDefines.h"

@interface Apple2Graphic : NSObject
{
	NSURL				*imageURL;		// not used

	NSData				*fileContents;
	GraphicType			graphicType;
	AppleIIGraphicType	subGraphicType;
	u_int32_t			pixelWidth;
	u_int32_t			pixelHeight;
}

@property (assign) AppleIIGraphicType subGraphicType;
@property (assign) u_int32_t pixelWidth;
@property (assign) u_int32_t pixelHeight;

// Public methods
+ (BOOL)isDoubleHires:(NSData *)fileData
    compressionMethod:(CompressionAlgorithm *)algorithm;

+ (BOOL)isHires:(NSData *)fileData
compressionMethod:(CompressionAlgorithm *)algorithm;

- (id)initWithData:(NSData *)fileData
       graphicType:(GraphicType)type
 compressionMethod:(CompressionAlgorithm)algorithm;

- (CGImageRef)colorCGImage;
- (CGImageRef)bwCGImage;
/*
 These should return an autoreleased object.
 */
- (NSImage *)colorImage;
- (NSImage *)monoChromeImage;
- (NSImage *)colorImage2x;
- (NSImage *)monoChromeImage2x;

@end
