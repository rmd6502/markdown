//
//  DetailViewController.h
//  markdownReader
//
//  Created by Robert Diamond on 4/16/16.
//  Copyright © 2016 Robert Diamond. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MarkdownInterpreter.h"

@interface DetailViewController : UIViewController<MarkdownInterpreterDelegate>

@property (strong, nonatomic) id detailItem;

@end

