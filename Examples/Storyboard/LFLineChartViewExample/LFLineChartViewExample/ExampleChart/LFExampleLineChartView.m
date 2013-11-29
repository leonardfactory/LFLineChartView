//
//  LFExampleLineChartView.m
//  LFLineChartView
//
//  Created by Leonardo on 05/11/13.
//  Copyright (c) 2013 LeonardFactory. All rights reserved.
//

#import "LFExampleLineChartView.h"

@interface LFExampleLineChartView ()
{
    NSInteger firstDifferentLineColorIndex;
}

@end

@implementation LFExampleLineChartView

- (id)initWithFrame:(CGRect)frame andItems:(NSArray *) items
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.datasource      = self;
        self.chartDelegate   = self;
        
        self.minimumItemRadius = 5.0;
        self.maximumItemRadius = 10.0;
        
        self.itemSpacing       = 100.0;
        self.initialScale      = 1.0;
        
        firstDifferentLineColorIndex = -1;
        
        self.backgroundColor = [UIColor colorWithRed:172/255.0f green:203/255.0f blue:251/255.0f alpha:1.0f];
        
        _items = [items copy];
        [self reloadData];
    }
    return self;
}

#pragma mark LineChartView data source
- (NSUInteger) numberOfItemsInLineChartView:(LFLineChartView *)lineChartView
{
    return [_items count];
}

- (CAShapeLayer *) lineChartView:(LFLineChartView *)lineChartView createLayerAtIndex:(NSUInteger)index
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.fillColor     = [UIColor whiteColor].CGColor;
    return layer;
}

- (CAShapeLayer *) lineChartView:(LFLineChartView *)lineChartView createLineLayerBetweenIndex:(NSUInteger)firstIndex andIndex:(NSUInteger)secondIndex
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    
    // Important!
    // Whatever path or shape you are using, it _MUST_ contain exactly two points, in order to animate it correctly.
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0.0, 0.0);
    CGPathAddLineToPoint(path, NULL, 1.0, 1.0);
    layer.path          = path;
    CGPathRelease(path);
    
    layer.lineWidth     = 3.0;
    layer.strokeColor   = [UIColor colorWithRed:92/255.0f green:96/255.0f blue:219/255.0f alpha:1.0f].CGColor;
    
    // Make it dashed if it's over our defined value. You apply do any customization here.
    if(secondIndex >= firstDifferentLineColorIndex)
    {
        layer.lineDashPattern   = @[@0, @(3.0*2)];
        layer.lineDashPhase     = 3.0;
        layer.lineCap           = kCALineCapRound;
    }
    
    return layer;
}

- (CGFloat) yAtIndex:(NSUInteger)index
{
    return [[_items objectAtIndex:index] floatValue];
}

// -----------------------------------------------------------------
// Size
// -----------------------------------------------------------------
- (CGFloat) sizeAtIndex:(NSUInteger)index
{
    return [[_items objectAtIndex:index] floatValue]*2.0;
}

// -----------------------------------------------------------------
// Text
// -----------------------------------------------------------------
- (NSString *) textAtIndex:(NSUInteger)index
{
    return [NSString stringWithFormat:@"%0.1f", [[_items objectAtIndex:index] floatValue]];
}

- (UIColor *) textColor
{
    return [UIColor whiteColor];
}

// -----------------------------------------------------------------
// Middle lines (average)
// -----------------------------------------------------------------
- (NSUInteger) numberOfMiddleLinesInLineChartView:(LFLineChartView *)lineChartView
{
    return 1;
}

- (CAShapeLayer *) lineChartView:(LFLineChartView *)lineChartView createMiddleLineLayerAtIndex:(NSUInteger)index
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    
    // Initialize to path with two points to make it animatable
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0.0, 0.0);
    CGPathAddLineToPoint(path, NULL, 1.0, 1.0);
    layer.path          = path;
    CGPathRelease(path);
    
    layer.lineWidth         = 3.0;
    layer.strokeColor       = [UIColor grayColor].CGColor;
    layer.lineDashPattern   = @[@0, @(3.0*2)];
    layer.lineDashPhase     = 3.0;
    layer.lineCap           = kCALineCapRound;
    
    return layer;
}

- (CGFloat) yForMiddleLineAtIndex:(NSUInteger) index
{
    return 12.0;
}

- (UIView *) emptyViewForLineChartView:(LFLineChartView *)lineChartView
{
    UIView *emptyView = [[UIView alloc] initWithFrame:self.frame];
    return emptyView;
}

@end
