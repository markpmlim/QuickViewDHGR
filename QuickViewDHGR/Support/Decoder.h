//
//  Decoder.h
//  QuickLook
//
//  Created by mark lim on 3/31/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Decoder : NSObject
{

}

+ (NSData *)unpackBytes:(NSData *)packedData;
+ (NSData *)lz4Expand:(NSData *)packedData;
+ (NSData *)lz4fhExpand:(NSData *)packedData;

@end
