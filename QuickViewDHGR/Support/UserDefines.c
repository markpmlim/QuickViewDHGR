#include <stdio.h>
#include "UserDefines.h"

u_int16_t baseOffsets[192];
Pixel colorPalette[16];

void GenerateColorTables(void)
{
	u_int8_t colorValues[] = {	0, 0, 0,		// 0 - Black
								206, 15, 49,	// 1 - Magenta		0x72, 0x26, 0x06
								156, 99, 1,		// 2 - Brown		0x40, 0x4C, 0x04
								255, 70, 0,		// 3 - Orange		0xE4, 0x65, 0x01
								0, 99, 49,		// 4 - Dark Green	0x0E, 0x59, 0x40
								82, 82, 82,		// 5 - Gray			0x80, 0x80, 0x80
								0, 221, 2,		// 6 - Green		0x1B, 0xCB, 0x01
								255, 253, 4,	// 7 - Yellow		0xBF, 0xCC, 0x80
								2, 19, 156,		// 8 - Dark Blue	0x40, 0x33, 0x7F
								206, 49, 206,	// 9 - Violet		0xE4, 0x34, 0xFE
								173, 173, 173,	// A - Grey			0x80, 0x80, 0x80
								255, 156, 156,	// B - Pink			0xF1, 0xA6, 0xBF
								49, 49, 255,	// C - Blue			0x1B, 0x9A, 0xFE
								99, 156, 255,	// D - Light Blue	0xBF, 0xB3, 0xFF
								49, 253, 156,	// E - Aqua			0x8D, 0xD9, 0xBF
								255, 255, 255};	// F - White		0xFF, 0xFF, 0xFF

	for (int i=0, index=0; i < 48; i += 3, index++)
	{
		Pixel pixel;
		pixel.r = colorValues[i+0];
		pixel.g = colorValues[i+1];
		pixel.b = colorValues[i+2];
		colorPalette[index] = pixel;
	}
}


void GenerateBaseOffsets(void)
{
	u_int16_t groupOfEight, lineOfEight, groupOfSixtyFour;
	
	// Both HGR and DHGR graphics have 192 vertical lines.
	// The graphic lines also have the same starting base offsets.
	for (int line = 0; line<192; line++)
	{
		lineOfEight = line % 8;				// 8 lines
		groupOfEight = (line % 64) / 8;		// 8 groups of 8 lines
		groupOfSixtyFour = line / 64;		// 3 groups of 64 lines
		
		baseOffsets[line] = lineOfEight * 0x0400 + groupOfEight * 0x0080 + groupOfSixtyFour * 0x0028;
	}

#if DEBUG
	 for (int line = 0; line<192; line++) 
     {
		printf("screen line:%u baseOffset:$%04x\n", line, baseOffsets[line]);
	 }
#endif
}
