//
//  Apple2Graphic_DoubleHires.h
//  QuickViewDHGR
//
//  Created by mark lim on 3/8/18.
//  Copyright 2018 Incremental Innovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "UserDefines.h"

@interface Apple2Graphic(DoubleHires)

// These methods should only be accessed by the public methods of Apple2Graphic.
- (CGImageRef)doubleHiresMonoChromeCGImage;
- (CGImageRef)doubleHiresColorCGImage;
- (NSImage *)doubleHiresMonoChromeImage;
- (NSImage *)doubleHiresMonoChromeImage2x;
- (NSImage *)doubleHiresColorImage;
- (NSImage *)doubleHiresColorImage2x;

@end
