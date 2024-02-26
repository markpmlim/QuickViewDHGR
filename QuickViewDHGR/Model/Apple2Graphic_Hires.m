//
//  Apple2Graphic_Hires.m
//  QuickViewDHGR
//
//  Created by mark lim on 3/8/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import "Apple2Graphic.h"
#import "Apple2Graphic_Hires.h"
#import "Decoder.h"
#import "NSImage+Conversion.h"

@implementation Apple2Graphic(Hires)

- (NSData *)hiresMonoChromeBitMapData
{
	unsigned char *bmBuf = malloc(560*3*384);	// 645 120 bytes
	u_int16_t kNumLines = 192;
	u_int8_t *srcData = (u_int8_t *)[fileContents bytes];
	for (int row=0; row<kNumLines; row++) 
    {
		u_int16_t lineOffset = baseOffsets[row];
		u_int16_t srcIndex = 0;
		Pixel srcPixels[280];
		Pixel whitePixel = {0xff, 0xff, 0xff};
		Pixel blackPixel = {0x00, 0x00, 0x00};

		// First step: extract 280 bits and form a line of 280 pixels.
		for (int col=0; col<40; col++)
        {
			u_int8_t srcByte = srcData[lineOffset+col];
			Pixel pixel;
			for (int k=0; k<7; k++)
            {
				u_int8_t bitMask = 1 << k;	// 1, 2, 4, ..., 32, 64
				if ((srcByte & bitMask) == bitMask)
                {
					pixel = whitePixel;
				}
				else
                {
					pixel = blackPixel;
				}
				srcPixels[srcIndex] = pixel;
				srcIndex += 1;
			}
		} // for

		Pixel destPixels[560];
		// We have a 280-pixel line, now convert to a 560-pixel line
		// Effectively, we are doubling the width
		for (int k=0; k<280; k++)
        {
			Pixel pixel = srcPixels[k];
			destPixels[2*k+0] = pixel;
			destPixels[2*k+1] = pixel;
		}

		// Double the row
		u_int32_t evenIndex = 2 * row * 560 * 3;
		u_int32_t oddIndex = (2 * row + 1) * 560 * 3;
		for (int k=0; k<560; k++) 
        {
			Pixel pixel = destPixels[k];
			bmBuf[evenIndex+3*k+0] = pixel.r;
			bmBuf[evenIndex+3*k+1] = pixel.g;
			bmBuf[evenIndex+3*k+2] = pixel.b;

			bmBuf[oddIndex+3*k+0] = pixel.r;
			bmBuf[oddIndex+3*k+1] = pixel.g;
			bmBuf[oddIndex+3*k+2] = pixel.b;
		}
	}
	NSData *bmData = [NSData dataWithBytes:bmBuf
									length:560*3*384];
	free(bmBuf);
	return bmData;
}

- (CGImageRef)hiresMonoChromeCGImage
{
	NSBitmapImageRep *bir = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
																	 pixelsWide:560
																	 pixelsHigh:384
																  bitsPerSample:8
																samplesPerPixel:3
																	   hasAlpha:NO
																	   isPlanar:NO
																 colorSpaceName:NSDeviceRGBColorSpace
																	bytesPerRow:560 * 3			// 1 680
																   bitsPerPixel:24] autorelease];

	NSData *bmData = [self hiresMonoChromeBitMapData];
	memcpy(bir.bitmapData, bmData.bytes, bmData.length);
	return [bir CGImage];			// Should have been set to autorelease
}

boolean_t isEqual(Pixel pix0, Pixel pix1)
{
	return ((pix0.r == pix1.r) &&
			(pix0.g == pix1.g) &&
			(pix0.b == pix1.b));
}

boolean_t isNotEqual(Pixel pix0, Pixel pix1)
{
	return ((pix0.r != pix1.r) ||
			(pix0.g != pix1.g) ||
			(pix0.b != pix1.b));
}

- (BOOL)isColoredDot:(u_int8_t)dot
{
	return dot != kBlackColor0 && dot != kWhiteColor0;
}

/*
 Needs more work since it does not take into a/c of a run of white dots
 */
- (NSData *)hiresColorBitMapData
{
	unsigned char *bmBuf = malloc(560*3*384);	// 645,120 bytes
	u_int16_t kDotsPerLine = 280;
	u_int16_t kNumLines = 192;
	u_int8_t colorDots[kDotsPerLine];
	BOOL colorBits[kDotsPerLine];
	u_int8_t *srcData = (u_int8_t *)[fileContents bytes];

	for (int row=0; row<kNumLines; row++)
    {
		u_int16_t lineOffset = baseOffsets[row];

		u_int16_t dotIndex = 0;
		for (int col=0; col<40; col++) 
        {
			u_int8_t srcByte = srcData[lineOffset+col];
			BOOL isColorBit  = (srcByte & 0x80) != 0;
			for (int k=0; k<7; k++) {
				colorBits[dotIndex] = isColorBit;
				u_int8_t value = srcByte & 0x01;
				BOOL isEven = (dotIndex % 2) == 0;	// ON bit in even column
				if (value == 0)
                {
					// We have an OFF bit.
					colorDots[dotIndex] = kBlackColor0;
				}
				else
                {
					// We have an ON bit, mark this column with a possible color.
					// We don't know yet if there are 2 or more successive ON bits.
					if (isColorBit && isEven)
                    {
						colorDots[dotIndex] = kBlueColor;
					}
					else if (isColorBit && !isEven) 
                    {
						colorDots[dotIndex] = kOrangeColor;
					}
					else if (!isColorBit && isEven)
                    {
						colorDots[dotIndex] = kVioletColor;
					}
					else if (!isColorBit && !isEven)
                    {
						colorDots[dotIndex] = kGreenColor;
					}
				}
				srcByte >>= 1;
				dotIndex += 1;
			}
		}

		// At this stage, we have marked all ON bits with a possible color.
		// Now convert 2 or more consecutive ON bits to white.
		for (int k=1; k<280; k++)
        {
			if (colorBits[k-1] != colorBits[k]) 
            {
				continue;
			}

			u_int8_t prevDot = colorDots[k-1];
			u_int8_t currDot = colorDots[k];
			if ((prevDot != kBlackColor0) && (currDot != kBlackColor0))
            {
				// We have 2 consecutive ON bits
				// All other combinations viz. OFF ON, ON OFF, OFF OFF are ignored.
				colorDots[k-1] = kWhiteColor0;
				colorDots[k] = kWhiteColor0;
			}
		}

		// At this stage, we have marked all ON bits that will be white pixels.
		for (int k=3; k<280; k++)
        {
			if (colorBits[k-2] != colorBits[k-1])
            {
				continue;
			}

			u_int8_t prevDot3 = colorDots[k-3];
			u_int8_t prevDot2 = colorDots[k-2];
			u_int8_t prevDot1 = colorDots[k-1];
			u_int8_t currDot = colorDots[k];
			if (prevDot2 == kBlackColor0) {
				if (currDot == kBlackColor0 && prevDot3 == prevDot1 && [self isColoredDot:prevDot3])
                {
                    // V-B-V-B ---> V-V-V-B
					colorDots[k-2] = prevDot3;
				}
				else if (currDot == kWhiteColor0 && prevDot1 == kWhiteColor0 && [self isColoredDot:prevDot3])
                {
                    // V-B-W-W ---> V-V-W-W
					colorDots[k-2] = prevDot3;
				}
			}
			else if (prevDot1 == kBlackColor0)
            {
				if (prevDot3 == kBlackColor0 && prevDot2 == currDot && [self isColoredDot:currDot])
                {
                    // B-G-B-G ---> B-G-G-G
					colorDots[k-1] = currDot;
				}
				else if (prevDot3 == kWhiteColor0 && prevDot2 == kWhiteColor0 && [self isColoredDot: currDot])
                {
                    // W-W-B-G ---> W-W-G-G
					colorDots[k-1] = currDot;
				}
			}
		}

		Pixel srcPixels[280];
		u_int16_t srcIndex = 0;
		// Convert the 280 dots into a 280-pixel color line
		for (int i=0; i<280; i++)
        {
			u_int8_t colorDot = colorDots[i];

			if (colorDot == kBlackColor0) 
            {
				Pixel pixel = {0x00, 0x00, 0x00};
				srcPixels[srcIndex] = pixel;
			}
			else if (colorDot == kVioletColor) 
            {
				Pixel pixel = {206, 49, 206};
				srcPixels[srcIndex] = pixel;
			}
			else if (colorDot == kGreenColor) 
            {
				Pixel pixel = {0x00, 221, 0x02};
				srcPixels[srcIndex] = pixel;
			}
			else if (colorDot == kBlueColor) 
            {
				Pixel pixel = {49, 49, 0xff};
				srcPixels[srcIndex] = pixel;
			}
			else if (colorDot == kOrangeColor)
            {
				Pixel pixel = {0xff, 70, 0x00};
				srcPixels[srcIndex] = pixel;
			}
			else if (colorDot == kWhiteColor0) 
            {
				Pixel pixel = {0xff, 0xff, 0xff};
				srcPixels[srcIndex] = pixel;
			}
			srcIndex += 1;
		}

		Pixel destPixels[560];
		// We have a 280-pixel color line; convert to a 560-pixel line
		for (int k=0; k<280; k++)
        {
			Pixel pixel = srcPixels[k];
			destPixels[2*k+0] = pixel;
			destPixels[2*k+1] = pixel;
		}

		u_int32_t evenIndex = 2 * row * 560 * 3;
		u_int32_t oddIndex = (2 * row + 1) * 560 * 3;
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
	} // for row

	NSData *bmData = [NSData dataWithBytes:bmBuf
									length:560*3*384];
	free(bmBuf);
	return bmData;
}

- (CGImageRef)hiresColorCGImage
{
	NSBitmapImageRep *bir = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
																	 pixelsWide:560
																	 pixelsHigh:384
																  bitsPerSample:8
																samplesPerPixel:3
																	   hasAlpha:NO
																	   isPlanar:NO
																 colorSpaceName:NSDeviceRGBColorSpace
																	bytesPerRow:560 * 3			// 1 680
																   bitsPerPixel:24] autorelease];
	NSData *bmData = [self hiresColorBitMapData];
	memcpy(bir.bitmapData, bmData.bytes, bmData.length);
	return [bir CGImage];			// Should have been set to autorelease
}

- (NSImage *)hiresMonoChromeImage
{
	CGImageRef cgImage;
	cgImage = [self hiresMonoChromeCGImage];
	
	NSSize size = NSMakeSize(280, 192);
	NSImage *image = [[[NSImage alloc] initWithCGImage:cgImage
												  size:size] autorelease];					
	return image;
}

- (NSImage *)hiresMonoChromeImage2x
{
	CGImageRef cgImage;
	cgImage = [self hiresMonoChromeCGImage];
	
	NSSize size = NSMakeSize(280*2, 192*2);
	NSImage *image = [[[NSImage alloc] initWithCGImage:cgImage
												  size:size] autorelease];					
	return image;
}

- (NSImage *)hiresColorImage
{
	CGImageRef cgImage;
	cgImage = [self hiresColorCGImage];
	
	NSSize size = NSMakeSize(280, 192);
	NSImage *image = [[[NSImage alloc] initWithCGImage:cgImage
												  size:size] autorelease];					
	return image;
}

- (NSImage *)hiresColorImage2x
{
	CGImageRef cgImage;
	cgImage = [self hiresColorCGImage];

	NSSize size = NSMakeSize(280*2, 192*2);
	NSImage *image = [[[NSImage alloc] initWithCGImage:cgImage
												  size:size] autorelease];					
	return image;
}


@end
