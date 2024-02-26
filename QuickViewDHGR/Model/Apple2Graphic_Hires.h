//
//  Apple2Graphic_Hires.h
//  QuickViewDHGR
//
//  Created by mark lim on 3/8/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Apple2Graphic.h"
#include "UserDefines.h"

@interface Apple2Graphic(Hires)

// These methods should only be accessed by the public methods of Apple2Graphic.
- (CGImageRef)hiresMonoChromeCGImage;
- (CGImageRef)hiresColorCGImage;
- (NSImage *)hiresMonoChromeImage;
- (NSImage *)hiresMonoChromeImage2x;
- (NSImage *)hiresColorImage;
- (NSImage *)hiresColorImage2x;

@end
