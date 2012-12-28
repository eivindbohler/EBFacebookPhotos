//
// Copyright (c) 2012 Eivind R. Bohler
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
//  EBTableViewController.h
//  EBFacebookPhotos/Examples/PhotoFetcher
//

#import "EBTableViewController.h"
#import "EBAppDelegate.h"
#import "FacebookSDK.h"
#import "EBFacebookPhotos.h"
#import "EBAlbumsTableViewController.h"
#import "EBPhotosTableViewController.h"
#import "EBFriendsTableViewController.h"

typedef enum {
    TableViewTypeMyProfilePictures = 0,
    TableViewTypeMyTimelinePictures,
    TableViewTypeMyAlbums,
    TableViewTypeMyFriends,
    TableViewTypeMyFriendsAlbums,
    TableViewTypeMyFriendsAlbumsFromLondon
} TableViewType;

NSString *const kPushPhotosTableViewController = @"PushPhotosTableViewController";

@interface EBTableViewController ()

@end

@implementation EBTableViewController

#pragma mark - NSObject

- (void)awakeFromNib
{
    [super awakeFromNib];

    // After this view controller has been instanciated by the storyboard,
    // make sure the app delegate has a reference to it.
    EBAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.rootTableViewController = self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    EBAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate checkSession];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *destinationViewController = segue.destinationViewController;
    TableViewType tableViewType = [(NSNumber *)sender integerValue];
    switch (tableViewType) {
        case TableViewTypeMyProfilePictures: {
            destinationViewController.navigationItem.title = @"My Profile Pictures";
            [EBFacebookPhotos myProfilePicturesWithSuccess:^(NSArray *photos) {
                if (destinationViewController) {
                    [(EBPhotosTableViewController *)destinationViewController setPhotos:photos];
                }
            } failure:^(NSError *error) {
                NSLog(@"Error fetching photos: %@", error);
            }];
            break;
        }
        case TableViewTypeMyTimelinePictures: {
            destinationViewController.navigationItem.title = @"My Timeline Pictures";
            [EBFacebookPhotos myTimelinePicturesWithSuccess:^(NSArray *photos) {
                if (destinationViewController) {
                    [(EBPhotosTableViewController *)destinationViewController setPhotos:photos];
                }
            } failure:^(NSError *error) {
                NSLog(@"Error fetching photos: %@", error);
            }];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    switch (indexPath.row) {
        case TableViewTypeMyProfilePictures:
            cell.textLabel.text = @"My Profile Pictures";
            break;
        case TableViewTypeMyTimelinePictures:
            cell.textLabel.text = @"My Timeline Pictures";
            break;
        case TableViewTypeMyAlbums:
            cell.textLabel.text = @"My Albums";
            break;
        case TableViewTypeMyFriends:
            cell.textLabel.text = @"My Friends";
            break;
        case TableViewTypeMyFriendsAlbums:
            cell.textLabel.text = @"My Friends' Albums";
            break;
        case TableViewTypeMyFriendsAlbumsFromLondon:
            cell.textLabel.text = @"My Friends' Albums From London";
            break;
        default:
            cell.textLabel.text = @"[unknown cell]";
            break;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case TableViewTypeMyAlbums: {
            EBAlbumsTableViewController *tableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumsTableViewController"];
            tableViewController.navigationItem.title = @"My Albums";
            [self.navigationController pushViewController:tableViewController animated:YES];
            [EBFacebookPhotos myAlbumsWithAlbumProperties:@[@"cover_photo", @"name", @"photo_count", @"created"]
                                          photoProperties:@[@"src"]
                                                  success:^(NSArray *albums) {
                                                      [tableViewController setAlbums:albums];
                                                  } failure:^(NSError *error) {
                                                      
                                                  }];
            break;
        }
        case TableViewTypeMyFriends: {
            EBFriendsTableViewController *tableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FriendsTableViewController"];
            tableViewController.navigationItem.title = @"My Friends";
            [self.navigationController pushViewController:tableViewController animated:YES];
            NSString *query = @"SELECT uid, first_name, name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())";
            [FBRequestConnection startWithGraphPath:@"/fql"
                                         parameters:@{@"q": query}
                                         HTTPMethod:@"GET"
                                  completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                      if ([result isKindOfClass:[NSDictionary class]]) {
                                          NSArray *friends = result[@"data"];
                                          if ([friends isKindOfClass:[NSArray class]]) {
                                              [tableViewController setFriends:friends];
                                          }
                                      }
                                  }];
            break;
        }
        case TableViewTypeMyFriendsAlbums: {
            EBAlbumsTableViewController *tableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumsTableViewController"];
            tableViewController.navigationItem.title = @"My Friends' Albums";
            [self.navigationController pushViewController:tableViewController animated:YES];
            [EBFacebookPhotos albumsForFriends:nil
                               albumProperties:@[@"cover_photo", @"name", @"photo_count", @"created"]
                               photoProperties:@[@"src"]
                                       success:^(NSArray *albums) {
                                           [tableViewController setAlbums:albums];
                                       } failure:^(NSError *error) {

                                       }];
            break;
        }
        case TableViewTypeMyFriendsAlbumsFromLondon: {
            EBAlbumsTableViewController *tableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumsTableViewController"];
            tableViewController.navigationItem.title = @"From London";
            [self.navigationController pushViewController:tableViewController animated:YES];
            [EBFacebookPhotos albumsForFriends:nil
                              matchingCriterea:@{@"location": @"London"}
                               albumProperties:@[@"cover_photo", @"name", @"photo_count", @"created"]
                               photoProperties:@[@"src"]
                                       success:^(NSArray *albums) {
                                           [tableViewController setAlbums:albums];
                                       } failure:^(NSError *error) {

                                       }];
            break;
        }
        case TableViewTypeMyProfilePictures:
        case TableViewTypeMyTimelinePictures:
            [self performSegueWithIdentifier:kPushPhotosTableViewController sender:[NSNumber numberWithInteger:indexPath.row]];
            break;
        default:
            break;
    }
}

@end
