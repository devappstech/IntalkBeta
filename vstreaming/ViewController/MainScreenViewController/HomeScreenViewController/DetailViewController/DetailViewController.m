//
//  DetailViewController.m
//  vstreaming
//
//  Created by developer on 7/24/16.
//  Copyright © 2016 ITGroup. All rights reserved.
//

#import "DetailViewController.h"
#import <AVKit/AVKit.h>
#import "QuestionViewController.h"
#import "UIView+Screenshot.h"
#import "QuestionTableCell.h"
#import "LECPlayer.h"
#import <mach/mach_time.h>
#import "MP4Writer.h"
#import "Question.h"
#import <UIImageView+AFNetworking.h>
#import <WowzaGoCoderSDK/WowzaGoCoderSDK.h>
#import "Expert.h"
#import "AboutMeTableViewCell.h"
#import "SuggestTableCell.h"
#import "IQKeyboardManager.h"
#import <AliyunPlayerSDK/AliVcMediaPlayer.h>
@interface DetailViewController () <WZStatusCallback, WZVideoSink, LECPlayerDelegate, /*WZVideoEncoderSink, WZAudioEncoderSink,*/ QuestionCellDelegate>{

    LiveStreamingScreenMode screenMode;
    BOOL isCaptureScreen;
    BOOL isFullMode;
    CGRect fullSizeFrame;
    CGRect originalSize;
    UIImage *sound_image;
    CIImage *frameImage;
    NSMutableArray * tableData;
    NSMutableArray * aboutMeData;
    BOOL isGetQuestionRunning;
    BOOL isPageClosed;
    BOOL isClosing;
    BOOL isSeeking;
    NSDate *now;
    int answeredCount;
    NSTimer *mTimer;
}

@property (weak, nonatomic) IBOutlet UIView *selectedQst;
@property (weak, nonatomic) IBOutlet UIView *selectedAboutEpt;
@property (weak, nonatomic) IBOutlet UIView *selectedSuggestQt;
@property (weak, nonatomic) IBOutlet UIView *selectedQstHost;
@property (weak, nonatomic) IBOutlet UIView *selectedMeHost;
@property (weak, nonatomic) IBOutlet UIView *selectedSummaryHost;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *playViewForRecord;
@property (weak, nonatomic) IBOutlet UITableView *questionTableView;
@property (weak, nonatomic) IBOutlet UITableView *fullScreenQuestionView;
@property (weak, nonatomic) IBOutlet UIButton *btnCaptureMode;
@property (weak, nonatomic) IBOutlet UIButton *btnCameraMode;
@property (weak, nonatomic) IBOutlet UIView *tabBarView;
@property (weak, nonatomic) IBOutlet UIView *hostTabBarView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *btnBottomRight;
@property (weak, nonatomic) IBOutlet UITextField *bottomText;
@property (weak, nonatomic) IBOutlet UIButton *btnFullScreenMode;
@property (weak, nonatomic) IBOutlet UIView *bottomChatView;
@property (weak, nonatomic) IBOutlet UIView *fullScreenView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sharingBtnTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *fullScreenHostSideProfile;
@property (weak, nonatomic) IBOutlet UIView *fullScreenClientSideProfile;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UIButton *btnCloseMain;
@property (weak, nonatomic) IBOutlet UILabel *lblStreamFinished;

@property (weak, nonatomic) IBOutlet UIImageView *small_sound_img;
@property (weak, nonatomic) IBOutlet UIImageView *full_sound_img;
@property (weak, nonatomic) IBOutlet UIImageView *hostProfileAvatar;
@property (weak, nonatomic) IBOutlet UIImageView *clientProfileAvatar;
@property (weak, nonatomic) IBOutlet UILabel *clientSideProfileNameOnFullScreen;

@property (nonatomic, strong) WowzaGoCoder *goCoder;
@property (nonatomic, strong) WZCameraPreview *goCoderCameraPreview;
@property (nonatomic, strong) LECPlayer *lecPlayer;
@property (nonatomic, strong) AliVcMediaPlayer* mPlayer;

#pragma mark - MP4Writing
//@property (nonatomic, strong) MP4Writer         *mp4Writer;
//@property (nonatomic, assign) BOOL              writeMP4;
@property (nonatomic, strong) dispatch_queue_t  video_capture_queue;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewConstraint;
@property (weak, nonatomic) IBOutlet UIButton *fullScreenBottomAsk;
@property (weak, nonatomic) IBOutlet UIButton *fullScreenBottomSend;
@property (weak, nonatomic) IBOutlet UISlider *fullScreenBottomSlider;

@end


@implementation DetailViewController

-(void)viewWillAppear:(BOOL)animated{
    if(screenMode == Streaming_Host) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
    isPageClosed = NO;
    if(isGetQuestionRunning == NO){
        [self getQuestions];
    }
    
    [[IQKeyboardManager sharedManager] setEnable:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    if(screenMode == Streaming_Host) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
    
    isPageClosed = YES;
    [[IQKeyboardManager sharedManager] setEnable:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


- (void)keyboardWillChange:(NSNotification *)notification {
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil]; //this is it!
    self.bottomViewConstraint.constant = keyboardRect.size.height;
}

- (void)keyboardDidHide:(NSNotification *)notification {
    self.bottomViewConstraint.constant = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    about key board
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    
    [self initTableView];
    selectedTab = QuestionTabSelected;
    [self setSelectMarksHiddenQuests:NO Expert:YES SuggestQt:YES];
    
    isFullMode = false; isClosing = NO; isSeeking = NO;
    answeredCount = 0;
    fullSizeFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    originalSize = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, self.view.frame.size.width, self.imageView.frame.size.height);
    //originalSize = CGRectMake(0, 0, 200, 100);
    
    [_imageView setFrame:originalSize];
    
    [_fullScreenView setHidden:YES];
    [_btnClose setHidden:YES];
    [_lblStreamFinished setHidden:YES];
    [_small_sound_img setHidden:YES];
    [_full_sound_img setHidden:YES];
    
    if(screenMode == Streaming_Client){
        [self playLiveStreamingVideo];
        
        [_btnCaptureMode setHidden:YES];
        [_btnCameraMode  setHidden:YES];
        [_bottomText setHidden:YES];
        [_fullScreenClientSideProfile setHidden:NO];
        [_btnBottomRight setImage:[UIImage imageNamed:@"icon_gift.png"] forState:UIControlStateNormal];
        [_hostTabBarView setHidden:YES];
        [self initUIForClient];
    }else if(screenMode == Streaming_Host){
        sound_image = [UIImage imageNamed:@"sound_img.png"];
        frameImage = [[CIImage alloc] initWithCGImage:sound_image.CGImage options:nil];
        
        [self initWowzaSDK];
        isCaptureScreen = true;
        [self startLiveStreamingVideo];
        [_bottomText setHidden:NO];
        [_fullScreenHostSideProfile setHidden:NO];
        [_btnBottomRight setImage:[UIImage imageNamed:@"icon_send.png"] forState:UIControlStateNormal];
        [self initUIForHost];
    }else if(screenMode == Streaming_Record){
        
        [self playRecordVideo];
        //[self playLiveStreamingVideo];
        [_btnCaptureMode setHidden:YES];
        [_btnCameraMode  setHidden:YES];
        [_btnFullScreenMode setHidden:YES];
        [_bottomText setHidden:YES];
        [_fullScreenBottomAsk setHidden:YES];
        [_fullScreenBottomSend setHidden:YES];
        [_fullScreenBottomSlider setHidden:NO];
        [_fullScreenClientSideProfile setHidden:NO];
        [_btnBottomRight setImage:[UIImage imageNamed:@"icon_gift.png"] forState:UIControlStateNormal];
        [_hostTabBarView setHidden:YES];
        [self initUIForClient];
        
        
        self.sharingBtnTopConstraint.constant = 35.0f;
        [_btnCloseMain setHidden:YES];
        [_bottomView setHidden:YES];
        [self.tabBarView setHidden:YES];
        [self.questionTableView setHidden:YES];
        [_btnFullScreenMode setImage:[UIImage imageNamed:@"icon_mini_mode.png"] forState:UIControlStateNormal];
        [self.fullScreenView setHidden:NO];
        [_btnClose setHidden:NO];
        
        [_fullScreenBottomSlider setValue:0.0f];
        [_fullScreenBottomSlider setMinimumValue:0];
        
        [_lecPlayer.videoView setFrame:fullSizeFrame];
        [_lecPlayer.videoView setBackgroundColor:[UIColor colorWithRed:44/255.0 green:124/255.0 blue:187/255.0 alpha:1]];
        
        
        [_fullScreenBottomSlider addTarget:self action:@selector(durationSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
        [_fullScreenBottomSlider addTarget:self action:@selector(durationSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
        [_fullScreenBottomSlider addTarget:self action:@selector(durationSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
        
    }else{
        SHOWALLERT(@"Error", @"Configure Error on Setting Screen Mode");
    }
    
    tableData = [NSMutableArray new];
    aboutMeData = [NSMutableArray new];
    [tableData removeAllObjects];
    [self.questionTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.fullScreenQuestionView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    if(isGetQuestionRunning == NO){
        [self getQuestions];
    }
    
    now = [NSDate date];
}

#pragma -mark Private
//-(void) sendBroadCastRequest{
//    [InTalkAPI startBroadcastWithToken:[[User getInstance] getUserToken] Url:self.liveStreamName recordedVidoUrl:self.recoredVideoUrl title:self.liveStreamTitle completion:^(NSDictionary *json, NSError *error) {
//                    if(!error){
//                        if(isPageClosed == NO){
//                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//                                if(isPageClosed == NO){
//                                    [self sendBroadCastRequest];
//                                }
//                            });
//                        }
//                    }
//                }];
//
//}
-(void) durationSliderTouchEnded:(UISlider *) slider{
    [self.mPlayer seekTo:slider.value];
}


-(void) durationSliderTouchBegan:(UISlider *) slider{
    isSeeking = YES;
}
-(void) getQuestions{
    isGetQuestionRunning = YES;
    if(screenMode == Streaming_Client || screenMode == Streaming_Record){
        [InTalkAPI getAllQuestions:[[User getInstance]getUserToken] broadcastId:self.info.item_id competion:^(NSDictionary *resp, NSError *err) {
            if(selectedTab == QuestionTabSelected)
                [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideLoader];
            if(!err){
                [tableData removeAllObjects];
                for(NSDictionary * item in [resp objectForKey:@"data"]){
                    Question *cell = [Question parseDataFromJson:item];
                    [tableData addObject:cell];
                }
                if(isPageClosed == NO){
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        if(isPageClosed == NO){
                            [self getQuestions];
                        }
                    });
                }
                
                if(selectedTab == QuestionTabSelected  && isPageClosed == NO){
                    [self.questionTableView reloadData];
                    [self.fullScreenQuestionView reloadData];
                }
                isGetQuestionRunning = NO;
            }else{
                SHOWALLERT(@"Sending error", err.localizedDescription);
            }
        }];
    }else if(screenMode == Streaming_Host){
        [InTalkAPI getAllQuestions:[[User getInstance]getUserToken] broadcastId:self.info.item_id competion:^(NSDictionary *resp, NSError *err) {
            if(selectedTab == QuestionTabSelected && !isClosing){
                [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideLoader];
            }
            if(!err){
                NSMutableArray * tempData = [NSMutableArray new];
                for(NSDictionary * item in [resp objectForKey:@"data"]){
                    Question *cell = [Question parseDataFromJson:item];
                    [tempData insertObject:cell atIndex:0];
                }
                if([tempData count] > [tableData count]){
                    int lastIndex = [tableData count];
                    for(int i = lastIndex; i < [tempData count]; i++){
                        [tableData addObject:[tempData objectAtIndex:i]];
                    }
                }
                
                if(isPageClosed == NO){
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        if(isPageClosed == NO){
                            [self getQuestions];
                        }
                    });
                }
                
                if(selectedTab == QuestionTabSelected && isPageClosed == NO){
                    [self.questionTableView reloadData];
                    [self.fullScreenQuestionView reloadData];
                }else{
                    isGetQuestionRunning = NO;
                }
            }else{
                SHOWALLERT(@"Sending error", err.localizedDescription);
            }
        }];
    }
}

-(void) initUIForHost{
    User* currentUser = [User getInstance];
    [self.hostProfileAvatar layoutIfNeeded];
    self.hostProfileAvatar.layer.cornerRadius = self.hostProfileAvatar.frame.size.height / 2;
    self.hostProfileAvatar.layer.masksToBounds = YES;
    
    [self.hostProfileAvatar setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:currentUser.avatar_url]]
                         placeholderImage:nil
                                  success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                      [self.hostProfileAvatar setImage:image];
                                  }
                                  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                  }];
}

-(void) initUIForClient{
    [self.clientProfileAvatar layoutIfNeeded];
    self.clientProfileAvatar.layer.cornerRadius = self.clientProfileAvatar.frame.size.height / 2;
    self.clientProfileAvatar.layer.masksToBounds = YES;
    [self.clientProfileAvatar setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.info.avatar_url]]
                                  placeholderImage:nil
                                           success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                               [self.clientProfileAvatar setImage:image];
                                           }
                                           failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                           }];
    [self.clientSideProfileNameOnFullScreen setText:self.info.name];
}
-(void)initWowzaSDK{
    NSError *goCoderLicensingError = [WowzaGoCoder registerLicenseKey:@"GOSK-D342-0103-B43D-39C3-09FB"];
    if (goCoderLicensingError != nil) {
        // Log license key registration failure
        NSLog(@"%@", [goCoderLicensingError localizedDescription]);
    } else {
        // Initialize the GoCoder SDK
        self.goCoder = [WowzaGoCoder sharedInstance];
        
        
        [WowzaGoCoder requestPermissionForType:WowzaGoCoderPermissionTypeCamera response:^(WowzaGoCoderCapturePermission permission) {
            NSLog(@"Camera permission is: %@", permission == WowzaGoCoderCapturePermissionAuthorized ? @"authorized" : @"denied");
        }];
        
        [WowzaGoCoder requestPermissionForType:WowzaGoCoderPermissionTypeMicrophone response:^(WowzaGoCoderCapturePermission permission) {
            NSLog(@"Microphone permission is: %@", permission == WowzaGoCoderCapturePermissionAuthorized ? @"authorized" : @"denied");
        }];
    }
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}



-(void)initTableView{
    //self.questionTableView.scrollEnabled = NO;
    //self.questionTableView.separatorColor = [UIColor clearColor];
    self.questionTableView.allowsSelection = NO;
}


// for playing streaming video
-(void) playLiveStreamingVideo{
    if (!_lecPlayer)
    {
        _lecPlayer = [[LECPlayer alloc] init];
        _lecPlayer.delegate = self;
    }
    _lecPlayer.videoView.frame = originalSize;
    _lecPlayer.videoView.contentMode = UIViewContentModeScaleAspectFill;
    _lecPlayer.videoView.clipsToBounds = YES;
    _lecPlayer.videoView.autoresizingMask =
    UIViewAutoresizingFlexibleTopMargin|
    UIViewAutoresizingFlexibleLeftMargin|
    UIViewAutoresizingFlexibleWidth|
    UIViewAutoresizingFlexibleHeight;
    [_imageView addSubview:_lecPlayer.videoView];
    
    
    
    [_lecPlayer registerWithURLString:_liveStreamName completion:^(BOOL result) {
        if (result){
           [_lecPlayer play];
        }else{
            
        }
    }];
}

-(void)addPlayerObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OnVideoPrepared:)
                                                 name:AliVcMediaPlayerLoadDidPreparedNotification object:self.mPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OnVideoError:)
                                                 name:AliVcMediaPlayerPlaybackErrorNotification object:self.mPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OnVideoFinish:)
                                                 name:AliVcMediaPlayerPlaybackDidFinishNotification object:self.mPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OnSeekDone:)
                                                 name:AliVcMediaPlayerSeekingDidFinishNotification object:self.mPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OnStartCache:)
                                                 name:AliVcMediaPlayerStartCachingNotification object:self.mPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OnEndCache:)
                                                 name:AliVcMediaPlayerEndCachingNotification object:self.mPlayer];
}

- (void)OnStartCache:(NSNotification *)notification {
    //[self showLoadingIndicators];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showLoader];
}

//recieve end cache notification
- (void)OnEndCache:(NSNotification *)notification {
    //[self hideLoadingIndicators];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideLoader];
}

- (void)OnVideoFinish:(NSNotification *)notification {
//    replay = YES;
//    [playBtn setSelected:YES];
//    [self showControls:nil];
//    
//    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"播放完成" message:@"播放完成" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    
//    [alter show];
    
    //    [seekBackwardButton setSelected:NO];
    //    [seekForwardButton setSelected:NO];
}


- (void)OnVideoError:(NSNotification *)notification {
    NSString* error_msg = @"未知错误";
    AliVcMovieErrorCode error_code = self.mPlayer.errorCode;
    
    if(error_code > 500 || error_code == ALIVC_ERR_FUNCTION_DENIED) {
        
        [self.mPlayer reset];
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"播放器错误" message:error_msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alter show];
        return;
    }
    
    if(error_code == ALIVC_ERR_NO_NETWORK) {
        
        [self.mPlayer pause];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示"
                                                        message:error_msg
                                                       delegate:self
                                              cancelButtonTitle:@"等待"
                                              otherButtonTitles:@"重新连接",nil];
        
        [alert show];
    }
    
}



- (void)OnSeekDone:(NSNotification *)notification {
    isSeeking = NO;
}

- (void)OnVideoPrepared:(NSNotification *)notification {
    
    NSTimeInterval duration = self.mPlayer.duration;
    self.fullScreenBottomSlider.maximumValue = duration;
    self.fullScreenBottomSlider.value = self.mPlayer.currentPosition;
}

-(void)UpdatePrg:(NSTimer *)timer{
    if(isSeeking)
        return;
    
    self.fullScreenBottomSlider.value = self.mPlayer.currentPosition;
    
//    double currentTime = floor(self.fullScreenBottomSlider.value);
//    double totalTime = floor(self.mPlayer.duration);
}

-(void)removePlayerObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AliVcMediaPlayerLoadDidPreparedNotification object:self.mPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AliVcMediaPlayerPlaybackErrorNotification object:self.mPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AliVcMediaPlayerPlaybackDidFinishNotification object:self.mPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AliVcMediaPlayerSeekingDidFinishNotification object:self.mPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AliVcMediaPlayerStartCachingNotification object:self.mPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AliVcMediaPlayerEndCachingNotification object:self.mPlayer];
}

-(void) playRecordVideo{
    [_playViewForRecord setHidden:NO];
    [_playViewForRecord setBackgroundColor:[UIColor colorWithRed:44/255.0 green:124/255.0 blue:187/255.0 alpha:1]];
    self.mPlayer = [[AliVcMediaPlayer alloc] init];
    [self.mPlayer create:_playViewForRecord];
    [self addPlayerObserver];
    self.mPlayer.mediaType = MediaType_AUTO;
    self.mPlayer.timeout = 25000;
    self.mPlayer.dropBufferDuration = 8000;
    
    mTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(UpdatePrg:) userInfo:nil repeats:YES];
    [mTimer fire];
    AliVcMovieErrorCode err = [self.mPlayer prepareToPlay:[NSURL URLWithString:self.liveStreamName]];
    if(err != ALIVC_SUCCESS) {
        NSLog(@"preprare failed,error code is %d",(int)err);
        return;
    }
    
    err = [self.mPlayer play];
    if(err != ALIVC_SUCCESS) {
        NSLog(@"play failed,error code is %d",(int)err);
        return;
    }
    [self.mPlayer.view setFrame:fullSizeFrame];
}

-(void) endBroadcast{
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showLoaderWithString:@"Ending..."];
    
    [InTalkAPI stopBroadCasting:[[User getInstance] getUserToken] broadcastID:self.info.item_id Video:nil block:^(NSDictionary *json, NSError *error) {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideLoader];
        if(!error){
            [self dismissViewControllerAnimated:YES completion:nil];
        }else{
            NSLog(@"\n ---EndBroadcast occurs such error %@", error);
            isClosing = NO;
            SHOWALLERT(@"Error", error.localizedDescription);
        }
    }];
}
//for capturing video on hosting side
-(void) startLiveStreamingVideo{
    if(self.goCoder != nil) {
        
        WowzaConfig *broadcastConfig = self.goCoder.config;
        [broadcastConfig loadPreset:WZFrameSizePreset640x480];
        broadcastConfig.capturedVideoRotates = false;
        broadcastConfig.broadcastScaleMode = WZBroadcastScaleModeAspectFit;
        //broadcastConfig.hostAddress = @"10.70.5.1";
        broadcastConfig.hostAddress = @"www.intalk.tv";
        broadcastConfig.applicationName = @"live";
        broadcastConfig.streamName = _liveStreamName;
        //broadcastConfig.streamName = @"myStream";
        
        
        self.goCoder.config = broadcastConfig;
        [self.goCoder registerVideoSink:self];
//        [self.goCoder registerAudioEncoderSink:self];
//        [self.goCoder registerVideoEncoderSink:self];
        self.goCoder.cameraView = _imageView;
        
        self.goCoderCameraPreview = self.goCoder.cameraPreview;
        self.goCoderCameraPreview.previewGravity = WZCameraPreviewGravityResizeAspectFill;
        [self.goCoderCameraPreview startPreview];
        [self doConnect];
        
    }
}

-(void) doConnect{
    if(screenMode == Streaming_Client || screenMode == Streaming_Record) {
        
    }else if(screenMode == Streaming_Host){
        [self.goCoder startStreaming:self];
    }else{
        SHOWALLERT(@"Error", @"Configure Error on Setting Screen Mode");
    }
}

-(void)setDisconnect {
    if( screenMode == Streaming_Client){
        [_lecPlayer unregister];
        [self dismissViewControllerAnimated:YES completion:nil];
    }else if(screenMode == Streaming_Record){
        [self.mPlayer destroy];
        //[_lecPlayer unregister];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if(screenMode == Streaming_Host){
        [_goCoder unregisterVideoSink:self];
//        [_goCoder unregisterAudioEncoderSink:self];
//        [_goCoder unregisterVideoEncoderSink:self];
        [_goCoder endStreaming:self];
        _goCoder = nil;
        //[self dismissViewControllerAnimated:YES completion:nil];
        [self endBroadcast];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)backBtnPressed:(id)sender {
    if(isClosing){ return;}
    isClosing = YES;
    [self setDisconnect];
    
}
- (IBAction)btnCaptureMode:(id)sender {
    isCaptureScreen = !isCaptureScreen;
    if(isCaptureScreen == false) {
        [_full_sound_img setHidden:NO];
        [_small_sound_img setHidden:NO];
    }else{
        [_small_sound_img setHidden:YES];
        [_full_sound_img setHidden:YES];
    }
}
- (IBAction)btnQuestionClicked:(id)sender {
    [self setSelectMarksHiddenQuests:NO Expert:YES SuggestQt:YES];
    selectedTab = QuestionTabSelected;
    //self.questionTableView.scrollEnabled = YES;
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showLoaderWithString:@"Loading Questions..."];
    if(isGetQuestionRunning == NO){
        [self getQuestions];
    }
}
- (IBAction)btnAboutEptClicked:(id)sender {
    [self setSelectMarksHiddenQuests:YES Expert:NO SuggestQt:YES];
    selectedTab = ExpertTabSelected;
    //self.questionTableView.scrollEnabled = NO;
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showLoaderWithString:@"Loading Expert..."];
    [InTalkAPI getExpert:[[User getInstance] getUserToken] userID:self.info.user_id competion:^(NSDictionary *resp, NSError *err) {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideLoader];
        if(!err){
            selectedTab = ExpertTabSelected; // Means about me is selelcted
            [aboutMeData removeAllObjects];
            Expert * expert = [Expert parseDataFromJson:resp];
            [aboutMeData addObject:expert];
            [self.questionTableView reloadData];
        }else{
            SHOWALLERT(@"About Me request Err", err.localizedDescription);
        }
    }];
}
- (IBAction)btnSuggestQtClicked:(id)sender {
    [self setSelectMarksHiddenQuests:YES Expert:YES SuggestQt:NO];
    selectedTab = SuggestQTTabSelected;
    [self.questionTableView reloadData];
}
- (IBAction)btnAskClicked:(id)sender {
    QuestionViewController *questionVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"QuestionViewController"];
    questionVC.broadcastId = self.info.item_id;
    [self presentViewController:questionVC animated:YES completion:nil];
}
- (IBAction)btnFullScreenMode:(id)sender {
    isFullMode = !isFullMode;
    [self switchViewMode];
}
- (IBAction)btnFollow:(id)sender {
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showLoaderWithString:@"Following"];
    [InTalkAPI follow:[[User getInstance]getUserToken] userID:self.info.user_id competion:^(NSDictionary *resp, NSError *err) {
        
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideLoader];
    }];
}

- (IBAction)btnBottomRight:(id)sender {
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showLoaderWithString:@"Sending"];
    
    [InTalkAPI addQuestion:[[User getInstance] getUserToken] broadcastId:self.info.item_id message:self.bottomText.text diamond:@"0" competion:^(NSDictionary *resp, NSError *err) {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideLoader];
        [self.bottomText setText:@""];
        if(!err){
            
        }else{
            SHOWALLERT(@"Sending error", err.localizedDescription);
        }
    }];
}

-(void)switchViewMode{
    if(isFullMode == true) {
        if(screenMode == Streaming_Client){
            self.sharingBtnTopConstraint.constant = 35.0f;
            [_btnCloseMain setHidden:YES];
            [_bottomView setHidden:YES];
            [_lecPlayer.videoView setFrame:fullSizeFrame];
            [_lecPlayer.videoView setBackgroundColor:[UIColor colorWithRed:44/255.0 green:124/255.0 blue:187/255.0 alpha:1]];
        }else{
            [_btnCloseMain setHidden:YES];
            [_goCoderCameraPreview.previewLayer setFrame:fullSizeFrame];
        }
        
        [self.tabBarView setHidden:YES];
        [self.questionTableView setHidden:YES];
        [_btnFullScreenMode setImage:[UIImage imageNamed:@"icon_mini_mode.png"] forState:UIControlStateNormal];
        [self.fullScreenView setHidden:NO];
        [_btnClose setHidden:NO];
        
    }else {
        if(screenMode == Streaming_Client){
            self.sharingBtnTopConstraint.constant = 2.0f;
            [_bottomView setHidden:NO];
            [_btnCloseMain setHidden:NO];
            [_lecPlayer.videoView setFrame:originalSize];
        }else{
            [_btnCloseMain setHidden:NO];
            [_goCoderCameraPreview.previewLayer setFrame:originalSize];
        }
        
        [self.bottomView setHidden:NO];
        [self.tabBarView setHidden:NO];
        [self.questionTableView setHidden:NO];
        [_btnFullScreenMode setImage:[UIImage imageNamed:@"icon_full_mode.png"] forState:UIControlStateNormal];
        [self.fullScreenView setHidden:YES];
        [_btnClose setHidden:YES];
    }
    
}

- (IBAction)btnUpFrontandBackCameraMode:(id)sender {

    [_goCoderCameraPreview switchCamera];
}

-(void) setSelectMarksHiddenQuests:(BOOL)qs Expert:(BOOL)ae SuggestQt:(BOOL)sq{
    [self.selectedQst setHidden:qs];
    [self.selectedAboutEpt setHidden:ae];
    [self.selectedSuggestQt setHidden:sq];
    
    [_selectedQstHost setHidden:qs];
    [_selectedMeHost setHidden:ae];
    [_selectedSummaryHost setHidden:sq];
}


-(void)setScreenMode:(LiveStreamingScreenMode)mode{
    screenMode = mode;  //this set this screen is the screen of hosting side or client side
}

-(void)pixelBufferShouldBePublished:(CVPixelBufferRef)pixelBuffer timestamp:(int)timestamp
{
    NSLog(@"width:%zu height:%zu",CVPixelBufferGetWidth(pixelBuffer),CVPixelBufferGetHeight(pixelBuffer));
}

#pragma Table View delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(selectedTab == SuggestQTTabSelected && tableView == _questionTableView){
        if(screenMode == Streaming_Host)
            return 1;
        else if(screenMode == Streaming_Client)
            return 0;
    }else if(selectedTab == ExpertTabSelected && tableView == _questionTableView){
        return [aboutMeData count];
    }
    return [tableData count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell;
    if(tableView == _questionTableView) {
        if(selectedTab == QuestionTabSelected){
            QuestionTableCell *questionCell = [tableView dequeueReusableCellWithIdentifier:@"QuestionTableCell"];
            [questionCell setScreenMode:screenMode];
            int lastIndex = [tableData count] - 1;
            [questionCell initCell:[tableData objectAtIndex:lastIndex - indexPath.row] questionIndex:lastIndex - indexPath.row];
            questionCell.delegate = self;
            cell = questionCell;
        }else if(selectedTab == ExpertTabSelected){
            AboutMeTableViewCell* expertCell = [tableView dequeueReusableCellWithIdentifier:@"AboutMeTableViewCell"];
            [expertCell initCell:[aboutMeData objectAtIndex:indexPath.row]];
            cell = expertCell;
        }else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"SuggestTableCell"];
            SuggestTableCell * suggestCell = (SuggestTableCell*) cell;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"hh:mma";
            [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
            [suggestCell initUI:answeredCount startTime:[dateFormatter stringFromDate:now] startDate:now];
        }
    }else{
        QuestionTableCellForFullScreen *questionCell = [tableView dequeueReusableCellWithIdentifier:@"QuestionTableCellForFullScreen"];
        questionCell.delegate = self;
        [questionCell setScreenMode:screenMode];
        int lastIndex = [tableData count] - 1;
        [questionCell initCell:[tableData objectAtIndex:lastIndex - indexPath.row] questionIndex:lastIndex - indexPath.row];
        cell = questionCell;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(tableView == self.questionTableView){
        if(selectedTab == ExpertTabSelected ){
            return 248;
        }else if(selectedTab == SuggestQTTabSelected){
            return 240;
        }
    }
    return 40;
}

#pragma mark - WZStatusCallback Protocol Instance Methods

-(void)onWZStatus:(WZStatus *)goCoderStatus{
//    switch (goCoderStatus.state) {
//            
//        case WZStateIdle:
//            if (self.writeMP4 && self.mp4Writer.writing) {
//                if (self.video_capture_queue) {
//                    dispatch_async(self.video_capture_queue, ^{
//                        [self.mp4Writer stopWriting];
//                    });
//                }
//                else {
//                    [self.mp4Writer stopWriting];
//                }
//            }
//            self.writeMP4 = NO;
//            break;
//        case WZStateRunning:
//            // A streaming broadcast session is running
//            self.writeMP4 = NO;
//            self.mp4Writer = [MP4Writer new];
//            self.writeMP4 = [self.mp4Writer prepareWithConfig:self.goCoder.config];
//            if (self.writeMP4) {
//                [self.mp4Writer startWriting];
//            }
//            break;
//            
//        case WZStateStopping:
//            // A streaming broadcast session is shutting down
//            break;
//            
//        default:
//            break;
//    }
   
}

-(void)onWZError:(WZStatus *)status{
    
}

-(void)onWZEvent:(WZStatus *)status{
    
}

#pragma mark - WZVideoSink
- (void) videoFrameWasCaptured:(nonnull CVImageBufferRef)imageBuffer framePresentationTime:(CMTime)framePresentationTime frameDuration:(CMTime)frameDuration {
    if (self.goCoder.isStreaming) {
        
        if (isCaptureScreen == false) {
            size_t width = CVPixelBufferGetWidth(imageBuffer);
            size_t height = CVPixelBufferGetHeight(imageBuffer);
            
            CIVector *cropRect =[CIVector vectorWithX:0 Y:0 Z: width W: height];
            
            CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
            
            [cropFilter setValue:frameImage forKey:@"inputImage"];
            [cropFilter setValue:cropRect forKey:@"inputRectangle"];
            
            frameImage = [cropFilter valueForKey:@"outputImage"];
            
            //CIFilter *scalefilter = [CIFilter filterWithName:@"CIPhotoEffectTonal"];
            //[grayFilter setValue:frameImage forKeyPath:@"inputImage"];
            //frameImage = [grayFilter outputImage];
            
            CIContext * context = [CIContext contextWithOptions:nil];
            
            [context render:[CIImage imageWithColor:[CIColor colorWithRed:45/255.0 green:123/255.0 blue:187/255.0]] toCVPixelBuffer:imageBuffer];
            [context render:frameImage toCVPixelBuffer:imageBuffer];
        }
        
    }
}

- (void) videoCaptureInterruptionStarted {
//    if (!self.goCoderConfig.backgroundBroadcastEnabled) {
//        [self.goCoder endStreaming:self];
//    }
}

- (void) videoCaptureUsingQueue:(nullable dispatch_queue_t)queue {
//    self.video_capture_queue = queue;
}

//#pragma mark - WZAudioEncoderSink
//- (void) audioSampleWasEncoded:(nullable CMSampleBufferRef)data {
//    if (self.writeMP4) {
//        [self.mp4Writer appendAudioSample:data];
//    }
//}
//
//
//#pragma mark - WZVideoEncoderSink
//- (void) videoFrameWasEncoded:(nonnull CMSampleBufferRef)data {
//    if (self.writeMP4) {
//        [self.mp4Writer appendVideoSample:data];
//    }
//}
//


#pragma mark - LECPlayerDelegate
/*播放器播放状态*/
- (void) lecPlayer:(LECPlayer *) player
       playerEvent:(LECPlayerPlayEvent) playerEvent
{
    switch (playerEvent)
    {
        case LECPlayerPlayEventPrepareDone:
            break;
        case LECPlayerPlayEventEOS:
            NSLog(@"播放结束");
//            [self showTips:@"直播播放结束"];
//            _isPlay = NO;
//            [_playStateButton setTitle:@"播放" forState:(UIControlStateNormal)];
            break;
        case LECPlayerPlayEventGetVideoSize:
            
            NSLog(@"width %f height %f",player.actualVideoWidth, player.actualVideoHeight);
//            NSLog(@"playerViewFrame:%@",NSStringFromCGSize(_playerView.frame.size));
            
            break;
        case LECPlayerPlayEventRenderFirstPic:
            NSLog(@"LECPlayerPlayEventRenderFirstPic:width %f height %f",player.actualVideoWidth, player.actualVideoHeight);
//            [_loadIndicatorView stopAnimating];
            break;
        case LECPlayerPlayEventBufferStart:
//            _loadIndicatorView.hidden = NO;
//            [_loadIndicatorView startAnimating];
            NSLog(@"开始缓冲");
            break;
        case LECPlayerPlayEventBufferEnd:
//            [_loadIndicatorView stopAnimating];
            NSLog(@"缓冲结束");
            break;
            
        case LECPlayerPlayEventSeekComplete:
            NSLog(@"完成Seek操作");
            break;
            
        case LECPlayerPlayEventNoStream:
        {
            NSString * error = [NSString stringWithFormat:@"%@:%@",player.errorCode,player.errorDescription];
            NSLog(@"无媒体信息:%@",error);
//            [self showTips:@"无媒体信息,请检查url"];
//            [_loadIndicatorView stopAnimating];
        }
            break;
        case LECPlayerPlayEventPlayError:
        {
            NSString * error = [NSString stringWithFormat:@"%@:%@",player.errorCode,player.errorDescription];
            NSLog(@"播放器错误:%@",error);
//            [self showTips:@"播放器错误"];
//            [_loadIndicatorView stopAnimating];
//            [self showTips:error];
        }
            break;
        default:
            break;
    }
}

/*播放器播放时间回调*/
- (void) lecPlayer:(LECPlayer *) player
          position:(int64_t) position
     cacheDuration:(int64_t) cacheDuration
          duration:(int64_t) duration{
        NSLog(@"播放位置:%lld,缓冲位置:%lld,总时长:%lld",position,cacheDuration,duration);
//    if(isSeeking == NO){
//        [_fullScreenBottomSlider setMaximumValue:duration - 1];
//        _fullScreenBottomSlider.value = position;
//    }
}

- (void) lecPlayer:(LECPlayer *) player contentTypeChanged:(LECPlayerContentType) contentType
{
    switch (contentType)
    {
        case LECPlayerContentTypeFeature:
            NSLog(@"正在播放正片");
            break;
        case LECPlayerContentTypeAdv:
            NSLog(@"正在播放广告");
            break;
            
        default:
            break;
    }
}

#pragma mark - QuestionCellDelegate
-(void)didAnswerBtnPressed:(int)questionID questionIndex:(int)index{
    HomeTableItemModel *item = [tableData objectAtIndex:index];
    [tableData removeObjectAtIndex:index];
    [tableData addObject:item];
    [self.questionTableView reloadData];
    [self.fullScreenQuestionView reloadData];
    answeredCount ++;
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showLoaderWithString:@"Sending..."];
    [InTalkAPI addAnswer:[[User getInstance] getUserToken]  questionId:questionID answer:@"answer" competion:^(NSDictionary *resp, NSError *err) {
            [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideLoader];
    }];
}


@end

