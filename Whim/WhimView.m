//
//  WhimView.m
//  Whim
//
//  Created by Nao on 2020/01/18.
//  Copyright © 2020 Nao. All rights reserved.
//

#import "Configuration.h"
#import "ConfigureSheetController.h"
#import "WhimView.h"

#define kFadeInDuration		2.0
#define kFadeOutDuration	2.0
#define kPreviewDuration	5.0

#define kPathKey		@"Path"
#define kInstanceKey	@"Instance"
#define kViewKey		@"View"
#define kStartedKey		@"Started"
#define kImageKey		@"Image"
#define kPointKey		@"Point"

@implementation WhimView {
	BOOL isPREVIEW;
	NSInteger screen;
	NSMutableArray *screenSavers;
	NSMutableDictionary *runningScreenSaver;
	BOOL executable;
	NSArray *pathsOfSelectedScreenSaver;
	NSUInteger screenSaverIndex;
	NSArray *backgrounds;
	NSUInteger backgroundIndex;
	NSView *boardView;
	NSImageView *backgroundImageView;
	NSImageView *balloonImageView;
	NSSize boardSize;
	NSSize balloonSize;
	NSDate *startTime;
	NSTimeInterval runningPeriod;
	NSTimeInterval backgroundDisplayPeriod;
	NSTimeInterval timeToSwitchScreenSaver;
	NSTimeInterval timeToSwitchBackground;
	ConfigureSheetController *configureSheetController;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
	// In Catalina, the value of 'isPreview' is always YES, so if the width of the View is narrow, it should be considered as preview mode.
	// Catalinaでは'isPreview'の値が常にYESでプレビューかどうか判断できないため、Viewの幅が狭かったらプレビューだと見なすようにする。
	isPREVIEW = frame.size.width < 320;

	static NSUInteger numberOfInstances = 0;
	screen = !isPREVIEW ? numberOfInstances : -1;
	numberOfInstances++;

	self = [super initWithFrame:frame isPreview:isPREVIEW];
	if (self) {
		[self setAnimationTimeInterval:1/30.0];

		screenSavers = [NSMutableArray array];

		balloonSize = NSMakeSize((CGFloat)(int)(frame.size.width / 3), (CGFloat)(int)(frame.size.height / 3));
		boardSize   = !isPREVIEW ? frame.size : balloonSize;

		frame.origin = NSMakePoint(0, 0);
		backgroundImageView = [[NSImageView alloc] initWithFrame:frame];
		backgroundImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
		[self addSubview:backgroundImageView];

		frame.size = boardSize;
		boardView = [[NSView alloc] initWithFrame:frame];
		[self addSubview:boardView];

		frame.size = balloonSize;
		balloonImageView = [[NSImageView alloc] initWithFrame:frame];
		balloonImageView.imageScaling = NSImageScaleProportionallyUpOrDown;

		NSBundle *bundle = [NSBundle bundleForClass:self.class];
		balloonImageView.image = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"QuestionMark" ofType:@"png"]];

		backgrounds = @[
			@{kImageKey:[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Fuyu1" ofType:@"jpg"]],
			  kPointKey:[NSValue valueWithPoint:NSMakePoint(1430, 340)]},
			@{kImageKey:[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Fuyu2" ofType:@"jpg"]],
			  kPointKey:[NSValue valueWithPoint:NSMakePoint( 510, 850)]},
			@{kImageKey:[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Fuyu3" ofType:@"jpg"]],
			  kPointKey:[NSValue valueWithPoint:NSMakePoint( 510, 360)]},
			@{kImageKey:[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Fuyu4" ofType:@"jpg"]],
			  kPointKey:[NSValue valueWithPoint:NSMakePoint(1430, 870)]},
			@{kImageKey:[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Fuyu5" ofType:@"jpg"]],
			  kPointKey:[NSValue valueWithPoint:NSMakePoint(1360, 330)]},
			@{kImageKey:[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Fuyu6" ofType:@"jpg"]],
			  kPointKey:[NSValue valueWithPoint:NSMakePoint( 500, 840)]},
			@{kImageKey:[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Fuyu7" ofType:@"jpg"]],
			  kPointKey:[NSValue valueWithPoint:NSMakePoint(1430, 510)]},
			@{kImageKey:[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Fuyu8" ofType:@"jpg"]],
			  kPointKey:[NSValue valueWithPoint:NSMakePoint(1370, 820)]},
		];
	}

	return self;
}

- (void)startAnimation
{
	[super startAnimation];

	runningScreenSaver = nil;

	pathsOfSelectedScreenSaver = Configuration.sharedConfiguration.pathsOfSelectedScreenSaver;
	executable                 = pathsOfSelectedScreenSaver.count > 0;

	screenSaverIndex = 0;

	backgroundImageView.image = nil;

	[balloonImageView removeFromSuperview];
	if (!executable) {
		[backgroundImageView addSubview:balloonImageView];
	}

	startTime = [NSDate date];

	runningPeriod           = kPreviewDuration;
	backgroundDisplayPeriod = kPreviewDuration;
	if (isPREVIEW && executable) {
		backgroundDisplayPeriod *= pathsOfSelectedScreenSaver.count;
	}

	timeToSwitchScreenSaver = 0;
	timeToSwitchBackground  = 0;

	[boardView           setAlphaValue:1];
	[backgroundImageView setAlphaValue:0];
}

- (void)stopAnimation
{
	[super stopAnimation];

	for (NSMutableDictionary *screenSaver in screenSavers) {
		if ([screenSaver[kStartedKey] boolValue]) {
			 screenSaver[kStartedKey] = @NO;

			[screenSaver[kInstanceKey] stopAnimation];
			[screenSaver[kViewKey    ] setHidden:YES];
		}
	}
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
}

- (void)animateOneFrame
{
	[runningScreenSaver[kInstanceKey] animateOneFrame];

	NSTimeInterval elapsedTime = -[startTime timeIntervalSinceNow];

	if (executable) {
		if (runningScreenSaver[kInstanceKey] == nil || elapsedTime >= timeToSwitchScreenSaver) {
			if (!isPREVIEW) {
				runningPeriod = Configuration.sharedConfiguration.runningPeriod;
			}

			timeToSwitchScreenSaver = (int)elapsedTime + runningPeriod;

			[self switchScreenSaver];
		}
	}

	if (isPREVIEW || !executable) {
		if (backgroundImageView.image == nil || elapsedTime >= timeToSwitchBackground) {
			timeToSwitchBackground = (int)elapsedTime + backgroundDisplayPeriod;

			NSDictionary *background = backgrounds[backgroundIndex % backgrounds.count];
			backgroundIndex = (backgroundIndex + 1) % backgrounds.count;

			backgroundImageView.image = background[kImageKey];

			NSSize frameSize = backgroundImageView.frame.size;
			NSSize imageSize = backgroundImageView.image.size;

			NSPoint origin = [background[kPointKey] pointValue];
			origin.y = imageSize.height - 1 - origin.y;

			CGFloat ratio;
			if (frameSize.width / frameSize.height > imageSize.width / imageSize.height) {
				origin.x += (imageSize.height * frameSize.width / frameSize.height - imageSize.width) / 2;
				ratio = frameSize.height / imageSize.height;
			}
			else {
				origin.y += (imageSize.width * frameSize.height / frameSize.width - imageSize.height) / 2;
				ratio = frameSize.width / imageSize.width;
			}

			origin.x *= ratio;
			origin.y *= ratio;

			origin.x -= balloonSize.width  / 2;
			origin.y -= balloonSize.height / 2;

			if (executable) {
				NSRect frame = boardView.frame;
				frame.origin = origin;
				boardView.frame = frame;
			}

			NSRect frame = balloonImageView.frame;
			frame.origin = origin;
			balloonImageView.frame = frame;
		}
	}

	if (executable) {
		CGFloat alpha = 1;

		if (elapsedTime < timeToSwitchScreenSaver - runningPeriod + kFadeInDuration) {
			alpha = (elapsedTime - (timeToSwitchScreenSaver - runningPeriod)) / kFadeInDuration;
		}

		if (elapsedTime > timeToSwitchScreenSaver - kFadeOutDuration) {
			alpha = (timeToSwitchScreenSaver - elapsedTime) / kFadeOutDuration;
		}

		if (!isPREVIEW) {
			[self setAlphaValue:alpha];
		}
		else {
			[boardView setAlphaValue:alpha];
		}
	}

	if (isPREVIEW || !executable) {
		CGFloat alpha = 1;

		if (elapsedTime < timeToSwitchBackground - backgroundDisplayPeriod + kFadeInDuration) {
			alpha = (elapsedTime - (timeToSwitchBackground - backgroundDisplayPeriod)) / kFadeInDuration;
		}

		if (elapsedTime > timeToSwitchBackground - kFadeOutDuration) {
			alpha = (timeToSwitchBackground - elapsedTime) / kFadeOutDuration;
		}

		[backgroundImageView setAlphaValue:alpha];
	}
}

- (void)switchScreenSaver
{
	if ([[Configuration.sharedConfiguration behaviorWithPath:runningScreenSaver[kPathKey]] isEqualToString:kBehaviorStopAfterFadeOut]) {
		 runningScreenSaver[kStartedKey ] = @NO;
		[runningScreenSaver[kInstanceKey] stopAnimation];
	}

	[runningScreenSaver[kViewKey] setHidden:YES];

	NSString *path;
	if (!isPREVIEW) {
		path = [Configuration.sharedConfiguration pathOfWhimsicallyPickedScreenSaverForScreen:screen];
	}
	else {
		path = pathsOfSelectedScreenSaver[screenSaverIndex % pathsOfSelectedScreenSaver.count];
		screenSaverIndex = (screenSaverIndex + 1) % pathsOfSelectedScreenSaver.count;
	}

	runningScreenSaver = [self screenSaverWithPath:path];

	[runningScreenSaver[kViewKey] setHidden:NO];

	[self setAnimationTimeInterval:MIN(1/10.0, [runningScreenSaver[kInstanceKey] animationTimeInterval])];

	if (![runningScreenSaver[kStartedKey] boolValue]) {
		  runningScreenSaver[kStartedKey] = @YES;

		[runningScreenSaver[kInstanceKey] startAnimation];
	}
}

- (NSMutableDictionary *)screenSaverWithPath:(NSString *)path
{
	for (NSMutableDictionary *screenSaver in screenSavers) {
		if ([path isEqualToString:screenSaver[kPathKey]]) {
			return screenSaver;
		}
	}

	NSRect frame = self.frame;
	frame.size = boardSize;

	id instance = [[[NSBundle bundleWithPath:path].principalClass alloc] initWithFrame:frame isPreview:isPREVIEW];
	[instance setFrame:frame];

	NSView *view = [[NSView alloc] initWithFrame:frame];
	[view addSubview:instance];
	[view setHidden:YES];

	[boardView addSubview:view];

	NSMutableDictionary *screenSaver = [[NSDictionary dictionaryWithObjectsAndKeys:path, kPathKey,
																			   instance, kInstanceKey,
																				   view, kViewKey,
																					@NO, kStartedKey, nil] mutableCopy];

	[screenSavers addObject:screenSaver];

	return screenSaver;
}

- (BOOL)hasConfigureSheet
{
	return YES;
}

- (NSWindow*)configureSheet
{
	if (configureSheetController == nil) {
		configureSheetController = [[ConfigureSheetController alloc] initWithWindowNibName:@"ConfigureSheet"];
	}

	return configureSheetController.window;
}

@end
