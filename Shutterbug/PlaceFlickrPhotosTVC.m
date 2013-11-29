//
//  PlaceFlickrPhotosTVC.m
//  Shutterbug
//
//  Created by qsu on 13-11-30.
//  Copyright (c) 2013年 Qi Su. All rights reserved.
//

#import "PlaceFlickrPhotosTVC.h"
#import "FlickrFetcher.h"

@interface PlaceFlickrPhotosTVC ()

@end

@implementation PlaceFlickrPhotosTVC

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
    NSURL *url = [FlickrFetcher URLforPhotosInPlace:self.placeId maxResults:20];
    // create a (non-main) queue to do fetch on
    dispatch_queue_t fetchQ = dispatch_queue_create("flickr fetcher", NULL);
    // put a block to do the fetch onto that queue
    dispatch_async(fetchQ, ^{
        // fetch the JSON data from Flickr
        NSData *jsonResults = [NSData dataWithContentsOfURL:url];
        // convert it to a Property List (NSArray and NSDictionary)
        NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:jsonResults
                                                                            options:0
                                                                              error:NULL];
        // get the NSArray of photo NSDictionarys out of the results
        NSArray *photos = [propertyListResults valueForKeyPath:FLICKR_RESULTS_PHOTOS];
        // update the Model (and thus our UI), but do so back on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing]; // stop the spinner
            self.photos = photos;
        });
    });
}


@end
