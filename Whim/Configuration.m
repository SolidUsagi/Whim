//
//  Configuration.m
//  Whim
//
//  Created by Nao on 2020/01/18.
//  Copyright © 2020 Nao. All rights reserved.
//

#import "Configuration.h"

#define kVersionKey				@"Version"
#define kScreenSaversKey		@"ScreenSavers"
#define kNameKey				@"Name"
#define kPathKey				@"Path"
#define kCheckboxStateKey		@"CheckboxState"
#define kBehaviorKey			@"Behavior"
#define kRunningPeriodIndexKey	@"RunningPeriodIndex"
#define kMinimumRandomPeriodKey	@"MinimumRandomPeriod"
#define kMaximumRandomPeriodKey	@"MaximumRandomPeriod"
#define kRunningOrderKey		@"RunningOrder"
#define kIndexesKey				@"Indexes"

@implementation Configuration {
	NSArray *bundleIdentifiersOfScreenSaverThatUnsupported;
	NSArray *bundleIdentifiersOfScreenSaverThatKeepRunning;
	ScreenSaverDefaults *defaults;
	NSMutableArray *screenSavers;
	NSArray *runningPeriods;
	NSUInteger minimumRandomPeriod;
	NSUInteger maximumRandomPeriod;
	NSArray *runningOrder;
	NSMutableArray *indexes;
}

@dynamic sharedConfiguration;
+ (Configuration *)sharedConfiguration
{
	static Configuration *shared = nil;

	if (shared == nil) {
		shared = [[Configuration alloc] init];
	}

	return shared;
}

@dynamic numberOfScreenSavers;
- (NSInteger)numberOfScreenSavers
{
	return screenSavers.count;
}

@dynamic runningPeriod;
- (NSTimeInterval)runningPeriod
{
	if (self.runningPeriodIndex <= 0 || self.pathsOfSelectedScreenSaver.count <= 1) {
		return 60.0 * 60.0 * 24.0 * 365.0 * 100.0;
	}

	if (self.runningPeriodIndex >= runningPeriods.count) {
		return rand() % (maximumRandomPeriod - minimumRandomPeriod + 1) + minimumRandomPeriod;
	}

	return [runningPeriods[self.runningPeriodIndex] doubleValue];
}

@dynamic pathsOfSelectedScreenSaver;
- (NSArray *)pathsOfSelectedScreenSaver
{
	NSMutableArray *paths = [NSMutableArray array];
	for (NSMutableDictionary *screenSaver in screenSavers) {
		if ([screenSaver[kCheckboxStateKey] boolValue]) {
			[paths addObject:screenSaver[kPathKey]];
		}
	}

	return paths.count > 0 ? [paths copy] : nil;
}

- (id)init
{
	self = [super init];

	if (self != nil) {
		srand((unsigned int)time(NULL));

		// List of screensavers to exclude.
		// 除外するスクリーンセーバーのリスト。
		bundleIdentifiersOfScreenSaverThatUnsupported = @[
			// Repeated intermittent operation of 'Word of the Day.saver' will eat up memory.
			// 'Word of the Day.saver'を繰り返し間欠動作させるとメモリを食い潰してしまう。
			@"com.apple.WordOfTheDay",

			// The following four of 'XScreenSaver' may stop when switching.
			// 'XScreenSaver'の以下の4つは切り替え時に止まってしまうことがある。
			@"org.jwz.DaliClockSaver",
			@"org.jwz.xscreensaver.JigglyPuff",
			@"org.jwz.xscreensaver.RotZoomer",
			@"org.jwz.xscreensaver.Voronoi",
		];

		// List of screensavers to keep running without stopping after fading out.
		// フェードアウト後も停止させず動かしっぱなしにするスクリーンセーバーのリスト。
		bundleIdentifiersOfScreenSaverThatKeepRunning = @[
			// The screensavers of 'Futurismo Zugakousaku'.
			// 「未来派図画工作」さんのスクリーンセーバー。
			@"com.zugakousaku.",
		];

		runningPeriods = @[@0.0, @10.0, @20.0, @30.0, @60.0, @120.0, @300.0, @600.0, @1200.0, @1800.0, @3600.0];

		defaults = [ScreenSaverDefaults defaultsForModuleWithName:[NSBundle bundleForClass:self.class].bundleIdentifier];

		screenSavers = [NSMutableArray array];
		indexes      = [NSMutableArray array];

		[self checkVersion];
		[self readDefaults];
		[self investigateEnvironment];
	}

	return self;
}

- (NSString *)nameAtIndex:(NSUInteger)index
{
	return screenSavers[index][kNameKey];
}

- (NSString *)pathAtIndex:(NSUInteger)index
{
	return screenSavers[index][kPathKey];
}

- (BOOL)checkboxStateAtIndex:(NSUInteger)index
{
	return [screenSavers[index][kCheckboxStateKey] boolValue];
}

- (void)setCheckboxState:(BOOL)checkboxState forIndex:(NSUInteger)index
{
	screenSavers[index][kCheckboxStateKey] = @(checkboxState);
}

- (NSString *)behaviorAtIndex:(NSUInteger)index
{
	return screenSavers[index][kBehaviorKey];
}

- (void)setBehavior:(NSString *)behavior forIndex:(NSUInteger)index
{
	screenSavers[index][kBehaviorKey] = behavior;
}

- (NSString *)behaviorWithPath:(NSString *)path
{
	for (NSMutableDictionary *screenSaver in screenSavers) {
		if ([screenSaver[kPathKey] caseInsensitiveCompare:path] == NSOrderedSame) {
			return screenSaver[kBehaviorKey];
		}
	}

	return @"";
}

- (void)synchronize
{
	[self writeDefaults];

	runningOrder = nil;
	[self decideRunningOrder];
}

- (NSString *)pathOfWhimsicallyPickedScreenSaverForScreen:(NSInteger)screen
{
	if (screen < 0 || screen >= runningOrder.count) {
		NSArray *pathsOfSelectedScreenSaver = self.pathsOfSelectedScreenSaver;
		return pathsOfSelectedScreenSaver[rand() % pathsOfSelectedScreenSaver.count];
	}

	NSUInteger index = [indexes[screen] unsignedIntegerValue];
	if (index >= ((NSArray *)runningOrder[screen]).count) {
		if (self.runningPeriodIndex < runningPeriods.count) {
			[self decideRunningOrder];
		}
		else {
			[self decideRunningOrderOfScreen:screen];
		}

		index = 0;
	}

	if (((NSArray *)runningOrder[screen]).count == 0) {
		return @"/System/Library/Screen Savers/FloatingMessage.saver";
	}

	NSString *path = ((NSArray *)runningOrder[screen])[index];

	indexes[screen] = [NSNumber numberWithUnsignedInteger:index + 1];

	[defaults setObject:indexes forKey:kIndexesKey];
	[defaults synchronize];

	return path;
}

- (void)checkVersion
{
	NSString *defaultsVersion = [defaults stringForKey:kVersionKey];
	NSString  *currentVersion = [[NSBundle bundleForClass:self.class] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

	if (![defaultsVersion isEqualToString:currentVersion]) {
		NSArray *immutableScreenSavers = [defaults arrayForKey:kScreenSaversKey];
		NSMutableArray   *screenSavers = [NSMutableArray array];

		for (NSDictionary *dictionary in immutableScreenSavers) {
			NSMutableDictionary *screenSaver = [dictionary mutableCopy];

			NSString *bundleIdentifier = [NSBundle bundleWithPath:screenSaver[kPathKey]].bundleIdentifier;

			BOOL keepRunning = NO;
			for (NSString *bundleIdentifierOfScreenSaverThatKeepRunning in bundleIdentifiersOfScreenSaverThatKeepRunning) {
				if ([bundleIdentifierOfScreenSaverThatKeepRunning hasSuffix:@"."]) {
					if ([bundleIdentifier rangeOfString:bundleIdentifierOfScreenSaverThatKeepRunning].location != NSNotFound) {
						keepRunning = YES;
					}
				}
				else {
					if ([bundleIdentifier isEqualToString:bundleIdentifierOfScreenSaverThatKeepRunning]) {
						keepRunning = YES;
					}
				}
			}

			if (keepRunning) {
				screenSaver[kBehaviorKey] = kBehaviorKeepRunning;
			}

			[screenSavers addObject:screenSaver];
		}

		[defaults setObject:currentVersion forKey:kVersionKey     ];
		[defaults setObject:screenSavers   forKey:kScreenSaversKey];
		[defaults synchronize];
	}
}

- (void)readDefaults
{
	[defaults registerDefaults:@{kRunningPeriodIndexKey:   @4}];
	[defaults registerDefaults:@{kMinimumRandomPeriodKey: @10}];
	[defaults registerDefaults:@{kMaximumRandomPeriodKey:@120}];

	NSArray *immutableScreenSavers = [defaults arrayForKey:kScreenSaversKey];
	[screenSavers removeAllObjects];
	for (NSDictionary *dictionary in immutableScreenSavers) {
		[screenSavers addObject:[dictionary mutableCopy]];
	}

	runningOrder = [defaults arrayForKey:kRunningOrderKey];

	indexes = [[defaults arrayForKey:kIndexesKey] mutableCopy];
	if (indexes == nil) {
		indexes = [NSMutableArray array];
	}

	self.runningPeriodIndex = [defaults integerForKey:kRunningPeriodIndexKey];

	minimumRandomPeriod = MAX([defaults integerForKey:kMinimumRandomPeriodKey], 10);
	maximumRandomPeriod = MAX([defaults integerForKey:kMaximumRandomPeriodKey], (NSInteger)minimumRandomPeriod);
}

- (void)writeDefaults
{
	[defaults  setObject:screenSavers            forKey:kScreenSaversKey       ];
	[defaults setInteger:self.runningPeriodIndex forKey:kRunningPeriodIndexKey ];
	[defaults setInteger:minimumRandomPeriod     forKey:kMinimumRandomPeriodKey];
	[defaults setInteger:maximumRandomPeriod     forKey:kMaximumRandomPeriodKey];
	[defaults synchronize];
}

- (void)investigateEnvironment
{
	NSMutableArray *actualScreenSavers = [NSMutableArray array];

	[actualScreenSavers addObjectsFromArray:[self screenSaversWithPath:@"/System/Library/Screen Savers"]];
	[actualScreenSavers addObjectsFromArray:[self screenSaversWithPath:@"/Library/Screen Savers"]];

	NSArray *pathComponents = [[@"~" stringByExpandingTildeInPath] pathComponents];
	if (pathComponents.count >= 3) {
		NSString *path = [NSString pathWithComponents:@[pathComponents[0], pathComponents[1], pathComponents[2], @"Library", @"Screen Savers"]];
		[actualScreenSavers addObjectsFromArray:[self screenSaversWithPath:path]];
	}

	NSUInteger count = screenSavers.count;
	for (NSMutableDictionary *actualScreenSaver in actualScreenSavers) {
		BOOL exist = NO;
		for (NSMutableDictionary *screenSaver in screenSavers) {
			if ([actualScreenSaver[kPathKey] caseInsensitiveCompare:screenSaver[kPathKey]] == NSOrderedSame) {
				exist = YES;
				break;
			}
		}

		if (!exist) {
			[screenSavers addObject:actualScreenSaver];
		}
	}

	BOOL changed = screenSavers.count > count;

	NSMutableArray *missingScreenSavers = [NSMutableArray array];
	for (NSMutableDictionary *screenSaver in screenSavers) {
		BOOL exist = NO;
		for (NSMutableDictionary *actualScreenSaver in actualScreenSavers) {
			if ([screenSaver[kPathKey] caseInsensitiveCompare:actualScreenSaver[kPathKey]] == NSOrderedSame) {
				exist = YES;
				break;
			}
		}

		if (!exist) {
			[missingScreenSavers addObject:screenSaver];
		}
	}

	count = screenSavers.count;
	for (NSMutableDictionary *missingScreenSaver in missingScreenSavers) {
		[screenSavers removeObject:missingScreenSaver];
	}

	if (screenSavers.count < count) {
		changed = YES;
	}

	[screenSavers sortUsingComparator:^NSComparisonResult(NSMutableDictionary *screenSaver1, NSMutableDictionary *screenSaver2) {
		BOOL builtIn1 = [screenSaver1[kPathKey] rangeOfString:@"/System/Library/Screen Savers/"
													  options:NSCaseInsensitiveSearch].location != NSNotFound;
		BOOL builtIn2 = [screenSaver2[kPathKey] rangeOfString:@"/System/Library/Screen Savers/"
													  options:NSCaseInsensitiveSearch].location != NSNotFound;

		if (!builtIn1 &&  builtIn2) {
			return NSOrderedAscending;
		}

		if ( builtIn1 && !builtIn2) {
			return NSOrderedDescending;
		}

		return [screenSaver1[kNameKey] compare:screenSaver2[kNameKey]];
	}];

	if (runningOrder.count != MAX(1, NSScreen.screens.count) || runningOrder.count != indexes.count) {
		changed = YES;
	}

	if (changed) {
		[self synchronize];
	}
}

- (NSMutableArray *)screenSaversWithPath:(NSString *)path
{
	NSMutableArray *screenSavers = [NSMutableArray array];

	NSArray *contentsOfDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:path]
																 includingPropertiesForKeys:nil
																					options:0
																					  error:nil];

	for (NSURL *url in contentsOfDirectory) {
		if ([[url.path pathExtension] caseInsensitiveCompare:@"saver"] != NSOrderedSame) {
			continue;
		}

		NSBundle *bundle = [NSBundle bundleWithPath:url.path];

		if ([bundle.bundleIdentifier isEqualToString:@"jp.metallic-usagi.Whim"]) {
			continue;
		}

		if ([bundle.bundleIdentifier isEqualToString:@"com.apple.ScreenSaver.Random"]) {
			continue;
		}

		BOOL unsupported = NO;
		for (NSString *bundleIdentifierOfScreenSaverThatUnsupported in bundleIdentifiersOfScreenSaverThatUnsupported) {
			if ([bundleIdentifierOfScreenSaverThatUnsupported hasSuffix:@"."]) {
				if ([bundle.bundleIdentifier rangeOfString:bundleIdentifierOfScreenSaverThatUnsupported].location != NSNotFound) {
					unsupported = YES;
					break;
				}
			}
			else {
				if ([bundle.bundleIdentifier isEqualToString:bundleIdentifierOfScreenSaverThatUnsupported]) {
					unsupported = YES;
					break;
				}
			}
		}
		if (unsupported) {
			continue;
		}

		NSString *name = bundle.localizedInfoDictionary[@"CFBundleDisplayName"];
		if (name == nil) {
			name = bundle.infoDictionary[@"CFBundleDisplayName"];
		}
		if (name == nil) {
			name = [[url.path lastPathComponent] stringByDeletingPathExtension];
		}

		BOOL keepRunning = NO;
		for (NSString *bundleIdentifierOfScreenSaverThatKeepRunning in bundleIdentifiersOfScreenSaverThatKeepRunning) {
			if ([bundleIdentifierOfScreenSaverThatKeepRunning hasSuffix:@"."]) {
				if ([bundle.bundleIdentifier rangeOfString:bundleIdentifierOfScreenSaverThatKeepRunning].location != NSNotFound) {
					keepRunning = YES;
				}
			}
			else {
				if ([bundle.bundleIdentifier isEqualToString:bundleIdentifierOfScreenSaverThatKeepRunning]) {
					keepRunning = YES;
				}
			}
		}

		NSMutableDictionary *screenSaver = [NSMutableDictionary dictionary];
		screenSaver[kNameKey         ] = name;
		screenSaver[kPathKey         ] = url.path;
		screenSaver[kCheckboxStateKey] = @YES;
		screenSaver[kBehaviorKey     ] = !keepRunning ? kBehaviorStopAfterFadeOut : kBehaviorKeepRunning;

		[screenSavers addObject:screenSaver];
	}

	return screenSavers;
}

- (void)decideRunningOrder
{
	NSArray *pathsOfSelectedScreenSaver = self.pathsOfSelectedScreenSaver;

	NSUInteger numberOfSelectedScreenSavers = pathsOfSelectedScreenSaver.count;
	if (numberOfSelectedScreenSavers == 0) {
		return;
	}

	NSUInteger numberOfScreens = MAX(1, NSScreen.screens.count);

	NSMutableArray *newOrder               = [NSMutableArray array];
	NSMutableArray *unassignedScreenSavers = [NSMutableArray array];
	for (NSUInteger screen = 0; screen < numberOfScreens; screen++) {
		[newOrder               addObject:[NSMutableArray array]];
		[unassignedScreenSavers addObject:[pathsOfSelectedScreenSaver mutableCopy]];
	}

	NSMutableArray *assignedScreenSaversAtIndex = [NSMutableArray array];
	NSMutableArray *quarantine                  = [NSMutableArray array];

	NSUInteger numberOfBlocks = (numberOfScreens + numberOfSelectedScreenSavers - 1) / numberOfSelectedScreenSavers;
	for (NSUInteger block = 0; block < numberOfBlocks; block++) {
		NSUInteger numberOfScreensInBlock = MIN(numberOfScreens, numberOfSelectedScreenSavers);
		if (numberOfBlocks > 1 && block == numberOfBlocks - 1 && numberOfScreens % numberOfSelectedScreenSavers > 0) {
			numberOfScreensInBlock = numberOfScreens % numberOfSelectedScreenSavers;
		}

		for (NSUInteger index = 0; index < numberOfSelectedScreenSavers; index++) {
			for (NSUInteger screenInBlock = 0; screenInBlock < numberOfScreensInBlock; screenInBlock++) {
				NSUInteger screen = block * numberOfSelectedScreenSavers + screenInBlock;

				NSMutableArray *unassignedScreenSaversOfScreen = unassignedScreenSavers[screen];

				NSString *latest = nil;
				if (index == 0 && runningOrder.count == numberOfScreens) {
					NSArray *runningOrderOfScreen = runningOrder[screen];
					latest = runningOrderOfScreen[runningOrderOfScreen.count - 1];

					[unassignedScreenSaversOfScreen removeObject:latest];
					if (unassignedScreenSaversOfScreen.count == 0) {
						[unassignedScreenSaversOfScreen addObject:latest];
						latest = nil;
					}
				}

				for (NSString *assigned in assignedScreenSaversAtIndex) {
					if ([unassignedScreenSaversOfScreen containsObject:assigned]) {
						[quarantine                          addObject:assigned];
						[unassignedScreenSaversOfScreen   removeObject:assigned];
					}
				}

				if (unassignedScreenSaversOfScreen.count == 0) {
					[unassignedScreenSaversOfScreen addObjectsFromArray:quarantine];
					[quarantine removeAllObjects];
				}

				NSString *picked = unassignedScreenSaversOfScreen[rand() % unassignedScreenSaversOfScreen.count];
				[newOrder[screen]                  addObject:picked];
				[assignedScreenSaversAtIndex       addObject:picked];
				[unassignedScreenSaversOfScreen removeObject:picked];

				if (latest) {
					[unassignedScreenSaversOfScreen addObject:latest];
				}

				[unassignedScreenSaversOfScreen addObjectsFromArray:quarantine];
				[quarantine removeAllObjects];
			}

			[assignedScreenSaversAtIndex removeAllObjects];
		}
	}

	runningOrder = [newOrder copy];

	[indexes removeAllObjects];
	for (NSUInteger screen = 0; screen < numberOfScreens; screen++) {
		[indexes addObject:@0U];
	}

	[defaults setObject:runningOrder forKey:kRunningOrderKey];
	[defaults setObject:indexes      forKey:kIndexesKey     ];
	[defaults synchronize];
}

- (void)decideRunningOrderOfScreen:(NSInteger)screen
{
	NSArray *pathsOfSelectedScreenSaver = self.pathsOfSelectedScreenSaver;

	if (screen < 0 || screen >= runningOrder.count || pathsOfSelectedScreenSaver.count == 0) {
		return;
	}

	NSMutableArray *newOrderOfScreen = [pathsOfSelectedScreenSaver mutableCopy];

	for (NSInteger index = pathsOfSelectedScreenSaver.count; index > 1; index--) {
		[newOrderOfScreen exchangeObjectAtIndex:rand() % index withObjectAtIndex:index - 1];
	}

	NSArray *runningOrderOfScreen = runningOrder[screen];
	if (newOrderOfScreen.count > 1 && [newOrderOfScreen[0] isEqualToString:runningOrderOfScreen[runningOrderOfScreen.count - 1]]) {
		[newOrderOfScreen exchangeObjectAtIndex:0 withObjectAtIndex:1];
	}

	NSMutableArray *newOrder = [runningOrder mutableCopy];
	newOrder[screen] = newOrderOfScreen;

	runningOrder = [newOrder copy];

	indexes[screen] = @0U;

	[defaults setObject:runningOrder forKey:kRunningOrderKey];
	[defaults setObject:indexes      forKey:kIndexesKey     ];
	[defaults synchronize];
}

@end
