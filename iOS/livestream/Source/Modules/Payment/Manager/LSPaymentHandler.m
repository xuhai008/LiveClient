//
//  PaymentHandler.m
//  demo
//
//  Created by  Samson on 6/22/16.
//  Copyright © 2016 Samson. All rights reserved.
//  支付处理器(包括AppStore支付处理和接口请求验证订单处理)

#import "LSPaymentHandler.h"
#import "LSDomainSessionRequestManager.h"
#import "LSAppStorePayHandler.h"
#import "LSIOSPayCallRequest.h"

@interface LSPaymentHandler () <LSAppStorePayHandlerDeleagte>
// 回调
@property (nonatomic, weak) id<LSPaymentHandlerDelegate> delegate;
// 订单号
@property (nonatomic, strong) NSString* orderNo;
// 产品ID
@property (nonatomic, strong) NSString* productId;
// 男士ID
@property (nonatomic, strong) NSString* manId;
// sid
@property (nonatomic, strong) NSString* sid;
// AppStore支付凭证
@property (nonatomic, strong) NSString* receipt;
// AppStore支付状态
@property (nonatomic, assign) SKPaymentTransactionState transState;
// 支付状态
@property (nonatomic, assign) PaymentHandleState state;
// 是否正在处理中
@property (nonatomic, assign) BOOL isHandling;
// 请求管理器
@property (nonatomic, strong) LSDomainSessionRequestManager* sessionRequestMgr;
// AppStore支付处理器
@property (nonatomic, strong) LSAppStorePayHandler* appStorePayHandler;

// 不判断是否正在处理的start
- (BOOL)startWithoutHandling;
// 向AppStore支付
- (BOOL)payWithStore;
// 验证支付信息
- (BOOL)checkPayment;
@end

@implementation LSPaymentHandler
/**
 *  初始化
 *
 *  @param orderNo   订单号
 *  @param productId 产品ID
 *  @param manId     男士ID
 *  @param delegate  回调
 *
 *  @return this
 */
- (id _Nullable)initWithOrderNo:(NSString* _Nonnull)orderNo productId:(NSString* _Nonnull)productId manId:(NSString* _Nonnull)manId delegate:(id<LSPaymentHandlerDelegate> _Nonnull)delegate
{
    self = [super init];
    if (nil != self) {
        self.delegate = delegate;
        self.orderNo = orderNo;
        self.productId = productId;
        self.manId = manId;
        self.sid = nil;
        self.receipt = @"";
        self.transState = SKPaymentTransactionStateFailed;
        self.state = PaymentHandleStatePayWithStore;
        self.isHandling = NO;
        self.sessionRequestMgr = [LSDomainSessionRequestManager manager];
    }
    return self;
}

- (id _Nullable)initWithOrderNo:(NSString* _Nonnull)orderNo productId:(NSString* _Nonnull)productId manId:(NSString* _Nonnull)manId receipt:(NSString* _Nonnull)receipt transState:(SKPaymentTransactionState)transState delegate:(id<LSPaymentHandlerDelegate> _Nonnull)delegate
{
    self = [super init];
    if (nil != self) {
        self.delegate = delegate;
        self.orderNo = orderNo;
        self.productId = productId;
        self.manId = manId;
        self.sid = nil;
        self.receipt = receipt;
        self.transState = transState;
        self.state = PaymentHandleStatePayWithStore;
        self.isHandling = NO;
        self.sessionRequestMgr = [LSDomainSessionRequestManager manager];
    }
    return self;
}

/**
 *  开始支付(或重试)
 *
 *  @return 是否成功
 */
- (BOOL)start:(NSString* _Nonnull)sid
{
    if (nil != sid && [sid length] > 0) {
        // 赋值sid
        self.sid = sid;
        // 开始处理支付
        if (!self.isHandling) {
            [self startWithoutHandling];
        }
    }
    return self.isHandling;
}

/**
 *  不判断是否正在处理中的start
 *
 *  @return 是否成功
 */
- (BOOL)startWithoutHandling
{
    // 不是正在处理状态
    switch (self.state) {
        case PaymentHandleStatePayWithStore:
            self.isHandling = [self payWithStore];
            break;
        case PaymentHandleStateCheckPayment:
            self.isHandling = [self checkPayment];
            break;
        case PaymentHandleStateFinish:
            break;
    }
    return self.isHandling;
}

/**
 *  向AppStore支付
 *
 *  @return 处理结果
 */
- (BOOL)payWithStore
{
    self.appStorePayHandler = [[LSAppStorePayHandler alloc] initWithProductId:self.productId orderNo:self.orderNo manId:self.manId delegate:self];
    [self.appStorePayHandler pay];
    return YES;
}

/**
 *  验证支付信息
 *
 *  @return 处理结果
 */
- (BOOL)checkPayment
{
    LSIOSPayCallRequest * request = [[LSIOSPayCallRequest alloc] init];
    request.manid = self.manId;
    request.sid = self.sid;
    request.orderNo = self.orderNo;
    request.receipt = self.receipt;
    request.code = (AppStorePayCodeType)self.transState;
    request.finishHandler = ^(BOOL success, NSString* _Nonnull code) {
        if (nil != self.delegate) {
            if (success) {
                self.state = PaymentHandleStateFinish;
            }
            self.isHandling = NO;
            BOOL isNetErr = ([code length] == 0);
            [self.delegate updatePaymentState:self state:self.state success:success code:code isNetErr:isNetErr];
        }
    };
    
    return [self.sessionRequestMgr sendRequest:request];
}

#pragma mark - AppStorePayHandlerDeleagte回调
/**
 *  支付完成回调
 *
 *  @param handler 支付处理器
 *  @param result  是否支付成功
 *  @param
 */
- (void)getProductFinish:(LSAppStorePayHandler* _Nonnull)handler result:(BOOL)result
{
    if (!result) {
        // 获取Product失败
        self.isHandling = NO;
        
        if (nil != self.delegate) {
            [self.delegate updatePaymentState:self state:self.state success:result code:@"" isNetErr:NO];
        }
    }
}

#pragma mark - 更新支付信息
/**
 *  更新AppStore支付信息
 */
- (void)updatedTransactions:(SKPaymentTransaction* _Nonnull)transaction sid:(NSString* _Nonnull)sid
{
    // 更新sid
    self.sid = sid;
    // 更新支付状态
    self.transState = transaction.transactionState;
    
    // 判断是否需要处理
    BOOL isToHandle = YES;
    switch (self.transState) {
        case SKPaymentTransactionStatePurchased:    // 购买成功
        case SKPaymentTransactionStateFailed:       // 购买失败
        case SKPaymentTransactionStateRestored:     // 恢复交易(仅Non-Consumable可重复使用商品(非消费)，及Auto-Renewable自动续费商品才有)
        case SKPaymentTransactionStateDeferred:     // 未确定(用户没绑信用卡，无法立即支付)
            break;
        case SKPaymentTransactionStatePurchasing:   // 正在购买
            isToHandle = NO;
            break;
    }
    
    // 处理
    if (isToHandle) {
        // 若支付成功，则获取凭证
        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
            self.receipt = [LSAppStorePayHandler getReceipt];
        }
        
        // 回调
        if (nil != self.delegate) {
            [self.delegate updatePaymentState:self state:PaymentHandleStatePayWithStore success:YES code:@"" isNetErr:NO];
        }
        
        // 设置支付完成(iOS不再回调本支付信息)
        [LSAppStorePayHandler finish:transaction];
        
        // 状态设为验证支付信息，继续处理
        self.state = PaymentHandleStateCheckPayment;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startWithoutHandling];
        });
    }
}

/**
 *  设置为"正在验证订单"状态
 */
- (void)setCheckPaymentStatus
{
    self.state = PaymentHandleStateCheckPayment;
}

#pragma mark - PaymentItem相关
/**
 *  获取订单信息
 */
- (LSPaymentItem*)getPaymentItem
{
    LSPaymentItem *item = [[LSPaymentItem alloc] init:self.manId orderNo:self.orderNo productId:self.productId transState:self.transState receipt:self.receipt];
    return item;
}
@end
