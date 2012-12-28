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
//  EBFriendsTableViewController.m
//  EBFacebookPhotos/Examples/PhotoFetcher
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
