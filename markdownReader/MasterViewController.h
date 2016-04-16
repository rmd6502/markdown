//
//  MasterViewController.h
//  markdownReader
//
//  Created by Robert Diamond on 4/16/16.
//  Copyright © 2016 Robert Diamond. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController<NSFilePresenter>

@property (strong, nonatomic) DetailViewController *detailViewController;


@end

