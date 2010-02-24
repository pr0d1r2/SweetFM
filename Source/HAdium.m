//
//  HAdium.m
//  SweetFM
//
//  Created by Nicolas Haunold on 8/20/09.
//  Copyright 2009 Tapolicious Software. All rights reserved.
//

#import "HAdium.h"
#import "SynthesizeSingleton.h"
#import "HSettings.h"
#import "XLog.h"

@implementation HAdium

SYNTHESIZE_SINGLETON_FOR_CLASS(HAdium, instance);

- (id)init
{
	if(self = [super init])
	{		
		if([HSettings adiumStatusChangeEnabled] == YES)
		{
			//
			// Register for terminate notification (to clear Adium status)
			//
			NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
			[notify addObserver:self selector:@selector(appWillTerminate)
										name:NSApplicationWillTerminateNotification object:nil];
		}
	}
	
	return self;
}

- (void)appWillTerminate
{
	[self setAdiumStatus:nil];
}

- (void)setAdiumStatus:(NSString *)status 
{
	if(![HSettings adiumStatusChangeEnabled])
		return;
	
	BOOL adiumRunning = NO;
	NSArray *runningApplications = [[NSWorkspace sharedWorkspace] launchedApplications];
	for (NSDictionary *thisApplication in runningApplications) {
		if ([[thisApplication objectForKey:@"NSApplicationName"] isEqualToString:@"Adium"]) {
			adiumRunning = YES;
			break;
		}
	}
	if (!adiumRunning)
		return;

	if(status != nil) 
	{
		status = [status stringByAppendingString:@" (SweetFM)"];
	} else {
		status = @"";
	}

	XLog(@"Changing Adium Status: %@", status);

	NSAppleScript *adiumScript = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"Adium\"\nset status message of every account whose status type is available to \"%@\"\nend tell\n", status]];
	[adiumScript executeAndReturnError:nil];
	[adiumScript release];
}

@end
