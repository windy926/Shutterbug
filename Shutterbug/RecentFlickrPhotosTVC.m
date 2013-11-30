//
//  RecentFlickrPhotosTVC.m
//  Shutterbug
//
//  Created by qsu on 13-11-30.
//  Copyright (c) 2013年 Qi Su. All rights reserved.
//

#import "RecentFlickrPhotosTVC.h"

@interface RecentFlickrPhotosTVC ()

@end

@implementation RecentFlickrPhotosTVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self fetchPhotos];
}

// this method is called in viewDidLoad,
//   but also when the user "pulls down" on the table view
//   (because this is the action of self.tableView.refreshControl)

- (IBAction)fetchPhotos
{
    [self.refreshControl beginRefreshing]; // start the spinner
    // create a (non-main) queue to do fetch on
    dispatch_queue_t fetchQ = dispatch_queue_create("flickr fetcher", NULL);
    // put a block to do the fetch onto that queue
    dispatch_async(fetchQ, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *photos = [defaults valueForKey:RECENT_PHOTOS];        
        // update the Model (and thus our UI), but do so back on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing]; // stop the spinner
            if ([photos count] > 20) {
                self.photos = [photos objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)]];
            } else {
                self.photos = photos;
            }
        });
    });
}
@end
