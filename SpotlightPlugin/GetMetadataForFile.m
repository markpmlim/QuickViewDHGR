#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#import <Foundation/Foundation.h> 
#import <Cocoa/Cocoa.h>
#import "Apple2Graphic.h"
//#import "Apple2HiresGraphic.h"
//#import "Apple2DoubleHiresGraphic.h"
#include "UserDefines.h"

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForURL function
  
   Implement the GetMetadataForURL function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update schema.xml and schema.strings files
   
   The schema.xml should be added whenever you need attributes displayed in 
   Finder's get info panel, or when you have custom attributes.  
   The schema.strings should be added whenever you have custom attributes. 
 
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void *thisInterface,
						   CFMutableDictionaryRef attributes,
						   CFStringRef contentTypeUTI, 
						   CFStringRef pathToFile)
{
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *path = (NSString *)pathToFile;
	BOOL result = FALSE;
	GenerateBaseOffsets();
	GenerateColorTables();

	NSURL *url = [NSURL fileURLWithPath:path];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *outErr = nil;
	NSDictionary *attr = [fm attributesOfItemAtPath:[url path]
											  error:&outErr];
	// Only plain (uncompressed) files supported.

	if (outErr == nil) {
		CompressionAlgorithm method = kNoCompression;
		unsigned long long fileLen = [[attr objectForKey:NSFileSize] unsignedLongLongValue];
	/*
		Apple2Graphic *graphic;
		if (fileLen >= 16376 && fileLen <= 16384)
		{
			graphic = [[[Apple2DoubleHiresGraphic alloc] initWithURL:(NSURL *)url] autorelease];
		}
		else if (fileLen >= 8184 && fileLen <= 8193)
		{
			graphic = [[[Apple2HiresGraphic alloc] initWithURL:(NSURL *)url] autorelease];
		}
		else
		{
			graphic = nil;
		}
	 */
		GraphicType type;
		if (fileLen >= minDoubleHiResFileSize &&
            fileLen <= maxDoubleHiResFileSize) {
			type = kDoubleHiRes;
		}
		else {
			type = kStdHiRes;
		}

		NSData *fileData = [NSData dataWithContentsOfURL:url];
        if (fileData == nil) {
            goto bailOut;
        }

		Apple2Graphic *graphic = [[[Apple2Graphic alloc] initWithData:fileData
														  graphicType:type
													compressionMethod:method] autorelease];
		if (graphic != nil) {
			//NSLog(@"Returning extended attributes");
			NSMutableDictionary *attrs = (NSMutableDictionary *)attributes;
			[attrs setValue:[NSNumber numberWithUnsignedInt:graphic.pixelWidth]
					 forKey:(NSString *)kMDItemPixelWidth];
			[attrs setValue:[NSNumber numberWithUnsignedInt:graphic.pixelHeight]
					 forKey:(NSString *)kMDItemPixelHeight];
			result = TRUE;
		}
	}

bailOut:
	[pool drain];
    return result;
    
}
