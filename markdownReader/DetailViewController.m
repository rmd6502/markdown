//
//  DetailViewController.m
//  markdownReader
//
//  Created by Robert Diamond on 4/16/16.
//  Copyright © 2016 Robert Diamond. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
@property MarkdownInterpreter *markdownInterpreter;
@property (weak, nonatomic) IBOutlet UITextView *markdownView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.markdownInterpreter = [[MarkdownInterpreter alloc] initWithDelegate:self];
        self.title = [self.detailItem description];
        NSData *markdownData = [NSData dataWithContentsOfURL:self.detailItem];
        [self.markdownInterpreter interpretString:[[NSString alloc]
                                                   initWithData:markdownData
                                                   encoding:NSUTF8StringEncoding]];
    }
}

- (void)interpretFailedWithError:(NSError *)error
{
    NSLog(@"interpret failed: %@", error.localizedDescription);
}

- (void)interpretResult:(NSAttributedString *)result
{
    _markdownView.attributedText = result;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
