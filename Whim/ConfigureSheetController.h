//
//  ConfigureSheetController.h
//  Whim
//
//  Created by Nao on 2020/01/18.
//  Copyright © 2020 Nao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConfigureSheetController : NSWindowController
@property (weak) IBOutlet NSPopUpButton *runningPeriodPopUpButton;
- (IBAction)okButtonClicked:(id)sender;
@end

NS_ASSUME_NONNULL_END
