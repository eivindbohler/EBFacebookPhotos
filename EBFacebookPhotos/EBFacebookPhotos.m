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
//  EBFacebookPhotos.m
//  EBFacebookPhotos
//

#import "EBFacebookPhotos.h"
#import "FacebookSDK.h"

NSString *const kAlbumProperties = @"aid, backdated_time, can_backdate, can_upload, comment_info, "
                                   @"cover_object_id, cover_pid, created, description, edit_link, "
                                   @"like_info, link, location, modified, modified_major, name, "
                                   @"object_id, owner, photo_count, place_id, type, video_count, "
                                   @"visible";

NSString *const kPhotoProperties = @"aid, album_object_id, backdated_time, backdated_time_granularity, "
                                   @"can_backdate, can_delete, can_tag, caption, caption_tags, "
                                   @"comment_info, created, images, like_info, link, modified, "
                                   @"object_id, offline_id, owner, page_story_id, pid, place_id, "
                                   @"position, src, src_big, src_big_height, src_big_width, "
                                   @"src_height, src_small, src_small_height, src_small_width, "
                                   @"src_width, target_id, target_type";

@implementation EBFacebookPhotos

#pragma mark - Public methods

+ (void)myProfilePicturesWithPhotoProperties:(NSArray *)photoProperties
                                     success:(void (^)(NSArray *))success
                                     failure:(void (^)(NSError *))failure
{
    NSString *query = @"aid IN (SELECT aid FROM album WHERE owner = me() AND name = \"Profile Pictures\")";
    [[self class] picturesWithQuery:query photoProperties:photoProperties success:success failure:failure];
}

+ (void)myTimelinePicturesWithPhotoProperties:(NSArray *)photoProperties
                                      success:(void (^)(NSArray *))success
                                      failure:(void (^)(NSError *))failure
{
    NSString *query = @"aid IN (SELECT aid FROM album WHERE owner = me() AND name = \"Timeline Photos\")";
    [[self class] picturesWithQuery:query photoProperties:photoProperties success:success failure:failure];
}

+ (void)picturesFromAlbum:(NSString *)albumId
          photoProperties:(NSArray *)photoProperties
                  success:(void (^)(NSArray *))success
                  failure:(void (^)(NSError *))failure
{
    NSString *query = [NSString stringWithFormat:@"aid = %@", albumId];
    [[self class] picturesWithQuery:query photoProperties:photoProperties success:success failure:failure];
}

+ (void)myAlbumsWithAlbumProperties:(NSArray *)albumProperties
                    photoProperties:(NSArray *)photoProperties
                            success:(void (^)(NSArray *))success
                            failure:(void (^)(NSError *))failure
{
    [[self class] albumsWithOwnerQuery:@"= me()"
                         matchingQuery:nil
                       albumProperties:albumProperties
                       photoProperties:photoProperties
                               success:success
                               failure:failure];
}

+ (void)albumsForFriends:(NSArray *)friends
         albumProperties:(NSArray *)albumProperties
         photoProperties:(NSArray *)photoProperties
                 success:(void (^)(NSArray *))success
                 failure:(void (^)(NSError *))failure
{
    [[self class] albumsForFriends:friends
                  matchingCriteria:nil
                   albumProperties:albumProperties
                   photoProperties:photoProperties
                           success:success
                           failure:failure];
}

+ (void)albumsForFriends:(NSArray *)friends
        matchingCriteria:(NSDictionary *)criteria
         albumProperties:(NSArray *)albumProperties
         photoProperties:(NSArray *)photoProperties
                 success:(void (^)(NSArray *))success
                 failure:(void (^)(NSError *))failure
{
    NSString *ownerQuery;
    if (friends) {
        NSMutableString *ownersMutable = [NSMutableString string];
        for (NSString *friendUid in friends) {
            [ownersMutable appendFormat:@"%@%@", [ownersMutable length] > 0 ? @", " : @"", friendUid];
        }
        ownerQuery = [NSString stringWithFormat:@"IN (%@)", ownersMutable];
    } else {
        ownerQuery = @"IN (SELECT uid2 FROM friend WHERE uid1 = me())";
    }

    NSString *matchingQueryString = nil;
    if (criteria) {
        NSMutableString *matchingQueryMutableString = [NSMutableString string];
        for (NSString *key in [criteria allKeys]) {
            id value = criteria[key];
            if ([value isKindOfClass:[NSString class]]) {
                [matchingQueryMutableString appendFormat:@" AND lower(%@) IN (\\\"%@\\\")", [key lowercaseString], [(NSString *)value lowercaseString]];
            } else if ([value isKindOfClass:[NSArray class]]) {
                NSMutableString *values = [NSMutableString string];
                for (NSString *valueString in (NSArray *)value) {
                    [values appendFormat:@"%@\\\"%@\\\"", [valueString length] > 0 ? @", " : @"", [valueString lowercaseString]];
                }
                [matchingQueryMutableString appendFormat:@" AND lower(%@) IN (%@)", [key lowercaseString], values];
            }
        }
        matchingQueryString = [NSString stringWithString:matchingQueryMutableString];
    }
    
    [[self class] albumsWithOwnerQuery:ownerQuery
                         matchingQuery:matchingQueryString
                       albumProperties:albumProperties
                       photoProperties:photoProperties
                               success:success
                               failure:failure];
}

#pragma mark - Private methods

+ (void)albumsWithOwnerQuery:(NSString *)ownerQuery
               matchingQuery:(NSString *)matchingQuery
             albumProperties:(NSArray *)albumProperties
             photoProperties:(NSArray *)photoProperties
                     success:(void (^)(NSArray *))success
                     failure:(void (^)(NSError *))failure
{
    BOOL fetchPhotos = NO;
    BOOL fetchCoverPhoto = NO;
    BOOL foundAlbumCoverObjectId = NO;
    BOOL foundAlbumAid = NO;

    NSString *albumPropertiesString;
    if (!albumProperties) {
        albumPropertiesString = kAlbumProperties;
        fetchPhotos = YES;
        fetchCoverPhoto = YES;
        foundAlbumCoverObjectId = YES;
        foundAlbumAid = YES;
    } else {
        NSMutableString *albumPropertiesMutableString = [NSMutableString string];

        for (NSUInteger i = 0; i < [albumProperties count]; i++) {
            NSString *property = [albumProperties[i] lowercaseString];
            if ([property isEqualToString:@"photos"]) {
                fetchPhotos = YES;
            } else if ([property isEqualToString:@"cover_photo"]) {
                fetchCoverPhoto = YES;
            } else {
                if ([property isEqualToString:@"cover_object_id"]) {
                    foundAlbumCoverObjectId = YES;
                } else if ([property isEqualToString:@"aid"]) {
                    foundAlbumAid = YES;
                }
                [albumPropertiesMutableString appendFormat:@"%@%@", [albumPropertiesMutableString length] > 0 ? @", " : @"", property];
            }
        }

        if (fetchCoverPhoto && !foundAlbumCoverObjectId) {
            [albumPropertiesMutableString appendFormat:@"%@%@", [albumPropertiesMutableString length] > 0 ? @", " : @"", @"cover_object_id"];
        }
        if (!foundAlbumAid) {
            [albumPropertiesMutableString appendFormat:@"%@%@", [albumPropertiesMutableString length] > 0 ? @", " : @"", @"aid"];
        }

        albumPropertiesString = [NSString stringWithString:albumPropertiesMutableString];
    }

    NSString *query = [NSString stringWithFormat:@"{\"albums\":\"SELECT %@ FROM album WHERE owner %@", albumPropertiesString, ownerQuery];

    if (matchingQuery) {
        query = [NSString stringWithFormat:@"%@%@", query, matchingQuery];
    }
    query = [NSString stringWithFormat:@"%@%@", query, @"\""];

    NSString *photoPropertiesString;
    if (!photoProperties) {
        photoPropertiesString = kPhotoProperties;
    } else {
        NSMutableString *photoPropertiesMutableString = [NSMutableString string];

        BOOL foundPhotoObjectId = NO;
        BOOL foundPhotoAid = NO;

        for (NSUInteger i = 0; i < [photoProperties count]; i++) {
            NSString *property = [photoProperties[i] lowercaseString];
            if ([property isEqualToString:@"object_id"]) {
                foundPhotoObjectId = YES;
            } else if ([property isEqualToString:@"aid"]) {
                foundPhotoAid = YES;
            }
            [photoPropertiesMutableString appendFormat:@"%@%@", [photoPropertiesMutableString length] > 0 ? @", " : @"", property];
        }

        if (fetchCoverPhoto && !foundPhotoObjectId) {
            [photoPropertiesMutableString appendFormat:@"%@%@", [photoPropertiesMutableString length] > 0 ? @", " : @"", @"object_id"];
        }
        if (fetchPhotos && !foundPhotoAid) {
            [photoPropertiesMutableString appendFormat:@"%@%@", [photoPropertiesMutableString length] > 0 ? @", " : @"", @"aid"];
        }

        photoPropertiesString = [NSString stringWithString:photoPropertiesMutableString];
    }

    if (fetchCoverPhoto && !fetchPhotos) {
        query = [NSString stringWithFormat:@"%@,\"photos\":\"SELECT %@ FROM photo WHERE object_id IN (SELECT cover_object_id FROM #albums)\"}",
                 query, photoPropertiesString];
    } else if (fetchPhotos) {
        query = [NSString stringWithFormat:@"%@,\"photos\":\"SELECT %@ FROM photo WHERE aid IN (SELECT aid FROM #albums)\"}",
                 query, photoPropertiesString];
    } else {
        query = [NSString stringWithFormat:@"%@}", query];
    }

    NSLog(@"query = %@", query);

    [[self class] albumsWithQuery:query success:success failure:failure];
}

+ (void)albumsWithQuery:(NSString *)query
                success:(void (^)(NSArray *))success
                failure:(void (^)(NSError *))failure
{
    [FBRequestConnection startWithGraphPath:@"/fql"
                                 parameters:@{@"q": query}
                                 HTTPMethod:@"GET"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                  if ([result isKindOfClass:[NSDictionary class]]) {
                                      //NSLog(@"%@", result);
                                      NSArray *data = result[@"data"];
                                      if ([data isKindOfClass:[NSArray class]]) {
                                          NSArray *albums = nil;
                                          NSArray *photos = nil;
                                          for (NSDictionary *dataDict in data) {
                                              if ([dataDict isKindOfClass:[NSDictionary class]]) {
                                                  NSString *dataDictName = dataDict[@"name"];
                                                  if ([dataDictName isKindOfClass:[NSString class]] && [dataDictName isEqualToString:@"albums"]) {
                                                      NSArray *albumsArray = dataDict[@"fql_result_set"];
                                                      if ([albumsArray isKindOfClass:[NSArray class]]) {
                                                          albums = albumsArray;
                                                      }
                                                  } else if ([dataDictName isKindOfClass:[NSString class]] && [dataDictName isEqualToString:@"photos"]) {
                                                      NSArray *photosArray = dataDict[@"fql_result_set"];
                                                      if ([photosArray isKindOfClass:[NSArray class]]) {
                                                          photos = photosArray;
                                                      }
                                                  }
                                              }
                                          }
                                          [[self class] connectPhotos:photos toAlbums:albums];
                                          albums = [albums sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *album1, NSDictionary *album2) {
                                              NSString *album1Name = album1[@"name"];
                                              NSString *album2Name = album2[@"name"];
                                              if ([album1Name isKindOfClass:[NSString class]] && [album2Name isKindOfClass:[NSString class]] &&
                                                  [album1Name length] > 0 && [album2Name length] > 0) {
                                                  return [album1Name compare:album2Name];
                                              } else {
                                                  return NSOrderedAscending;
                                              }
                                          }];
                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                              success(albums);
                                          });
                                          return;
                                      }
                                  }
                                  dispatch_sync(dispatch_get_main_queue(), ^{
                                      failure(error);
                                  });
                              });
                          }];
}

+ (void)picturesWithQuery:(NSString *)query
          photoProperties:(NSArray *)photoProperties
                  success:(void (^)(NSArray *))success
                  failure:(void (^)(NSError *))failure
{
    NSString *photoPropertiesString;
    if (!photoProperties) {
        photoPropertiesString = kPhotoProperties;
    } else {
        NSMutableString *photoPropertiesMutableString = [NSMutableString string];
        for (NSString *property in photoProperties) {
            [photoPropertiesMutableString appendFormat:@"%@%@", [photoPropertiesMutableString length] > 0 ? @", " : @"", property];
        }
        photoPropertiesString = [NSString stringWithString:photoPropertiesMutableString];
    }

    NSString *queryString = [NSString stringWithFormat:@"SELECT %@ FROM photo WHERE %@", photoPropertiesString, query];

    [FBRequestConnection startWithGraphPath:@"/fql"
                                 parameters:@{@"q": queryString}
                                 HTTPMethod:@"GET"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if ([result isKindOfClass:[NSDictionary class]]) {
                                  NSLog(@"%@", result);
                                  NSArray *photos = result[@"data"];
                                  success(photos);
                              } else {
                                  failure(error);
                              }
                          }];
}

+ (void)connectPhotos:(NSArray *)photos toAlbums:(NSArray *)albums
{
    for (NSDictionary *photo in photos) {
        NSString *aid = photo[@"aid"];
        if (aid) {
            aid = [NSString stringWithFormat:@"%@", aid];
        }
        if (aid) {
            for (NSMutableDictionary *album in albums) {
                NSString *albumAid = album[@"aid"];
                if (albumAid) {
                    albumAid = [NSString stringWithFormat:@"%@", albumAid];
                }
                if (albumAid && [aid isEqualToString:albumAid]) {
                    NSMutableArray *albumPhotosMutable = album[@"photos"];
                    if (albumPhotosMutable) {
                        [albumPhotosMutable addObject:photo];
                    } else {
                        albumPhotosMutable = [NSMutableArray arrayWithObject:photo];
                        album[@"photos"] = albumPhotosMutable;
                    }
                    break;
                }
            }
        }

        NSString *objectId = photo[@"object_id"];
        if (objectId) {
            objectId = [NSString stringWithFormat:@"%@", objectId];
        }
        if (objectId) {
            for (NSMutableDictionary *album in albums) {
                NSString *coverObjectId = album[@"cover_object_id"];
                if (coverObjectId) {
                    coverObjectId = [NSString stringWithFormat:@"%@", coverObjectId];
                }
                if (coverObjectId && [objectId isEqualToString:coverObjectId]) {
                    album[@"cover_photo"] = photo;
                    break;
                }
            }
        }
    }
}

@end
