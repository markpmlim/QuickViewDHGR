//
//  Apple2Graphic.m
//  QuickViewDHGR
//
//  Created by mark lim on 3/8/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import "Apple2Graphic.h"
#import "Apple2Graphic_Hires.h"
#import "Apple2Graphic_DoubleHires.h"
#import "Decoder.h"

@implementation Apple2Graphic
@synthesize subGraphicType;
@synthesize pixelWidth;
@synthesize pixelHeight;

/*
 This method is called for both plain and compressed files.
 The parameter "fileData" is the contents of the file itself.
 */
+ (BOOL)isDoubleHires:(NSData *)fileData
    compressionMethod:(CompressionAlgorithm *)algorithm
{
	NSUInteger fileSize = [fileData length];
	NSData *unpackedData = nil;
	BOOL result = NO;
	if (fileSize >= minDoubleHiResFileSize && fileSize <= maxDoubleHiResFileSize)
    {
		*algorithm = kNoCompression;
		result = YES;
		goto done;
	}

	if ((unpackedData = [Decoder lz4Expand:fileData]) != nil)
    {
		fileSize = [unpackedData length];
		if (fileSize >= minDoubleHiResFileSize && fileSize <= maxDoubleHiResFileSize) 
        {
			*algorithm = kLZ4Compression;
			result = YES;
			goto done;
		}
	}

	// unpackBytes never returns a nil
	unpackedData = [Decoder unpackBytes:fileData];
	{
		fileSize = [unpackedData length];
		if (fileSize >= minDoubleHiResFileSize && fileSize <= maxDoubleHiResFileSize)
        {
			*algorithm = kPakCompression;
			result = YES;
		}
	}

done:
	return result;
}

/*
 This method is called for both plain and compressed files.
 */
+ (BOOL)isHires:(NSData *)fileData
compressionMethod:(CompressionAlgorithm *)algorithm;
{
	NSUInteger fileSize = [fileData length];
	NSData *unpackedData = nil;
	BOOL result = NO;
	uint8_t *srcPtr = (uint8_t *)[fileData bytes];

	if (*srcPtr == 0x66)
    {
		*algorithm = kLZ4FHCompression;
		result = YES;
		goto done;
	}

	if (fileSize >= minHiResFileSize && fileSize <= maxHiResFileSize)
    {
		// Maybe
		*algorithm = kNoCompression;
		result = YES;
		goto done;
	}

	if ((unpackedData = [Decoder lz4Expand:fileData]) != nil)
    {
		fileSize = [unpackedData length];
		if (fileSize >= minHiResFileSize && fileSize <= maxHiResFileSize)
        {
			*algorithm = kLZ4Compression;
			result = YES;
			goto done;
		}
	}

	unpackedData = [Decoder unpackBytes:fileData];
	{
		fileSize = [unpackedData length];
		if (fileSize >= minHiResFileSize && fileSize <= maxHiResFileSize) 
        {
			*algorithm = kPakCompression;
			result = YES;
		}
	}

done:
	return result;
}

- (BOOL)validateSize:(NSUInteger)size
{
	return ((size >= minDoubleHiResFileSize && size <= maxDoubleHiResFileSize) ||
			(minHiResFileSize >= 8184 && size <= maxHiResFileSize));
}

- (BOOL)validateHiresSize:(NSUInteger)size
{
	return (size >= minHiResFileSize && size <= maxHiResFileSize);
}

- (BOOL)validateDoubleHiresSize:(NSUInteger)size
{
	return (size >= minDoubleHiResFileSize && size <= maxDoubleHiResFileSize);
}


- (NSData *)inflatePackBytes:(NSData *)packedData
{
	//NSLog(@"inflatePackBytes");
	return [Decoder unpackBytes:packedData];
}


- (NSData *)inflateLZ4:(NSData *)packedData
{
	return [Decoder lz4Expand:packedData];
}

- (NSData *)inflateLZ4FH:(NSData *)packedData
{
	return [Decoder lz4fhExpand:packedData];
}



/*
 The plugin must decide whether to instantiate a Mac OS X CGImage object
 from a std HiRes or from a Double Hires graphic.
 To do that it must find out
 
 a) the size of file if it is a plain file

 b) the size of the inflated data if it a compressed file (LZ4, PackBytes) 

 A file compressed with PackBytes will have be $08/$4000 or $08/$4001
 A file compressed with LZ4 will have be $08/$???? or $08/$????
 
 Once the size of the data is known then only can we call the
 correct method. 

 */
- (id)initWithURL:(NSURL *)url
{
	self = [super init];
	if (self != nil) 
    {
		imageURL = [url retain];
		// Don't retain the object yet.
		NSData *dataContents = [NSData dataWithContentsOfURL:imageURL];
        if (dataContents == nil)
        {
            [imageURL release];
			[self release];
            self = nil;
            goto bailOut;
        }

		NSFileManager *fm = [NSFileManager defaultManager];
		NSError *outErr = nil;
		NSDictionary *attr = [fm attributesOfItemAtPath:url.path
												  error:&outErr];
		OSType typeCode = [attr fileHFSTypeCode];
		uint16_t fileType = (typeCode & 0x00ff0000) >> 16;
		uint16_t auxType = typeCode & 0x0000ffff;
		NSString *fileExt = [[url.path pathExtension] uppercaseString];
		BOOL isPakCompressed = [fileExt isEqualToString:@"PAK"];
		BOOL isLZ4Compressed = [fileExt isEqualToString:@"LZ4"];

		if (fileType == kTypeFOT)
        {
			// Handles files with have the ProDOS type $08(FOT).
			// This includes files with suffixes LZ4 and PAK which also have
			// appropriate ProDOS file/aux types.
			if (auxType == kFOTPackedHGR || auxType == kFOTPackedDHGR)
            {
				printf("File is FOT - Packbytes compressed\n");
				NSData *unpackedData = [self inflatePackBytes:dataContents];
				if ([self validateSize:[unpackedData length]])
                {
					fileContents = [unpackedData retain];
				}
			}
			else if (auxType <= 0x3FFF) 
            {
				// Plain (uncompressed) files.
				NSUInteger fileSize = [dataContents length];
				if ([self validateSize: fileSize]) {
					printf("file is not compressed\n");
					fileContents = [dataContents retain];
				}
				else 
                {
					fileContents = nil;
				}
			}
		}
		else if (isLZ4Compressed == YES) 
        {
			NSData *unpackedData = [self inflateLZ4:dataContents];
			if ([self validateSize:[unpackedData length]]) {
				fileContents = [unpackedData retain];
			}
		}
		else if (isPakCompressed == YES)
        {
			NSData *unpackedData = [self inflatePackBytes:dataContents];
			if ([self validateSize:[unpackedData length]]) 
            {
				fileContents = [unpackedData retain];
			}
		}
		else if (fileType == kTypeBIN) 
        {
			// Only plain (uncompressed) BINary files are handled.
			NSUInteger fileSize = [dataContents length];
			if ([self validateSize: fileSize]) 
            {
				fileContents = [dataContents retain];
			} 
            else 
            {
				fileContents = nil;
			}
		}
		else
        {
			// Handles files with no ProDOS File and Aux types which
			// must be plain (uncompressed) files.
			NSUInteger fileSize = [dataContents length];
			if ([self validateSize: fileSize]) {
				fileContents = [dataContents retain];
			}
			else 
            {
				fileContents = nil;
			}
		}

		if (fileContents != nil)
        {
			u_int8_t *pixelData = (u_int8_t *)[fileContents bytes];
			u_int8_t graphicMode = pixelData[0x78];
			if (graphicMode == 0 || graphicMode == 4)
            {
				subGraphicType = kStdHiResBW;
				pixelWidth = 280;
				pixelHeight = 192;
			}
			else if (graphicMode == 1 || graphicMode == 5)
            {
				subGraphicType = kStdHiResColor;
				pixelWidth = 140;
				pixelHeight = 192;
			}
			else if (graphicMode == 2 || graphicMode == 6) 
            {
				subGraphicType = kDoubleHiResBW;
				pixelWidth = 560;
				pixelHeight = 192;
			}
			else if (graphicMode == 3 || graphicMode == 7)
            {
				subGraphicType = kDoubleHiResColor;	// full colors
				pixelWidth = 140;
				pixelHeight = 192;
			}
			else {
				// KIV. Problem: if value is not 0-7, no instantiation allowed.
				// Use the size to determine the default values.
				NSUInteger size = [fileContents length];
				if (size >= 16376 && size <= 16384) 
                {
					//NSLog(@"Double HiRes");
					subGraphicType = kDoubleHiResColor;	// full colors
					pixelWidth = 140;
					pixelHeight = 192;
				}
				else if (size >= 8184 && size <= 8193) 
                {
					//NSLog(@"Standard HiRes");
					subGraphicType = kStdHiResColor;
					pixelWidth = 140;
					pixelHeight = 192;
				}
				else 
                {
					// Definitely not an AppleII Hires/Double Hires file
					//NSLog(@"Don't know what it is!");
					[imageURL release];
					[fileContents release];
					[self release];
					self = nil;
				}
			}
		}
		else 
        {
            // fileContents is nil
			[imageURL release];
			[self release];
			self = nil;
		}
	}

bailOut:
	return self;
}

/*
 This is the designated initializer.
 The GraphicType and CompressionAlgorithm must be known.
 */
- (id)initWithData:(NSData *)fileData
       graphicType:(GraphicType)type
 compressionMethod:(CompressionAlgorithm)algorithm
{
	self = [super init];
	if (self != nil) 
    {
		graphicType = type;
		if (graphicType == kStdHiRes)
        {
			if (algorithm == kLZ4Compression)
            {
				fileContents = [[self inflateLZ4:fileData] retain];
			}
			else if (algorithm == kPakCompression)
            {
				fileContents = [[self inflatePackBytes:fileData] retain];
			}
			else if (algorithm == kLZ4FHCompression)
            {
				fileContents = [[self inflateLZ4FH:fileData] retain];
			}
			else
            {
				// no compression
				fileContents = [fileData retain];
			}
			if ([self validateHiresSize: [fileContents length]] == NO) 
            {
				[fileContents release];
				fileContents = nil;
			}
		}
		else if (graphicType == kDoubleHiRes)
        {
			if (algorithm == kLZ4Compression)
            {
				fileContents = [[self inflateLZ4:fileData] retain];
			}
			else if (algorithm == kPakCompression) 
            {
				fileContents = [[self inflatePackBytes:fileData] retain];
			}
			else {
				// no compression
				fileContents = [fileData retain];
			}
			if ([self validateDoubleHiresSize:[fileContents length]] == NO)
            {
				[fileContents release];
				fileContents = nil;
			}
		}

		if (fileContents != nil)
        {
			u_int8_t *pixelData = (u_int8_t *)[fileContents bytes];
			u_int8_t graphicMode = pixelData[0x78];
			//printf("graphic mode:%u\n", graphicMode);
			if (graphicMode == 0 || graphicMode == 4)
            {
				subGraphicType = kStdHiResBW;
				pixelWidth = 280;
				pixelHeight = 192;
			}
			else if (graphicMode == 1 || graphicMode == 5)
            {
				subGraphicType = kStdHiResColor;
				pixelWidth = 140;
				pixelHeight = 192;
			}
			else if (graphicMode == 2 || graphicMode == 6)
            {
				subGraphicType = kDoubleHiResBW;
				pixelWidth = 560;
				pixelHeight = 192;
			}
			else if (graphicMode == 3 || graphicMode == 7)
            {
				subGraphicType = kDoubleHiResColor;	// full colors
				pixelWidth = 140;
				pixelHeight = 192;
			}
			else {
				// KIV. Problem: if value is not 0-7, no instantiation allowed.
				// Use the size to determine the default values.
				NSUInteger size = [fileContents length];
				if ([self validateDoubleHiresSize:size]) 
                {
					//NSLog(@"Double HiRes");
					subGraphicType = kDoubleHiResColor;	// full colors
					pixelWidth = 140;
					pixelHeight = 192;
				}
				else if ([self validateHiresSize:size])
                {
					//NSLog(@"Standard HiRes");
					subGraphicType = kStdHiResColor;
					pixelWidth = 140;
					pixelHeight = 192;
				}
				else 
                {
					// This branch might not be necessary.
					// Definitely not an AppleII Hires/Double Hires file
					//NSLog(@"Don't know what it is!");
					[fileContents release];
					[self release];
					self = nil;
				}
			}
		}
		else 
        {
			[self release];
			self = nil;
		}
	}
bailOut:
	return self;
}


- (void)dealloc
{
	//printf("deallocating Apple2Graphic\n");
	if (fileContents != nil)
    {
		[fileContents release];
		fileContents = nil;
	}
	if (imageURL != nil) 
    {
		[imageURL release];
		imageURL = nil;
	}
	[super dealloc];
}

// Methods to be overridden by the sub-classes Apple2HiresGraphic & Apple2DoubleHiresGraphic
- (CGImageRef)colorCGImage
{
	if (graphicType == kStdHiRes)
    {
		return [self hiresColorCGImage];
	}
	else if (graphicType == kDoubleHiRes)
    {
		return [self doubleHiresColorCGImage];
	}
	return NULL;
}

- (CGImageRef)bwCGImage
{
	if (graphicType == kStdHiRes)
    {
		return [self hiresMonoChromeCGImage];
	}
	else if (graphicType == kDoubleHiRes)
    {
		return [self doubleHiresMonoChromeCGImage];
	}
	return NULL;
}

- (NSImage *)monoChromeImage
{
	if (graphicType == kStdHiRes)
    {
		return [self hiresMonoChromeImage];
	}
	else if (graphicType == kDoubleHiRes)
    {
		return [self doubleHiresMonoChromeImage];
	}
	return nil;
}

- (NSImage *)monoChromeImage2x
{
	if (graphicType == kStdHiRes) 
    {
		return [self hiresMonoChromeImage2x];
	}
	else if (graphicType == kDoubleHiRes)
    {
		return [self doubleHiresMonoChromeImage2x];
	}
	return nil;
}

- (NSImage *)colorImage
{
	if (graphicType == kStdHiRes)
    {
		return [self hiresColorImage];
	}
	else if (graphicType == kDoubleHiRes)
    {
		return [self doubleHiresColorImage];
	}
	return nil;
}

- (NSImage *)colorImage2x
{
	if (graphicType == kStdHiRes)
    {
		return [self hiresColorImage2x];
	}
	else if (graphicType == kDoubleHiRes)
    {
		return [self doubleHiresColorImage2x];
	}
	return nil;
}

@end
