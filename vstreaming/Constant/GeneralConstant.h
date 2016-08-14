//
//  GeneralConstant.h
//  vstreaming
//
//  Created by developer on 7/24/16.
//  Copyright © 2016 ITGroup. All rights reserved.
//

#ifndef GeneralConstant_h
#define GeneralConstant_h

typedef NS_ENUM(NSInteger, SelectedTab)
{
    QuestionTabSelected = 0,
    ExpertTabSelected,
    SuggestQTTabSelected
};

typedef NS_ENUM(NSInteger, SelectedTabOnProfile)
{
    ProfileExpertTabSelected = 0,
    ShowTabSelected
};

typedef NS_ENUM(NSInteger, SelectedSetting)
{
    Privacy_Policy = 0,
    Rules_Info,
    Terms_Service
};

typedef NS_ENUM(NSInteger, FollowScreenInfoType)
{
    Follower_Screen = 0,
    Following_Screen
};

typedef NS_ENUM(NSInteger, ExpertSearchTapType)
{
    Expert_Tab = 0,
    Tag_Tab
};


typedef NS_ENUM(NSInteger, LiveStreamingScreenMode)
{
    Streaming_Host = 0,
    Streaming_Client
};

#define greenColorForButtons [UIColor colorWithRed:0.3 green:0.57 blue:0.43 alpha:1]

#define SHOWALLERT(title, mes) UIAlertController *controller = \
[UIAlertController alertControllerWithTitle:title \
message:mes \
preferredStyle:UIAlertControllerStyleAlert];\
UIAlertAction *cancelAction = \
[UIAlertAction actionWithTitle:@"OK" \
style:UIAlertActionStyleCancel \
handler:nil];\
[controller addAction:cancelAction];\
[self presentViewController:controller \
animated:YES \
completion:nil];\
controller.view.tintColor = \
greenColorForButtons


#define TOKEN @"token"

//QCloud live active broadcasting identifier
#define REST_SERVER_ADDRESS      @"https://swis.online"
#define REST_API_USERLOGIN       @"/api/rest/user_login"
#define REST_API_USERSIGNIN       @"/api/user/register"
#define REST_API_JOIN_ME        @"/api/rest/join_me"
#define REST_API_CHECK_MD5        @"/api/rest/md5_drawing"

//#define RTMP_SERVER_ADDRESS     @"rtmp://www.intalk.tv:1935/live"
#define RTMP_SERVER_ADDRESS     @"rtmp://10.70.5.11:1935/live"


#endif /* GeneralConstant_h */
