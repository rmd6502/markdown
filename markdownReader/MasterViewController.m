//
//  MasterViewController.m
//  markdownReader
//
//  Created by Robert Diamond on 4/16/16.
//  Copyright © 2016 Robert Diamond. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"

@interface MasterViewController ()

@property NSMutableArray *objects;
@property dispatch_queue_t backgroundQueue;
@property NSOperationQueue *presentedItemOperationQueue;
@property NSURL *presentedItemURL;
@property NSFileCoordinator *fileCoordinator;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    _backgroundQueue = dispatch_queue_create("com.robertdiamond.directoryfetcher", DISPATCH_QUEUE_SERIAL);
    NSArray *documentUrls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    if ([documentUrls count] > 0) {
        _presentedItemURL = documentUrls[0];
        NSLog(@"document url: %@", _presentedItemURL);
        _presentedItemOperationQueue = [NSOperationQueue new];
        [_presentedItemOperationQueue setUnderlyingQueue:_backgroundQueue];
        _fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    if (![[NSFileCoordinator filePresenters] containsObject:self]) {
        [NSFileCoordinator addFilePresenter:self];
    }
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if ([[NSFileCoordinator filePresenters] containsObject:self]) {
        [NSFileCoordinator removeFilePresenter:self];
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // traverse the Documents directory and collect files
    [self _discoverDocuments];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSURL *object = self.objects[indexPath.row];
    NSString *fileName = nil;
    NSError *error = nil;
    [object getResourceValue:&fileName forKey:NSURLNameKey error:&error];
    if (error) {
        cell.textLabel.text = error.localizedDescription;
    } else {
        cell.textLabel.text = fileName;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

#pragma mark - FilePresenter
- (void)presentedItemDidChange
{
    [self _discoverDocuments];
}

#pragma mark - Internal Methods
- (void)_discoverDocuments
{
    dispatch_async(_backgroundQueue, ^{
        NSMutableArray *documentFiles = [NSMutableArray array];
        for (NSURL *entry in [[NSFileManager defaultManager] enumeratorAtURL:self.presentedItemURL includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLIsReadableKey, NSURLNameKey] options:0 errorHandler:nil]) {
            NSDictionary<NSString *,id> *resourceValues = [entry resourceValuesForKeys:@[NSURLIsRegularFileKey, NSURLIsReadableKey, NSURLNameKey] error:nil];
            if (![resourceValues[NSURLIsRegularFileKey] boolValue] || ![resourceValues[NSURLIsReadableKey] boolValue]) {
                continue;
            }
            NSString *fileName = resourceValues[NSURLNameKey];
            if (![fileName hasSuffix:@".md"]) {
                continue;
            }
            [documentFiles addObject:entry];
        }
//        [documentFiles sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
//            return [(NSString *)obj1 compare:(NSString *)obj2];
//        }];
        self.objects = documentFiles;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}
@end
