// Copyright (c) 2012 Eivind R. Bohler
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//  EBAlbumsTableViewController.m
//  EBFacebookPhotos/Examples/PhotoFetcher
//

#import "EBAlbumsTableViewController.h"
#import "EBAlbumTableViewCell.h"
#import "EBImageView.h"
#import "EBPhotosTableViewController.h"
#import "EBAppDelegate.h"
#import "EBFacebookPhotos.h"

@interface EBAlbumsTableViewController ()

@property (strong, nonatomic, readonly) NSArray *albums;
@property (strong, nonatomic, readonly) NSDateFormatter *dateFormatter;

@end

@implementation EBAlbumsTableViewController

#pragma mark - NSObject

- (void)awakeFromNib
{
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.locale = [NSLocale currentLocale];
    _dateFormatter.dateStyle = NSDateFormatterShortStyle;
    _dateFormatter.timeStyle = NSDateFormatterShortStyle;
}

#pragma mark - UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = (NSIndexPath *)sender;
    NSDictionary *album = _albums[indexPath.row];
    NSString *albumAid = album[@"aid"];
    NSString *albumName = album[@"name"];

    UIViewController *destinationViewController = segue.destinationViewController;
    destinationViewController.navigationItem.title = albumName;
    [EBFacebookPhotos picturesFromAlbum:albumAid
                        photoProperties:@[@"created", @"caption", @"src_width", @"src_height", @"src"]
                                success:^(NSArray *photos) {
                                    if (destinationViewController) {
                                        [(EBPhotosTableViewController *)destinationViewController setPhotos:photos];
                                    }
                                } failure:^(NSError *error) {
                                    NSLog(@"Error fetching photos: %@", error);
                                }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_albums count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AlbumCellIdentifier";
    EBAlbumTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    NSDictionary *album = _albums[indexPath.row];
    NSString *albumName = album[@"name"];
    cell.nameLabel.text = [NSString stringWithFormat:@"Name: %@", albumName ? albumName : @""];
    id albumCreatedAt = album[@"created"];
    NSString *albumCreatedAtText = @"";
    if (albumCreatedAt) {
        albumCreatedAtText = [_dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[albumCreatedAt doubleValue]]];
    }
    cell.createdAtLabel.text = [NSString stringWithFormat:@"Created at: %@", albumCreatedAtText];
    id albumPhotoCount = album[@"photo_count"];
    NSString *albumPhotoCountText = @"";
    if (albumPhotoCount) {
        albumPhotoCountText = [NSString stringWithFormat:@"%lu", (unsigned long)[albumPhotoCount unsignedIntegerValue]];
    }
    cell.numberOfPicturesLabel.text = [NSString stringWithFormat:@"Number of Pictures: %@", albumPhotoCountText];
    NSString *urlString = album[@"cover_photo"][@"src"];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        if ([cell.pictureImageView isImageWithURLNew:url]) {
            [cell.pictureImageView setImageWithURL:url placeholderImage:nil success:^(UIImage *image, BOOL cachedImage) {
                cell.pictureImageView.image = image;
                if (!cachedImage && image) {
                    cell.pictureImageView.alpha = 0.0;
                    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        cell.pictureImageView.alpha = 1.0;
                    } completion:nil];
                }
            } failure:^{
                NSLog(@"Error fetching image with url %@", url);
            }];
        }
    } else {
        cell.pictureImageView.image = nil;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:kPushPhotosTableViewControllerIdentifier sender:indexPath];
}

#pragma mark - Public methods

- (void)setAlbums:(NSArray *)albums
{
    //NSLog(@"%@", albums);
    _albums = albums;
    [self.tableView reloadData];
}

@end
