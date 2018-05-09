//
//  LiveModuleManager.m
//  livestream
//
//  Created by randy on 2017/8/3.
//  Copyright © 2017年 net.qdating. All rights reserved.
//

#import "LiveModule.h"

#pragma mark - 界面
#import "LSMainViewController.h"
#import "LiveChannelAdViewController.h"
#import "PushInviteViewController.h"
#import "PushBookingViewController.h"

#pragma mark - 登录
#import "LiveGiftListManager.h"
#import "LiveGiftDownloadManager.h"
#import "LSChatEmotionManager.h"
#import "LSStreamSpeedManager.h"

#pragma mark - 公共
#import "LSFileCacheManager.h"
#import "BackpackSendGiftManager.h"
#import "UserInfoManager.h"
#import "LiveRoomCreditRebateManager.h"
#import "LiveBundle.h"
#import "LSImageViewLoader.h"

#pragma mark - HTTP
#import "LSLoginManager.h"
#import "LSRequestManager.h"
#import "LSSessionRequestManager.h"
#import "LSUserUnreadCountManager.h"

#pragma mark - IM
#import "LSImManager.h"

#pragma mark - 流媒体
#import "LiveGobalManager.h"
#import "LiveStreamSession.h"

#pragma mark - 广告
#import "GetAnchorListRequest.h"
#import "LiveChannelAdView.h"

#pragma mark - URL跳转
#import "LiveUrlHandler.h"

#pragma mark - QN
#import "LiveService.h"

#import "PushShowViewController.h"

static LiveModule *gModule = nil;
@interface LiveModule () <LoginManagerDelegate, IQNService, IServiceManager, IMLiveRoomManagerDelegate, IMManagerDelegate, LSUserUnreadCountManagerDelegate> {
    UIViewController *_moduleVC;
    UIViewController *_adVc;
}

// 是否在后台
@property (assign, nonatomic) BOOL isBackground;
@property (strong, nonatomic) NSString *manId;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) LSSessionRequestManager *sessionManager;
@property (strong, nonatomic) LSLoginManager *loginManager;
@property (strong, nonatomic) LSImManager *imManager;
@property (strong, nonatomic) LiveGobalManager *liveGobalManager;
@property (strong, nonatomic) LiveGiftListManager *giftListManager;
@property (strong, nonatomic) LiveGiftDownloadManager *giftDownloadManager;
@property (strong, nonatomic) BackpackSendGiftManager *backGiftManager;
@property (strong, nonatomic) LSChatEmotionManager *emotionManager;
@property (strong, nonatomic) LiveChannelAdViewController *liveChannel;
@property (strong, nonatomic) LSStreamSpeedManager *speedManager;
// 余额及返点信息管理器
@property (strong, nonatomic) LiveRoomCreditRebateManager *creditRebateManager;
// 通知界面
@property (strong, nonatomic) UIViewController *notificationVC;
// 广告界面
@property (strong, nonatomic) UIViewController *adVc;
/** 未读信息管理器 */
@property (nonatomic, strong) LSUserUnreadCountManager *unReadManager;

@property (nonatomic, assign) int unreadCount;
@end

@implementation LiveModule
#pragma mark - 获取实例
+ (instancetype)module {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!gModule) {
            gModule = [[LiveModule alloc] init];
        }
    });
    return gModule;
}

- (id)init {
    NSLog(@"LiveModule::init()");

    if (self = [super init]) {
        // 模块主界面
        _debug = NO;
        _debugLog = YES;
        _moduleVC = nil;
        _fromVC = nil;
        _notificationVC = nil;
        _adVc = nil;
        _showListGuide = YES;
        _isForTest = NO;
        _appVerCode = @"122";
        // 创建直播服务
        [LiveService service];
        // 资源全局管理
        [LiveBundle gobalInit];
        // 初始化图像下载器
        [LSImageViewLoader gobalInit];
        // 初始化流媒体管理器
        self.liveGobalManager = [LiveGobalManager manager];
        // 初始化测速管理器
        self.speedManager = [[LSStreamSpeedManager alloc] init];
        // 初始化Http登陆管理器
        self.loginManager = [LSLoginManager manager];
        [self.loginManager addDelegate:self];
        // 初始化IM管理器
        self.imManager = [LSImManager manager];
        [self.imManager addDelegate:self];
        [self.imManager.client addDelegate:self];

        // 初始化礼物下载器
        self.giftListManager = [LiveGiftListManager manager];
        self.giftDownloadManager = [LiveGiftDownloadManager manager];
        // 初始化聊天表情管理器
        self.emotionManager = [LSChatEmotionManager emotionManager];
        // 初始化背包礼物管理器
        self.backGiftManager = [BackpackSendGiftManager backpackGiftManager];
        // 初始session管理器
        self.sessionManager = [LSSessionRequestManager manager];
        // 初始化用户信息管理器
        [UserInfoManager manager];
        // 初始化余额及返点信息管理器
        self.creditRebateManager = [LiveRoomCreditRebateManager creditRebateManager];
        // 清除webview的缓存
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        //        // 开启后台播放
        //        [[LiveStreamSession session] activeSession];
        // 设置接口管理类属性
        [LSRequestManager setLogEnable:_debugLog];
        [LSRequestManager setLogDirectory:[[LSFileCacheManager manager] requestLogPath]];
        LSRequestManager *manager = [LSRequestManager manager];
        [manager setWebSite:@""];
        // 初始化未读信息管理器
        self.unReadManager = [LSUserUnreadCountManager shareInstance];
        [self.unReadManager addDelegate:self];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"LiveModule::dealloc()");

    if (_serviceManager) {
        [_serviceManager removeService:self];
    }

    [self.imManager.client removeDelegate:self];
    [self.imManager removeDelegate:self];
    [self.loginManager removeDelegate:self];
    [self.unReadManager removeDelegate:self];
}

- (void)setConfigUrl:(NSString *)url {
    NSLog(@"LiveModule::setConfigUrl( url : %@ )", url);

    LSRequestManager *manager = [LSRequestManager manager];
    [manager setConfigWebSite:url];
}

- (BOOL)start:(NSString *)manId token:(NSString *)token {
    BOOL bFlag = YES;

    NSLog(@"LiveModule::start( manId : %@, token : %@ )", manId, token);

    @synchronized(self) {
        self.token = token;
        self.manId = manId;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loginManager login:self.manId userSid:self.token];
    });

    return bFlag;
}

- (void)stop {
    NSLog(@"LiveModule::stop( manId : %@, token : %@ )", self.manId, self.token);

    @synchronized(self) {
        self.token = nil;
        self.manId = nil;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loginManager logout:YES msg:@""];
        [self.imManager logout];
    });
}

- (void)cleanCache {
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
}

#pragma mark - Get/Set方法
- (void)setDebugLog:(BOOL)debugLog {
    [LSRequestManager setLogEnable:debugLog];
}

- (void)setHttpProxy:(NSString *)httpProxy {
    [LSRequestManager setProxy:httpProxy];
}

- (void)setServiceManager:(id<IServiceManager>)serviceManager {
    _serviceManager = serviceManager;
    if (_serviceManager) {
        [_serviceManager addService:self.service];
    }
}

- (id<IQNService>)service {
    return (id<IQNService>)[LiveService service];
}

- (void)setFromVC:(UIViewController *)fromVC {
    _fromVC = fromVC;
}

- (UIViewController *)notificationVC {
    NSLog(@"LiveModule::notificationVC()");
    return _notificationVC;
}

- (UIViewController *)adVc {
    NSLog(@"LiveModule::notificationVC()");
    return _adVc;
}

- (void)setModuleVC:(UIViewController *)vc {
    _moduleVC = vc;
}

- (UIViewController *)moduleVC {
    if (!_moduleVC) {
        _moduleVC = [[LSMainViewController alloc] initWithNibName:nil bundle:nil];
    }
    return _moduleVC;
}

#pragma mark - HTTP登录回调
- (void)manager:(LSLoginManager *_Nonnull)manager onLogin:(BOOL)success loginItem:(LSLoginItemObject *_Nullable)loginItem errnum:(HTTP_LCC_ERR_TYPE)errnum errmsg:(NSString *_Nonnull)errmsg {
    if (success) {
        if (loginItem.isPushAd) {
            // 调用QN弹出广告
            LiveChannelAdViewController *vc = [[LiveChannelAdViewController alloc] initWithNibName:nil bundle:nil];
            _adVc = vc;
            if ([self.delegate respondsToSelector:@selector(moduleOnAdViewController:)]) {
                [self.delegate moduleOnAdViewController:self];
            }
        }
        self.qnMainAdId = loginItem.qnMainAdId ;
        self.qnMainAdUrl = loginItem.qnMainAdUrl;
        self.qnMainAdTitle = loginItem.qnMainAdTitle;

        // Http登陆成功
        if ([self.delegate respondsToSelector:@selector(moduleOnLogin:)]) {
            [self.delegate moduleOnLogin:self];
        }
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 继续登陆
            if (self.token) {
                [self.loginManager login:self.manId userSid:self.token];
            }
        });
    }
}

- (void)manager:(LSLoginManager *_Nonnull)manager onLogout:(BOOL)kick msg:(NSString *)msg {
    NSLog(@"LiveModule::onLogout( [Http注销], kick : %@, msg : %@ )", BOOL2YES(kick), msg);

    // Http注销
    @synchronized(self) {
        self.token = nil;
        self.manId = nil;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // 停止直播间, 退出到模块入口
        [[LiveService service] stopService];

        // 通知外部模块停止
        if ([self.delegate respondsToSelector:@selector(moduleOnLogout:kick:msg:)]) {
            [self.delegate moduleOnLogout:self kick:kick msg:msg];
        }
    });
}

#pragma mark - IM通知
- (void)onHandleLoginRoom:(NSString *_Nonnull)roomId userId:(NSString *_Nullable)userId userName:(NSString *_Nullable)userName {
    // TODO:第一次登陆成功, 通知QN强制进入直播间
    NSLog(@"LiveModule::onHandleLoginRoom( [第一次登陆成功, 通知QN强制进入直播间], roomId : %@, userId : %@, userName : %@ )", roomId, userId, userName);

    dispatch_async(dispatch_get_main_queue(), ^{
        // 生成直播间跳转的URL
        NSURL *url = [[LiveUrlHandler shareInstance] createUrlToInviteByRoomId:roomId userId:userId roomType:LiveRoomType_Private];
        [[LiveService service] openUrlByLive:url];
    });
}

- (void)onHandleLoginInvite:(ImInviteIdItemObject *_Nonnull)inviteItem {
    // TODO:第一次登陆成功, 通知QN强制进入有效的立即私密邀请
    NSLog(@"LiveModule::onHandleLoginInvite( [第一次登陆成功, 通知QN强制进入有效的立即私密邀请], invitationId : %@, roomId : %@, userId : %@, replyType : %d )", inviteItem.invitationId, inviteItem.roomId, inviteItem.oppositeId, (int)inviteItem.replyType);

    dispatch_async(dispatch_get_main_queue(), ^{
        // 生成直播间跳转的URL
        NSURL *url = [[LiveUrlHandler shareInstance] createUrlToInviteByRoomId:inviteItem.roomId userId:inviteItem.oppositeId roomType:LiveRoomType_Private];
        [[LiveService service] openUrlByLive:url];
    });
}

- (void)onRecvInstantInviteUserNotice:(NSString *_Nonnull)inviteId anchorId:(NSString *_Nonnull)anchorId nickName:(NSString *_Nonnull)nickName avatarImg:(NSString *_Nonnull)avatarImg msg:(NSString *_Nonnull)msg {
    // TODO:接收主播立即私密邀请通知
    NSLog(@"LiveModule::onRecvInstantInviteUserNotice( [接收主播立即私密邀请通知], show : %@, inviteId : %@, userId : %@, userName : %@, msg : %@ )", BOOL2YES(_moduleVC.navigationController), inviteId, anchorId, nickName, msg);

    dispatch_async(dispatch_get_main_queue(), ^{
        // 当前在直播模块
        if (_moduleVC.navigationController) {
            // 当前主播私密邀请能否显示
            if ([_liveGobalManager canShowInvite:anchorId]) {
                // 生成直播间跳转的URL
                NSURL *url = [[LiveUrlHandler shareInstance] createUrlToInviteByInviteId:inviteId anchorId:anchorId nickName:nickName];
                // 调用QN弹出通知
                PushInviteViewController *vc = [[PushInviteViewController alloc] initWithNibName:nil bundle:nil];
                vc.url = url;
                vc.inviteId = inviteId;
                vc.anchorId = anchorId;
                _notificationVC = vc;

                if ([self.delegate respondsToSelector:@selector(moduleOnNotification:)]) {
                    [self.delegate moduleOnNotification:self];
                }
            } else {
                // 无法显示主播立即私密邀请
                [self.imManager InstantInviteUserReport:inviteId
                                                 isShow:NO
                                          finishHandler:^(BOOL success, LCC_ERR_TYPE errType, NSString *_Nonnull errMsg) {
                                              NSLog(@"LiveModule::InstantInviteUserReport( [当前主播私密邀请无法显示], success : %d, errtype : %d, errmsg : %@ )", success, errType, errMsg);
                                          }];
            }
        }
    });
}

- (void)onRecvBookingNotice:(NSString *_Nonnull)roomId userId:(NSString *_Nonnull)userId nickName:(NSString *_Nonnull)nickName avatarImg:(NSString *_Nonnull)avatarImg leftSeconds:(int)leftSeconds {
    // TODO:接收主播预约开始倒数邀请通知
    NSLog(@"LiveModule::onRecvBookingNotice( [接收预约开始倒数通知], roomId : %@, userId : %@, userName : %@, leftSeconds : %d )", roomId, userId, nickName, leftSeconds);

    dispatch_async(dispatch_get_main_queue(), ^{
        // 生成直播间跳转的URL
        NSURL *url = [[LiveUrlHandler shareInstance] createUrlToInviteByRoomId:roomId userId:userId roomType:LiveRoomType_Private];
        // 调用QN弹出通知
        PushBookingViewController *vc = [[PushBookingViewController alloc] initWithNibName:nil bundle:nil];
        vc.url = url;
        vc.userId = userId;
        _notificationVC = vc;

        if ([self.delegate respondsToSelector:@selector(moduleOnNotification:)]) {
            [self.delegate moduleOnNotification:self];
        }
    });
}

- (void)onRecvProgramPlayNotice:(IMProgramItemObject *)item type:(IMProgramNoticeType)type msg:(NSString * _Nonnull)msg
{
    // TODO:接收节目开播通知接口
    NSLog(@"LiveModule::onRecvProgramPlayNotice( [接收节目开播通知], showLiveId : %@, anchorId : %@, anchorNickName : %@, type : %d )", item.showLiveId, item.anchorId, item.anchorNickName, type);
    
    if (type == IMPROGRAMNOTICETYPE_BUYTICKET) {
       
        dispatch_async(dispatch_get_main_queue(), ^{
            // 生成直播间跳转的URL
            NSURL *url =[[LiveUrlHandler shareInstance] createUrlToShowRoomId:item.showLiveId userId:item.anchorId];
            // 调用QN弹出通知
            PushShowViewController *vc = [[PushShowViewController alloc] initWithNibName:nil bundle:nil];
            vc.url = url;
            vc.tips = msg;
            vc.anchorId = item.anchorId;
            _notificationVC = vc;
            
            if ([self.delegate respondsToSelector:@selector(moduleOnNotification:)]) {
                [self.delegate moduleOnNotification:self];
            }
        });
    }
}

- (void)onHandleLoginOnGingShowList:(NSArray<IMOngoingShowItemObject *> *)ongoingShowList
{
    IMOngoingShowItemObject * item = [ongoingShowList firstObject];
    NSLog(@"LiveModule::onRecvProgramPlayNotice( [接收节目开播通知], showLiveId : %@, anchorId : %@, anchorNickName : %@, type : %d )", item.showInfo.showLiveId, item.showInfo.anchorId, item.showInfo.anchorNickName, item.type);
    
    [self onRecvProgramPlayNotice:item.showInfo type:item.type msg:item.msg];
    
}
#pragma mark 获取用户中心未读数
- (void)getUnReadMsg {
    [self.unReadManager getResevationsUnredCount];
}

- (void)onGetBackpackUnreadCount:(GetBackPackUnreadNumItemObject *)item {
    NSInteger count = self.unreadCount + item.total;
    if ([self.delegate respondsToSelector:@selector(moduleOnGetUnReadMsg:unReadCount:)]) {
        [self.delegate moduleOnGetUnReadMsg:self unReadCount:count];
    }
}

- (void)onGetResevationsUnredCount:(BookingUnreadUnhandleNumItemObject *)item {
    self.unreadCount = item.totalNoReadNum;
    [self.unReadManager getBackpackUnreadCount];
}

#pragma mark - Application
- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"LiveModule::applicationDidEnterBackground()");
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"LiveModule::applicationWillEnterForeground()");
    [LiveGobalManager manager].enterRoomBackgroundTime = nil;
}

@end

