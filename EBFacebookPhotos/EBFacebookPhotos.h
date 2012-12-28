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
//  EBFacebookPhotos.h
//  EBFacebookPhotos
//

#import <Foundation/Foundation.h>

@interface EBFacebookPhotos : NSObject

/**
 Fetches all the Profile Pictures owned by the Facebook user
 */
+ (void)myProfilePicturesWithSuccess:(void (^)(NSArray *photos))success
                             failure:(void (^)(NSError *error))failure;

/**
 Fetches all the Timeline Pictures owned by the Facebook user
 */
+ (void)myTimelinePicturesWithSuccess:(void (^)(NSArray *photos))success
                              failure:(void (^)(NSError *error))failure;

/**
 Fetches all the albums owned by the Facebook user.
 
 Album properties are:
  aid, backdated_time, can_backdate, can_upload, comment_info, cover_object_id,
  cover_pid, created, description, edit_link, like_info, link, location,
  modified, modified_major, name, object_id, owner, owner_cursor, photo_count,
  place_id, type, video_count, visible, photos, cover_photo
 
 All album properties except photos and cover_photo are built-in columns
 from the Facebook table 'album'.
 More info here: https://developers.facebook.com/docs/reference/fql/album
 If albumProperties is nil, all properties except cursors are returned.
 
 The photos property is an array of Facebook photo objects.
 If photos is not a property in the albums array, the photo properties are ignored.
 
 Photo properties are:
  aid, aid_cursor, album_object_id, album_object_id_cursor, backdated_time,
  backdated_time_granularity, can_backdate, can_delete, can_tag, caption,
  caption_tags, comment_info, created, images, like_info, link, modified,
  object_id, offline_id, owner, owner_cursor, page_story_id, pid, place_id,
  position, src, src_big, src_big_height, src_big_width, src_height, src_small,
  src_small_height, src_small_width, src_width, target_id, target_type
 
 All photo properties are built-in columns from the Facebook table 'photo'.
 More info here: https://developers.facebook.com/docs/reference/fql/photo
 If photoProperties is nil, all properties except cursors are returned.
 
 The cover_photo property is a Facebook photo object with the same properties
 as the ones specified in the photoProperties array.
 */
+ (void)myAlbumsWithAlbumProperties:(NSArray *)albumProperties
                    photoProperties:(NSArray *)photoProperties
                       success:(void (^)(NSArray *albums))success
                       failure:(void (^)(NSError *error))failure;

/**
 Same method as myAlbumsWithAlbumProperties:photoProperties:success:failure:
 but returns the specified friends' albums instead of the user's albums.
 Each element in the friends array should be an NSString of the friend's uid.

 If friends is nil, all the user's friends are queried.
 
 Warning: use the album property photo with caution, as this has the potential
 of making the response and processing of the Facebook query rather slow.
 */
+ (void)albumsForFriends:(NSArray *)friends
         albumProperties:(NSArray *)albumProperties
         photoProperties:(NSArray *)photoProperties
                 success:(void (^)(NSArray *albums))success
                 failure:(void (^)(NSError *error))failure;

/**
 Same method as albumsForFriends:albumProperties:photoProperties:success:failure:
 but with the addition of a dictionary where keys are album properties and values
 are strings or arrays of strings. The strings are treated case insensitively.
 
 Example of usage: @{@"location": @[@"London", @"San Francisco"]}
 */
+ (void)albumsForFriends:(NSArray *)friends
        matchingCriterea:(NSDictionary *)criterea
         albumProperties:(NSArray *)albumProperties
         photoProperties:(NSArray *)photoProperties
                 success:(void (^)(NSArray *albums))success
                 failure:(void (^)(NSError *error))failure;

@end
