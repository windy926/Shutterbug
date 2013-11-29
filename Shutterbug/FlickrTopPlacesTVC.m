//
//  FlickrTopPlacesTVC.m
//  Shutterbug
//
//  Created by qsu on 13-11-30.
//  Copyright (c) 2013年 Qi Su. All rights reserved.
//

#import "FlickrTopPlacesTVC.h"
#import "FlickrFetcher.h"
#import "PlaceFlickrPhotosTVC.h"

@interface FlickrTopPlacesTVC ()
@property (strong, nonatomic) NSArray *countrys; // of country dictionary
@end

@implementation FlickrTopPlacesTVC

- (IBAction)refresh:(UIRefreshControl *)sender
{
    
}

- (void)setCountrys:(NSArray *)countrys
{
    _countrys = countrys;
    [self.tableView reloadData];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self fetchTopPlaces];
}

#define TOP_PLACES_COUNTRY  @"country"
#define TOP_PLACES_PLACES   @"places"
#define TOP_PLACES_STATE    @"state"
#define TOP_PLACES_CITY     @"city"
#define TOP_PLACES_ID       @"id"

- (IBAction)fetchTopPlaces
{
    [self.refreshControl beginRefreshing];
    NSURL *url = [FlickrFetcher URLforTopPlaces];
    dispatch_queue_t fetchQ = dispatch_queue_create("flickr top places", NULL);
    dispatch_async(fetchQ, ^{
        NSData *jsonResults = [NSData dataWithContentsOfURL:url];
        NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:jsonResults
                                                                            options:0
                                                                              error:NULL];
        //   NSLog(@"%@", propertyListResults);
        NSArray *topPlaces = [propertyListResults valueForKeyPath:FLICKR_RESULTS_PLACES];
        
        NSMutableArray *countrys = [[NSMutableArray alloc] init];
        
        for (NSDictionary *place in topPlaces) {
            NSString *placeName = [place valueForKey:FLICKR_PLACE_NAME];
            NSArray *list = [placeName componentsSeparatedByString:@", "];
            if ([list count] ==1) {
                NSLog(@"%@", list);
            }
            NSMutableDictionary *newPlaces = [[NSMutableDictionary alloc] init];
            [newPlaces setObject:[list firstObject] forKey:TOP_PLACES_CITY];
            [newPlaces setObject:list[1] forKey:TOP_PLACES_STATE];
            [newPlaces setObject:[place valueForKey:FLICKR_PLACE_ID] forKey:TOP_PLACES_ID];
            NSMutableDictionary *country = nil;
            for (NSMutableDictionary *c in countrys) {
                if ([[c valueForKey:TOP_PLACES_COUNTRY] isEqualToString:[list lastObject]]) {
                    country = c;
                    break;
                }
            }
            if (country) {
                NSMutableArray *p = [country valueForKey:TOP_PLACES_PLACES];
                [p addObject:newPlaces];
            } else {
                country = [[NSMutableDictionary alloc] init];
                [country setObject:[list lastObject] forKey:TOP_PLACES_COUNTRY];
                NSMutableArray *placeArray = [[NSMutableArray alloc] init];
                [placeArray addObject:newPlaces];
                [country setObject:placeArray forKey:TOP_PLACES_PLACES];
                [countrys addObject:country];
            }
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
            self.countrys = countrys;
        });

    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.countrys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.countrys[section] valueForKey:TOP_PLACES_PLACES] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Flickr Top Place Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *place = [self.countrys[indexPath.section] valueForKey:TOP_PLACES_PLACES][indexPath.row];
    cell.textLabel.text = [place valueForKey:TOP_PLACES_CITY];
    cell.detailTextLabel.text = [place valueForKey:TOP_PLACES_STATE];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.countrys[section] valueForKey:TOP_PLACES_COUNTRY];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    // Top Places Segue
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        // find out which row in which section we're seguing from
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Display One Place"]) {
                if ([segue.destinationViewController isKindOfClass:[PlaceFlickrPhotosTVC class]]) {
                    PlaceFlickrPhotosTVC *tvc = (PlaceFlickrPhotosTVC *)segue.destinationViewController;
                    tvc.placeId = [[self.countrys[indexPath.section] valueForKey:TOP_PLACES_PLACES][indexPath.row] valueForKey:TOP_PLACES_ID];
                    tvc.title = ((UITableViewCell *)sender).textLabel.text;
                }
            }
        }
    }
}



@end
