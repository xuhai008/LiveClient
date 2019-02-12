//
//  LSNavWebViewController.m
//  livestream
//
//  Created by test on 2018/6/11.
//  Copyright © 2018年 net.qdating. All rights reserved.
//

#import "LSNavWebViewController.h"
#import "LiveModule.h"
#define NavNormalHeight 64
#define NavIphoneXHeight 88

@interface LSNavWebViewController ()<UIScrollViewDelegate>


/** 顶部标题 */
@property (nonatomic, strong) UILabel *navTitleLabel;

@property (nonatomic, assign) BOOL didFinshNav;
@property (nonatomic, assign) BOOL hasDisappear;
@end

@implementation LSNavWebViewController

- (void)dealloc {
    NSLog(@"LSNavWebViewController::dealloc()");
    // 在9.0上需清空代理,会导致crash
    self.webView.scrollView.delegate = nil;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:NSStringFromClass([self.superclass class]) bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.isShowTaBar = YES;
    self.isFirstProgram = YES;
    
    self.webView.scrollView.delegate = self;
    self.navTitleLabel = [[UILabel alloc] init];

    
    if (self.alphaType) {
          if (IS_IPHONE_X) {
              self.webViewTopDistance.constant = -NavIphoneXHeight;
          }else {
              self.webViewTopDistance.constant = -NavNormalHeight;
          }
        self.navTitleLabel.alpha = 0;
    }else {
        self.webViewTopDistance.constant = 0;
        self.navTitleLabel.alpha = 1;
    }
    self.requestUrl = self.url;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 跟踪显示屏幕
    //[[LiveModule module].analyticsManager reportShowWebScreen:self];
    [self hideNavgationBarBottomLine:YES];
    
    if (@available(iOS 11, *)) {
        // translucent为yes防止在ios11系统上,透明会失效
        self.navigationController.navigationBar.translucent = YES;
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.navigationController.navigationBar.translucent = NO;
    }
}

- (void)setupRequestWebview {
    [super setupRequestWebview];
}

- (void)setupIsResume:(BOOL)isResume {
    [super setupIsResume:self.isResume];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.hidden = NO;
        self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navTitleLabel.text = self.navTitle;
    CGRect frame = self.navTitleLabel.frame;
    frame.size = CGSizeMake(100, 44);
    self.navTitleLabel.frame = frame;
    self.navTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.navTitleLabel.font = [UIFont systemFontOfSize:19];
    self.navigationItem.titleView = self.navTitleLabel;
    
    // 每次进来判断是否需要显示导航栏的透明的状态,防止跳转下一页返回透明状态不准确的问题
    if (self.alphaType) {
        [self setupAlphaStatus:self.webView.scrollView];
    }else {
        [self setNeedsNavigationBackground:1];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.translucent = NO;
        [self hideNavgationBarBottomLine:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.alphaType) {
        [self setupAlphaStatus:scrollView];
    }
}

// 设置透明状态
- (void)setupAlphaStatus:(UIScrollView *)scrollView {
    CGFloat navHeight = NavNormalHeight;
    
    if (IS_IPHONE_X) {
        navHeight = NavIphoneXHeight;
    }
    
    CGFloat per = scrollView.contentOffset.y /navHeight;
    if (scrollView.contentOffset.y >= navHeight) {
        [self setNeedsNavigationBackground:1];
    }else {
        [self setNeedsNavigationBackground:per];
    }
}

- (void)setNeedsNavigationBackground:(CGFloat)alpha {
    // 导航栏背景透明度设置
    
    NSArray * views = [self.navigationController.navigationBar subviews];
    UIView *barBackgroundView = [views objectAtIndex:0];
    UIImageView *backgroundImageView = [[barBackgroundView subviews] objectAtIndex:0];
    BOOL result = self.navigationController.navigationBar.isTranslucent;
    NSLog(@"navigationBar.isTranslucent %@  barBackgroundView %@",BOOL2SUCCESS(result),[barBackgroundView subviews]);
    if (result) {
        if (backgroundImageView != nil && backgroundImageView.image != nil) {
            barBackgroundView.alpha = alpha;
        } else {
            NSArray * subViews = [barBackgroundView subviews];
            if (subViews.count > 1) {
                UIView *backgroundEffectView = [subViews objectAtIndex:1];
                if (backgroundEffectView != nil) {
                    backgroundEffectView.alpha = alpha;
                }
            }else {
               barBackgroundView.alpha = alpha;
            }
        }
    } else {
        barBackgroundView.alpha = alpha;
    }
    self.navTitleLabel.alpha = alpha;
}

@end