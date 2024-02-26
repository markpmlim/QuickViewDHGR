//
//  Decoder.m
//  QuickViewDHGR
//
//  Created by mark lim on 3/31/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//
// All the decoders work when the program is run under Rosetta.

#import "Decoder.h"
#include "UserDefines.h"

@implementation Decoder

#pragma mark unpackBytes decoder used by many Apple II & IIGS graphics programs
/*
 An entire file.
 The caller will decide whether the # of bytes in the 
 returned instance of NSData is valid since a NIL object
 is never returned
 This method is not crash-proofed; acccessing the input/output buffers
 (via the inp, outp pointers) beyond their limits can happen.
 The variable srcLen can serve as a sentinel/guard for Input Buffer
 We could use the "count" to compute value which is then compare to 256 to
 determine if there is overflow in the Output Buffer (rldBuf).
 The parameter "numBytes" + (outp - rldBuf) < 256
 This may not be necessary after all on further investigation because there is
 no way an overrun of the output can happen since outp is reset to rldBuf after
 each mini-run.
 */
+ (NSData *)unpackBytes:(NSData *)packedData
{
	Byte *inp = (Byte *)[packedData bytes];
	int srcLen = [packedData length];
	NSMutableData *unpackedData = [NSMutableData data];
	Byte rldBuf[256];							// max runlen= 64 x 4
	NSUInteger numBytes;
	NSUInteger totalBytes = 0;					// running total of decoded bytes
	
	while (srcLen > 0) {
		Byte header = *inp++;
		--srcLen;
		Byte *outp = rldBuf;					// Run Len Decode buffer
		int whichFormat = (header & 0xC0) >> 6;	// isolate 2 flag bits
		int count = (header & 0x3F) + 1;		// isolate 6 length bits (0-63)
												// count is 0-based so add 1
		numBytes = count;						// set this for cases 0 and 1
		switch (whichFormat) {
			case 0:
				// add a sentinel here
				//NSLog(@"%d", numBytes + outp - rldBuf);
				while (count--) {
					*outp++ = *inp++;			// AllDifferent
					--srcLen;
				}
				break;
			case 1:
			{
				// add a sentinel here
				//NSLog(@"%d", numBytes + outp - rldBuf);
				Byte repeatedByte = *inp++;		// RepeatNextByte
				--srcLen;
				// count: 3, 5, 6 or 7
				while (count--) {
					*outp++ = repeatedByte;
				}
				break;
			}
			case 2:
			{
				Byte fourBytes[4];				// REPEAT NEXT 4 BYTES
				fourBytes[0] = *inp++;
				fourBytes[1] = *inp++;
				fourBytes[2] = *inp++;
				fourBytes[3] = *inp++;
				srcLen -= 4;
				numBytes = count*4;				// # of bytes to be decoded
				// add a sentinel here?
				//NSLog(@"%d", numBytes + outp - rldBuf);
				while (count--) {
					*outp++ = fourBytes[0];
					*outp++ = fourBytes[1];
					*outp++ = fourBytes[2];
					*outp++ = fourBytes[3];
				}
				break;
			}
			case 3:
			{
				Byte repeatedByte = *inp++;		// REPEAT 4 OF NEXT 1 BYTE
				--srcLen;
				numBytes = count *= 4;			// total # of bytes to be decoded
				// add a sentinel here
				//NSLog(@"%d", numBytes + outp - rldBuf);
				while (count--) {
					*outp++ = repeatedByte;
				}
				break;
			}
		} // switch
		[unpackedData appendBytes:rldBuf
						   length:numBytes];
		totalBytes += numBytes;
	} // while

	// NB. the length of the returned data block is never 0
	// The caller must check the size of the block.
	return unpackedData;
}

/*
 KIV: currently 16-byte header is passed as well.
 */
+ (NSData *)lz4Expand:(NSData *)packedData
{
	uint8_t *srcPtr = (uint8_t *)[packedData bytes];
	NSData *unpackedData = nil;
	//uint8_t *srcBegin = srcPtr;
	uint8_t *srcEnd = srcPtr + [packedData length];
	[packedData getBytes:srcPtr
				  length:[packedData length]];
	uint32_t originalLen = (srcPtr[7] << 24) + (srcPtr[6] << 16) + (srcPtr[5] << 8) + srcPtr[4];
	//printf("original len:%u\n", originalLen);
	// KIV. check originalLen
	BOOL isLengthValid = ((originalLen >= minDoubleHiResFileSize && originalLen <= maxDoubleHiResFileSize) ||
						  (originalLen >= minHiResFileSize && originalLen <= maxHiResFileSize));
	if (isLengthValid == NO) {
		//printf("Invalid original len:%u\n", originalLen);
		return unpackedData; 
	}

	uint8_t *destPtr = malloc(originalLen);
	uint8_t *destBegin = destPtr;
	uint8_t *destEnd = destPtr + originalLen;
	bzero(destPtr, originalLen);

	srcPtr += 16;			// skip past header
	while (srcPtr < srcEnd) {
		uint8_t token = *srcPtr++;
		uint32_t literalLength = (token >> 4) & 0x0f;	// 0..15
		// min value is 4, max value 15+4=19
		uint32_t matchLength = 4 + (token & 0x0f);		// 4..19

		if (literalLength == 15) {
			//print("extra bytes for literal Length")
			// extra bytes for literal Length
			uint8_t extraBytes = 0;
			do {
				if (srcPtr >= srcEnd) {
					printf("Token Failed\n");
					goto bailOut;
				}
				extraBytes = *srcPtr++;
				literalLength += extraBytes;
			} while (extraBytes == 255);
		}

		// Next is the string of literals which comes after the token and extra bytes
		// Copy the string of literals to the output.
		if (literalLength > (destEnd - destPtr)) {
			// literal will take us past the end of the destination buffer,
			// so we can only copy part of it.
			//printf("copy part of literal\n");
			literalLength = destEnd - destPtr;
			memcpy(destPtr, srcPtr, literalLength);
			destPtr += literalLength;
			break;
		}

		memcpy(destPtr, srcPtr, literalLength);
		srcPtr += literalLength;
		destPtr += literalLength;
		if (srcPtr >= srcEnd) {
			//printf("valid end of stream\n");
			goto out_full;
		}

		// After the string of literals is an offset to indicate how far back in the output buffer to begin copying.
		uint16_t matchDistance = *(const uint16_t *)srcPtr;
		//printf("Match Distance: %u\n", matchDistance);
		srcPtr += 2;
		uint8_t *ref = destPtr - matchDistance;		// pointer to copy position
        if (matchDistance == 0) {
            // 0x0000 invalid
			//printf("Invalid match distance D = 0\n");
			goto bailOut;
		}

		// Why are we failing here sometimes?
		if (ref < destBegin) {
			// Sometimes the matchDistance is wrong.
			//NSLog(@"ref failed:%p %p %u", ref, destBegin, matchDistance);
			goto bailOut;
		}
		
		// 0x0000 <= matchDistance <= 0xffff
		// Finally the extra bytes (if any) of the matchLength come at the end of the sequence.
		// extra bytes for matchLength
		if (matchLength == 19) {
			uint8_t s = 0;
			do {
				if (srcPtr >= srcEnd) {
					//printf("matchDistance Failed\n");
					goto bailOut;
				}
				s = *srcPtr++;
				matchLength += s;
			} while (s == 255);
		}

		if (matchLength > (destEnd - destPtr)) {
			//  Match will take us past the end of the destination buffer,
			//  so we can only copy part of it.
			matchLength = (destEnd - destPtr);
			for (int i=0; i<matchLength; i++) {
				destPtr[i] = ref[i];
			}
			destPtr += matchLength;
			// full?
			//printf("End\n");
			break;
		}
		for (int i=0; i<matchLength; i++) {
			destPtr[i] = ref[i];
		}
		destPtr += matchLength;
	} // while

out_full:	
	unpackedData = [NSData dataWithBytes:destBegin
								  length:originalLen];
	//printf("done\n");
	// fall thru
bailOut:
	if (destBegin != NULL) {
		free(destBegin);
    }
	return unpackedData;
}

+ (NSData *)lz4fhExpand:(NSData *)packedData
{
	NSData *unpackedData = nil;
	NSUInteger srcLen = packedData.length;
	uint8_t *srcPtr = (uint8_t *)packedData.bytes;
	uint8_t *srcBegin = srcPtr;
	uint8_t *srcEnd = srcPtr + srcLen;
	static const uint16_t kExpectedSize = 8192;

	static const uint16_t MIN_MATCH_LEN = 4;
	static const uint16_t INITIAL_LEN = 15;
	static const uint8_t EMPTY_MATCH_TOKEN = 253;
	static const uint8_t EOD_MATCH_TOKEN = 254;
	static const uint8_t LZ4FH_MAGIC = 0x66;

	uint8_t magicNumber = *srcPtr;

	if (magicNumber != LZ4FH_MAGIC) {
		printf("No magic number!\n");
		goto bailOut;
	}

	uint16_t MAX_SIZE = kExpectedSize;
	uint8_t *destPtr = (uint8_t *)malloc(MAX_SIZE);
	uint8_t *destBegin = destPtr;
	bzero(destPtr, MAX_SIZE);
	srcPtr++;

	while (srcPtr < srcEnd) {
		uint8_t mixedLen = *srcPtr++;
		int literalLen = (mixedLen >> 4);
		
		if (literalLen != 0) {
			if (literalLen == INITIAL_LEN) {
				literalLen += *srcPtr++;
			}
			if ((destPtr - destBegin) + literalLen > MAX_SIZE ||
				(srcPtr - srcBegin) + literalLen > srcLen) {
				printf("Buffer overrun\n");
				goto bailOut;
			}
			memcpy(destPtr, srcPtr, literalLen);
			destPtr += literalLen;
			srcPtr += literalLen;
		}

		int matchLen = mixedLen & 0x0f;
		if (matchLen == INITIAL_LEN) {
			uint8_t extraBytes = *srcPtr++;
			if (extraBytes == EMPTY_MATCH_TOKEN) {
				matchLen = -MIN_MATCH_LEN;
			}
			else if (extraBytes == EOD_MATCH_TOKEN) {
				break;		// out of while
			}
			else {
				matchLen += extraBytes;
			}
		}

		matchLen += MIN_MATCH_LEN;
		if (matchLen != 0) {
			uint16_t matchOffset = *(const uint16_t *)srcPtr;
			srcPtr += 2;
			// Can't use memcpy() here, because we need to guarantee
			// that the match is overlapping.
			uint8_t *refPtr = destBegin + matchOffset;
			if ((destPtr - destBegin) + matchLen > MAX_SIZE ||
				(refPtr - destBegin) + matchLen > MAX_SIZE) {
				printf("Buffer overrun\n");
				goto bailOut;
			}

			for (int i=0; i < matchLen; i++) {
				destPtr[i] = refPtr[i];
			}
			destPtr += matchLen;
		}
	} // while

	unpackedData = [NSData dataWithBytes:destBegin
								  length:MAX_SIZE];
bailOut:
	if (destBegin != NULL) {
		free(destBegin);
    }
	return unpackedData;
}
@end
