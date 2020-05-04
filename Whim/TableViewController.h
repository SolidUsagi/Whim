//
//  TableViewController.h
//  Whim
//
//  Created by Nao on 2020/01/18.
//  Copyright © 2020 Nao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TableViewController : NSObjectController <NSTableViewDelegate, NSTableViewDataSource>
@property (weak) IBOutlet NSTableView *tableView;
@end

NS_ASSUME_NONNULL_END
