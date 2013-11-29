//
//  LFExamsChartView.h
//  MyLibretto
//
//  Created by Leonardo on 05/11/13.
//  Copyright (c) 2013 LeonardFactory. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

int signf(float n);
float scaledOffset(float offset);

@class LFLineChartView;

// -----------------------------------------------------------------
// LFLineChartView DataSource
// -----------------------------------------------------------------
@protocol LFLineChartViewDataSource <NSObject>

- (NSUInteger) numberOfItemsInLineChartView:(LFLineChartView *)lineChartView;
- (CAShapeLayer *) lineChartView:(LFLineChartView *)lineChartView createLayerAtIndex:(NSUInteger) index;
- (CAShapeLayer *) lineChartView:(LFLineChartView *)lineChartView createLineLayerBetweenIndex:(NSUInteger) firstIndex andIndex:(NSUInteger) secondIndex;

- (CGFloat) yAtIndex:(NSUInteger) index;

@optional
// Size
- (CGFloat) sizeAtIndex:(NSUInteger) index;

// Text
- (NSString *) textAtIndex:(NSUInteger) index;
- (UIColor *) textColorAtIndex:(NSUInteger) index;

- (NSString *) scoreTextAtIndex:(NSUInteger) index;

// Lines
- (NSUInteger) numberOfMiddleLinesInLineChartView:(LFLineChartView *)lineChartView;
- (CAShapeLayer *) lineChartView:(LFLineChartView *)lineChartView createMiddleLineLayerAtIndex:(NSUInteger)index;
- (CGFloat) yForMiddleLineAtIndex:(NSUInteger) index;

// Empty view
- (UIView *) emptyViewForLineChartView:(LFLineChartView *)lineChartView;

@end

// -----------------------------------------------------------------
// LFLineChartView Delegate
// -----------------------------------------------------------------
@protocol LFLineChartViewDelegate <NSObject>

@optional
- (void) lineChartView:(LFLineChartView *)lineChartView didPressLayerAtIndex:(NSUInteger) index;

@end

// -----------------------------------------------------------------
// LFLineChartView
// -----------------------------------------------------------------
@interface LFLineChartView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (assign) CGFloat bounceTolerance;
@property (assign) CGFloat horizontalPadding;
@property (assign) CGFloat verticalPadding;
@property (assign) CGFloat itemSpacing;
@property (assign) CGFloat initialScale;

@property (assign) CGFloat minimumItemRadius;
@property (assign) CGFloat maximumItemRadius;

@property (assign) CGFloat minimumTextHeight;
@property (assign) CGFloat textHeight;
@property (assign) CGFloat textWidth;

@property (weak, nonatomic) id<LFLineChartViewDelegate> chartDelegate;
@property (weak, nonatomic) id<LFLineChartViewDataSource> datasource;

- (void) reloadData;

@end
