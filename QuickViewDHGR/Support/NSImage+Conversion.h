/*

File: NSImage+Conversion.h

Copyright � 2006 Apple Computer, Inc., All Rights Reserved

*/

#import <Cocoa/Cocoa.h>

@interface NSImage(CreatingFromCGImages)

- (id)initWithCGImage:(CGImageRef)cgImage
                 size:(NSSize)size;
@end
