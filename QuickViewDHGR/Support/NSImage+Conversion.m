/*

File: NSImage+Conversion.m

Copyright � 2006 Apple Computer, Inc., All Rights Reserved

*/

#import "NSImage+Conversion.h"

@implementation NSImage(CreatingFromCGImages)

- (id)initWithCGImage:(CGImageRef)cgImage
                 size:(NSSize)size
{
    if (cgImage != nil) {
		// Take advantage of NSBitmapImageRep's -initWithCGImage: initializer, which is new in Leopard.
        NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
        if (bitmapImageRep != nil) 
        {
            self = [self initWithSize:size];
            [self addRepresentation:bitmapImageRep];
            [bitmapImageRep release];
            return self;
        }
    }
    [self release];
    return nil;
}

@end
