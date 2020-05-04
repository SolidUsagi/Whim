//
//  Configuration.h
//  Whim
//
//  Created by Nao on 2020/01/18.
//  Copyright © 2020 Nao. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>

#define kBehaviorStopAfterFadeOut	@"StopAfterFadeOut"
#define kBehaviorKeepRunning		@"KeepRunning"

NS_ASSUME_NONNULL_BEGIN

@interface Configuration : NSObject
@property (class, readonly) Configuration *sharedConfiguration;
@property (nonatomic, readonly) NSInteger numberOfScreenSavers;
@property (nonatomic, readonly) NSTimeInterval runningPeriod;
@property (nonatomic) NSInteger runningPeriodIndex;
@property (nonatomic, readonly) NSArray *pathsOfSelectedScreenSaver;
- (NSString *)nameAtIndex:(NSUInteger)index;
- (NSString *)pathAtIndex:(NSUInteger)index;
- (BOOL)checkboxStateAtIndex:(NSUInteger)index;
- (void)setCheckboxState:(BOOL)checkboxState forIndex:(NSUInteger)index;
- (NSString *)behaviorAtIndex:(NSUInteger)index;
- (void)setBehavior:(NSString *)behavior forIndex:(NSUInteger)index;
- (NSString *)behaviorWithPath:(NSString *)path;
- (void)synchronize;
- (NSString *)pathOfWhimsicallyPickedScreenSaverForScreen:(NSInteger)screen;
@end

NS_ASSUME_NONNULL_END
