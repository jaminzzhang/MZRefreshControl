//
//  MZRefreshControl.h
//  MZ
//
//  Created by Jamin on 8/6/14.
//  Copyright (c) 2014 MZ. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface MZRefreshControl : UIControl

@property (nonatomic, strong) UIImageView * imageView;
@property (nonatomic, strong) UILabel * titleLabel;


//超时后自动endRefreshing，默认为30s
@property (nonatomic, assign) NSTimeInterval timeout;



// May be used to indicate to the refreshControl that an external event has initiated the refresh action
- (void)beginRefreshing;



// Must be explicitly called when the refreshing has completed
- (void)endRefreshing;



@end

