//
//  HLyrics.m
//  SweetFM
//
//  Created by Piero Avola on 09.07.09.
//  Copyright 2009. All rights reserved.
//

#import "HLyrics.h"
#import "XLog.h"
#import "Device.h"

@implementation HLyrics

+(NSString *)lyricsForTrack:(DeviceTrack *)track {
	NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"http://lyrics.wikia.com/%@:%@",
								 [track.artist stringByReplacingSpecialCharacters],
								 [track.name stringByReplacingSpecialCharacters]]
								stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	NSError *error;
	NSString *lyrics = [[NSString alloc] initWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error];
	
	// If there was an error downloading the lyrics
	if (!lyrics) {
		NSLog(@"HLyrics: %@", error);
		return @"";
	}
	
	// Remove un-needed data from the lyrics
	lyrics = [lyrics substringFromIndex:[lyrics rangeOfString:@"<div class='lyricbox'>"].location]; // Take out everything before the lyricbox div
	lyrics = [lyrics substringToIndex:[lyrics rangeOfString:@"<!--"].location]; // Take out everything after the statistics commentblock
	lyrics = [lyrics stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
	
	// Check if the ringtone ad is displayed, and if so, remove it
	NSRange ringtone = [lyrics rangeOfString:@"</div>"];
	if (ringtone.length	> 0) {
		lyrics = [lyrics substringFromIndex:ringtone.location + 6]; // Remove everything before (and including the ringtone div
	}
	
	// Strip out any remaining html tags
	lyrics = [lyrics stringByFlatteningHtml];
	
	// Decode the lyrics
	lyrics = [lyrics stringByDecodingXMLEntities];
	return lyrics;
}

@end

@implementation NSString(LyricAdditions)

-(NSString *)stringByReplacingSpecialCharacters {
	NSMutableString *aString = [self mutableCopy];
	[aString replaceOccurrencesOfString:@"&" withString:@"and" options:NSLiteralSearch range:NSMakeRange(0, [aString length])];
	return aString;
}

// Modified by Spenser Jones. Original from http://mohrt.blogspot.com/2009/03/stripping-html-with-objective-ccocoa.html
- (NSString *)stringByFlatteningHtml {
	NSString *html = [self mutableCopy];
	NSScanner *theScanner;
	NSString *text = nil;
	
	theScanner = [NSScanner scannerWithString:html];
	
	while ([theScanner isAtEnd] == NO) {
		// find start of tag
		[theScanner scanUpToString:@"<" intoString:NULL] ;                 
		// find end of tag         
		[theScanner scanUpToString:@">" intoString:&text] ;
		
		// replace the found tag with a space
		//(you can filter multi-spaces out later if you wish)
		html = [html stringByReplacingOccurrencesOfString:
				[ NSString stringWithFormat:@"%@>", text]
											   withString:@" "];
	} // while //
	
	// trim off whitespace
	return [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString *)stringByDecodingXMLEntities {
    NSUInteger myLength = [self length];
    NSUInteger ampIndex = [self rangeOfString:@"&" options:NSLiteralSearch].location;
	
    // Short-circuit if there are no ampersands.
    if (ampIndex == NSNotFound) {
        return self;
    }
    // Make result string with some extra capacity.
    NSMutableString *result = [NSMutableString stringWithCapacity:(myLength * 1.25)];
	
    // First iteration doesn't need to scan to & since we did that already, but for code simplicity's sake we'll do it again with the scanner.
    NSScanner *scanner = [NSScanner scannerWithString:self];
	
    [scanner setCharactersToBeSkipped:nil];
	
    NSCharacterSet *boundaryCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r;"];
	
    do {
        // Scan up to the next entity or the end of the string.
        NSString *nonEntityString;
        if ([scanner scanUpToString:@"&" intoString:&nonEntityString]) {
            [result appendString:nonEntityString];
        }
        if ([scanner isAtEnd]) {
            goto finish;
        }
        // Scan either a HTML or numeric character entity reference.
        if ([scanner scanString:@"&amp;" intoString:NULL])
            [result appendString:@"&"];
        else if ([scanner scanString:@"&apos;" intoString:NULL])
            [result appendString:@"'"];
        else if ([scanner scanString:@"&quot;" intoString:NULL])
            [result appendString:@"\""];
        else if ([scanner scanString:@"&lt;" intoString:NULL])
            [result appendString:@"<"];
        else if ([scanner scanString:@"&gt;" intoString:NULL])
            [result appendString:@">"];
        else if ([scanner scanString:@"&#" intoString:NULL]) {
            BOOL gotNumber;
            unsigned charCode;
            NSString *xForHex = @"";
			
            // Is it hex or decimal?
            if ([scanner scanString:@"x" intoString:&xForHex]) {
                gotNumber = [scanner scanHexInt:&charCode];
            }
            else {
                gotNumber = [scanner scanInt:(int*)&charCode];
            }
			
            if (gotNumber) {
                [result appendFormat:@"%C", charCode];
				
				[scanner scanString:@";" intoString:NULL];
            }
            else {
                NSString *unknownEntity = @"";
				
				[scanner scanUpToCharactersFromSet:boundaryCharacterSet intoString:&unknownEntity];
				
				
				[result appendFormat:@"&#%@%@", xForHex, unknownEntity];
				
                //[scanner scanUpToString:@";" intoString:&unknownEntity];
                //[result appendFormat:@"&#%@%@;", xForHex, unknownEntity];
                NSLog(@"Expected numeric character entity but got &#%@%@;", xForHex, unknownEntity);
				
            }
			
        }
        else {
			NSString *amp;
			
			[scanner scanString:@"&" intoString:&amp];      //an isolated & symbol
			[result appendString:amp];
			
			/*
			 NSString *unknownEntity = @"";
			 [scanner scanUpToString:@";" intoString:&unknownEntity];
			 NSString *semicolon = @"";
			 [scanner scanString:@";" intoString:&semicolon];
			 [result appendFormat:@"%@%@", unknownEntity, semicolon];
			 NSLog(@"Unsupported XML character entity %@%@", unknownEntity, semicolon);
			 */
        }
		
    }
    while (![scanner isAtEnd]);
	
finish:
	return result;
}

@end

