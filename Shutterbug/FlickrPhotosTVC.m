//
//  FlickrPhotosTVC.m
//  Shutterbug
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "FlickrPhotosTVC.h"
#import "FlickrFetcher.h"
#import "PlaceFlickrPhotosTVC.h"
#import "RecentFlickrPhotosTVC.h"
#import "ImageViewController.h"

@implementation FlickrPhotosTVC

// whenever our Model is set, must update our View

- (void)setPhotos:(NSArray *)photos
{
    _photos = photos;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

// the methods in this protocol are what provides the View its data
// (remember that Views are not allowed to own their data)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section (we only have one)
    return [self.photos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // we must be sure to use the same identifier here as in the storyboard!
    static NSString *CellIdentifier = @"Flickr Photo Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    // get the photo out of our Model
    NSDictionary *photo = self.photos[indexPath.row];
    
    // update UILabels in the UITableViewCell
    // valueForKeyPath: supports "dot notation" to look inside dictionaries at other dictionaries
    NSString *title = [[photo valueForKeyPath:FLICKR_PHOTO_TITLE] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!title || [title length] == 0) {
        title = [[photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if (!title || [title length] == 0) {
        title = @"Unkonwn";
    }
    cell.textLabel.text = title;
    cell.detailTextLabel.text = [photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
    
    return cell;
}

#pragma mark - UITableViewDelegate

// when a row is selected and we are in a UISplitViewController,
//   this updates the Detail ImageViewController (instead of segueing to it)
// knows how to find an ImageViewController inside a UINavigationController in the Detail too
// otherwise, this does nothing (because detail will be nil and not "isKindOfClass:" anything)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the Detail view controller in our UISplitViewController (nil if not in one)
    id master = self.splitViewController.viewControllers[0];
    id detail = self.splitViewController.viewControllers[1];
    // if Detail is a UINavigationController, look at its root view controller to find it
    if ([detail isKindOfClass:[UINavigationController class]]) {
        detail = [((UINavigationController *)detail) visibleViewController];
    }
    // is the Detail is an ImageViewController?
    if ([detail isKindOfClass:[ImageViewController class]]) {
        // yes ... we know how to update that!
        if ([master isKindOfClass:[UITabBarController class]]) {
            master = [((UITabBarController *)master) selectedViewController];
        }
        if ([master isKindOfClass:[UINavigationController class]]) {
            master = [((UINavigationController *)master) visibleViewController];
        }
        if ([master isKindOfClass:[PlaceFlickrPhotosTVC class]]) {
            [self preparePlaceImageViewController:detail toDisplayPhoto:self.photos[indexPath.row]];
        } else if ([master isKindOfClass:[RecentFlickrPhotosTVC class]]) {
            [self prepareRecentImageViewController:detail toDisplayPhoto:self.photos[indexPath.row]];
        }
    }
}

#pragma mark - Navigation

// prepares the given ImageViewController to show the given photo
// used either when segueing to an ImageViewController
//   or when our UISplitViewController's Detail view controller is an ImageViewController


- (void)preparePlaceImageViewController:(ImageViewController *)ivc toDisplayPhoto:(NSDictionary *)photo
{
    ivc.imageURL = [FlickrFetcher URLforPhoto:photo format:FlickrPhotoFormatLarge];
    ivc.title = [photo valueForKeyPath:FLICKR_PHOTO_TITLE];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *recentPhotos = [[userDefaults objectForKey:RECENT_PHOTOS] mutableCopy];
    if (!recentPhotos) {
        recentPhotos = [[NSMutableArray alloc] init];
        [userDefaults setObject:(NSArray *)recentPhotos forKey:RECENT_PHOTOS];
        [userDefaults synchronize];
    }
    
 //   NSString *urlString = [ivc.imageURL absoluteString];
    
    BOOL exist = NO;
    for (NSDictionary *photo in recentPhotos) {
        NSURL *photoUrl = [FlickrFetcher URLforPhoto:photo format:FlickrPhotoFormatLarge];
        if ([photoUrl isEqual:ivc.imageURL]) {
            exist = YES;
            break;
        }
    }
    if (!exist) {
        [recentPhotos insertObject:photo  atIndex:0];
        [userDefaults setObject:(NSArray *)recentPhotos forKey:RECENT_PHOTOS];
        [userDefaults synchronize];
    }
}

- (void)prepareRecentImageViewController:(ImageViewController *)ivc toDisplayPhoto:(NSDictionary *)photo
{
    ivc.imageURL = [FlickrFetcher URLforPhoto:photo format:FlickrPhotoFormatLarge];
    ivc.title = [photo valueForKeyPath:FLICKR_PHOTO_TITLE];
}

// In a story board-based application, you will often want to do a little preparation before navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    if ([sender isKindOfClass:[UITableViewCell class]]) {
        // find out which row in which section we're seguing from
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            // found it ... are we doing the Display Photo segue?
            if ([segue.identifier isEqualToString:@"Display One Place Photo"]) {
                // yes ... is the destination an ImageViewController?
                if ([segue.destinationViewController isKindOfClass:[ImageViewController class]]) {
                    // yes ... then we know how to prepare for that segue!
                    [self preparePlaceImageViewController:segue.destinationViewController
                                      toDisplayPhoto:self.photos[indexPath.row]];
                }
            } else if ([segue.identifier isEqualToString:@"Display Recent Photo"]) {
                // yes ... is the destination an ImageViewController?
                if ([segue.destinationViewController isKindOfClass:[ImageViewController class]]) {
                    // yes ... then we know how to prepare for that segue!
                    [self prepareRecentImageViewController:segue.destinationViewController
                                           toDisplayPhoto:self.photos[indexPath.row]];
                }
            }
        }
    }
}

@end
