//
//  ConfigureSheetController.m
//  Whim
//
//  Created by Nao on 2020/01/18.
//  Copyright © 2020 Nao. All rights reserved.
//

#import "Configuration.h"
#import "ConfigureSheetController.h"

@implementation ConfigureSheetController

- (void)windowDidLoad
{
	[super windowDidLoad];

	[self.runningPeriodPopUpButton selectItemAtIndex:Configuration.sharedConfiguration.runningPeriodIndex];
}

- (IBAction)okButtonClicked:(id)sender
{
	Configuration.sharedConfiguration.runningPeriodIndex = [self.runningPeriodPopUpButton indexOfSelectedItem];
	[Configuration.sharedConfiguration synchronize];

	[self.window.sheetParent endSheet:self.window];
}

@end
