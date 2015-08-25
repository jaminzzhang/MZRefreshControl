//
//  MZRefreshControl.m
//  MZ
//
//  Created by Jamin on 8/6/14.
//  Copyright (c) 2014 MZ. All rights reserved.
//

#import "MZRefreshControl.h"






#pragma mark -
#pragma mark - WQScrollViewProxy
//用于scrollView的delete方法的多播。
@interface WQScrollViewProxy : NSProxy

@property (nonatomic, weak) id  target;
@property (nonatomic, weak) id originalTarget;

- (instancetype)initWithTarget:(id)target withOriginalTarget:(id)originalTarget;

@end



@implementation WQScrollViewProxy


- (instancetype)init
{
    if (self) {
        _target = nil;
        _originalTarget = nil;
    }
    
    return self;
}


- (instancetype)initWithTarget:(id)target withOriginalTarget:(id)originalTarget
{
    if (self) {
        _target = target;
        _originalTarget = originalTarget;
    }
    
    return self;
}



- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([self.originalTarget respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.originalTarget];
    }
    
    if ([self.target respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.target];
    }
}




- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    if (nil != self.originalTarget) {
        return [self.originalTarget methodSignatureForSelector:sel];
    }
    
    return [self.target methodSignatureForSelector:sel];
}



- (BOOL)respondsToSelector:(SEL)aSelector {
    
    if (self.target == nil) {
        return NO;
    }
    
    if ([self.target respondsToSelector:aSelector] || [self.originalTarget respondsToSelector:aSelector]) {
        return YES;
    }
    
    return NO;
}

@end




#pragma mark - 
#pragma mark - WQRreshControl


static CGFloat const kWQRefreshHeight = 50;


@interface MZRefreshControl() <UIScrollViewDelegate>


@property (nonatomic, strong) WQScrollViewProxy * scrollViewProxy;
@property (nonatomic, strong) UIActivityIndicatorView * loadingView;
//@property (nonatomic, strong) UIImageView * loadingLogoView;
//@property (nonatomic, strong) UIImageView * waterView;
//@property (nonatomic, assign) CGRect logoOriginalFrame;

@property (nonatomic, weak) UIScrollView * scrollView;
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) UIEdgeInsets originalInsets;


@end



@implementation MZRefreshControl

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        _timeout = 30;
        _isRefreshing = NO;
        _originalInsets = UIEdgeInsetsZero;
        
        self.clipsToBounds = YES;
//        UIImage * logoImage = [UIImage imageNamed:@"pull_refresh_logo"];
//        CGFloat logoHeight = logoImage.size.height;
//        self.logoOriginalFrame = CGRectMake(0, frame.size.height - logoHeight/2 - 24, frame.size.width, logoHeight);
//        self.loadingLogoView = [[UIImageView alloc] initWithFrame:self.logoOriginalFrame];
//        self.loadingLogoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
//        self.loadingLogoView.contentMode = UIViewContentModeCenter;
//        self.loadingLogoView.image = logoImage;
//        [self addSubview:self.loadingLogoView];

        
        self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.loadingView.frame = CGRectMake((self.bounds.size.width - 24)/2, 12, 24, 24);
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
//        self.loadingView.center = self.imageView.center;
        [self addSubview:self.loadingView];

        
        
        CGFloat originY = self.loadingView.frame.origin.y + self.loadingView.frame.size.height;//self.imageView.frame.origin.y + self.imageView.frame.size.height;
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, originY, frame.size.width, 20)];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        self.titleLabel.textColor = [UIColor darkGrayColor];
        self.titleLabel.text = NSLocalizedString(@"下拉刷新", nil);
        [self addSubview:self.titleLabel];

    }
    
    return self;
}


- (instancetype)init

{
    CGFloat height = kWQRefreshHeight + 10;
    self = [self initWithFrame:CGRectMake(0, -height, [UIScreen mainScreen].bounds.size.width, height)];
    if (self) {
        
    }
    
    return self;
}



#pragma mark - Override


- (void)didMoveToSuperview
{
    UIScrollView * scrollView = (UIScrollView *)self.superview;
    if (![scrollView isKindOfClass:[UIScrollView class]]) {
        return;
    }
    
    self.frame = CGRectMake(0, -self.bounds.size.height, self.bounds.size.width, self.bounds.size.height);
    
    //绑定scrollView，用于多播发给scrollView的delegate的消息（SEL）
    if (nil == self.scrollViewProxy) {
        self.scrollViewProxy = [[WQScrollViewProxy alloc] init];
    }
    
    if (self.scrollView == scrollView) {
        //重设下，用于多次绑定更新
        if (scrollView.delegate != self.scrollViewProxy) {
            self.scrollViewProxy.originalTarget = scrollView.delegate;
            self.scrollView.delegate = (id<UIScrollViewDelegate>)self.scrollViewProxy;
        }
        return;
    }
    
    
    self.scrollView = scrollView;
    self.originalInsets = scrollView.contentInset;
    self.scrollViewProxy.target = self;
    self.scrollViewProxy.originalTarget = scrollView.delegate;
    scrollView.delegate = (id<UIScrollViewDelegate>)self.scrollViewProxy;
    
    [self.superview sendSubviewToBack:self];
}


#pragma mark - Public
- (void)beginRefreshing
{
    if (self.isRefreshing) {
        return;
    }
    
    self.isRefreshing = YES;
    
    BOOL isShowed = self.scrollView.showsVerticalScrollIndicator;
    self.scrollView.showsVerticalScrollIndicator = NO;
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         UIEdgeInsets insets = self.originalInsets;
                         insets.top += kWQRefreshHeight;
                         self.scrollView.contentInset = insets;
                         
                         if (self.scrollView.contentOffset.y != -insets.top) {
                             [self.scrollView setContentOffset:CGPointMake(0, -insets.top)];
                         }
//                         self.loadingLogoView.frame = self.logoOriginalFrame;
                     }
                     completion:^(BOOL finished) {
                         [self sendActionsForControlEvents:UIControlEventValueChanged];
                         self.scrollView.showsVerticalScrollIndicator = isShowed;
                         self.titleLabel.text = NSLocalizedString(@"加载中", nil);
                         
                         [self startAnimating];
                     }];
    
    [self performSelector:@selector(endRefreshing) withObject:nil afterDelay:self.timeout];
    
}



- (void)endRefreshing
{
    if (!self.isRefreshing) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(endRefreshing) object:nil];
    self.isRefreshing = NO;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = self.originalInsets;
//                         self.loadingLogoView.frame = self.logoOriginalFrame;
                     }
                     completion:^(BOOL finished) {
 //                                  self.titleLabel.text = NSLocalizedString(@"加载完成", nil);
                         [self stopAnimating];
                     }];
}

#pragma mark - Private
- (CGFloat)criticalPullOffset
{
    return -(self.originalInsets.top + kWQRefreshHeight);
}


- (void)startAnimating
{

    [self.loadingView startAnimating];
//    self.loadingLogoView.frame = self.logoOriginalFrame;
//    [UIView animateWithDuration:0.5
//                          delay:0
//                        options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
//                     animations:^{
//                         CGRect logoFrame = self.logoOriginalFrame;
//                         logoFrame.origin.y += 6;
//                         self.loadingLogoView.frame = logoFrame;
//                     }
//                     completion:^(BOOL finished) {
//                         self.loadingLogoView.frame = self.logoOriginalFrame;
//                     }];
}


- (void)stopAnimating
{
//    [self.loadingLogoView.layer removeAllAnimations];
    [self.loadingView stopAnimating];
}



#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (UIEdgeInsetsEqualToEdgeInsets(self.originalInsets, UIEdgeInsetsZero) && !self.isRefreshing) {
        self.originalInsets = scrollView.contentInset;
    }

}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.isDragging) {
        if (UIEdgeInsetsEqualToEdgeInsets(self.originalInsets, scrollView.contentInset)) {
            scrollView.contentInset = self.originalInsets;
        }
        
        if (!self.isRefreshing) {
            if (scrollView.contentOffset.y < self.criticalPullOffset) {
                self.titleLabel.text = NSLocalizedString(@"释放刷新", nil);
//                CGRect logoFrame = self.logoOriginalFrame;
//                logoFrame.origin.y += scrollView.contentOffset.y - self.criticalPullOffset;
//                if (logoFrame.origin.y  > self.frame.size.height - logoFrame.size.height) {
//                    self.loadingLogoView.frame = logoFrame;
//                }

                
            } else {
                self.titleLabel.text = NSLocalizedString(@"下拉刷新", nil);
            }
            
        }
    }
    
    

}



- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView.contentOffset.y <= -(self.originalInsets.top + kWQRefreshHeight) && !self.isRefreshing) {
        [self beginRefreshing];
    }
}

- (void)sendValueChangedEvent
{
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}



@end
