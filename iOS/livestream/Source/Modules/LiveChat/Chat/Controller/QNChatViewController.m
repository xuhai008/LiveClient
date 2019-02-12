//
//  QNChatViewController.m
//  dating
//
//  Created by Max on 16/2/24.
//  Copyright © 2016年 qpidnetwork. All rights reserved.
//

#import "QNChatViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#import "Masonry.h"

#import "LSAddCreditsViewController.h"
#import "AnchorPersonalViewController.h"
//#import "ChatSecretPhotoViewController.h"

#import "QNChatTextLadyTableViewCell.h"
#import "QNChatTextSelfTableViewCell.h"
#import "QNChatSystemTipsTableViewCell.h"
#import "QNChatCouponTableViewCell.h"
#import "QNChatPhotoLadyTableViewCell.h"
#import "QNChatPhotoSelfTableViewCell.h"
#import "QNChatSmallEmotionLadyTableViewCell.h"
#import "QNChatSmallEmotionselfTableViewCell.h"
#import "QNChatNomalSmallEmotionView.h"
#import "QNChatEmotionCreditsCollectionViewCell.h"
#import "QNChatLargeEmotionLadyTableViewCell.h"
#import "QNChatLargeEmotionSelfTableViewCell.h"
#import "QNChatVoiceTableViewCell.h"
#import "QNChatVoiceSelfTableViewCell.h"
#import "QNChatMoonFeeTableViewCell.h"

#import "QNChatEmotionKeyboardView.h"
#import "QNChatEmotionChooseView.h"
//#import "ChatEmotionListView.h"
//#import "ChatPhotoView.h"
//#import "ChatPhoneAlbumPhoto.h"

#import "LSLadyRecentContactObject.h"
#import "LSLCLiveChatMsgProcResultObject.h"
#import "QNMessage.h"

#import "LSLiveChatManagerOC.h"
#import "QNContactManager.h"
//#import "MonthFeeManager.h"
#import "LSUserInfoManager.h"

//#import "LadyDetailMsgManager.h"
#import "LSImageViewLoader.h"
#import "LSLCLiveChatMsgItemObject.h"

#import "QNChatVoiceManager.h"

#import "QNChatVoiceView.h"
#import "QNChatAudioPlayer.h"

#import "DialogTip.h"
#import "LiveModule.h"

#define ADD_CREDIT_URL @"ADD_CREDIT_URL"

#define INPUTMESSAGEVIEW_MAX_HEIGHT 44.0 * 2

#define TextMessageFontSize 18
#define SystemMessageFontSize 16
#define WarningMessageFontSize 16
#define MessageGrayColor [LSColor colorWithIntRGB:180 green:180 blue:180 alpha:255]
#define halfWidth self.view.frame.size.width * 0.5f
#define PreloadPhotoCount 10
#define maxInputCount 200

#define column 5
#define imageRow 2
#define defaultPage 1

typedef enum AlertType {
    AlertType200Limited = 100000,
    AlertTypeCameraAllow,
    AlertTypeCameraDisable,
    AlertTypePhotoAllow,
    AlertTypeInChatAllow,
    AlertTypeInChatToCamShare
} AlertType;

typedef enum AlertPayType {
    AlertTypePayDefault = 200000,
    AlertTypePayAppStorePay,
    AlertTypePayCheckOrder,
    AlertTypePayMonthFee
} AlertPayType;

@interface QNChatViewController () <UIAlertViewDelegate, ChatTextSelfDelegate,
LSLiveChatManagerListenerDelegate,
LSCheckButtonDelegate, ChatEmotionChooseViewDelegate, TTTAttributedLabelDelegate, ChatTextViewDelegate,
//MonthFeeManagerDelegate,
ChatMoonFeeTableViewCellDelegate,
ChatLargeEmotionSelfTableViewCellDelegate, ChatEmotionKeyboardViewDelegate, ChatSmallEmotionViewDelegate, ChatSmallEmotionSelfTableViewCellDelegate, ChatNormalSmallEmotionViewDelegate, UIScrollViewDelegate,
ChatVoiceViewDelegate, ChatVoiceSelfTableViewCellDelegate, ChatVoiceTableViewCellDelegate, ChatAudioPlayerDelegate, UIActionSheetDelegate> {
    CGRect _orgFrame;
}
#pragma mark - 界面
@property (nonatomic, strong) QNChatTitleView *titleView;
/**
 *  表情选择器键盘
 */
@property (nonatomic, strong) QNChatEmotionKeyboardView *chatEmotionKeyboardView;

/**
 *  表情列表
 */
@property (nonatomic, retain) NSArray *emotionArray;
/**
 *  表情列表(用于查找)
 */
@property (nonatomic, retain) NSDictionary *emotionDict;
/**
 *  消息列表
 */
@property (atomic, retain) NSMutableArray *msgArray;
/**
 *  自定义消息
 */
@property (nonatomic, retain) NSMutableDictionary *msgCustomDict;
/**
 *  Livechat管理器
 */
@property (nonatomic, strong) LSLiveChatManagerOC *liveChatManager;
/**
 *  单击收起输入控件手势
 */
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;

/**
 相册图片路径
 */
@property (atomic, strong) NSMutableArray *photoPathArray;
/** 消息数据 */
@property (nonatomic, strong) LSLCLiveChatMsgItemObject *msgItem;

/**
 键盘弹出高度
 */
@property (nonatomic, assign) CGFloat keyboardHeight;

#pragma mark - 表情属性
/**
 表情缩略图缓存列表
 */
@property (strong, atomic) NSMutableDictionary *emotionImageCacheDict;
/**
 表情播放图片缓存列表
 */
@property (strong, atomic) NSMutableDictionary *emotionImageArrayCacheDict;
@property (nonatomic, strong) NSArray *smallEmotionListArray;
@property (nonatomic, strong) NSArray *nomalSmallEmotionArray;
/**
 小高表情缩略图缓存列表
 */
@property (strong, atomic) NSMutableDictionary *smallEmotionImageCacheDict;
@property (nonatomic, copy) NSAttributedString *emotionAttributedString;
/**
 普通表和小高表界面
 */
@property (nonatomic, strong) QNChatNomalSmallEmotionView *normalAndSmallEmotionView;

#pragma mark - 语音管理
@property (nonatomic, strong) QNChatVoiceView *chatVoiceView;
@property (nonatomic, strong) QNChatAudioPlayer *audioPlayer;
@property (nonatomic, assign) NSInteger voicePlayRow;
@property (nonatomic, strong) QNChatVoiceManager *voiceManager;

@property (nonatomic, assign) BOOL isEndChat;

@end

@implementation QNChatViewController
- (void)dealloc {
    [self.liveChatManager removeDelegate:self];
    //清空自定义消息
    [self clearCustomMessage];
    [[LSImageViewLoader loader] stop];
    [self.audioPlayer removNotification];
    [self.audioPlayer removDelegate];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //监听进入后台
    __weak typeof(self) weakSelf = self;
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:app
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {

                                                      if (!weakSelf.voiceImageView.hidden) {
                                                          [weakSelf voiceButtonTouchUpInside];
                                                      }
                                                  }];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // 防止在锁定照片跳转过来隐藏了导航栏
    self.navigationController.navigationBarHidden = NO;

    // 添加键盘事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    if (!self.viewDidAppearEver) {
        // 刷新消息列表
        [self reloadData:YES scrollToEnd:YES animated:NO];

        // 检测用户聊天状态
        LSLCLiveChatUserItemObject *user = [self.liveChatManager getUserWithId:self.womanId];
        if (user.chatType != LC_CHATTYPE_IN_CHAT_CHARGE) {
            // 检测试聊券
            [self.liveChatManager checkTryTicket:self.womanId];
        }
    }
        // 更新聊天列表未读数
        [[QNContactManager manager] updateReadMsg:self.womanId];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 关闭输入框
    [self closeAllInputView];

    // 去除键盘事件
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    // 停止声音
    [self.voiceImageView removeFromSuperview];
    [self voiceButtonTouchUpOutside];
    [self.audioPlayer stopSound];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 界面逻辑
- (void)initCustomParam {
    // 初始化父类参数
    [super initCustomParam];
    self.backTitle = NSLocalizedString(@"Chat", nil);

    self.liveChatManager = [LSLiveChatManagerOC manager];
    [self.liveChatManager addDelegate:self];
    
    // 加载普通表情
    [self reloadEmotion];
    // 加载小高级表情
    [self reloadSmallEmotion];

    // 初始化表情缓存
    self.emotionImageCacheDict = [NSMutableDictionary dictionary];
    self.emotionImageArrayCacheDict = [NSMutableDictionary dictionary];
    self.smallEmotionImageCacheDict = [NSMutableDictionary dictionary];

    // 初始化自定义消息列表
    self.msgCustomDict = [NSMutableDictionary dictionary];
}

- (void)setupNavigationBar {
    [super setupNavigationBar];

    // 标题
    self.titleView = [[QNChatTitleView alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
    self.titleView.personName.text = self.firstName;
    self.titleView.personName.textColor = COLOR_WITH_16BAND_RGB(0x0099FF);
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showLadyDetail)];
    [self.titleView addGestureRecognizer:singleTap];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        [self.titleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(200);
        }];
    }

    self.navigationItem.titleView = self.titleView;

    UIView *rightcontainVew = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    UIButton *settingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingBtn addTarget:self action:@selector(settingDid) forControlEvents:UIControlEventTouchUpInside];
    [settingBtn setImage:[UIImage imageNamed:@"LS_Nav_More"] forState:UIControlStateNormal];
    settingBtn.frame = CGRectMake(rightcontainVew.frame.size.width - 40, 0, 40, 40);
    [rightcontainVew addSubview:settingBtn];
    
    UIBarButtonItem * barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightcontainVew];
    
    self.navigationItem.rightBarButtonItem = barButtonItem;
    
    // 获取用户信息
    __weak typeof(self) weakSelf = self;
    [[LSUserInfoManager manager]getLiverInfo:self.womanId finishHandler:^(LSUserInfoModel * _Nonnull item) {
        NSLog(@"ChatViewController::getLiverInfo( 获取用户信息回调 userId : %@, photoUrl : %@ nickName: %@)", item.userId, item.photoUrl,item.nickName);
        if (item.photoUrl.length > 0) {
            weakSelf.photoURL = item.photoUrl;
            [[LSImageViewLoader loader] refreshCachedImage:weakSelf.titleView.personIcon options:SDWebImageRefreshCached imageUrl:weakSelf.photoURL placeholderImage:[UIImage imageNamed:@"Default_Img_Lady_Circyle"]];
            weakSelf.titleView.personName.text = item.nickName;
            weakSelf.firstName = item.nickName;
        }
    }];
}

- (void)setupContainView {
    [super setupContainView];

    [self setupTableView];
    [self setupInputView];
    [self setupEmotionInputView];
    
    self.audioPlayer = [QNChatAudioPlayer sharedInstance];
    self.audioPlayer.delegate = self;
    self.voiceManager = [[QNChatVoiceManager alloc] init];
}

- (void)setupTableView {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.tableView setTableFooterView:footerView];
}

- (void)setupInputView {
    // 文字输入
    self.textView.placeholder = NSLocalizedStringFromSelf(@"Tips_Input_Message_Here");
    self.textView.chatTextViewDelegate = self;

    if (IS_IPHONE_X) {
        self.inputMessageViewBottom.constant = -35;
        CGRect rect = self.tableView.frame;
        rect.size.height = rect.size.height - 35;
        self.tableView.frame = rect;
    }

    // 表情输入
    self.emotionBtn.adjustsImageWhenHighlighted = NO;
    self.emotionBtn.selectedChangeDelegate = self;
    [self.emotionBtn setImage:[UIImage imageNamed:@"LS_Chat-EmotionGray"] forState:UIControlStateNormal];
    [self.emotionBtn setImage:[UIImage imageNamed:@"LS_Chat-EmotionBlue"] forState:UIControlStateSelected];

    [self.voiceButton addTarget:self action:@selector(voiceButtonTouchDown) forControlEvents:UIControlEventTouchDown];
    [self.voiceButton addTarget:self action:@selector(voiceButtonTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
    [self.voiceButton addTarget:self action:@selector(voiceButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [self.voiceButton addTarget:self action:@selector(voiceButtonDragOutside) forControlEvents:UIControlEventTouchDragExit];
    [self.voiceButton addTarget:self action:@selector(voiceButtonDragInside) forControlEvents:UIControlEventTouchDragEnter];
}

- (void)setupEmotionInputView {
    if (self.normalAndSmallEmotionView == nil) {
        self.normalAndSmallEmotionView = [QNChatNomalSmallEmotionView chatNormalSmallEmotionView:self];
        self.normalAndSmallEmotionView.delegate = self;
        self.normalAndSmallEmotionView.emotionInputView.delegate = self;
        self.normalAndSmallEmotionView.smallEmotionView.delegate = self;
        self.normalAndSmallEmotionView.defaultEmotionArray = self.emotionArray;
        self.normalAndSmallEmotionView.smallEmotionArray = self.smallEmotionListArray;
        [self.normalAndSmallEmotionView createUI];
    }

    // 表情选择器
    if (self.chatEmotionKeyboardView == nil) {
        self.chatEmotionKeyboardView = [QNChatEmotionKeyboardView chatEmotionKeyboardView:self];
        self.chatEmotionKeyboardView.delegate = self;
        [self.view addSubview:self.chatEmotionKeyboardView];
        [self.chatEmotionKeyboardView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self.inputMessageView.mas_width);
            make.height.equalTo(@262);
            make.left.equalTo(self.view.mas_left).offset(0);
            make.top.equalTo(self.inputMessageView.mas_bottom).offset(0);
        }];

        NSMutableArray *array = [NSMutableArray array];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [UIImage imageNamed:@"LS_Chat_SmallEmotion"];
        [button setImage:image forState:UIControlStateNormal];
        button.adjustsImageWhenHighlighted = NO;
        [array addObject:button];

        self.chatEmotionKeyboardView.buttons = array;

        self.chatEmotionKeyboardView.hidden = YES;
    }
}

- (void)showLadyDetail {
    //TODO:风控
        //if (![[RiskControlManager manager] isRiskControlType:RiskType_Ladyprofile]) {
 
            AnchorPersonalViewController *vc = [[AnchorPersonalViewController alloc] initWithNibName:nil bundle:nil];
            vc.anchorId = self.womanId;
            vc.enterRoom = 1;
            [self.navigationController pushViewController:vc animated:YES];
        //}
}

#pragma mark - 键盘和底部输入控件管理
- (void)addSingleTap {
    // 增加点击收起键盘手势
    if (self.singleTap == nil) {
        self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeAllInputView)];
        [self.tableView addGestureRecognizer:self.singleTap];
    }
}

- (void)removeSingleTap {
    // 移除点击收起键盘手势
    if (self.singleTap) {
        [self.tableView removeGestureRecognizer:self.singleTap];
        self.singleTap = nil;
    }
}

- (void)showKeyboardView {
    // 显示系统键盘
    [self addSingleTap];

    self.textView.inputView = nil;
    [self.textView becomeFirstResponder];
}

- (void)showEmotionView {
    [self addSingleTap];

    self.chatEmotionKeyboardView.hidden = NO;

    // 关闭系统键盘
    [self.textView resignFirstResponder];
    if (self.inputMessageViewBottom.constant != -self.chatEmotionKeyboardView.frame.size.height) {
        // 未显示则显示
        [self moveInputBarWithKeyboardHeight:self.chatEmotionKeyboardView.frame.size.height withDuration:0.25];
    }
    [self.chatEmotionKeyboardView reloadData];
}

- (void)closeAllInputView {
    // 关闭所有输入控件

    // 降低加速度
    self.tableView.decelerationRate = UIScrollViewDecelerationRateNormal;

    // 移除手势
    [self removeSingleTap];

    // 关闭表情输入
    if (self.emotionBtn.selected == YES) {
        self.emotionBtn.selected = NO;
        [self moveInputBarWithKeyboardHeight:0 withDuration:0.25];
    }
    // 关闭系统键盘
    [self.textView resignFirstResponder];
}

#pragma mark - 点击按钮事件
- (void)settingDid {
    [self closeAllInputView];

    NSString *endChatStr = @"";
        if ([self.liveChatManager isChatingUserInChatState:self.womanId]) {
            //在聊显示EndChat
            endChatStr = NSLocalizedStringFromSelf(@"EndChat");
            self.isEndChat = YES;
        } else if (![self.liveChatManager isInManInvite:self.womanId]) {
            //非男士主动邀请
            endChatStr = NSLocalizedStringFromSelf(@"EndChat");
            self.isEndChat = YES;
        } else {
            //男士主动邀请
            endChatStr = NSLocalizedStringFromSelf(@"Cancel invitation");
            self.isEndChat = NO;
        }

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:endChatStr, nil];
    [actionSheet showInView:self.view];
}

- (void)sendMsgAction:(id)sender {
    [[LiveModule module].analyticsManager reportActionEvent:SendLivechatMessage eventCategory:EventCategoryLiveChat];
    // 点击发送
    if (self.textView.text.length > 0) {
        [self sendMsg:self.textView.text];
    }
}

#pragma mark - 点击消息提示按钮
- (void)chatTextSelfRetryButtonClick:(QNChatTextSelfTableViewCell *)cell {
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    [self handleErrorMsg:path.row];
}

#pragma mark - 点击弹窗提示
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self closeAllInputView];

    NSInteger index = alertView.tag;
    if (index < self.msgArray.count) {
        QNMessage *msg = [self.msgArray objectAtIndex:index];
                LSLCLiveChatMsgProcResultObject *procResult = msg.liveChatMsgItemObject.procResult;
        
                if (procResult) {
                    switch (procResult.errType) {
                        case LSLIVECHAT_LCC_ERR_FAIL:
                        case LSLIVECHAT_LCC_ERR_NOTRANSORAGENTFOUND: // 没有找到翻译或机构
                        case LSLIVECHAT_LCC_ERR_BLOCKUSER:           // 对方为黑名单用户（聊天）
                        case LSLIVECHAT_LCC_ERR_SIDEOFFLINE:
                        case LSLIVECHAT_LCC_ERR_NOMONEY: {
                            // 重新获取当前女士用户状态
                            LSLCLiveChatUserItemObject *user = [self.liveChatManager getUserWithId:self.womanId];
                            if (user) {
                                if (user.statusType == USTATUS_ONLINE) {
                                    // 用户重新在线, 重发
                                    if (buttonIndex != alertView.cancelButtonIndex) {
                                        [self reSendMsg:index];
                                    }
                                } else {
                                    // 用户不在线 发EMF
                                    if (buttonIndex != alertView.cancelButtonIndex) {
                                        
                                    }
                                }
                            }
                        } break;
                        default: {
                            // 其他未处理错误, 重发
                            if (buttonIndex != alertView.cancelButtonIndex) {
                                [self reSendMsg:index];
                            }
                        } break;
                    }
                }
    } else {
        switch (index) {
            case AlertType200Limited: {
                // 200个字符限制
            } break;
            case AlertTypeCameraAllow: {
                // 不允许相机提示
            } break;
            case AlertTypeCameraDisable: {
                // 不能使用相册提示
            } break;
            case AlertTypePhotoAllow: {
                // 不允许相册提示
            } break;
            case AlertTypeInChatAllow: {
                // 开聊才能发图
            } break;
            case AlertTypePayDefault: {
                // 点击普通提示
            } break;
            default:
                break;
        }
    }
}

#pragma mark - 点击超链接回调
- (void)attributedLabel:(TTTAttributedLabel *)label
    didSelectLinkWithURL:(NSURL *)url {
    if ([[url absoluteString] isEqualToString:ADD_CREDIT_URL]) {
        [self addCreditsViewShow];
    }
}

#pragma mark - 表情按钮选择回调
- (void)selectedChanged:(id)sender {
    [self.textView endEditing:YES];
    UIButton *emotionBtn = (UIButton *)sender;
    if (emotionBtn.selected == YES) {
        // 弹出底部emotion的键盘
        [self showEmotionView];
        
    } else {
        // 切换成系统的的键盘
        [self showKeyboardView];
    }
}

#pragma mark - 普通表情选择回调
- (void)chatEmotionChooseView:(QNChatEmotionChooseView *)chatEmotionChooseView didSelectNomalItem:(NSInteger)item {
    if (self.textView.text.length < maxInputCount) {
        // 插入表情到输入框
        QNChatEmotion *emotion = [self.emotionArray objectAtIndex:item];
        [self.textView insertEmotion:emotion];
    }
}

- (void)chatEmotionChooseView:(QNChatEmotionChooseView *)chatEmotionChooseView didSelectSmallItem:(QNChatSmallGradeEmotion *)item {
    // 点击普通界面的小高表
    [self chatEmotionViewDidSelectSmallItem:item];
}

- (void)chatSmallEmotionView:(QNChatSmallEmotionView *)emotionListView didSelectSmallEmotion:(QNChatSmallGradeEmotion *)item {
    // 点击小高表界面的小高表
    [self chatEmotionViewDidSelectSmallItem:item];
}

- (void)chatEmotionViewDidSelectSmallItem:(QNChatSmallGradeEmotion *)item {
    // 点击小高表
    if ([self.liveChatManager isChatingUserInChatState:self.womanId]) {
        LSLCMagicIconItemObject *emotionItemObject = item.magicIconItemObject;
        [self.liveChatManager getMagicIconSrcImage:emotionItemObject.iconId];
        [self sendSmallEmotion:emotionItemObject.iconId];
    } else {
        // 必须开聊才能发送图片
        NSString *inChatTips = NSLocalizedStringFromSelf(@"Tips_InChat_Emotion");
        UIAlertView *chatAlertView = [[UIAlertView alloc] initWithTitle:nil message:inChatTips delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        chatAlertView.tag = AlertTypeInChatAllow;
        [chatAlertView show];
    }
}

#pragma mark - 表情键盘选择回调
- (NSUInteger)pagingViewCount:(QNChatEmotionKeyboardView *)chatEmotionKeyboardView {
    return 1;
}

- (Class)chatEmotionKeyboardView:(QNChatEmotionKeyboardView *)chatEmotionKeyboardView classForIndex:(NSUInteger)index {
    Class cls = nil;
    switch (index) {
        case 0: {
            // 普通表情
            cls = [QNChatNomalSmallEmotionView class];
        } break;
        default: {
            cls = [UIView class];
        } break;
    }
    return cls;
}

- (UIView *)chatEmotionKeyboardView:(QNChatEmotionKeyboardView *)chatEmotionKeyboardView pageViewForIndex:(NSUInteger)index {
    UIView *view = nil;
    switch (index) {
        case 0: {
            // 普通表情
            view = self.normalAndSmallEmotionView;
        } break;
        default: {
            view = [[UIView alloc] init];
        } break;
    }

    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    view.frame = frame;

    return view;
}

- (void)chatEmotionKeyboardView:(QNChatEmotionKeyboardView *)chatEmotionKeyboardView preparePageViewForDisplay:(UIView *)pageView forIndex:(NSUInteger)index {
    switch (index) {
        case 0: {
            // 普通表情
            [self.normalAndSmallEmotionView reloadData];

            // 大侠好手速 兼容scrollview和page不同步 Calvin 2-4 优化成同步点而不是同步界面，同时下载表情
            CGFloat pageWidth = self.normalAndSmallEmotionView.smallEmotionView.frame.size.width;
            int currentPage = self.normalAndSmallEmotionView.smallEmotionView.emotionCollectionView.contentOffset.x / pageWidth;
            if (self.normalAndSmallEmotionView.pageView.currentPage != 0) {
                self.normalAndSmallEmotionView.pageView.currentPage = currentPage + 1;
                // 下载表情
                [self chatSmallEmotionView:nil currentPageNumber:currentPage];
            }

        } break;
        default: {
        } break;
    }
}

#pragma mark - 高表操作内容点击回调
/*
- (void)chatLargeEmotionSelfTableViewCell:(QNChatLargeEmotionSelfTableViewCell *)cell DidClickRetryBtn:(UIButton *)retryBtn {
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    [self handleErrorMsg:path.row];
}

- (void)chatEmotionListView:(ChatEmotionListView *)emotionListView didSelectLargeEmotion:(ChatHighGradeEmotion *)item {
    LSLCLiveChatMsgItemObject *msg = [self.liveChatManager getTheOtherLastMessage:self.womanId];
    if (msg) {
        EmotionItemObject *emotionItemObject = item.emotionItemObject;
        [self sendLargeEmotion:emotionItemObject.emotionId];

    } else {
        // 必须开聊才能发送图片
        NSString *inChatTips = NSLocalizedStringFromSelf(@"Tips_InChat_Emotion");
        UIAlertView *chatAlertView = [[UIAlertView alloc] initWithTitle:nil message:inChatTips delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        chatAlertView.tag = AlertTypeInChatAllow;
        [chatAlertView show];
    }
}

- (void)chatEmotionListView:(ChatEmotionListView *)emotionListView didLongPressLargeEmotion:(ChatHighGradeEmotion *)item {
    //    // 切换视图将播放数组置空
    //    self.largeEmotion.animationArray = nil;
    //
    //    // 展示预览视图
    //    [self.view.window addSubview:self.largeEmotion];
    //    [self.largeEmotion mas_updateConstraints:^(MASConstraintMaker *make) {
    //        make.width.equalTo(@122);
    //        make.height.equalTo(@122);
    //        make.centerX.equalTo(self.view.mas_centerX);
    //        make.bottom.equalTo(self.chatEmotionKeyboardView.mas_top).offset(-10);
    //    }];
    //
    //    // 记录当前播放高表Id
    //    self.playingEmotionId = item.emotionItemObject.emotionId;
    //
    //    // 获取高表播放图片
    //    [self.liveChatManager GetEmotionPlayImage:item.emotionItemObject.emotionId];
    //
    //    // 开始播放
    //    [self.largeEmotion playGif:item.liveChatEmotionItemObject.imagePath];
}

- (void)chatEmotionListView:(ChatEmotionListView *)emotionListView didLongPressReleaseLargeEmotion:(ChatHighGradeEmotion *)item {
    //    // 移除预览视图
    //
    //    self.largeEmotion.imageView.animationImages = nil;
    //    [self.largeEmotion removeFromSuperview];
    //    self.largeEmotion = nil;
}

- (void)chatEmotionListView:(ChatEmotionListView *)emotionListView currentPageNumber:(NSInteger)page {
    // 按照分页加载表情
    //    int maxLoadPic = screenSize.width == 320 ? 8 : 10;
    //    for (NSInteger i = page * maxLoadPic; i < self.largeEmotionListArray.count; i++) {
    //        ChatHighGradeEmotion *item = [self.largeEmotionListArray objectAtIndex:i];
    //        if (!item.image) {
    //            [self.liveChatManager GetEmotionImage:item.emotionItemObject.emotionId];
    //        }
    //        if (i == self.largeEmotionListArray.count || i >= (page * maxLoadPic) + maxLoadPic) {
    //            break;
    //        }
    //    }
}
*/

#pragma mark - 小高表操作回调
- (void)chatSmallEmotionSelfTableViewCellDelegate:(QNChatSmallEmotionSelfTableViewCell *)cell DidClickRetryBtn:(UIButton *)retryBtn {
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    [self handleErrorMsg:path.row];
}

#pragma mark - 更新联系人逻辑
- (void)updateRecents:(LSLCLiveChatMsgItemObject *)msg {
    // 更新最近联系人数据
    LSLadyRecentContactObject *recent = [[QNContactManager manager] getOrNewRecentWithId:self.womanId];
    [recent updateRecent:self.firstName recentPhoto:self.photoURL];
    recent.lasttime = msg.createTime;
    recent.manLastMsg = YES;
    // 更新联系人列表
    [[QNContactManager manager] updateRecents];
}

#pragma mark - 发送消息逻辑
- (void)reSendMsg:(NSInteger)index {
    // 重发消息
    if (index < self.msgArray.count) {
        QNMessage *msg = [self.msgArray objectAtIndex:index];

                // 删除旧信息, 只改数据
                [self.liveChatManager removeHistoryMessage:self.womanId msgId:msg.msgId];
                [self.msgArray removeObjectAtIndex:index];
        
                // 刷新列表
                [self.tableView beginUpdates];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
        
                @synchronized(self) {
                    NSMutableArray *warnningMsg = [NSMutableArray array];
                    for (QNMessage *msg in self.msgArray) {
                        if (msg.type == MessageTypeWarningTips) {
                            [self.liveChatManager removeHistoryMessage:self.womanId msgId:msg.msgId];
                            [warnningMsg addObject:msg];
                            break;
                        }
                    }
        
                    NSMutableArray *warnningMsgIndex = [NSMutableArray array];
                    for (int i = 0; i < self.msgArray.count; i++) {
                        QNMessage *msg = [self.msgArray objectAtIndex:i];
                        if (msg.type == MessageTypeWarningTips) {
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                            [warnningMsgIndex addObject:indexPath];
                            break;
                        }
                    }
        
                    [self.msgArray removeObjectsInArray:warnningMsg];
                    [self.tableView beginUpdates];
                    [self.tableView deleteRowsAtIndexPaths:warnningMsgIndex withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                }
        
                // 重新发送
                switch (msg.type) {
                    case MessageTypeText: {
                        [self sendMsg:msg.text];
                    } break;
                    case MessageTypePhoto: {
                       // [self sendPhoto:msg.liveChatMsgItemObject.secretPhoto.srcFilePath];
                    } break;
                    case MessageTypeSmallEmotion: {
                        [self sendSmallEmotion:msg.liveChatMsgItemObject.magicIconMsg.magicIconId];
        
                    } break;
                    case MessageTypeLargeEmotion: {
                       // [self sendLargeEmotion:msg.liveChatMsgItemObject.emotionMsg.emotionId];
                    } break;
                    case MessageTypeVoice: {
                        [self sendVoice:msg.liveChatMsgItemObject.voiceMsg.filePath time:msg.liveChatMsgItemObject.voiceMsg.timeLength];
                    } break;
                    default:
                        break;
                }
    }
}

- (BOOL)isEmpty:(NSString *)str {
    // 判断内容是否全部为空格  yes 全部为空格  no 不是
    if (!str) {
        return true;
    } else {
        NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *trimedString = [str stringByTrimmingCharactersInSet:set];
        if ([trimedString length] == 0) {
            return true;
        } else {
            return false;
        }
    }
}

- (void)sendMsg:(NSString *)text {
     //TODO:发送文本
        if ([self isEmpty:text]) {
            [self.textView setText:@""];
            [self.textView setNeedsDisplay];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedStringFromSelf(@"Send_Error_Tips_Space") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            return;
        }
    
        // 去除掉首尾的空白字符和换行字符
        text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        text = [text stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
        // 发送消息
        LSLCLiveChatMsgItemObject *msg = [self.liveChatManager sendTextMsg:self.womanId text:text];
        if (msg != nil) {
            NSLog(@"ChatViewController::sendMsg( 发送文本消息 : %@, msgId : %ld )", text, (long)msg.msgId);
    
            // 更新最近联系人数据
            [self updateRecents:msg];
    
        } else {
            NSLog(@"ChatViewController::sendMsg( 发送文本消息 : %@, 失败 )", text);
        }
    
        // 刷新输入框
        [self.textView setText:@""];
        // 刷新默认提示
        [self.textView setNeedsDisplay];
        // 刷新列表
        [self insertData:msg scrollToEnd:YES animated:YES];
}

- (void)sendVoice:(NSString *)filePath time:(int)time {
    [[LiveModule module].analyticsManager reportActionEvent:SendLivechatVoiceMessage eventCategory:EventCategoryLiveChat];
        // TODO:发送语音
        if (filePath) {
            LSLCLiveChatMsgItemObject *msg = nil;
            msg = [self.liveChatManager sendVoice:self.womanId voicePath:filePath fileType:@"mp3" timeLength:time];
            if (msg != nil) {
                NSLog(@"ChatViewController::sendVoice( 发送语音消息 : %@, msgId : %ld )", msg.voiceMsg.filePath, (long)msg.msgId);
    
                // 更新最近联系人数据
                [self updateRecents:msg];
                // 刷新列表, 拉到最低
                [self insertData:msg scrollToEnd:YES animated:YES];
    
            } else {
                NSLog(@"ChatViewController::sendVoice( 发送语音消息 : %@, 失败 )", msg.voiceMsg.filePath);
            }
        }
}

- (void)sendSmallEmotion:(NSString *)emotionId {
    [[LiveModule module].analyticsManager reportActionEvent:SendLivechatSticker eventCategory:EventCategoryLiveChat];
    // TODO:发送小高级表情
        LSLCLiveChatMsgItemObject *msg = [self.liveChatManager sendMagicIcon:self.womanId iconId:emotionId];
        self.msgItem = msg;
        if (msg != nil) {
            NSLog(@"ChatViewController::sendEmotion( 发送小高级表情消息 emotionId : %@ )", msg.magicIconMsg.magicIconId);
    
            // 更新最近联系人数据
            [self updateRecents:msg];
    
        } else {
            NSLog(@"ChatViewController::sendEmotion( 发送小高级表情消息 : %@, 失败 )", msg.magicIconMsg.magicIconId);
        }
        [self insertData:msg scrollToEnd:YES animated:YES];
}

#pragma mark - 播放语音
- (void)palyVoice:(NSInteger)row {
        // 语音在播放中，点击其他语音
        if (self.audioPlayer.isPlaying && row != self.voicePlayRow) {
            QNMessage *item = [self.msgArray objectAtIndex:self.voicePlayRow];
            if (item.sender == MessageSenderSelf) {
                QNChatVoiceSelfTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.voicePlayRow inSection:0]];
                [cell setPalyButtonImage:NO];
                item.liveChatMsgItemObject.voiceMsg.isPalying = NO;
            } else {
                QNChatVoiceTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.voicePlayRow inSection:0]];
                [cell setPalyButtonImage:NO];
                item.liveChatMsgItemObject.voiceMsg.isPalying = NO;
            }
        }
    
        self.voicePlayRow = row;
        QNMessage *item = [self.msgArray objectAtIndex:row];
        //将语音标记为已读
        QNChatVoiceTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    
        if (item.liveChatMsgItemObject.voiceMsg.filePath.length > 0) {
            [self stopVoice:row];
            [cell setPalyButtonImage:YES];
            if (item.sender != MessageSenderSelf) {
                cell.redView.hidden = YES;
                NSString *voiceID = [NSString stringWithFormat:@"%@_%@", item.liveChatMsgItemObject.voiceMsg.voiceId, item.liveChatMsgItemObject.fromId];
                [self.voiceManager saveVoiceReadMessage:voiceID];
                item.liveChatMsgItemObject.voiceMsg.isRead = YES;
            }
            item.liveChatMsgItemObject.voiceMsg.isPalying = YES;
            [self.audioPlayer playSongWithUrl:item.liveChatMsgItemObject.voiceMsg.filePath];
        } else {
            [cell setPalyButtonImage:NO];
            [self.liveChatManager getVoice:self.womanId msgId:(int)item.msgId];
        }
}

//停止播放语音
- (void)stopVoice:(NSInteger)row {
    if (self.msgArray.count > 0) {
        QNMessage *item = [self.msgArray objectAtIndex:row];
        if (item.type == MessageTypeVoice) {
            item.liveChatMsgItemObject.voiceMsg.isPalying = NO;

            QNChatVoiceTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
            [cell setPalyButtonImage:NO];

            [self.audioPlayer stopSound];
        }
    }
}

//播放语音完成
- (void)chatAudioPlayerDidFinishPlay {
    if (self.msgArray.count > 0) {
        QNMessage *item = [self.msgArray objectAtIndex:self.voicePlayRow];
        if (item.type == MessageTypeVoice) {
            if (item.sender == MessageSenderSelf) {
                QNChatVoiceSelfTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.voicePlayRow inSection:0]];
                [cell setPalyButtonImage:NO];
                item.liveChatMsgItemObject.voiceMsg.isPalying = NO;
            } else {
                QNChatVoiceTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.voicePlayRow inSection:0]];
                [cell setPalyButtonImage:NO];
                item.liveChatMsgItemObject.voiceMsg.isPalying = NO;
            }
        }
    }
}

- (void)chatAudioPlayerFailPlay {
        if (self.msgArray.count > 0) {
            QNMessage *item = [self.msgArray objectAtIndex:self.voicePlayRow];
            item.liveChatMsgItemObject.voiceMsg.isPalying = NO;
            [self.liveChatManager getVoice:self.womanId msgId:(int)item.msgId];
            NSString *voiceID = [NSString stringWithFormat:@"%@_%@", item.liveChatMsgItemObject.voiceMsg.voiceId, item.liveChatMsgItemObject.fromId];
            [self.voiceManager removeVoiceReadMessage:voiceID];
    
            [self chatAudioPlayerDidFinishPlay];
        }
}

#pragma mark - 录音按钮点击事件
// 录音按钮按下
- (void)voiceButtonTouchDown {
    [self stopVoice:self.voicePlayRow];
    [self chatAudioPlayerDidFinishPlay];
    if (![QNChatVoiceView canRecord]) {
        NSString *messageTips = [NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"Allow", nil), [[[LiveBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"], NSLocalizedString(@"Tips_Voice_Allow", nil)];
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:messageTips
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    } else {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"DidAudioPermissions"]) {
            LSLCLiveChatMsgItemObject *msg = [self.liveChatManager getTheOtherLastMessage:self.womanId];
            if (msg) {
                self.voiceImageView.hidden = NO;
                [self.view bringSubviewToFront:self.voiceImageView];
                [self.chatVoiceView removeFromSuperview];
                self.chatVoiceView = [[QNChatVoiceView alloc] initWithFrame:self.view.window.bounds];
                self.chatVoiceView.delegate = self;
                [self.view.window addSubview:self.chatVoiceView];
                [self.chatVoiceView voiceButtonTouchDown];
            } else {
                // 必须开聊才能发送语音
                NSString *inChatTips = NSLocalizedStringFromSelf(@"Tips_InChat_Voice");
                UIAlertView *chatAlertView = [[UIAlertView alloc] initWithTitle:nil message:inChatTips delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                chatAlertView.tag = AlertTypeInChatAllow;
                [chatAlertView show];
            }
        }
    }
}

- (void)voiceButtonTouchUpOutside {
    // 手指在录音按钮外部时离开
    self.voiceImageView.hidden = YES;
    [self.chatVoiceView voiceButtonTouchUpOutside];
    [self.chatVoiceView removeFromSuperview];
}

- (void)voiceButtonTouchUpInside {
    // 手指在录音按钮内部时离开
    self.voiceImageView.hidden = YES;
    [self.chatVoiceView voiceButtonTouchUpInside];
    if (!self.chatVoiceView.isFail) {
        [self.chatVoiceView removeFromSuperview];
    }
}

- (void)voiceButtonDragOutside {
    // 手指移动到录音按钮外部
    [self.chatVoiceView voiceButtonDragOutside];
}

- (void)voiceButtonDragInside {
    // 手指移动到录音按钮内部
    [self.chatVoiceView voiceButtonDragInside];
}

#pragma mark - 消息管理逻辑
- (void)reloadData:(BOOL)isReloadView scrollToEnd:(BOOL)scrollToEnd animated:(BOOL)animated {
        // TODO:刷新消息列表
        NSMutableArray *dataArray = [NSMutableArray array];
        NSArray *array = [self.liveChatManager getMsgsWithUser:self.womanId];
        for (LSLCLiveChatMsgItemObject *msg in array) {
            QNMessage *item = [self reloadMessageFromLiveChatMsgItemObject:msg];
            [dataArray addObject:item];
        }
        if (isReloadView) {
            self.msgArray = dataArray;
            [self.tableView reloadData];
    
            if (scrollToEnd) {
                [self scrollToEnd:animated];
            }
        }
}

- (void)insertData:(LSLCLiveChatMsgItemObject *)object scrollToEnd:(BOOL)scrollToEnd animated:(BOOL)animated {
    // TODO:插入界面消息
    QNMessage *item = [self reloadMessageFromLiveChatMsgItemObject:object];
    [self.msgArray addObject:item];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.msgArray.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];

    if ([object.toId isEqualToString:self.womanId]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didChatList" object:nil];
    }

    if (scrollToEnd) {
        [self scrollToEnd:animated];
    }
}

- (void)updataMessageData:(LSLCLiveChatMsgItemObject *)object scrollToEnd:(BOOL)scrollToEnd animated:(BOOL)animated {
    // TODO:更新界面消息
    @synchronized(self) {
        //为了兼容cell插入数据时动画不冲突，延迟执行刷新
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            QNMessage *item = [self reloadMessageFromLiveChatMsgItemObject:object];
            NSInteger count = 0;
            for (int i = 0; i < self.msgArray.count; i++) {
                QNMessage *msg = self.msgArray[i];
                if (msg.msgId == object.msgId) {
                    count = i;
                    break;
                }
            }
            if (self.msgArray.count > 0) {
                [self.msgArray removeObjectAtIndex:count];
            }
            [self.msgArray insertObject:item atIndex:count];

            if (self.msgArray.count > 1) {
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:count inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
            } else {
                [self.tableView reloadData];
            }
            if (scrollToEnd) {
                [self scrollToEnd:animated];
            }
        });
    }
}

- (QNMessage *)reloadMessageFromLiveChatMsgItemObject:(LSLCLiveChatMsgItemObject *)msg {
    // TODO:生成消息数据
    QNMessage *item = [[QNMessage alloc] init];
        item.liveChatMsgItemObject = msg;
        item.msgId = msg.msgId;
        if (msg.msgType == MT_Custom) {
            // 自定义消息
            QNMessage *custom = [self.msgCustomDict valueForKey:[NSString stringWithFormat:@"%ld", (long)msg.msgId]];
            if (custom != nil) {
                item = [custom copy];
            }
        } else {
            // 其他
    
            // 方向
            switch (msg.sendType) {
                case SendType_Send: {
                    // 发出去的消息
                    item.sender = MessageSenderSelf;
                } break;
                case SendType_Recv: {
                    // 接收到的消息
                    item.sender = MessageSenderLady;
                } break;
                case SendType_System: {
                    // 系统消息
                } break;
                default:
                    break;
            }
    
            // 类型
            switch (msg.msgType) {
                case MT_Text: {
                    // 文本
                    item.type = MessageTypeText;
                    item.text = [LSStringEncoder htmlEntityDecode:msg.textMsg.displayMsg];
                    item.attText = [self parseMessageTextEmotion:item.text font:[UIFont systemFontOfSize:TextMessageFontSize]];
                } break;
                case MT_System: {
                    item.type = MessageTypeSystemTips;
    
                    switch (msg.systemMsg.codeType) {
                        case MESSAGE: {
                            // 普通系统消息
                            item.text = msg.systemMsg.message;
                        } break;
                        case TRY_CHAT_END: {
                            // 试聊结束消息
                            item.text = msg.systemMsg.message;
                            item.text = NSLocalizedStringFromSelf(@"Tips_Your_Free_Chat_Is_Ended");
                        } break;
                        case NOT_SUPPORT_TEXT: {
                            // 不支持文本消息
                            item.text = msg.systemMsg.message;
                            item.text = NSLocalizedStringFromSelf(@"Tips_Text_Not_Support");
                        } break;
                        case NOT_SUPPORT_EMOTION: {
                            // 试聊券系统消息
                            item.text = msg.systemMsg.message;
                            item.text = NSLocalizedStringFromSelf(@"Tips_Emotion_Not_Support");
                        } break;
                        case NOT_SUPPORT_VOICE: {
                            // 不支持语音消息
                            item.text = msg.systemMsg.message;
                            item.text = NSLocalizedStringFromSelf(@"Tips_Voice_Not_Support");
                        } break;
                        case NOT_SUPPORT_PHOTO: {
                            // 不支持私密照消息
                            item.text = msg.systemMsg.message;
                            item.text = NSLocalizedStringFromSelf(@"Tips_Photo_Not_Support");
                        } break;
                        case NOT_SUPPORT_MAGICICON: {
                            // 不支持小高表消息
                            item.text = msg.systemMsg.message;
                            item.text = NSLocalizedStringFromSelf(@"Tips_MagicIcon_Not_Support");
                        } break;
                        default:
                            break;
                    }
    
                    item.attText = [self parseMessage:item.text font:[UIFont systemFontOfSize:SystemMessageFontSize] color:MessageGrayColor];
                } break;
                case MT_Warning: {
                    item.type = MessageTypeWarningTips;
                    switch (msg.warningMsg.codeType) {
                        case WARNING_NOMONEY: {
                            item.text = msg.warningMsg.message;
                            NSString *tips = [NSString stringWithFormat:@"%@ Please ", NSLocalizedStringFromSelf(@"Warning_Error_Tips_No_Money")];
                            NSString *linkMessage = NSLocalizedStringFromSelf(@"Tips_Add_Credit");
                            item.attText = [self parseNoMomenyWarningMessage:tips linkMessage:linkMessage font:[UIFont systemFontOfSize:WarningMessageFontSize] color:MessageGrayColor];
                        } break;
                        default: {
                            item.text = msg.warningMsg.message;
                            item.attText = [self parseMessage:item.text font:[UIFont systemFontOfSize:SystemMessageFontSize] color:MessageGrayColor];
                        } break;
                    }
                } break;
                case MT_Photo: {
                    item.type = MessageTypePhoto;
                    item.secretPhotoImage = [UIImage imageNamed:@"LS_Chat_SecretPlaceholder"];
                } break;
                //语音类型
                case MT_Voice: {
                    item.type = MessageTypeVoice;
    
                    //如果本地没有语音文件就自动下载
                    if (item.liveChatMsgItemObject.voiceMsg.filePath.length == 0) {
                        [self.liveChatManager getVoice:self.womanId msgId:(int)item.msgId];
                    }
                    switch (item.sender) {
                        case MessageSenderLady: {
                            NSString *voiceID = [NSString stringWithFormat:@"%@_%@", item.liveChatMsgItemObject.voiceMsg.voiceId, item.liveChatMsgItemObject.fromId];
                            //标记是否已读
                            item.liveChatMsgItemObject.voiceMsg.isRead = [self.voiceManager voiceMessageIsRead:voiceID];
                        } break;
                        default:
                            break;
                    }
                } break;
                case MT_Emotion: {
                    item.type = MessageTypeLargeEmotion;
                    switch (item.sender) {
                        case MessageSenderLady:
                        case MessageSenderSelf: {
                            NSString *emotionId = msg.emotionMsg.emotionId;
    
                            // 设置缩略图
                            if (msg.emotionMsg.imagePath.length > 0) {
                                NSString *imagePath = msg.emotionMsg.imagePath;
                                item.emotionDefault = [self getEmotionImageFromCache:emotionId imagePath:imagePath];
                            } else {
                                [self.liveChatManager getEmotionImage:msg.emotionMsg.emotionId];
                            }
    
                            // 设置动画图片
                            if (msg.emotionMsg.playBigImages.count > 0) {
                                item.emotionAnimationArray = [self getEmotionImageArrayFromCache:emotionId imagePathArray:msg.emotionMsg.playBigImages];
                            } else {
                                [self.liveChatManager getEmotionPlayImage:emotionId];
                            }
    
                        } break;
    
                        default:
                            break;
                    }
                } break;
                case MT_MagicIcon: {
                    item.type = MessageTypeSmallEmotion;
                    switch (item.sender) {
                        case MessageSenderLady:
                        case MessageSenderSelf: {
                            NSString *emotionId = msg.magicIconMsg.magicIconId;
                            // 设置缩略图
                            if (msg.magicIconMsg.thumbPath.length > 0) {
                                NSString *imagePath = msg.magicIconMsg.thumbPath;
                                item.emotionDefault = [self getSmallThumbEmotionImageFromCache:emotionId imagePath:imagePath];
                            } else {
                                if (emotionId.length > 0) {
                                    [self.liveChatManager getMagicIconThumbImage:emotionId];
                                }
                            }
    
                        } break;
    
                        default:
                            break;
                    }
                } break;
                default:
                    break;
            }
    
            // 状态
            switch (msg.statusType) {
                case StatusType_Processing: {
                    // 处理中
                    item.status = MessageStatusProcessing;
                } break;
                case StatusType_Fail: {
                    // 失败
                    item.status = MessageStatusFail;
                } break;
                case StatusType_Finish: {
                    // 完成
                    item.status = MessageStatusFinish;
                } break;
    
                default:
                    break;
            }
        }

    return item;
}

- (void)scrollToEnd:(BOOL)animated {
    // TODO:滚动到列表底部
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSInteger count = [self.tableView numberOfRowsInSection:0];
        if( count > 0 ) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:count - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
        }
    });
}

- (QNMessage *)insertCustomMessage {
    // TODO:插入自定义消息类型
    LSLCLiveChatMsgItemObject *msg = [[LSLCLiveChatMsgItemObject alloc] init];
    msg.msgType = MT_Custom;
    msg.createTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970];

        // 无用代码
        msg.customMsg = [[LSLCLiveChatCustomItemObject alloc] init];

    // 记录自定义消息
    QNMessage *custom = [[QNMessage alloc] init];

        NSInteger msgId = [self.liveChatManager insertHistoryMessage:self.womanId msg:msg];
        custom.msgId = msgId;

    [self.msgCustomDict setValue:custom forKey:[NSString stringWithFormat:@"%ld", (long)msgId]];

    return custom;
}

- (void)insertWaringMessage {
    // TODO:插入非法警告消息
        LSLCLiveChatMsgItemObject *msg = [[LSLCLiveChatMsgItemObject alloc] init];
        msg.msgType = MT_Warning;
        msg.createTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970];
        msg.warningMsg = [[LSLCLiveChatWarningItemObject alloc] init];
        msg.warningMsg.message = NSLocalizedStringFromSelf(@"Send_Error_Tips_Illegal");
        [self.liveChatManager insertHistoryMessage:self.womanId msg:msg];
        [self insertData:msg scrollToEnd:YES animated:YES];
}

- (void)clearCustomMessage {
    // TODO:清空自定义消息
        for (NSString *key in self.msgCustomDict) {
            QNMessage *msg = [self.msgCustomDict valueForKey:key];
            [self.liveChatManager removeHistoryMessage:self.womanId msgId:msg.msgId];
        }
}

- (void)outCreditEvent:(NSInteger)index {
    // TODO:帐号余额不足, 弹出买点
    NSString *tips = NSLocalizedStringFromSelf(@"Send_Error_Tips_No_Money");
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:nil message:tips preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *_Nonnull action) {
                                                       [self addCreditsViewShow];
                                                   }];
        [alertVc addAction:ok];
        [self presentViewController:alertVc animated:NO completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:tips delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        alertView.tag = index;
        [alertView show];
    }
}

- (void)handleErrorMsg:(NSInteger)index {
    // TODO:错误消息处理
    QNMessage *msg = [self.msgArray objectAtIndex:index];
    LSLCLiveChatMsgProcResultObject *procResult = msg.liveChatMsgItemObject.procResult;

    if (procResult) {
        switch (procResult.errType) {
            case LSLIVECHAT_LCC_ERR_FAIL:
            case LSLIVECHAT_LCC_ERR_UNBINDINTER:         // 女士的翻译未将其绑定
            case LSLIVECHAT_LCC_ERR_SIDEOFFLINE:         // 对方不在线
            case LSLIVECHAT_LCC_ERR_NOTRANSORAGENTFOUND: // 没有找到翻译或机构
            case LSLIVECHAT_LCC_ERR_BLOCKUSER:           // 对方为黑名单用户（聊天）
            case LSLIVECHAT_LCC_ERR_NOMONEY: {
                // 重新获取当前女士用户状态
                LSLCLiveChatUserItemObject *user = [self.liveChatManager getUserWithId:self.womanId];
                if (user && user.statusType == USTATUS_ONLINE) {
                    // 弹出重试
                    NSString *tips = NSLocalizedStringFromSelf(@"Send_Error_Tips_Retry");
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:tips delegate:self cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:NSLocalizedString(@"Retry", nil), nil];

                    alertView.tag = index;
                    [alertView show];

                } else {
                    // 弹出不在线
                    NSString *tips = NSLocalizedStringFromSelf(@"Send_Error_Tips_Offline");
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:tips delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                    alertView.tag = index;
                    [alertView show];
                }

            } break;
            default: {
                // 其他未处理错误
                NSString *tips = NSLocalizedStringFromSelf(@"Send_Error_Tips_Other");
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:tips delegate:self cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:NSLocalizedString(@"Retry", nil), nil];

                alertView.tag = index;
                [alertView show];

            } break;
        }
    }
}

#pragma mark - 买点和月费逻辑
- (void)addCreditsViewShow {
    // TODO:显示买点
    LSAddCreditsViewController *vc = [[LSAddCreditsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 表情管理逻辑
- (void)reloadEmotion {
    // TODO:加载表情配置文件
    NSString *emotionPlistPath = [[LiveBundle mainBundle] pathForResource:@"LSEmotionList" ofType:@"plist"];
    NSArray *emotionFileArray = [[NSArray alloc] initWithContentsOfFile:emotionPlistPath];

    // 初始化普通表情文件名字
    NSMutableArray *emotionArray = [NSMutableArray array];
    NSMutableDictionary *emotionDict = [NSMutableDictionary dictionary];

    QNChatEmotion *emotion = nil;
    UIImage *image = nil;
    NSString *imageFileName = nil;
    NSString *imageName = nil;

    for (NSDictionary *dict in emotionFileArray) {
        imageFileName = [dict objectForKey:@"name"];
        image = [UIImage imageNamed:imageFileName];
        if (image != nil) {
            imageName = [self parseEmotionTextByImageName:imageFileName];
            emotion = [[QNChatEmotion alloc] initWithTextImage:imageName image:image];

            [emotionDict setObject:emotion forKey:imageName];
            [emotionArray addObject:emotion];
        }
    }
    self.emotionDict = emotionDict;
    self.emotionArray = emotionArray;
}

- (UIImage *)getEmotionImageFromCache:(NSString *)emotionId imagePath:(NSString *)imagePath {
    UIImage *image = [self.emotionImageCacheDict valueForKey:emotionId];
    if (image == nil) {
        NSData *data = [NSData dataWithContentsOfFile:imagePath];
        image = [UIImage imageWithData:data];
        [self.emotionImageCacheDict setValue:image forKey:emotionId];
    }

    return image;
}

- (NSArray<UIImage *> *)getEmotionImageArrayFromCache:(NSString *)emotionId imagePathArray:(NSArray<NSString *> *)imagePathArray {
    NSMutableArray *imageArray = [NSMutableArray array];
    @synchronized(self.emotionImageArrayCacheDict) {
        imageArray = [self.emotionImageArrayCacheDict valueForKey:emotionId];
    }

    if (imageArray == nil) {
        imageArray = [NSMutableArray array];
        for (NSString *filePath in imagePathArray) {
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            UIImage *image = [UIImage imageWithData:data];
            if (image != nil) {
                [imageArray addObject:image];
            }
        }
        if (imageArray.count > 0) {
            @synchronized(self.emotionImageArrayCacheDict) {
                [self.emotionImageArrayCacheDict setValue:imageArray forKey:emotionId];
            }
        } else {
            [self.liveChatManager getEmotionPlayImage:emotionId];
        }
    }
    return imageArray;
}

- (void)reloadSmallEmotion {
    // TODO:加载小高表配置和列表
    LSLCLiveChatMagicIconConfigItemObject *items = [self.liveChatManager getMagicIconConfigItem];
    NSArray<LSLCMagicIconItemObject *> *emotions = items.magicIconList;
    NSMutableArray *array = [NSMutableArray array];
    for (LSLCMagicIconItemObject *emotion in emotions) {
        QNChatSmallGradeEmotion *item = [[QNChatSmallGradeEmotion alloc] init];
        item.magicIconItemObject = emotion;

        //判断本地文件是否有图片 Calvin 2-4 这个逻辑需要与下载表情的逻辑同步
        NSString *filePath = [self.liveChatManager getMagicIconThumbPath:emotion.iconId];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            LSLCLiveChatMagicIconItemObject *magicItem = [[LSLCLiveChatMagicIconItemObject alloc] init];
            magicItem.thumbPath = filePath;
            item.liveChatMagicIconItemObject = magicItem;
        }

        [array addObject:item];
    }
    // 排序
    NSSortDescriptor *typeDesc = [NSSortDescriptor sortDescriptorWithKey:@"magicIconItemObject.typeId" ascending:NO];
    NSSortDescriptor *iconIdDesc = [NSSortDescriptor sortDescriptorWithKey:@"magicIconItemObject.iconId" ascending:NO];
    NSArray *descs = [NSArray arrayWithObjects:typeDesc, iconIdDesc, nil];
    NSArray *sortArray = [array sortedArrayUsingDescriptors:descs];
    self.smallEmotionListArray = sortArray;
    [self.normalAndSmallEmotionView reloadData];

    //下载15张
    int maxLoadPic = screenSize.width == 320 ? 12 : 15;
    for (int i = 0; i < self.smallEmotionListArray.count; i++) {
        QNChatSmallGradeEmotion *item = [self.smallEmotionListArray objectAtIndex:i];
        // 手动下载/更新小高级表情图片文件
        [self.liveChatManager getMagicIconThumbImage:item.magicIconItemObject.iconId];
        if (i >= maxLoadPic) {
            break;
        }
    }
}

- (QNChatSmallGradeEmotion *)getSmallThumbEmotionFromCache:(NSString *_Nonnull)emotionId {
    QNChatSmallGradeEmotion *item = nil;
    for (QNChatSmallGradeEmotion *emotion in self.smallEmotionListArray) {
        if ([emotion.magicIconItemObject.iconId isEqualToString:emotionId]) {
            item = emotion;
            break;
        }
    }
    return item;
}

/**
 *  小高级表情排序比较函数
 *
 *  @param obj1    小高级表情object1
 *  @param obj2    小高级表情object2
 *  @param context 参数
 *
 *  @return 排序结果
 */
NSInteger sortSmallThumbEmotion(id _Nonnull obj1, id _Nonnull obj2, void *_Nullable context) {
    NSComparisonResult result = NSOrderedSame;
    QNChatSmallGradeEmotion *emotionItem1 = (QNChatSmallGradeEmotion *)obj1;
    QNChatSmallGradeEmotion *emotionItem2 = (QNChatSmallGradeEmotion *)obj2;

    //    // tag
    if (NSOrderedSame == result) {
        if (emotionItem1.magicIconItemObject.typeId != emotionItem2.magicIconItemObject.typeId) {
            result = (emotionItem1.magicIconItemObject.typeId ? NSOrderedAscending : NSOrderedDescending);
        }
    }

    if (NSOrderedSame == result) {
        if (emotionItem1.magicIconItemObject.iconId != emotionItem2.magicIconItemObject.iconId) {
            result = (emotionItem1.magicIconItemObject.iconId ? NSOrderedAscending : NSOrderedDescending);
        }
    }
    return result;
}

- (UIImage *)getSmallThumbEmotionImageFromCache:(NSString *)emotionId imagePath:(NSString *)imagePath {
    UIImage *image = [self.smallEmotionImageCacheDict valueForKey:emotionId];
    if (image == nil) {
        NSData *data = [NSData dataWithContentsOfFile:imagePath];
        if (data != nil) {
            image = [UIImage imageWithData:data];
            [self.smallEmotionImageCacheDict setValue:image forKey:emotionId];
        } else {
            [self.liveChatManager getMagicIconThumbImage:emotionId];
        }
    }
    return image;
}

#pragma mark - 消息列表文本解析
/**
 *  根据表情文件名字生成表情协议名字
 *
 *  @param imageName 表情文件名字
 *
 *  @return 表情协议名字
 */
- (NSString *)parseEmotionTextByImageName:(NSString *)imageName {
    NSMutableString *resultString = [NSMutableString stringWithString:imageName];

    NSRange range = [resultString rangeOfString:@"img"];
    if (range.location != NSNotFound) {
        [resultString replaceCharactersInRange:range withString:@"[img:"];
        [resultString appendString:@"]"];
    }
    return resultString;
}

/**
 *  解析消息表情和文本消息
 *
 *  @param text 普通文本消息
 *  @param font        字体
 *  @return 表情富文本消息
 */
- (NSAttributedString *)parseMessageTextEmotion:(NSString *)text font:(UIFont *)font {
    NSMutableAttributedString *attributeString = nil;
    if (text != nil) {
        attributeString = [[NSMutableAttributedString alloc] initWithString:text];
    }
    NSRange range;
    NSRange endRange;
    NSRange valueRange;
    NSRange replaceRange;

    NSString *emotionOriginalString = nil;
    NSAttributedString *emotionAttString = nil;
    QNChatTextAttachment *attachment = nil;

    NSString *findString = attributeString.string;

    // 替换img
    while (
        (range = [findString rangeOfString:@"[img:"]).location != NSNotFound &&
        (endRange = [findString rangeOfString:@"]"]).location != NSNotFound &&
        range.location < endRange.location) {
        // 增加表情文本
        attachment = [[QNChatTextAttachment alloc] init];
        attachment.bounds = CGRectMake(0, -4, font.lineHeight, font.lineHeight);

        // 解析表情字串
        valueRange = NSMakeRange(range.location, NSMaxRange(endRange) - range.location);
        // 原始字符串
        emotionOriginalString = [findString substringWithRange:valueRange];

        QNChatEmotion *emotion = [self.emotionDict objectForKey:emotionOriginalString];
        if (emotion != nil) {
            attachment.image = emotion.image;
        }

        attachment.text = emotionOriginalString;
        // 生成表情富文本
        emotionAttString = [NSAttributedString attributedStringWithAttachment:attachment];
        // 替换普通文本为表情富文本
        replaceRange = NSMakeRange(range.location, NSMaxRange(endRange) - range.location);
        [attributeString replaceCharactersInRange:replaceRange withAttributedString:emotionAttString];
        // 替换查找文本
        findString = attributeString.string;
    }

    [attributeString addAttributes:@{ NSFontAttributeName : font } range:NSMakeRange(0, attributeString.length)];

    return attributeString;
}

/**
 *  解析普通消息
 *
 *  @param text 普通文本
 *  @param font        字体
 *  @return 普通富文本消息
 */
- (NSAttributedString *)parseMessage:(NSString *)text font:(UIFont *)font color:(UIColor *)textColor {
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributeString addAttributes:@{
        NSFontAttributeName : font,
        NSForegroundColorAttributeName : textColor
    }
                             range:NSMakeRange(0, attributeString.length)];
    return attributeString;
}

/**
 *  解析没钱警告消息
 *
 *  @param text 没钱警告消息
 *  @param linkMessage 可以点击的文字
 *  @param font        字体
 *  @return 没钱富文本警告消息
 */
- (NSAttributedString *)parseNoMomenyWarningMessage:(NSString *)text linkMessage:(NSString *)linkMessage font:(UIFont *)font color:(UIColor *)textColor {
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributeString addAttributes:@{
        NSFontAttributeName : font,
        NSForegroundColorAttributeName : textColor
    }
                             range:NSMakeRange(0, attributeString.length)];

    QNChatTextAttachment *attachment = [[QNChatTextAttachment alloc] init];
    attachment.text = linkMessage;
    attachment.url = [NSURL URLWithString:ADD_CREDIT_URL];
    attachment.bounds = CGRectMake(0, -4, font.lineHeight, font.lineHeight);
    NSMutableAttributedString *attributeLinkString = [[NSMutableAttributedString alloc] initWithString:linkMessage];
    [attributeLinkString addAttributes:@{
        NSFontAttributeName : font,
        NSAttachmentAttributeName : attachment,
    }
                                 range:NSMakeRange(0, attributeLinkString.length - 1)];

    [attributeString appendAttributedString:attributeLinkString];
    return attributeString;
}

#pragma mark - 消息列表界面回调 (UITableViewDataSource / UITableViewDelegate)
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int count = 1;
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger number = self.msgArray.count;
    return number;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0;
    if (indexPath.row < 0 || indexPath.row >= self.msgArray.count) {
        return height;
    }
    // 数据填充
    QNMessage *item = [self.msgArray objectAtIndex:indexPath.row];
    switch (item.type) {
        case MessageTypeSystemTips: {
            // 系统消息
            CGSize viewSize = CGSizeMake(self.tableView.frame.size.width, [QNChatSystemTipsTableViewCell cellHeight:self.tableView.frame.size.width detailString:item.attText]);
            height = viewSize.height;
        } break;
        case MessageTypeWarningTips: {
            // 警告消息
            // 系统消息
            CGSize viewSize = CGSizeMake(self.tableView.frame.size.width, [QNChatSystemTipsTableViewCell cellHeight:self.tableView.frame.size.width detailString:item.attText]);
            height = viewSize.height;
        } break;
        case MessageTypeText: {
            // 文本
            switch (item.sender) {
                case MessageSenderLady: {
                    // 对方
                    CGSize viewSize = CGSizeMake(self.tableView.frame.size.width, [QNChatTextLadyTableViewCell cellHeight:self.tableView.frame.size.width detailString:item.attText]);
                    height = viewSize.height;
                } break;
                case MessageSenderSelf: {
                    // 自己
                    CGSize viewSize = CGSizeMake(self.tableView.frame.size.width, [QNChatTextSelfTableViewCell cellHeight:self.tableView.frame.size.width detailString:item.attText]);
                    height = viewSize.height;
                } break;
                default: {
                } break;
            }
        } break;
        case MessageTypePhoto: {
            // 图片
            switch (item.sender) {
                case MessageSenderLady: {
                    // 对方
                    CGSize viewSize = CGSizeMake(self.tableView.frame.size.width, [QNChatPhotoLadyTableViewCell cellHeight]);
                    height = viewSize.height;
                } break;
                case MessageSenderSelf: {
                    // 自己
                    CGSize viewSize = CGSizeMake(self.tableView.frame.size.width, [QNChatPhotoSelfTableViewCell cellHeight]);
                    height = viewSize.height;
                } break;
                default: {
                } break;
            }
        } break;
        case MessageTypeVoice: {
            //语音
            CGSize viewSize = CGSizeMake(self.tableView.frame.size.width, [QNChatVoiceTableViewCell cellHeight]);
            height = viewSize.height;
        } break;
        case MessageTypeCoupon: {
            // 试聊券
            CGSize viewSize = CGSizeMake(self.tableView.frame.size.width, [QNChatCouponTableViewCell cellHeight]);
            height = viewSize.height;
        } break;
        case MessageTypeLargeEmotion: {
            //  高级表情
            switch (item.sender) {
                case MessageSenderLady: {
                    // 对方
                    CGSize viewSize = CGSizeMake(self.tableView.frame.size.width, [QNChatLargeEmotionLadyTableViewCell cellHeight]);
                    height = viewSize.height;
                } break;
                case MessageSenderSelf: {
                    // 自己
                    CGSize viewsize = CGSizeMake(self.tableView.frame.size.width, [QNChatLargeEmotionSelfTableViewCell cellHeight]);
                    return viewsize.height;
                } break;
                default:
                    break;
            }
        } break;
        case MessageTypeSmallEmotion: {
            //  小高级表情
            switch (item.sender) {
                case MessageSenderLady: {
                    // 对方
                    CGSize viewSize = CGSizeMake(self.tableView.frame.size.width, [QNChatSmallEmotionLadyTableViewCell cellHeight]);
                    height = viewSize.height;
                } break;
                case MessageSenderSelf: {
                    // 自己
                    CGSize viewsize = CGSizeMake(self.tableView.frame.size.width, [QNChatSmallEmotionSelfTableViewCell cellHeight]);
                    return viewsize.height;
                } break;
                default:
                    break;
            }
        } break;
        default: {
        } break;
    }
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *result = nil;
    if (indexPath.row < 0 || indexPath.row >= self.msgArray.count) {
        result = [tableView dequeueReusableCellWithIdentifier:@""];
        if (!result) {
            result = [[UITableViewCell alloc] init];
        }
    }
    // 数据填充
    QNMessage *item = [self.msgArray objectAtIndex:indexPath.row];
    switch (item.type) {
        case MessageTypeSystemTips: {
            // 系统提示
            QNChatSystemTipsTableViewCell *cell = [QNChatSystemTipsTableViewCell getUITableViewCell:tableView];
            result = cell;
            cell.detailLabel.attributedText = item.attText;
            cell.detailLabel.delegate = self;
            [item.attText enumerateAttributesInRange:NSMakeRange(0, item.attText.length)
                                             options:0
                                          usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
                                              QNChatTextAttachment *attachment = attrs[NSAttachmentAttributeName];
                                              if (attachment && attachment.url != nil) {
                                                  [cell.detailLabel addLinkToURL:attachment.url withRange:range];
                                              }
                                          }];
        } break;
        case MessageTypeWarningTips: {
            // 警告消息
            QNChatSystemTipsTableViewCell *cell = [QNChatSystemTipsTableViewCell getUITableViewCell:tableView];
            result = cell;
            cell.detailLabel.attributedText = item.attText;
            cell.detailLabel.delegate = self;
            [item.attText enumerateAttributesInRange:NSMakeRange(0, item.attText.length)
                                             options:0
                                          usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
                                              QNChatTextAttachment *attachment = attrs[NSAttachmentAttributeName];
                                              if (attachment && attachment.url != nil) {
                                                  [cell.detailLabel addLinkToURL:attachment.url withRange:range];
                                              }
                                          }];
        } break;
        case MessageTypeText: {
            // 文本
            switch (item.sender) {
                case MessageSenderLady: {
                    // 接收到的消息
                    QNChatTextLadyTableViewCell *cell = [QNChatTextLadyTableViewCell getUITableViewCell:tableView];
                    result = cell;
                    // 用于点击重发按钮
                    result.tag = indexPath.row;
                    cell.detailLabel.attributedText = item.attText;
                } break;
                case MessageSenderSelf: {
                    // 发出去的消息
                    QNChatTextSelfTableViewCell *cell = [QNChatTextSelfTableViewCell getUITableViewCell:tableView];
                    result = cell;
                    // 用于点击重发按钮
                    result.tag = indexPath.row;
                    cell.delegate = self;
                    cell.detailLabel.attributedText = item.attText;
                    switch (item.status) {
                        case MessageStatusProcessing: {
                            // 发送中
                            cell.activityIndicatorView.hidden = NO;
                            [cell.activityIndicatorView startAnimating];
                            cell.retryButton.hidden = YES;
                        } break;
                        case MessageStatusFinish: {
                            // 发送成功
                            cell.activityIndicatorView.hidden = YES;
                            cell.retryButton.hidden = YES;
                        } break;
                        case MessageStatusFail: {
                            // 发送失败
                            cell.activityIndicatorView.hidden = YES;
                            cell.retryButton.hidden = NO;
                            cell.delegate = self;
                        } break;
                        default: {
                            // 未知
                            cell.activityIndicatorView.hidden = YES;
                            cell.retryButton.hidden = YES;
                            cell.delegate = self;
                        } break;
                    }
                } break;
                default: {
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@""];
                    result = cell;
                } break;
            }
        } break;
        //语音消息
        case MessageTypeVoice: {
            switch (item.sender) {
                case MessageSenderLady: {
                    QNChatVoiceTableViewCell *cell = [QNChatVoiceTableViewCell getUITableViewCell:tableView];
                    result = cell;
                    result.tag = indexPath.row;
                    cell.delegate = self;
                    cell.voicePath = item.liveChatMsgItemObject.voiceMsg.filePath;
                    [cell setPalyButtonTime:item.liveChatMsgItemObject.voiceMsg.timeLength];
                    //获取语音下载的状态
                    cell.loading.hidden = cell.voicePath.length > 0 ? YES : NO;
                    cell.redView.hidden = item.liveChatMsgItemObject.voiceMsg.isRead;
                    [cell setPalyButtonImage:item.liveChatMsgItemObject.voiceMsg.isPalying];
                } break;
                case MessageSenderSelf: {
                    QNChatVoiceSelfTableViewCell *cell = [QNChatVoiceSelfTableViewCell getUITableViewCell:tableView];
                    result = cell;
                    result.tag = indexPath.row;
                    cell.delegate = self;
                    cell.voicePath = item.liveChatMsgItemObject.voiceMsg.filePath;
                    [cell setPalyButtonTime:item.liveChatMsgItemObject.voiceMsg.timeLength];
                    [cell setPalyButtonImage:item.liveChatMsgItemObject.voiceMsg.isPalying];
                    //获取语音发送的状态,显示语音以及加载状态
                    switch (item.status) {
                        case MessageStatusProcessing: {
                            // 发送中
                            cell.loading.hidden = NO;
                            cell.retryBtn.hidden = YES;
                        } break;
                        case MessageStatusFinish: {
                            // 发送成功
                            cell.loading.hidden = YES;
                            cell.retryBtn.hidden = YES;
                        } break;
                        case MessageStatusFail: {
                            // 发送失败
                            cell.loading.hidden = YES;
                            cell.retryBtn.hidden = NO;
                        } break;
                        default: {
                            // 未知
                            cell.loading.hidden = YES;
                            cell.retryBtn.hidden = YES;
                        } break;
                    }
                }
                default:
                    break;
            }
        } break;
        case MessageTypeCoupon: {
            // 试聊券
            QNChatCouponTableViewCell *cell = [QNChatCouponTableViewCell getUITableViewCell:tableView];
            result = cell;
        } break;
        case MessageTypeSmallEmotion: {
            // 小高级表情
            switch (item.sender) {
                case MessageSenderLady: {
                    QNChatSmallEmotionLadyTableViewCell *cell = [QNChatSmallEmotionLadyTableViewCell getUITableViewCell:tableView];
                    result = cell;
                    cell.smallEmotonImageView.image = item.emotionDefault;
                } break;
                case MessageSenderSelf: {
                    QNChatSmallEmotionSelfTableViewCell *cell = [QNChatSmallEmotionSelfTableViewCell getUITableViewCell:tableView];
                    result = cell;
                    result.tag = indexPath.row;
                    cell.smallEmotonImageView.image = item.emotionDefault;
                    switch (item.status) {
                        case MessageStatusProcessing: {
                            // 发送中
                            [cell.sendingLoadingView startAnimating];
                            cell.retryBtn.hidden = YES;
                        } break;
                        case MessageStatusFinish: {
                            // 发送成功
                            [cell.sendingLoadingView stopAnimating];
                            cell.retryBtn.hidden = YES;
                        } break;
                        case MessageStatusFail: {
                            // 发送失败
                            [cell.sendingLoadingView stopAnimating];
                            cell.retryBtn.hidden = NO;
                            cell.delegate = self;
                        } break;
                        default: {
                            // 未知
                            [cell.sendingLoadingView stopAnimating];
                            cell.retryBtn.hidden = YES;
                            cell.delegate = self;
                        } break;
                    }
                } break;
                default:
                    break;
            }
        }
        default: {
        } break;
    }

    if (!result) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@""];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        }
        result = cell;
    }
    return result;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - 滚动界面回调 (UIScrollViewDelegate)
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self closeAllInputView];
}

#pragma mark 小高表操作回调
- (void)chatSmallEmotionView:(QNChatSmallEmotionView *)emotionListView currentPageNumber:(NSInteger)page {
    NSInteger currentPage = page + 1;
    self.normalAndSmallEmotionView.pageView.currentPage = currentPage;
    //加上首次加载多出的4~5张，凑够一屏
    NSInteger maxPicNum = screenSize.width == 320 ? 8 : 10;
    NSInteger onePicNum = screenSize.width == 320 ? 4 : 5;
    NSInteger loadPage = (page * maxPicNum) + onePicNum;
    //按照分页加载表情
    for (NSInteger i = loadPage; i < self.smallEmotionListArray.count; i++) {
        QNChatSmallGradeEmotion *item = [self.smallEmotionListArray objectAtIndex:i];
        if (!item.image) {
            [self.liveChatManager getMagicIconThumbImage:item.magicIconItemObject.iconId];
        }
        if (i == self.smallEmotionListArray.count || i >= loadPage + maxPicNum) {
            break;
        }
    }
}

- (void)chatNormalSmallEmotionViewDidEndDecelerating:(QNChatNomalSmallEmotionView *)normalSmallView {
    CGPoint offsetofScrollView = normalSmallView.pageScrollView.contentOffset;
    [normalSmallView.pageScrollView setContentOffset:offsetofScrollView];

    //这里调用下载方法是为了防止首次下载时失败
    int maxLoadPic = screenSize.width == 320 ? 12 : 15;
    for (int i = 0; i < self.smallEmotionListArray.count; i++) {
        QNChatSmallGradeEmotion *item = [self.smallEmotionListArray objectAtIndex:i];
        if (!item.image) { //没有图片才下载
            [self.liveChatManager getMagicIconThumbImage:item.magicIconItemObject.iconId];
        }
        if (i >= maxLoadPic) {
            break;
        }
    }
}

#pragma mark - 语音操作回调
- (void)ChatVoiceSelfTableViewCellDidClickRetryBtn:(QNChatVoiceSelfTableViewCell *)cell {
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    [self handleErrorMsg:path.row];
}

#pragma mark - 键盘回调
- (void)moveInputBarWithKeyboardHeight:(CGFloat)height withDuration:(NSTimeInterval)duration {
    BOOL bFlag = NO;
    [self.view layoutIfNeeded];

    int h = 0;
    if (IS_IPHONE_X) {
        h = -35;
    }

    if (height != 0) {
        // 弹出键盘
        // 增加加速度

        if (self.emotionBtn.selected == YES) {
            self.inputMessageViewBottom.constant = -height + h;
        } else {
            self.inputMessageViewBottom.constant = -height;
        }
        self.tableView.decelerationRate = UIScrollViewDecelerationRateFast;
        bFlag = YES;
    } else {
        // 收起键盘

        self.inputMessageViewBottom.constant = h;
        //self.photoView.hidden = YES;
        self.chatEmotionKeyboardView.hidden = YES;
    }

    [UIView animateWithDuration:duration
        animations:^{
            [self.view layoutIfNeeded];
        }
        completion:^(BOOL finished) {
            if (bFlag) {
                [self scrollToEnd:YES];
            }
        }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    self.keyboardHeight = keyboardRect.size.height;
    // 从表情键盘切换成系统键盘,保存普通表情的富文本属性
    self.emotionAttributedString = self.textView.attributedText;
    [self moveInputBarWithKeyboardHeight:keyboardRect.size.height withDuration:animationDuration];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];

    if (self.emotionBtn.selected == NO) {
        // 没有选择表情
        [self moveInputBarWithKeyboardHeight:0.0 withDuration:animationDuration];
    }
}

#pragma mark - 输入回调

- (void)textViewDidChange:(UITextView *)textView {
    // 超过字符限制
    NSString *toBeString = textView.text;
    UITextRange *selectedRange = [textView markedTextRange];
    UITextPosition *position = [textView positionFromPosition:selectedRange.start offset:0];
    if (position) {
        if (toBeString.length > maxInputCount) {
            // 取出之前保存的属性
            textView.attributedText = self.emotionAttributedString;

        } else {
            // 记录当前的富文本属性
            self.emotionAttributedString = textView.attributedText;
        }
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    // 增加手势
    [self addSingleTap];
    // 切换所有按钮到系统键盘状态
    self.emotionBtn.selected = NO;
     
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    BOOL result = YES;

    if ([text containEmoji]) {
        // 系统表情，不允许输入
        result = NO;
    } else if ([text isEqualToString:@"\n"]) {
        // 输入回车，即按下send，不允许输入
        [self sendMsgAction:nil];
        result = NO;
    } else {
        // 判断是否超过字符限制
        NSInteger strLength = textView.text.length - range.length + text.length;
        if (strLength >= maxInputCount && text.length >= range.length) {
            // 判断是否删除字符
            if ('\000' != [text UTF8String][0] && ![text isEqualToString:@"\b"]) {
                // 非删除字符，不允许输入
                result = NO;
            }
        }
    }
    return result;
}

#pragma mark - 输入栏高度改变回调
- (void)textViewChangeHeight:(QNChatTextView *_Nonnull)textView height:(CGFloat)height {
    if (height < INPUTMESSAGEVIEW_MAX_HEIGHT) {
        self.inputMessageViewHeight.constant = height + 10;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.textView setNeedsDisplay];
    });
}

#pragma mark - LivechatManager回调
- (void)onSendTextMsg:(LSLIVECHAT_LCC_ERR_TYPE)errType errMsg:(NSString *_Nonnull)errMsg msgItem:(LSLCLiveChatMsgItemObject *_Nullable)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (msg != nil) {
            if ([msg.toId isEqualToString:self.womanId]) {
                if (msg.statusType == StatusType_Finish) {
                    NSLog(@"ChatViewController::onSendTextMsg( 发送文本消息回调, 发送成功 : %@, toId : %@ )", msg.textMsg.displayMsg, msg.toId);
                    
                    if (msg.textMsg.illegal) {
                        [self performSelector:@selector(insertWaringMessage) withObject:self afterDelay:1];
                    }
                } else {
                    NSLog(@"ChatViewController::onSendTextMsg( 发送文本消息回调, 发送失败 : %@, toId : %@, errMsg : %@ )", msg.textMsg.displayMsg, msg.toId, errMsg);
                }
                [self updataMessageData:msg scrollToEnd:NO animated:NO];
            }
        }
    });
}

- (void)onSendTextMsgsFail:(LSLIVECHAT_LCC_ERR_TYPE)errType msgs:(NSArray *_Nonnull)msgs {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (LSLCLiveChatMsgItemObject *msg in msgs) {
            // 当前聊天女士才显示
            if ([msg.toId isEqualToString:self.womanId]) {
                NSLog(@"ChatViewController::onSendTextMsgsFail( 发送消息失败回调（多条）: %@ )", msg);

                [self updataMessageData:msg scrollToEnd:NO animated:NO];
            }
        }
    });
}

- (void)onRecvTextMsg:(LSLCLiveChatMsgItemObject *_Nonnull)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 当前聊天女士才显示
        if ([msg.fromId isEqualToString:self.womanId]) {
            NSLog(@"ChatViewController::onRecvTextMsg( 接收文本消息回调 fromId : %@, message : %@ )", msg.fromId, msg.textMsg.displayMsg);
            [[QNContactManager manager] updateReadMsg:self.womanId];
            [self insertData:msg scrollToEnd:YES animated:YES];
        }
    });
}

- (void)onRecvSystemMsg:(LSLCLiveChatMsgItemObject *_Nonnull)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 当前聊天女士才显示
        if ([msg.fromId isEqualToString:self.womanId]) {
            NSLog(@"ChatViewController::onRecvSystemMsg( 接收系统消息回调 fromId : %@, message : %@ )", msg.fromId, msg.systemMsg.message);
            [self insertData:msg scrollToEnd:YES animated:YES];
        }
    });
}

- (void)onRecvWarningMsg:(LSLCLiveChatMsgItemObject *_Nonnull)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 当前聊天女士才显示
        if ([msg.fromId isEqualToString:self.womanId]) {
            NSLog(@"ChatViewController::onRecvWarningMsg( 接收警告消息 fromId : %@, message : %@ )", msg.fromId, msg.warningMsg.message);
            [self insertData:msg scrollToEnd:YES animated:YES];
        }
    });
}

- (void)onRecvEditMsg:(NSString *_Nonnull)userId {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 当前聊天女士才显示
        if ([userId isEqualToString:self.womanId]) {
            NSLog(@"ChatViewController::onRecvEditMsg( 对方编辑消息回调 )");
            [self reloadData:YES scrollToEnd:YES animated:YES];
        }
    });
}

- (void)onGetHistoryMessage:(BOOL)success errNo:(NSString *_Nonnull)errNo errMsg:(NSString *_Nonnull)errMsg userId:(NSString *_Nonnull)userId {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 当前聊天女士才显示
        if ([userId isEqualToString:self.womanId]) {
            NSLog(@"ChatViewController::onGetHistoryMessage( 获取单个用户历史聊天记录 )");
            [self reloadData:YES scrollToEnd:YES animated:YES];
        }
    });
}

- (void)onGetUsersHistoryMessage:(BOOL)success errNo:(NSString *_Nonnull)errNo errMsg:(NSString *_Nonnull)errMsg userIds:(NSArray *_Nonnull)userIds {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSString *userId in userIds) {
            // 当前聊天女士才显示
            if ([userId isEqualToString:self.womanId]) {
                NSLog(@"ChatViewController::onGetHistoryMessage( 获取多个用户历史聊天记录 )");
                [self reloadData:YES scrollToEnd:YES animated:YES];
                break;
            }
        }
    });
}

- (void)onCheckTryTicket:(BOOL)success errNo:(NSString *_Nonnull)errNo errMsg:(NSString *_Nonnull)errMsg userId:(NSString *_Nonnull)userId status:(CouponStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            // 当前聊天女士才显示
            if ([userId isEqualToString:self.womanId]) {
                if (status == CouponStatus_Yes) {
                    NSLog(@"ChatViewController::onCheckTryTicket( 检测是否可使用试聊券回调, 可用 userId : %@ )", userId);
                    // 插入试聊券消息
                    QNMessage *custom = [self insertCustomMessage];
                    custom.type = MessageTypeCoupon;

                    // 插入资费提示
                    custom = [self insertCustomMessage];
                    custom.type = MessageTypeSystemTips;
                    custom.text = NSLocalizedStringFromSelf(@"Tips_Try_Ticket_Credit_YES");
                    custom.attText = [self parseMessage:custom.text font:[UIFont systemFontOfSize:SystemMessageFontSize] color:MessageGrayColor];

                } else {
                    NSLog(@"ChatViewController::onCheckTryTicket( 检测是否可使用试聊券回调, 不可用 userId : %@ )", userId);

                    // 插入资费提示
                    QNMessage *custom = [self insertCustomMessage];
                    custom.type = MessageTypeSystemTips;
                    custom.text = NSLocalizedStringFromSelf(@"Tips_Try_Ticket_Credit_NO_Reply");
                    custom.attText = [self parseMessage:custom.text font:[UIFont systemFontOfSize:SystemMessageFontSize] color:MessageGrayColor];
                }
                // 刷新界面
                [self reloadData:YES scrollToEnd:YES animated:NO];
            }
        }
    });
}

- (void)onRecvTryTalkEnd:(LSLCLiveChatUserItemObject *_Nullable)user {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 当前聊天女士才显示
        if ([user.userId isEqualToString:self.womanId]) {
            NSLog(@"ChatViewController::onRecvTryTalkEnd( 结束试聊回调 userId : %@ )", user.userId);
        }
    });
}

#pragma mark - 小高表消息回调
- (void)onGetMagicIconConfig:(bool)success errNo:(NSString *_Nonnull)errNo errMsg:(NSString *_Nonnull)errMsg magicIconConItem:(LSLCLiveChatMagicIconConfigItemObject *_Nonnull)config {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"ChatViewController::onGetMagicIconConfig( 获取小高级表情消息回调 maxupdatetime : %ld, path : %@ )", (long)config.maxupdatetime, config.path);
    });
}

- (void)onGetMagicIconSrcImage:(bool)success magicIconItem:(LSLCLiveChatMagicIconItemObject *_Nonnull)item {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"ChatViewController::onGetMagicIconSrcImage( 获取小高级表情清晰图消息回调 magicIconId : %@, sourcePath : %@ )", item.magicIconId, item.sourcePath);
    });
}

- (void)onGetMagicIconThumbImage:(bool)success magicIconItem:(LSLCLiveChatMagicIconItemObject *_Nonnull)item {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"ChatViewController::onGetMagicIconThumbImage( 获取小高级表情缩略图消息回调 magicIconId : %@, thumbPath : %@ )", item.magicIconId, item.thumbPath);
        // 获取缩略图
        QNChatSmallGradeEmotion *emotion = [self getSmallThumbEmotionFromCache:item.magicIconId];
        emotion.liveChatMagicIconItemObject = item;

        [self.normalAndSmallEmotionView reloadData];
        [self reloadData:YES scrollToEnd:YES animated:NO];
    });
}

- (void)onSendMagicIcon:(LSLIVECHAT_LCC_ERR_TYPE)errType errMsg:(NSString *_Nonnull)errMsg msgItem:(LSLCLiveChatMsgItemObject *_Nullable)msgItem {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"ChatViewController::onSendMagicIcon( 发送小高级表情消息回调 fromId : %@, emotionId : %@ )", msgItem.fromId, msgItem.emotionMsg.emotionId);
        if ([msgItem.toId isEqualToString:self.womanId]) {
            [self updataMessageData:msgItem scrollToEnd:NO animated:NO];
        }
    });
}

- (void)onRecvMagicIcon:(LSLCLiveChatMsgItemObject*  _Nonnull)msgItem {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"ChatViewController::onRecvMagicIcon( 接收小高级表情消息回调 fromId : %@, emotionId : %@ )", msgItem.fromId, msgItem.emotionMsg.emotionId);
        if ([msgItem.fromId isEqualToString:self.womanId]) {
            [[QNContactManager manager] updateReadMsg:self.womanId];
            [self insertData:msgItem scrollToEnd:YES animated:YES];
        }
    });
}

#pragma mark - 语音消息回调
- (void)onGetVoice:(LSLIVECHAT_LCC_ERR_TYPE)errType errNo:(NSString*)errNo errMsg:(NSString*)errMsg msgItem:(LSLCLiveChatMsgItemObject*)msgItem {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"ChatViewController::onGetVoice( 获取语音消息回调回调 errType:%d, voicePath: %@)",errType,msgItem.voiceMsg.filePath);
        if ([self.womanId isEqualToString:msgItem.fromId] && errType == LSLIVECHAT_LCC_ERR_SUCCESS) {
            [self updataMessageData:msgItem scrollToEnd:NO animated:NO];
        }
    });
}

- (void)onRecvVoice:(LSLCLiveChatMsgItemObject*)msgItem
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.womanId isEqualToString:msgItem.fromId]) {
            NSLog(@"ChatViewController::onRecvVoice( 接收到语音消息 , voiceId : %@, voicePath: %@)",msgItem.voiceMsg.voiceId,msgItem.voiceMsg.filePath);
            [[QNContactManager manager] updateReadMsg:self.womanId];
            [self insertData:msgItem scrollToEnd:YES animated:YES];
            [self.liveChatManager getVoice:self.womanId msgId:(int)msgItem.msgId];
        }
    });
}

- (void)onSendVoice:(LSLIVECHAT_LCC_ERR_TYPE) errType errNo:(NSString*) errNo errMsg:(NSString*) errMsg msgItem:(LSLCLiveChatMsgItemObject*) msgItem
{
    dispatch_async(dispatch_get_main_queue(), ^{

        if( msgItem != nil ) {
            if( msgItem.statusType == StatusType_Finish ) {
                NSLog(@"ChatViewController::onSendVoice( 发送语音消息回调, 发送成功 : %@, toId : %@ )", msgItem.voiceMsg.filePath, msgItem.toId);
            } else {
                NSLog(@"ChatViewController::onSendVoice( 发送语音消息回调, 发送失败 : %@, toId : %@, errMsg : %@ )", msgItem.voiceMsg.filePath, msgItem.toId, errMsg);
            }
            [self updataMessageData:msgItem scrollToEnd:NO animated:NO];
        }
    });
}

#pragma mark - 弹窗
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex != buttonIndex) {
//        if (!AppShareDelegate().isNetwork) {
//            [self showHUDIcon:@"" message:NSLocalizedStringFromSelf(@"NoNetwork") isToast:YES];
//            return;
//        }

        if (self.isEndChat) {

            if ([self.liveChatManager isChatingUserInChatState:self.womanId]) {
                 [self.liveChatManager endTalk:self.womanId];
                 [[QNContactManager manager]removeChatLastMsg:self.womanId];
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            if ([self.liveChatManager isChatingUserInChatState:self.womanId]) {
                [[DialogTip dialogTip] showDialogTip:self.view tipText:NSLocalizedStringFromSelf(@"InChat_Tip")];

            }else
            {
                if ([self.liveChatManager isInManInviteCanCancel:self.womanId]) {
                    [self.liveChatManager endTalk:self.womanId];
                    [[QNContactManager manager]removeChatLastMsg:self.womanId];
                    [self.navigationController popViewControllerAnimated:YES];
                }
                else
                {
                    [[DialogTip dialogTip] showDialogTip:self.view tipText:NSLocalizedStringFromSelf(@"on2min")];
                }
            }
        }
    }
}


@end
