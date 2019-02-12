//
//  ShowLiveViewController.m
//  livestream
//
//  Created by Calvin on 2018/5/2.
//  Copyright © 2018年 net.qdating. All rights reserved.
//

#import "ShowLiveViewController.h"
#import "LSMainViewController.h"
#import "LSAddCreditsViewController.h"

#import "SetFavoriteRequest.h"
#import "LiveFansListRequest.h"

#import "LSLoginManager.h"
#import "LiveModule.h"
#import "AudienModel.h"
#import "RoomTypeIsFirstManager.h"
#import "LSUserInfoManager.h"
#import "LiveRoomCreditRebateManager.h"
#import "AnchorPersonalViewController.h"
#import "DialogTip.h"
#import "DialogChoose.h"
#import "LSImageViewLoader.h"

@interface ShowLiveViewController ()
<IMManagerDelegate, IMLiveRoomManagerDelegate,PlayViewControllerDelegate>

// 观众数组
@property (nonatomic, strong) NSMutableArray *audienceArray;

@property (nonatomic, strong) NSTimer *hidenTimer;

@property (nonatomic, assign) BOOL isTipShow;

@property (nonatomic, assign) BOOL isClickGot;

// 管理器
@property (nonatomic, strong) LSImManager *imManager;

@property (nonatomic, strong) LSLoginManager *loginManager;

@property (nonatomic, strong) LSSessionRequestManager *sessionManager;

// 是否第一次进类型直播间管理器
@property (nonatomic, strong) RoomTypeIsFirstManager *firstManager;

#pragma mark - toast控件
@property (nonatomic, strong) DialogTip *dialogTipView;
@property (nonatomic, strong) DialogChoose *closeDialogTipView;

@property (nonatomic, strong) LSImageViewLoader *ladyImageLoader;
@end

@implementation ShowLiveViewController

- (void)initCustomParam {
    [super initCustomParam];
    
    NSLog(@"PublicVipViewController::initCustomParam( self : %p )", self);
    
    self.sessionManager = [LSSessionRequestManager manager];
    self.firstManager = [RoomTypeIsFirstManager manager];
    self.imManager = [LSImManager manager];
    [self.imManager addDelegate:self];
    [self.imManager.client addDelegate:self];
    
    self.dialogTipView = [DialogTip dialogTip];
    self.audienceArray = [[NSMutableArray alloc] init];
    
    self.ladyImageLoader = [LSImageViewLoader loader];
}

- (void)setupContainView {
    [super setupContainView];
    
    // 初始化头部界面
    //    [self setupHeaderImageView];
    
    // 更新头部直播间数据
    [self setupHeadViewInfo];
}

- (void)dealloc {
    NSLog(@"ShowLiveViewController::dealloc( self : %p )", self);
    
    if (self.closeDialogTipView) {
        [self.closeDialogTipView removeFromSuperview];
    }
    
    [self.imManager removeDelegate:self];
    [self.imManager.client removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.navigationBar.hidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    self.navigationController.navigationBar.translucent = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.headBackgroundView.layer.cornerRadius = self.headBackgroundView.frame.size.height / 2;
    self.headBackgroundView.layer.masksToBounds = YES;
    
    self.laddyHeadImageView.layer.cornerRadius = self.laddyHeadImageView.frame.size.height / 2;
    self.laddyHeadImageView.layer.masksToBounds = YES;
    
    // 根据时候关注
    if (self.liveRoom.imLiveRoom.favorite) {
        self.followBtnWidth.constant = 0;
    }
    
    self.liveRoom.superView = self.view;
    self.liveRoom.superController = self;
    
    // 初始化播放界面
    [self setupPlayController];
    
    // 请求观众席列表
    [self setupAudienView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - 界面风格初始化
- (void)setupPlayController {
    // 输入栏
    self.playVC = [[PlayViewController alloc] initWithNibName:nil bundle:nil];
    self.playVC.playDelegate = self;
    [self addChildViewController:self.playVC];
    self.playVC.liveRoom = self.liveRoom;
    // 直播间风格
    self.playVC.liveVC.roomStyleItem = [[RoomStyleItem alloc] init];
    // 连击礼物
    self.playVC.liveVC.roomStyleItem.comboViewBgImage = [UIImage imageNamed:@"Live_Public_Bg_Combo"];
    // 座驾背景
    self.playVC.liveVC.roomStyleItem.riderBgColor = Color(8, 68, 158, 0.58);
    self.playVC.liveVC.roomStyleItem.driverStrColor = Color(255, 210, 5, 1);
    // 弹幕
    self.playVC.liveVC.roomStyleItem.barrageBgColor = Color(255, 255, 255, 0.9);
    // 聊天列表
    self.playVC.liveVC.roomStyleItem.myNameColor = Color(41, 122, 243, 1);
    self.playVC.liveVC.roomStyleItem.liverNameColor = Color(0, 153, 39, 1);
    self.playVC.liveVC.roomStyleItem.userNameColor = Color(255, 135, 0, 1);
    self.playVC.liveVC.roomStyleItem.liverTypeImage = [UIImage imageNamed:@"Live_Public_Vip_Broadcaster"];
    self.playVC.liveVC.roomStyleItem.followStrColor = Color(255, 135, 0, 1);
    self.playVC.liveVC.roomStyleItem.sendStrColor = Color(41, 122, 243, 1);
    self.playVC.liveVC.roomStyleItem.chatStrColor = Color(0, 0, 0, 1);
    self.playVC.liveVC.roomStyleItem.announceStrColor = Color(41, 122, 243, 1);
    self.playVC.liveVC.roomStyleItem.riderStrColor = Color(255, 135, 0, 1);
    self.playVC.liveVC.roomStyleItem.warningStrColor = Color(255, 77, 77, 1);
    self.playVC.liveVC.roomStyleItem.textBackgroundViewColor = Color(181, 181, 181, 0.49);
    
    [self.view addSubview:self.playVC.view];
    [self.playVC.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleBackGroundView.mas_bottom);
        make.left.equalTo(self.view);
        make.width.equalTo(self.view);
        if (IS_IPHONE_X) {
            make.bottom.equalTo(self.view).offset(-35);
        } else {
            make.bottom.equalTo(self.view);
        }
    }];
    
    [self.playVC.liveVC bringSubviewToFrontFromView:self.view];
    [self.view bringSubviewToFront:self.playVC.chooseGiftListView];
    CGRect frame = self.playVC.chooseGiftListView.frame;
    frame.origin.y = SCREEN_HEIGHT;
    self.playVC.chooseGiftListView.frame = frame;
    
    if (self.liveRoom.liveShowType == IMPUBLICROOMTYPE_PROGRAM || !self.liveRoom.priv.isHasOneOnOneAuth) {
        // 隐藏立即私密邀请控件
        self.playVC.liveVC.startOneView.backgroundColor = [UIColor clearColor];
    }
    else
    {
        // 设置邀请私密按钮
        self.playVC.liveVC.startOneViewHeigh.constant = 40;
        self.playVC.liveVC.startOneBtn.hidden = NO;
        self.playVC.liveVC.startOneView.hidden = NO;
    }
    
    // 立即私密按钮
    //    self.playVC.liveVC.cameraBtn.hidden = NO;
    //    [self.playVC.liveVC.cameraBtn setImage:[UIImage imageNamed:@"Live_Public_Vip_Invite_Btn"] forState:UIControlStateNormal];
    //    [self.playVC.liveVC.cameraBtn addTarget:self action:@selector(cameraAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // 礼物按钮
    [self.playVC.giftBtn setImage:[UIImage imageNamed:@"Live_Public_Vip_Gift_Btn"] forState:UIControlStateNormal];
    // 输入栏目
    [self.playVC.chatBtn setImage:[UIImage imageNamed:@"Live_Public_Vip_Btn_Chat"]];
    // 返点界面
    self.playVC.liveVC.rewardedBgView.backgroundColor = COLOR_WITH_16BAND_RGB(0x5D0E86);
    // 视频播放界面
    //        self.playVC.liveVC.videoBgImageView.backgroundColor = self.view.backgroundColor;
    
    // 聊天输入框
    [self.playVC.liveSendBarView.sendBtn setImage:[UIImage imageNamed:@"Live_Public_Vip_Send_Btn"] forState:UIControlStateNormal];
    self.playVC.liveSendBarView.louderBtnImage = [UIImage imageNamed:@"Live_Public_Vip_Pop_Btn"];
    self.playVC.liveSendBarView.placeholderColor = COLOR_WITH_16BAND_RGB(0xbaac3f);
    self.playVC.liveSendBarView.inputBackGroundImageView.image = [UIImage imageNamed:@"Public_Input_icon"];
    self.playVC.liveSendBarView.sendBarBgImageView.image = [UIImage imageNamed:@"Live_Public_Vip_SendBar_bg"];
    self.playVC.liveSendBarView.inputTextField.textColor = COLOR_WITH_16BAND_RGB(0x3c3c3c);
    // 隐藏表情按钮
    self.playVC.liveSendBarView.emotionBtnWidth.constant = 0;
    
    // 消息列表顶部间隔
    self.playVC.msgSuperTabelTop = 6;
    self.playVC.liveVC.barrageViewTop.constant = -6;
}

#pragma mark - 直播间类型资费提示
- (void)setupHeaderImageView {
    self.tipView = [[ChardTipView alloc] init];
    self.tipView.gotBtn.backgroundColor = COLOR_WITH_16BAND_RGB(0x5d0e86);
    
    [self.tipView setTipWithRoomPrice:self.liveRoom.imLiveRoom.roomPrice
                              roomTip:NSLocalizedStringFromSelf(@"VIP_PUBLIC_TIP")
                           creditText:NSLocalizedStringFromSelf(@"CREDIT_TIP")];
    [self.view addSubview:self.tipView];
    [self.roomTypeImageView sizeToFit];
    [self.tipView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.roomTypeImageView.mas_bottom).offset(2);
        make.width.equalTo(@(self.roomTypeImageView.frame.size.width * 1.5));
        make.left.equalTo(@0);
    }];
    
    // 图片点击事件
    WeakObject(self, weakSelf);
    [self.roomTypeImageView addTapBlock:^(id obj) {
        
        if (!weakSelf.isTipShow) {
            weakSelf.hidenTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                                   target:weakSelf
                                                                 selector:@selector(hidenChardTip:)
                                                                 userInfo:nil
                                                                  repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:weakSelf.hidenTimer forMode:NSRunLoopCommonModes];
            [weakSelf.view bringSubviewToFront:weakSelf.tipView];
            weakSelf.tipView.hidden = NO;
            weakSelf.isTipShow = YES;
        }
    }];
    
    // 是否第一次进入该类型直播间 显示资费提示
    BOOL haveCome = [self.firstManager getThisTypeHaveCome:@"Public_VIP_Join"];
    if (haveCome) {
        [self.tipView hiddenChardTip];
    } else {
        [self.firstManager comeinLiveRoomWithType:@"Public_VIP_Join" HaveComein:YES];
    }
}

// 更新头部直播间数据
- (void)setupHeadViewInfo {
    // 计算StatusBar高度
    if (IS_IPHONE_X) {
        self.titleBgImageTop.constant = 44;
    } else {
        self.titleBgImageTop.constant = 20;
    }
    
    if (self.liveRoom.userName.length > 0) {
        self.laddyNameLabel.text = [NSString stringWithFormat:@"%@’s",self.liveRoom.userName];
    } else {
        self.laddyNameLabel.text = [NSString stringWithFormat:@"%@’s",self.liveRoom.httpLiveRoom.nickName];
    }
    [self.ladyImageLoader refreshCachedImage:self.laddyHeadImageView options:SDWebImageRefreshCached imageUrl:self.liveRoom.photoUrl placeholderImage:[UIImage imageNamed:@"Default_Img_Lady_Circyle"]];
    
    //    NSString *audienceNum = [NSString stringWithFormat:@"(%d/%d)", self.liveRoom.imLiveRoom.fansNum, self.liveRoom.imLiveRoom.maxFansiNum];
}

#pragma mark - 网络请求

// 获取观众列表
- (void)setupAudienView {
    WeakObject(self, weakSelf);
    LiveFansListRequest *request = [[LiveFansListRequest alloc] init];
    request.roomId = self.liveRoom.roomId;
    request.start = 0;
    request.finishHandler = ^(BOOL success, HTTP_LCC_ERR_TYPE errnum, NSString *_Nonnull errmsg,
                              NSArray<ViewerFansItemObject *> *_Nullable array) {
        
        NSLog(@"PublicViewController::LiveFansListRequest( [请求观众列表], success : %d, errnum : %ld, errmsg : %@, array : %u )", success, (long)errnum, errmsg, (unsigned int)array.count);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                
                [weakSelf.audienceArray removeAllObjects];
                for (ViewerFansItemObject *item in array) {
                    
                    AudienModel *model = [[AudienModel alloc] init];
                    model.userId = item.userId;
                    model.nickName = item.nickName;
                    model.photoUrl = item.photoUrl;
                    model.mountId = item.mountId;
                    model.mountUrl = item.mountUrl;
                    model.level = item.level;
                    model.image = [UIImage imageNamed:@"Default_Img_Man_Circyle"];
                    model.isHasTicket = item.isHasTicket;
                    [weakSelf.audienceArray addObject:model];
                    
                    // 更新并缓存本地观众数据
                    LSUserInfoModel *infoItem = [[LSUserInfoModel alloc] init];
                    infoItem.userId = item.userId;
                    infoItem.nickName = item.nickName;
                    infoItem.photoUrl = item.photoUrl;
                    infoItem.riderId = item.mountId;
                    infoItem.riderName = item.mountUrl;
                    infoItem.userLevel = item.level;
                    infoItem.isAnchor = 0;
                    infoItem.isHasTicket = item.isHasTicket;
                    [[LSUserInfoManager manager] setAudienceInfoDicL:infoItem];
                }
                
                // 显示最大人数默认头像
                if (weakSelf.audienceArray.count < weakSelf.liveRoom.imLiveRoom.maxFansiNum) {
                    NSUInteger count = weakSelf.liveRoom.imLiveRoom.maxFansiNum - weakSelf.audienceArray.count;
                    for (NSUInteger num = 0; num < count; num++) {
                        AudienModel *model = [[AudienModel alloc] init];
                        model.image = [UIImage imageNamed:@"Default_Img_Noman_Circyle"];
                        [weakSelf.audienceArray addObject:model];
                    }
                }
                weakSelf.audienceView.audienceArray = weakSelf.audienceArray;
            }
        });
    };
    [self.sessionManager sendRequest:request];
}

#pragma mark - PlayViewControllerDelegate
- (void)pushToAddCredit:(PlayViewController *)vc {
    LSAddCreditsViewController *addVC = [[LSAddCreditsViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:addVC animated:YES];
}

#pragma mark - IM回调

- (void)onRecvEnterRoomNotice:(NSString *_Nonnull)roomId userId:(NSString *_Nonnull)userId nickName:(NSString *_Nonnull)nickName photoUrl:(NSString *_Nonnull)photoUrl riderId:(NSString *_Nonnull)riderId riderName:(NSString *_Nonnull)riderName riderUrl:(NSString *_Nonnull)riderUrl fansNum:(int)fansNum honorImg:(NSString *_Nonnull)honorImg isHasTicket:(BOOL)isHasTicket{
    NSLog(@"PublicViewController::onRecvEnterRoomNotice( [接收观众进入直播间通知] ) roomId : %@, userId : %@, nickName : %@, photoUrl : %@, riderId : %@, riderName : %@, riderUrl : %@, fansNum : %d", roomId, userId, nickName, photoUrl, riderId, riderName, riderUrl, fansNum);
    WeakObject(self, weakSelf);
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新并缓存本地观众数据
        LSUserInfoModel *infoItem = [[LSUserInfoModel alloc] init];
        infoItem.userId = userId;
        infoItem.nickName = nickName;
        infoItem.photoUrl = photoUrl;
        infoItem.riderId = riderId;
        infoItem.riderName = riderName;
        infoItem.riderUrl = riderUrl;
        infoItem.isAnchor = 0;
        infoItem.isHasTicket = isHasTicket;
        [[LSUserInfoManager manager] setAudienceInfoDicL:infoItem];
        
        // 刷观众列表
        [weakSelf setupAudienView];
    });
}

- (void)onRecvLeaveRoomNotice:(NSString *_Nonnull)roomId userId:(NSString *_Nonnull)userId nickName:(NSString *_Nonnull)nickName photoUrl:(NSString *_Nonnull)photoUrl fansNum:(int)fansNum {
    NSLog(@"PublicViewController::onRecvLeaveRoomNotice( [接收观众退出直播间通知] ) roomId : %@, userId : %@, nickName : %@, photoUrl : %@, fansNum : %d", roomId, userId, nickName, photoUrl, fansNum);
    WeakObject(self, weakSelf);
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf setupAudienView];
    });
}

#pragma mark - 按钮事件
- (IBAction)hidenChardTip:(id)sender {
    [[LiveModule module].analyticsManager reportActionEvent:BroadcastClickBroadcastInfo eventCategory:EventCategoryBroadcast];
    self.tipView.hidden = YES;
    if (self.hidenTimer) {
        [self.hidenTimer invalidate];
        self.hidenTimer = nil;
    }
    self.isTipShow = NO;
}

- (IBAction)pushLiveHomePage:(id)sender {
    AnchorPersonalViewController *listViewController = [[AnchorPersonalViewController alloc] initWithNibName:nil bundle:nil];
    listViewController.anchorId = self.liveRoom.userId;
    listViewController.enterRoom = 0;
    [self.navigationController pushViewController:listViewController animated:YES];
}

- (IBAction)followLiverAction:(id)sender {
    WeakObject(self, weakSelf);
    [[LiveModule module].analyticsManager reportActionEvent:BroadcastClickFollow eventCategory:EventCategoryBroadcast];
    SetFavoriteRequest *request = [[SetFavoriteRequest alloc] init];
    request.userId = self.liveRoom.userId;
    request.roomId = self.liveRoom.roomId;
    request.isFav = YES;
    request.finishHandler = ^(BOOL success, HTTP_LCC_ERR_TYPE errnum, NSString *_Nonnull errmsg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                weakSelf.followBtnWidth.constant = 0;
                //                [self.playVC.liveVC addAudienceFollowLiverMessage:self.playVC.loginManager.loginItem.nickName];
            } else {
                [weakSelf.dialogTipView showDialogTip:weakSelf.liveRoom.superView tipText:NSLocalizedStringFromSelf(@"FOLLOW_FAIL")];
            }
            NSLog(@"PublicViewController::followLiverAction( success : %d, errnum : %ld, errmsg : %@ )", success, (long)errnum, errmsg);
        });
    };
    [self.sessionManager sendRequest:request];
}

- (IBAction)closeAction:(id)sender {
    if (self.closeDialogTipView) {
        [self.closeDialogTipView removeFromSuperview];
    }
    self.closeDialogTipView = [DialogChoose dialog];
    [self.closeDialogTipView hiddenCheckView];
    self.closeDialogTipView.tipsLabel.text = NSLocalizedStringFromSelf(@"EXIT_LIVEROOM_TIP");
    WeakObject(self, weakObj);
    [self.closeDialogTipView showDialog:self.view cancelBlock:^{
        
    } actionBlock:^{
        // 停止流
        [weakObj.playVC.liveVC stopPlay];
        [weakObj.playVC.liveVC stopPublish];
        
        // 退出界面
//        [weakObj.navigationController dismissViewControllerAnimated:YES completion:nil];
        LSNavigationController *nvc = (LSNavigationController *)weakObj.navigationController;
        [nvc forceToDismissAnimated:YES completion:nil];
    }];
}


@end
