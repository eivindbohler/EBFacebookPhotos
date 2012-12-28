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
//  EBPhotosTableViewController.m
//  EBFacebookPhotos/Examples/PhotoFetcher
//

#import "EBPhotosTableViewController.h"
#import "EBPhotoTableViewCell.h"
#import "EBImageView.h"

@interface EBPhotosTableViewController ()

@property (strong, nonatomic, readonly) NSArray *photos;
@property (strong, nonatomic, readonly) NSDateFormatter *dateFormatter;

@end

@implementation EBPhotosTableViewController

#pragma mark - UIViewController

- (void)awakeFromNib
{
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.locale = [NSLocale currentLocale];
    _dateFormatter.dateStyle = NSDateFormatterShortStyle;
    _dateFormatter.timeStyle = NSDateFormatterShortStyle;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_photos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PhotoCellIdentifier";
    EBPhotoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    NSDictionary *photo = _photos[indexPath.row];
    cell.pictureSizeLabel.text = [NSString stringWithFormat:@"Photo size: %u x %u",
                                  [photo[@"src_width"] unsignedIntegerValue],
                                  [photo[@"src_height"] unsignedIntegerValue]];
    cell.createdAtLabel.text = [NSString stringWithFormat:@"Created at: %@",
                                [_dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[photo[@"created"] doubleValue]]]];
    cell.captionLabel.text = [NSString stringWithFormat:@"Caption: %@", photo[@"caption"]];
    NSString *url = photo[@"src"];
    if ([cell.pictureImageView isImageWithURLNew:url]) {
        [cell.pictureImageView setImageWithURL:url placeholderImage:nil success:^(BOOL usedCachedImage){
            if (!usedCachedImage && !cell.pictureImageView.image) {
                cell.pictureImageView.alpha = 0.0;
                [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    cell.pictureImageView.alpha = 1.0;
                } completion:nil];
            }
        } failure:^{
            NSLog(@"Error fetching image with url %@", url);
        }];
    }
    
    return cell;
}

#pragma mark - Public methods

- (void)setPhotos:(NSArray *)photos
{
    //NSLog(@"%@", photos);
    _photos = photos;
    [self.tableView reloadData];
}

@end
