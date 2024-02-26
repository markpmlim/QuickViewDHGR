#ifndef __USER_DEFINES_H__
#define __USER_DEFINES_H__

#include <sys/types.h>
// std Apple // Double Hi-Res screen layout
#define kBytesPerScanline	40
#define kRowsPerScreen		192

typedef struct _Pixel
{
	u_int8_t r;
	u_int8_t g;
	u_int8_t b;
} Pixel;

extern u_int16_t baseOffsets[];
extern Pixel colorPalette[];

void GenerateBaseOffsets(void);
void GenerateColorTables(void);

/*
 Apple // Hi-res Graphic identifiers
 Ref: File Type Note: $08/$0000-$3FFF
 Standard Hires files are 8 192 (8 Kb) bytes long 
 Double Hires files are 16 384 (16 Kb) bytes long.
	8 192 in Aux mem and another 8 192 in main aux
 
 pg 1 mem is at $2000-$3FFF, pg 2 mem is at $4000-$5FFF,
 both 8 Kb.
 The 128K Apple has 2 page1 mem labelled page1, page1X and
					2 page2 mem labelled page2, page2X
 */

typedef enum
{
	kPaintWorks		= 0,	// PaintWorks Format		($C0/$0000)
	kPacked			= 1,	// packed screen image		($C0/$0001)
	kAPF			= 2,	// Apple Preferred Format	($C0/$0002)
	kDG256			= 3,	// DreamGrafix 256 colors	($C0/$8005)
	kDG3200			= 4,	// DreamGrafix 3200 colors	($C0/$8005)
	kSHR			= 5,	// unpacked screen image	($C1/$0000)
	kBrooks			= 6,	// Brooks' 3200 format		($C1/$0002)
	kSHR3201		= 7,	// No tech note
	kPIC			= 8,	// unpacked Apple IIGS screen
	kPNT			= 9,	// packed Apple IIGS screen
	kStdHiRes		= 10,
	kDoubleHiRes	= 11,
} GraphicType;

typedef enum
{								// value at offset $78 (120 decimal)
	kStdHiResBW			= 0,	// 0 (pg1) or 4 (pg 2)
	kStdHiResColor		= 1,	// 1 (pg1) or 5 (pg 2)
	kDoubleHiResBW		= 2,	// 2 (pg1) or 6 (pg 2)
	kDoubleHiResColor	= 3,	// 3 (pg1) or 7 (pg 2)
} AppleIIGraphicType;

typedef enum _HiResColors {
	kBlackColor0	= 0,
	kGreenColor		= 1,
	kVioletColor	= 2,
	kWhiteColor0	= 3,
	kBlackColor1	= 4,
	kOrangeColor	= 5,
	kBlueColor		= 6,
	kWhiteColor1	= 7,
} HiResColors;

typedef enum
{
	kNoCompression			= 0,
	kLZ4Compression			= 1,
	kPakCompression			= 2,
	kLZ4FHCompression		= 3,
	kUnknownCompression		= 0xffff,
} CompressionAlgorithm;

#define kTypeFOT		0x08
#define kTypeBIN		0x06
#define kFOTPackedHGR	0x4000
#define kFOTPackedDHGR	0x4001
#define kFOTLZ4HGR		0x8005
#define kFOTLZ4DHGR		0x8006
#define kFOTLZ4FH		0x8066

#define minHiResFileSize		8184
#define maxHiResFileSize		8192
#define minDoubleHiResFileSize	16376
#define maxDoubleHiResFileSize	16384

#endif