# EBFacebookPhotos
EBFacebookPhotos for iOS is designed to make it easy to fetch photo albums and photos through the Facebook SDK using as few HTTP requests as possible.

## How To Get Started
- If you haven't already, download and install [CocoaPods](https://github.com/CocoaPods/CocoaPods).
- [Download EBFacebookPhotos (zipped)](https://github.com/eivindbohler/EBFacebookPhotos/zipball/master) or clone the git repo.
- Run pod install.
- Open EBFacebookPhotos.xcworkspace and try out the included iOS example app "PhotoFetcher"

## How To Use
- Include EBFacebookPhotos in your Podfile, and run the pod install command:  
``` ruby
platform :ios, '5.1'

pod 'EBFacebookPhotos', :git => 'https://github.com/eivindbohler/EBFacebookPhotos.git', :tag => '0.0.2'
```

- Run the pod install command:  
```
$ pod install
```

- [Read the documentation](https://developers.facebook.com/docs/getting-started/getting-started-with-the-ios-sdk) for Facebook SDK setup instructions
- Enjoy!

## Example
``` objective-c
[EBFacebookPhotos albumsForFriends:nil
                  matchingCriteria:@{@"location": @"London"}
                   albumProperties:@[@"cover_photo", @"name", @"photo_count", @"created"]
                   photoProperties:@[@"src"]
                           success:^(NSArray *albums) {
                               [albumsViewController setAlbums:albums];
                           } failure:^(NSError *error) {
                               NSLog(@"Error fetching albums: %@", error);
                           }];

```
``` objective-c
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
```

## Contact
Mail: [eivind.bohler@gmail.com](mailto:eivind.bohler@gmail.com)  
GitHub: [github.com/eivindbohler](http://github.com/eivindbohler)  
Twitter: [@eivindbohler](https://twitter.com/eivindbohler)  
LinkedIn: [no.linkedin.com/in/eivindbohler](http://no.linkedin.com/in/eivindbohler)

## License
EBFacebookPhotos is available under the MIT license. See the LICENSE file for more info.