//
//  EBFriendsTableViewController.m
//  EBFacebookPhotos
//
//  Created by Eivind Rannem Bøhler on 12/27/12.
//  Copyright (c) 2012 Eivind R. Boehler. All rights reserved.
//

#import "EBFriendsTableViewController.h"
#import "EBAlbumsTableViewController.h"
#import "EBFacebookPhotos.h"
#import "EBAppDelegate.h"

@interface EBFriendsTableViewController ()

@property (strong, nonatomic, readonly) NSArray *sectionTitles;
@property (strong, nonatomic, readonly) NSArray *sections;

@end

@implementation EBFriendsTableViewController

#pragma mark - UIViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = (NSIndexPath *)sender;
    NSArray *friends = _sections[indexPath.section];
    NSDictionary *friend = friends[indexPath.row];

    UIViewController *destinationViewController = segue.destinationViewController;
    destinationViewController.navigationItem.title = [NSString stringWithFormat:@"%@'s Albums", friend[@"first_name"]];

    [EBFacebookPhotos albumsForFriends:@[friend[@"uid"]]
                       albumProperties:@[@"aid", @"cover_photo", @"name", @"photo_count", @"created"]
                       photoProperties:@[@"src"]
                               success:^(NSArray *albums) {
                                   [(EBAlbumsTableViewController *)destinationViewController setAlbums:albums];
                               } failure:^(NSError *error) {
                                   NSLog(@"Error fetching albums: %@", error);
                               }];

}

#pragma mark - UITableViewDataSource

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return _sectionTitles;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *friends = _sections[section];
    return [friends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"FriendCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    NSArray *friends = _sections[indexPath.section];
    NSDictionary *friend = friends[indexPath.row];
    cell.textLabel.text = friend[@"name"];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:kPushAlbumsTableViewControllerIdentifier sender:indexPath];
}

#pragma mark - Public methods

- (void)setFriends:(NSArray *)friends
{
    NSMutableDictionary *sectionsDictMutable = [NSMutableDictionary dictionary];
    for (NSDictionary *friend in friends) {
        NSString *key = [friend[@"name"] substringWithRange:NSMakeRange(0, 1)];
        NSMutableArray *friendsWithSameLetterMutable = sectionsDictMutable[key];
        if (friendsWithSameLetterMutable) {
            [friendsWithSameLetterMutable addObject:friend];
        } else {
            friendsWithSameLetterMutable = [NSMutableArray arrayWithObject:friend];
            sectionsDictMutable[key] = friendsWithSameLetterMutable;
        }
    }

    _sectionTitles = [[sectionsDictMutable allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *sectionsMutable = [NSMutableArray arrayWithCapacity:[_sectionTitles count]];
    for (NSString *key in _sectionTitles) {
        [sectionsMutable addObject:sectionsDictMutable[key]];
    }
    _sections = [NSArray arrayWithArray:sectionsMutable];
    [self.tableView reloadData];
}

@end
