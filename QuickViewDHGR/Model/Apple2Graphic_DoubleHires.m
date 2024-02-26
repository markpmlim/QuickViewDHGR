//
//  Apple2Graphic_DoubleHires.m
//  QuickViewDHGR
//
//  Created by mark lim on 3/8/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import "Apple2Graphic.h"
#import "Apple2Graphic_DoubleHires.h"
#import "Decoder.h"
#import "NSImage+Conversion.h"

@implementation Apple2Graphic(DoubleHires)

- (u_int8_t)reverseBits:(u_int8_t)bitPattern
{
	u_int8_t newValue = 0;

	for (u_int8_t i=0; i<8; i++) 
    {
		if ((bitPattern & (1 << i)) != 0)
        {
			newValue |= (1 << (7-i));
		}
	}
	newValue >>= 4;
	return newValue;
}

- (NSData *)doubleHiresMonoChromeBitMapData
{
	unsigned char *bmBuf = malloc(560*3*384);	// 645,120 bytes
	u_int8_t *srcData = (u_int8_t *)[fileContents bytes];

	for (int row=0; row<192; row++)
    {
		u_int8_t dots[560];
		bzero(dots, 560);
		u_int16_t dotIndex = 0;
		u_int16_t lineOffset = baseOffsets[row];
		for (int col=0; col<80; col++)
        {
			u_int8_t value = 0;
			if ((col % 2) == 0x01) 
            {
				// dot in an odd column come from main mem.
				value = (srcData[0x2000+lineOffset+col/2]);
			}
			else 
            {
				// dot in an even column come from aux mem.
				value = (srcData[lineOffset+col/2]);
			}

			// Reverse the 7 bits
			for (int bit = 0; bit<7; bit++)
            {
				dots[dotIndex] = value & 0x01;
				dotIndex += 1;
				value >>= 1;
			}
		}

		u_int32_t evenIndex = 2 * row * 560 * 3;		// offset to even # line
		u_int32_t oddIndex = (2 * row + 1) * 560 * 3;	// offset to odd # line
														// Convert each line
		for (int k = 0; k<560; k++)
        {
			if (dots[k] == 0) 
            {
				bmBuf[evenIndex+3*k+0] = 0x00;			// even # line
				bmBuf[evenIndex+3*k+1] = 0x00;
				bmBuf[evenIndex+3*k+2] = 0x00;
				bmBuf[oddIndex+3*k+0]  = 0x00;			// odd # line
				bmBuf[oddIndex+3*k+1]  = 0x00;
				bmBuf[oddIndex+3*k+2]  = 0x00;
			}
			else 
            {
				bmBuf[evenIndex+3*k+0] = 0xff;
				bmBuf[evenIndex+3*k+1] = 0xff;
				bmBuf[evenIndex+3*k+2] = 0xff;
				bmBuf[oddIndex+3*k+0]  = 0xff;
				bmBuf[oddIndex+3*k+1]  = 0xff;
				bmBuf[oddIndex+3*k+2]  = 0xff;
			}
		}
	}
	NSData *bmData = [NSData dataWithBytes:bmBuf
									length:560*3*384];
	free(bmBuf);
	return bmData;
}

- (CGImageRef)doubleHiresMonoChromeCGImage
{
    // Let the system allocate memory
	NSBitmapImageRep *bir = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
																	 pixelsWide:560
																	 pixelsHigh:384
																  bitsPerSample:8
																samplesPerPixel:3
																	   hasAlpha:NO
																	   isPlanar:NO
																 colorSpaceName:NSDeviceRGBColorSpace
																	bytesPerRow:560 * 3				// 1 680
																   bitsPerPixel:24] autorelease];
	NSData *bmData = [self doubleHiresMonoChromeBitMapData];
	memcpy(bir.bitmapData, bmData.bytes, bmData.length);
	return [bir CGImage];			// Should have been set to autorelease
}

- (NSData *)doubleHiresColorBitMapData
{
	unsigned char *bmBuf = malloc(560*3*384);	// 645,120 bytes
	u_int8_t *srcData = (u_int8_t *)[fileContents bytes];

	for (int row=0; row<192; row++) 
    {
		u_int16_t lineOffset = baseOffsets[row];
		Pixel srcPixels[140];
		u_int32_t pixelIndex = 0;
		for (int col=0; col<40; col += 2) 
        {
			u_int8_t aux0  = (srcData[lineOffset+col+0]);
			u_int8_t aux1  = (srcData[lineOffset+col+1]);
			u_int8_t main0 = (srcData[0x2000+lineOffset+col+0]);
			u_int8_t main1 = (srcData[0x2000+lineOffset+col+1]);

			u_int8_t bitPattern[] = {0, 0, 0, 0, 0, 0, 0};		// 7 bits

			// We extract 7-bit patterns from the 4 bytes
			bitPattern[0] = aux0 &	0x0f;
			bitPattern[1] = ((main0 & 0x01) << 3) | ((aux0 & 0x70) >> 4);
			bitPattern[2] = ((main0 & 0x1E) >> 1);
			bitPattern[3] = ((aux1 & 0x03) << 2) | ((main0 & 0x60) >> 5);
			bitPattern[4] = ((aux1 & 0x3C) >> 2);
			bitPattern[5] = ((main1 & 0x07) << 1) | ((aux1 & 0x40) >> 6);
			bitPattern[6] = ((main1 & 0x78) >> 3);

			// 7 color pixels
			for (int i=0; i<7; i++) 
            {
				Pixel colorPixel = colorPalette[[self reverseBits:bitPattern[i]]];
				srcPixels[pixelIndex] = colorPixel;
				pixelIndex += 1;
			}
		} // col

		// We have a 140-pixel line so proceed convert to 560-pixel line
		Pixel destPixels[560];
		for (int k=0; k<140; k++) 
        {
			Pixel pixel = srcPixels[k];
			destPixels[4*k+0] = pixel;
			destPixels[4*k+1] = pixel;
			destPixels[4*k+2] = pixel;
			destPixels[4*k+3] = pixel;
		}

		u_int32_t evenIndex = 2 * row * 560 * 3;		// offset to even numbered line
		u_int32_t oddIndex  = (2 * row + 1) * 560 * 3;	// offset to odd numbered line
														// Double the row
		for (int k=0; k<560; k++)
        {
			Pixel pixel = destPixels[k];
			bmBuf[evenIndex+3*k+0] = pixel.r;
			bmBuf[evenIndex+3*k+1] = pixel.g;
			bmBuf[evenIndex+3*k+2] = pixel.b;
			bmBuf[oddIndex+3*k+0]  = pixel.r;
			bmBuf[oddIndex+3*k+1]  = pixel.g;
			bmBuf[oddIndex+3*k+2]  = pixel.b;
		}
	} // row

	NSData *bmData = [NSData dataWithBytes:bmBuf
									length:560*3*384];
	free(bmBuf);
	return bmData;
}

- (CGImageRef)doubleHiresColorCGImage
{
	NSBitmapImageRep *bir = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
																	 pixelsWide:560
																	 pixelsHigh:384
																  bitsPerSample:8
																samplesPerPixel:3
																	   hasAlpha:NO
																	   isPlanar:NO
																 colorSpaceName:NSDeviceRGBColorSpace
																	bytesPerRow:560 * 3		// 1 680
																   bitsPerPixel:24] autorelease];
	NSData *bmData = [self doubleHiresColorBitMapData];
	memcpy(bir.bitmapData, bmData.bytes, bmData.length);
	return [bir CGImage];			// Should have been set to autorelease
}

- (NSImage *)doubleHiresMonoChromeImage
{
	CGImageRef cgImage;
	cgImage = [self doubleHiresMonoChromeCGImage];
	NSSize size = NSMakeSize(280, 192);
	NSImage *image = [[[NSImage alloc] initWithCGImage:cgImage
												  size:size] autorelease];					
	return image;
}

- (NSImage *)doubleHiresMonoChromeImage2x
{
	CGImageRef cgImage;
	cgImage = [self doubleHiresMonoChromeCGImage];
	NSSize size = NSMakeSize(280*2, 192*2);
	NSImage *image = [[[NSImage alloc] initWithCGImage:cgImage
												  size:size] autorelease];					
	return image;
}

- (NSImage *)doubleHiresColorImage
{
	CGImageRef cgImage;
	cgImage = [self doubleHiresColorCGImage];

	NSSize size = NSMakeSize(280, 192);
	NSImage *image = [[[NSImage alloc] initWithCGImage:cgImage
												  size:size] autorelease];					
	return image;
}

- (NSImage *)doubleHiresColorImage2x
{
	CGImageRef cgImage;
	cgImage = [self doubleHiresColorCGImage];

	NSSize size = NSMakeSize(280*2, 192*2);
	NSImage *image = [[[NSImage alloc] initWithCGImage:cgImage
												  size:size] autorelease];					
	return image;
}

@end
