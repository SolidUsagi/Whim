//
//  TableViewController.m
//  Whim
//
//  Created by Nao on 2020/01/18.
//  Copyright © 2020 Nao. All rights reserved.
//

#import "Configuration.h"
#import "TableViewController.h"

@implementation TableViewController {
	BOOL advancedSettings;
	NSArray *pathsOfSelectedScreenSaver;
}

- (void)awakeFromNib
{
	[self.tableView setTarget:self];
	[self.tableView setDoubleAction:@selector(doubleAction:)];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return Configuration.sharedConfiguration.numberOfScreenSavers;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if ([tableColumn.identifier isEqualToString:@"Checkbox"]) {
		return [NSNumber numberWithBool:[Configuration.sharedConfiguration checkboxStateAtIndex:row]];
	}

	if ([tableColumn.identifier isEqualToString:@"Name"]) {
		if (!advancedSettings) {
			return [Configuration.sharedConfiguration nameAtIndex:row];
		}
		else {
			NSString *behavior = @"Undefined";
			if ([[Configuration.sharedConfiguration behaviorAtIndex:row] isEqualToString:kBehaviorStopAfterFadeOut]) {
				behavior = @"Stop after fade out";
			}
			else if ([[Configuration.sharedConfiguration behaviorAtIndex:row] isEqualToString:kBehaviorKeepRunning]) {
				behavior = @"Keep running";
			}

			return [NSString stringWithFormat:@"%@ (%@)", [Configuration.sharedConfiguration nameAtIndex:row], behavior];
		}
	}

	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if ([tableColumn.identifier isEqualToString:@"Checkbox"]) {
		[Configuration.sharedConfiguration setCheckboxState:[object boolValue] forIndex:row];

		pathsOfSelectedScreenSaver = nil;
	}
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	if ([tableColumn.identifier isEqualToString:@"Checkbox"]) {
		NSInteger  numberOfScreenSavers         = Configuration.sharedConfiguration.numberOfScreenSavers;
		NSUInteger numberOfSelectedScreenSavers = Configuration.sharedConfiguration.pathsOfSelectedScreenSaver.count;

		if (numberOfScreenSavers == numberOfSelectedScreenSavers && pathsOfSelectedScreenSaver.count > 0) {
			for (NSInteger row = 0; row < numberOfScreenSavers; row++) {
				BOOL checkboxState = NO;
				for (NSString *path in pathsOfSelectedScreenSaver) {
					if ([path isEqualToString:[Configuration.sharedConfiguration pathAtIndex:row]]) {
						checkboxState = YES;
						break;
					}
				}

				[Configuration.sharedConfiguration setCheckboxState:checkboxState forIndex:row];
			}

			pathsOfSelectedScreenSaver = nil;
		}
		else {
			BOOL checkboxState = numberOfSelectedScreenSavers == 0;

			if (!checkboxState && numberOfScreenSavers > numberOfSelectedScreenSavers) {
				pathsOfSelectedScreenSaver = Configuration.sharedConfiguration.pathsOfSelectedScreenSaver;
			}

			for (NSInteger row = 0; row < numberOfScreenSavers; row++) {
				[Configuration.sharedConfiguration setCheckboxState:checkboxState forIndex:row];
			}
		}

		[tableView reloadData];
	}
}

- (void)doubleAction:(id)sender
{
	if (self.tableView.clickedColumn != 1) {
		return;
	}

	if (self.tableView.clickedRow == -1) {
		if (!(NSEvent.modifierFlags & NSEventModifierFlagShift)) {
			return;
		}

		advancedSettings = YES;

		self.tableView.tableColumns[1].headerCell.title = @"Screen Saver (Behavior when switching)";
	}
	else {
		NSString *behavior;
		if ([[Configuration.sharedConfiguration behaviorAtIndex:self.tableView.clickedRow] isEqualToString:kBehaviorStopAfterFadeOut]) {
			behavior = kBehaviorKeepRunning;
		}
		else {
			behavior = kBehaviorStopAfterFadeOut;
		}

		[Configuration.sharedConfiguration setBehavior:behavior forIndex:self.tableView.clickedRow];
	}

	[self.tableView reloadData];
}

@end
