//
//  QBCommunicationManager.h
//  QuizzingBricks
//
//  Created by Linus Hedenberg on 2013-11-05.
//  Copyright (c) 2013 Linus Hedenberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QBLobby.h"

@protocol QBLoginComDelegate <NSObject>

- (void)loginToken:(NSString *) token;
- (void)loginFailed;

@end

@protocol QBLobbyComDelegate <NSObject>

- (void)lobbies:(NSArray *)lobbyList;
- (void)getLobbiesFailed;
- (void)lobby:(QBLobby *)l;
- (void)getLobbyFailed;
- (void)createdLobby:(QBLobby *)l;
- (void)createLobbyFailed;

@end

@interface QBCommunicationManager : NSObject

{
    id <QBLoginComDelegate> _loginDelegate;
    id <QBLobbyComDelegate> _lobbyDelegate;
}
@property (nonatomic, strong) id loginDelegate;
@property (nonatomic, strong) id lobbyDelegate;

- (void)loginWithEmail:(NSString *)username password:(NSString *)password;
- (void)getLobbiesWithToken:(NSString *)token;
- (void)createLobbyWithToken:(NSString *)token size:(int)size;
- (void)getLobbyWithToken:(NSString *)token lobbyId:(NSString *)l_id;

@end