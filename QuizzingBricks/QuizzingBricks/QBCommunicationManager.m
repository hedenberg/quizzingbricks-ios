//
//  QBCommunicationManager.m
//  QuizzingBricks
//
//  Created by Linus Hedenberg on 2013-11-05.
//  Copyright (c) 2013 Linus Hedenberg. All rights reserved.
//

#import "QBCommunicationManager.h"
#import "QBLobby.h"
#import "QBPlayer.h"

@implementation QBCommunicationManager

- (NSMutableURLRequest *)createRequestWithPost:(NSString *)post endpoint:(NSString *)endpoint
{
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
    //130.240.108.25
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://192.168.2.6:5000%@", endpoint]];
    //NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://130.240.108.196:5000%@", endpoint]];
    //NSURL *url = [[NSURL alloc] initWithString:@"http://130.240.110.120:5000/api/game/lobby/"];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    return request;
}

- (void)loginWithEmail:(NSString *)email password:(NSString *)password
{
    NSString *post = [NSString stringWithFormat:@"email=%@&password=%@", email, password];
    NSMutableURLRequest *request = [self createRequestWithPost:post endpoint:@"/api/user/login/"];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self loginFailedWithError:error];
        } else {
            [self receivedLoginJSON:data];
        }
    }];
}

- (void)getLobbiesWithToken:(NSString *)token
{
    NSLog(@"getLobbies");
    NSString *post = [NSString stringWithFormat:@"token=%@", token];
    NSMutableURLRequest *request = [self createRequestWithPost:post endpoint:@"/api/game/lobby/"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self lobbiesFailedWithError:error];
        } else {
            [self receivedLobbiesJSON:data];
        }
    }];
}

- (void)getLobbyWithToken:(NSString *)token lobbyId:(NSString *)l_id
{
    NSLog(@"getLobbies");
    NSString *post = [NSString stringWithFormat:@"token=%@", token];
    NSMutableURLRequest *request = [self createRequestWithPost:post endpoint:[NSString stringWithFormat:@"/api/game/lobby/%@",l_id]];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self getLobbyFailedWithError:error];
        } else {
            [self receivedLobbyJSON:data];
        }
    }];
}

- (void)receivedLobbyJSON:(NSData *)objectNotation
{
    NSLog(@"lobbyreceived");
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:objectNotation options:0 error:&localError];
    if (localError != nil) {
        [self lobbiesFailedWithError:localError];
    } else {
        NSInteger lobbySize = [[parsedObject objectForKey:@"size"] integerValue];
        BOOL isOwner = [[parsedObject objectForKey:@"owner"] boolValue];
        NSArray *jsonPlayers = [parsedObject objectForKey:@"players"];
        NSMutableArray *players = [[NSMutableArray alloc] init];
        for (NSDictionary *jsonPlayer in jsonPlayers) {
            NSString *statusString = [jsonPlayer objectForKey:@"status"];
            if ([[jsonPlayer objectForKey:@"status"] isEqualToString:@"accepted"]) {
                statusString = @"Accepted";
            } else if ([[jsonPlayer objectForKey:@"status"] isEqualToString:@"waiting"]) {
                statusString = @"Waiting";
            }
            QBPlayer *player = [[QBPlayer alloc] initWithUserID:[jsonPlayer objectForKey:@"u_id"] email:[jsonPlayer objectForKey:@"u_mail"] status:statusString];
            [players addObject:player];
        }
        QBLobby *lobby = [[QBLobby alloc] initWithSize:lobbySize isOwner:isOwner players:players];
        [self.lobbyDelegate lobby:lobby];
    }
}

- (void)getLobbyFailedWithError:(NSError *)error
{
    [self.lobbyDelegate getLobbyFailed];
}

- (void)createLobbyWithToken:(NSString *)token size:(int)size
{
    NSLog(@"createLobby");
    NSString *post = [NSString stringWithFormat:@"token=%@&size=%d", token, size];
    NSMutableURLRequest *request = [self createRequestWithPost:post endpoint:@"/api/game/lobby/create"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self createLobbyFailedWithError:error];
        } else {
            [self receivedCreatedLobbyJSON:data];
        }
    }];
}

- (void)receivedCreatedLobbyJSON:(NSData *)objectNotation
{
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:objectNotation options:0 error:&localError];
    if (localError != nil) {
        [self createLobbyFailedWithError:localError];
        NSLog(@"error creating lobby");
    } else {
        NSLog(@"createdLobbyID:%@", [parsedObject objectForKey:@"l_id"]);
        NSInteger lobbySize = [[parsedObject objectForKey:@"size"] integerValue];
        BOOL isOwner = [[parsedObject objectForKey:@"owner"] boolValue];
        NSArray *jsonPlayers = [parsedObject objectForKey:@"players"];
        NSMutableArray *players = [[NSMutableArray alloc] init];
        for (NSDictionary *jsonPlayer in jsonPlayers) {
            NSString *statusString = [jsonPlayer objectForKey:@"status"];
            if ([[jsonPlayer objectForKey:@"status"] isEqualToString:@"accepted"]) {
                statusString = @"Accepted";
            } else if ([[jsonPlayer objectForKey:@"status"] isEqualToString:@"waiting"]) {
                statusString = @"Waiting";
            }
            QBPlayer *player = [[QBPlayer alloc] initWithUserID:[jsonPlayer objectForKey:@"u_id"] email:[jsonPlayer objectForKey:@"u_mail"] status:statusString];
            [players addObject:player];
        }
        QBLobby *lobby = [[QBLobby alloc] initWithSize:lobbySize isOwner:isOwner players:players];
        [self.lobbyDelegate createdLobby:lobby];
    }
}

- (void)receivedLobbiesJSON:(NSData *)objectNotation
{
    NSLog(@"lobbiesreceived");
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:objectNotation options:0 error:&localError];
    if (localError != nil) {
        [self lobbiesFailedWithError:localError];
    } else {
        NSArray *ls = [parsedObject objectForKey:@"lobbies"];
        NSMutableArray *lobbies = [[NSMutableArray alloc] init];
        for (NSDictionary *l_id in ls) {
            [lobbies addObject:[l_id objectForKey:@"l_id"]];
        }
        [self.lobbyDelegate lobbies:lobbies];
    }
}

- (void)lobbiesFailedWithError:(NSError *)error
{
    [self.lobbyDelegate getLobbiesFailed];
}

- (void)createLobbyFailedWithError:(NSError *)error
{
    [self.lobbyDelegate createLobbyFailed];
}

- (void)receivedLoginJSON:(NSData *)objectNotation
{
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:objectNotation options:0 error:&localError];
    if (localError != nil) {
        [self loginFailedWithError:localError];
        NSLog(@"error wtf");
    } else {
        NSLog(@"receivedToken:%@", [parsedObject objectForKey:@"token"]);
        [self.loginDelegate loginToken:[parsedObject objectForKey:@"token"]];
    }
}

- (void)loginFailedWithError:(NSError *)error
{
    NSLog(@"failed with error: %@",error);
    [self.loginDelegate loginFailed];
}


@end
