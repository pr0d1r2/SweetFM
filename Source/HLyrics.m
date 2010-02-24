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
	NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"http://api.lyricsfly.com/api/api.php?i=841a66a0ca9c8584b-temporary.API.access&a=%@&t=%@",
								 [track.artist stringByReplacingSpecialCharacters],
								 [track.name stringByReplacingSpecialCharacters]]
								stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	NSError *error;
	NSXMLDocument *xml = [[[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error] autorelease];
	if(!xml) {
		XLog(@"HLyrics: %@", error);
		return nil;
	}
	
	NSArray *result = [xml nodesForXPath:@"start/sg/tx" error:&error];
	if(!result) {
		XLog(@"HLyrics: %@", error);
		return nil;
	}
	
	if([result count] == 0) {
		return nil;
	}
	
	NSString *lyrics = [[result objectAtIndex:0] stringValue];
	if([lyrics isEqual:@"Not found"]) {
		return nil;
	}
	
	lyrics = [lyrics stringByReplacingOccurrencesOfString:@"[br]" withString:@"\n"];
	return lyrics;
}

@end

@implementation NSString(LyricAdditions)

-(NSString *)stringByReplacingSpecialCharacters {
	NSMutableString *aString = [self mutableCopy];
	[aString replaceOccurrencesOfString:@"&" withString:@"and" options:NSLiteralSearch range:NSMakeRange(0, [aString length])];
	return aString;
}

@end

