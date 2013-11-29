//
//  LFLineChartView.m
//  LFLineChartView
//
//  Created by Leonardo on 05/11/13.
//  Copyright (c) 2013 LeonardFactory. All rights reserved.
//

#import "LFLineChartView.h"

int signf(float n)
{
    return n < 0 ? -1 : 1;
}

float scaledOffset(float offset)
{
    return - signf(offset) * powf(offset/120.0, 4.0);
}

// -----------------------------------------------------------------
// LFExamsChartView private interface
// -----------------------------------------------------------------
@interface LFLineChartView ()
{
    // Max & Min y-axis values
    float minY;
    float maxY;
    
    // Max & Min 'weight' for items
    float minSize;
    float maxSize;
    
    // Spacing between items
    float baseGraphSpacing; // Does not count for scaling
    float graphSpacing;
    
    // Internal CALayer used for drawing
    CALayer *contentLayer;
    
    // UIView used to keep track of empty view
    UIView *emptyView;
    
    // Pinch Recognizer
    UIPinchGestureRecognizer *customPinchRecognizer;
    float baseScale;
    BOOL isPinchBouncing;
    
    // Temp
    UIBezierPath *tempPath;
    int tempLayerIndexPressed;
    
    // Items
    NSMutableArray *items;
    NSMutableArray *texts;
    
    // Connecting lines
    NSMutableArray *lines;
    
    NSMutableArray *middleLines;
}

@end

// -----------------------------------------------------------------
// LFExamsChartView implementation
// -----------------------------------------------------------------
@implementation LFLineChartView

#pragma mark - Initialization
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _horizontalPadding  = 100.0;
        _verticalPadding    = 80.0;
        _itemSpacing        = 140.0;
        _initialScale       = 1.4;
        graphSpacing        = _itemSpacing;
        _bounceTolerance    = 20.0;
        
        _minimumItemRadius  = 14.0;
        _maximumItemRadius  = 14.0;
        
        _minimumTextHeight  = 12.0;
        _textHeight         = 18.0;
        _textWidth          = 120.0;
        
        items = [NSMutableArray array];
        lines = [NSMutableArray array];
        texts = [NSMutableArray array];
        middleLines = [NSMutableArray array];
        
        // Temp
        tempPath = nil;
        tempLayerIndexPressed = -1;
        
        // Gesture recognizer
        customPinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDetected:)];
        customPinchRecognizer.delegate = self;
        [self addGestureRecognizer:customPinchRecognizer];
        
        [self.pinchGestureRecognizer requireGestureRecognizerToFail:customPinchRecognizer];
        isPinchBouncing = NO;
        
        // ScrollView
        self.showsVerticalScrollIndicator   = NO;
        self.alwaysBounceHorizontal         = YES;
        self.delegate   = self;
        self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height); // Zero items, so no need to calculate real contentSize.
        contentLayer = [CALayer layer];
        [self.layer addSublayer:contentLayer];
        
        // Emtpy view
        emptyView = nil;
    }
    return self;
}

- (void) reloadData
{
    // Reset
    minY    = INFINITY;
    maxY    = 0;
    minSize = INFINITY;
    maxSize = 0;
    
    [items removeAllObjects];
    [lines removeAllObjects];
    [texts removeAllObjects];
    [middleLines removeAllObjects];
    
    NSUInteger count = [self.datasource numberOfItemsInLineChartView:self];
    
    // Reload middleLines from datasource
    if([self.datasource respondsToSelector:@selector(numberOfMiddleLinesInLineChartView:)])
    {
        NSUInteger middleCount = [self.datasource numberOfMiddleLinesInLineChartView:self];
        
        for(int j=0; j<middleCount; j++)
        {
            [middleLines addObject:[self.datasource lineChartView:self createMiddleLineLayerAtIndex:j]];
        }
    }
    
    // Reload from datasource
    for(int i=0; i<count; i++)
    {
        float y       = [self.datasource yAtIndex:i];
        minY          = MIN(minY, y);
        maxY          = MAX(maxY, y);
        
        // Count size if the protocol method is provided
        if([self.datasource respondsToSelector:@selector(sizeAtIndex:)])
        {
            float size  = [self.datasource sizeAtIndex:i];
            minSize     = MIN(minSize, size);
            maxSize     = MAX(maxSize, size);
        }
        
        // Add CAShapeLayer
        [items addObject:[self.datasource lineChartView:self createLayerAtIndex:i]];
        
        // Add line
        if(i < count -1)
        {
            [lines addObject:[self.datasource lineChartView:self createLineLayerBetweenIndex:i andIndex:i+1]];
        }
    }
    
    // Use Pinch gesture recognizer only for items > 1
    if([items count] <= 1)
    {
        [self removeGestureRecognizer:customPinchRecognizer];
    }
    
    // Draw anything except for EmptyView
    [self prepareForDrawing];
    [self reposition];
    
    // -----------------------------------------------------------------
    // Centering empty view and showing it in case it's needed.
    // Else, remove it.
    // -----------------------------------------------------------------
    if([self.datasource respondsToSelector:@selector(emptyViewForLineChartView:)])
    {
        if([items count] == 0)
        {
            emptyView = [self.datasource emptyViewForLineChartView:self];
            
            // Center the view
            emptyView.frame = CGRectMake(self.contentSize.width/2.0 - emptyView.frame.size.width/2.0,
                                         self.contentSize.height/2.0 - emptyView.frame.size.height/2.0,
                                         emptyView.frame.size.width,
                                         emptyView.frame.size.height);
            
            [self addSubview:emptyView];
        }
        else
        {
            if(emptyView != nil)
            {
                [emptyView removeFromSuperview];
                emptyView = nil;
            }
        }
    }
    
    [self setNeedsDisplay];
}

// -----------------------------------------------------------------
// Text handling & creation
// -----------------------------------------------------------------
- (CATextLayer *) textLayerAtIndex:(NSUInteger) index
{
    if(index > 0 && index < [texts count])
    {
        return (CATextLayer *)[texts objectAtIndex:index];
    }
    else
    {
        CATextLayer *layer  = [CATextLayer layer];
        layer.zPosition     = 0.0;
        layer.contentsScale = [[UIScreen mainScreen] scale];
        [texts insertObject:layer atIndex:index];
        return layer;
    }
}

- (NSDictionary *) textAttributes
{
    return [self textAttributesWithFontSize:_textHeight];
}

- (NSDictionary *) textAttributesWithFontSize:(CGFloat) fontSize
{
    CTFontRef textFont = CTFontCreateWithName(CFSTR("Helvetica"), fontSize, NULL);
    
    CTTextAlignment alignment       = kCTCenterTextAlignment;
    CTLineBreakMode lineBreakMode   = kCTLineBreakByWordWrapping;
    
    CTParagraphStyleSetting settings[] = {
        {kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment},
        {kCTParagraphStyleSpecifierLineBreakMode, sizeof(lineBreakMode), &lineBreakMode}
    };
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(settings[0]));
    
    UIColor *textColor = [UIColor whiteColor]; // Default
    if([self.datasource respondsToSelector:@selector(textColor)])
    {
        textColor = [self.datasource textColor];
    }
    
    NSDictionary *textAttributes = @{(NSString *)kCTFontAttributeName: (__bridge id) textFont,
                                     (NSString *)kCTForegroundColorAttributeName: (__bridge id)textColor.CGColor,
                                     (NSString *)kCTParagraphStyleAttributeName: (__bridge  id)paragraphStyle};
    CFRelease(textFont);
    CFRelease(paragraphStyle);
    
    return textAttributes;
}

- (NSDictionary *) textAttributesToFit:(NSString *) string inSize:(CGSize) frameSize
{
    CGFloat fontSize = _textHeight + 1.0;
    NSDictionary *attributes;
    NSAttributedString *attrString;
    BOOL fit = false;
    while(!fit)
    {
        fontSize -= 1.0;
        
        attributes      = [self textAttributesWithFontSize:fontSize];
        attrString      = [[NSAttributedString alloc] initWithString:string attributes:attributes];
        
        CTLineRef line  = CTLineCreateWithAttributedString((CFAttributedStringRef) attrString);
        CGFloat ascent;
        CGFloat descent;
        CGFloat width   = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        
        fit = (width <= frameSize.width) || fontSize <= _minimumTextHeight;
        
        //CGPathRelease(path);
        //CGPathRelease(framePath);
        CFRelease(line);
        //CFRelease(frameSetter);
    }
    
    return attributes;
}

- (CGSize) sizeWithAttributedString:(NSAttributedString *) attrString toFitWidth:(CGFloat) width
{
    CTFramesetterRef frameSetter    = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) attrString);
    CGSize size                     = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), NULL, CGSizeMake(width, 10000), NULL);
    return size;
}

// Places text under the Score Dot (upper in CGC coordinates) if the graph is going up,
// places it over the Score Dot if the graph is going down
- (CGPoint) textPositionAtIndex:(NSUInteger) index forPosition:(CGPoint) position andSize:(CGSize) size
{
    float prev = (index > 0)                    ? [self normalizedYAtIndex:index - 1] : 0.0;
    float next = (index < [items count] - 1)    ? [self normalizedYAtIndex:index + 1] : 0.0;
    float curr = [self normalizedYAtIndex:index];
    
    float delta = (curr-prev) + (curr-next);
    
    // Add radius variable distance
    float circleSpacing = [self radiusAtIndex:index] + 4.0;
    
    float y = (delta < 0) ? position.y - circleSpacing - size.height : position.y + circleSpacing;
    return CGPointMake(position.x, y);
}

// -----------------------------------------------------------------
// Prepare to draw, adding sublayers and setting default properties
// -----------------------------------------------------------------
- (void) prepareForDrawing
{
    NSUInteger count = [items count];
    
    // Calculate graphSpacing.
    // +Inf for only one element, doesn't matter because if there is only one element graphSpacing is not used.
    baseGraphSpacing    = [self baseGraphSpacingForCurrentNumberOfItems];
    graphSpacing        = baseGraphSpacing * _initialScale; // Scaled at start by initialScale
    
    // Calculate width
    self.contentSize = CGSizeMake([self widthForCurrentNumberOfItems], self.frame.size.height);
    
    // Reset contentLayer
    [contentLayer removeFromSuperlayer];
    contentLayer = [CALayer layer];
    contentLayer.frame = CGRectMake(0.0, 0.0, self.contentSize.width, self.contentSize.height);
    [self.layer addSublayer:contentLayer];
    
    // Dispose lines and insert sublayers
    NSUInteger middleCount = [middleLines count];
    for(int j=0; j<middleCount; j++)
    {
        CAShapeLayer *middleLineLayer = (CAShapeLayer *)[middleLines objectAtIndex:j];
        [contentLayer addSublayer:middleLineLayer];
    }
    
    // Dispose elements and insert sublayers
    for(int i=0; i<count; i++)
    {
        CGPoint position = [self pointAtIndex:i];
        
        CAShapeLayer *layer     = (CAShapeLayer *)[items objectAtIndex:i];
        
        CGFloat radius          = [self radiusAtIndex:i];
        UIBezierPath *finalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-radius, -radius, 2*radius, 2*radius)];
        layer.path              = finalPath.CGPath;
        
        layer.position          = position;
        [contentLayer addSublayer:layer];
        
        // Draw text if provided
        if([self.datasource respondsToSelector:@selector(textAtIndex:)])
        {
            NSString *textString                = [self.datasource textAtIndex:i];
            NSDictionary *textStringAttributes  = [self textAttributesToFit:textString inSize:CGSizeMake(_textWidth, _textHeight)];
            NSAttributedString *attrString      = [[NSAttributedString alloc] initWithString:textString attributes:textStringAttributes];
            
            CGSize frameSize                    = [self sizeWithAttributedString:attrString toFitWidth:_textWidth];
            
            // TextLayer
            CATextLayer *textLayer          = [self textLayerAtIndex:i];
            textLayer.string                = attrString;
            textLayer.position              = [self textPositionAtIndex:i forPosition:position andSize:frameSize];
            textLayer.alignmentMode         = kCAAlignmentCenter;
            textLayer.truncationMode        = kCATruncationNone;
            textLayer.wrapped               = YES;
            textLayer.anchorPoint           = CGPointMake(0.5, 0.0);
            textLayer.frame                 = CGRectMake(frameSize.height/2.0, 0.0, frameSize.width, frameSize.height);
            
            [contentLayer addSublayer:textLayer];
        }
        
        if(i < count-1)
        {
            // Next item position
            CGPoint nextPosition = [self pointAtIndex:i+1];
            
            // Line path
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathMoveToPoint(path, NULL, position.x, position.y);
            CGPathAddLineToPoint(path, NULL, nextPosition.x, nextPosition.y);
            
            // Line layer
            CAShapeLayer *lineLayer = (CAShapeLayer *)[lines objectAtIndex:i];
            lineLayer.path  = path;
            CGPathRelease(path);
            
            [contentLayer insertSublayer:lineLayer below:layer];
        }
    }
}

// -----------------------------------------------------------------
// Zoom
// -----------------------------------------------------------------
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void) pinchDetected:(UIPinchGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        baseScale = 1.0;
    }
    
    // Slow down if graphSpacing is beyond _bounceTolerance @todo remove magic numbers
    float scaleMultiplier = (graphSpacing < baseGraphSpacing || graphSpacing > 400.0) ? 1.0 : 1.0;
    
    float scale = (1.0 - (baseScale - sender.scale*scaleMultiplier));
    baseScale = sender.scale;
    
    // Scale inside bounds
    float newGraphSpacing = MIN(MAX(graphSpacing * scale, baseGraphSpacing - _bounceTolerance), 400.0 + _bounceTolerance);
    float realScale = newGraphSpacing/graphSpacing;
    
    // If we released, check if `graphSpacing` is beyond `bounceTolerance` and animate consequently
    if(sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled)
    {
        if(newGraphSpacing < baseGraphSpacing || newGraphSpacing > 400.0)
        {
            float finalGraphSpacing = (newGraphSpacing < baseGraphSpacing) ? baseGraphSpacing : 400.0;
            
            NSTimeInterval timeInterval = 0.3;
            isPinchBouncing = YES;
            
            // Change contentSize to hold final animation result, and store old offsetX to avoid overrides
            CGFloat oldOffsetX  = self.contentOffset.x;
            CGFloat oldWidth    = self.contentSize.width;
            self.contentSize    = CGSizeMake([self widthForCurrentNumberOfItemsWithGraphSpacing:finalGraphSpacing], self.frame.size.height);
            contentLayer.frame  = CGRectMake(0.0, 0.0, self.contentSize.width, self.contentSize.height);
            
            // Move the actual layers to start position
            [self repositionWithAnimationTime:0.0 andExtraPadding:(self.contentSize.width - oldWidth)/2.0 completion:^(void)
             {
                 //CGPoint position = [[items objectAtIndex:0] position];
                 
                 // Now we can change global graphSpacing to final desired
                 graphSpacing = finalGraphSpacing;
                 
                 // Change contentOffset to fake same disposition as before
                 CGFloat fakeOffsetX = oldOffsetX + (self.contentSize.width - oldWidth)/2.0;
                 [self setContentOffset:CGPointMake([self offsetXInViewBounds:fakeOffsetX], self.contentOffset.y) animated:NO];
                 
                 //CGFloat distanceCenterToBounds = [sender locationInView:self].x - self.contentOffset.x;
                 CGFloat offsetX     = self.contentOffset.x * realScale;
                 
                 [self repositionWithAnimationTime:timeInterval andExtraPadding:0.0 completion:nil];
                 [UIView animateWithDuration:timeInterval
                                  animations:^(void)
                  {
                      [self setContentOffset:CGPointMake([self offsetXInViewBounds:offsetX], self.contentOffset.y) animated:NO];
                  }
                                  completion:^(BOOL finished)
                  {
                      isPinchBouncing = NO;
                  }];
             }];
        }
    }
    else
    {
        [self updateGraphSpacingTo:newGraphSpacing
                   keepingCenterTo:[sender locationInView:self]
                         withScale:realScale]; // Not using directly scale because effective scale is calculated with MIN & MAX bounds for graphSpacing
        [self reposition];
    }
}

// -----------------------------------------------------------------
// Graph spacing and width
// -----------------------------------------------------------------
- (CGFloat) widthForCurrentNumberOfItems
{
    //return MAX(self.frame.size.width, 2*_horizontalPadding + ([items count] - 1)*graphSpacing);
    if([items count] <= 1) // It is very important to count even 0 items, else app will hang out indefinitely
    {
        return self.frame.size.width;
    }
    return [self widthForCurrentNumberOfItemsWithGraphSpacing:graphSpacing];
}

// Note: Not defined for items count = 0
- (CGFloat) widthForCurrentNumberOfItemsWithGraphSpacing:(CGFloat) myGraphSpacing
{
    return 2*_horizontalPadding + ([items count] - 1) *myGraphSpacing;
}

// Note: Not defined for items count = 0
- (CGFloat) baseGraphSpacingForCurrentNumberOfItems
{
    return MAX(_itemSpacing, (self.frame.size.width - 2*_horizontalPadding)/(float)([items count] - 1));
}

/**
 * When zooming, we update graphSpacing to increase space between dots.
 */
- (void) updateGraphSpacingTo:(CGFloat) newGraphSpacing keepingCenterTo:(CGPoint) centerPoint withScale:(CGFloat) scale
{
    graphSpacing = newGraphSpacing;
    
    // centerPoint, as pinchCenter, are relative to contentSize not frame. (> 568 is ok!)
    CGFloat distanceCenterToBounds = centerPoint.x - self.contentOffset.x;
    CGFloat offsetX     = (self.contentOffset.x + distanceCenterToBounds) * scale - distanceCenterToBounds;
    
    self.contentSize    = CGSizeMake([self widthForCurrentNumberOfItems], self.frame.size.height);
    contentLayer.frame  = CGRectMake(0.0, 0.0, self.contentSize.width, self.contentSize.height);
    
    offsetX             = [self offsetXInViewBounds:offsetX];
    self.contentOffset  = CGPointMake(offsetX, self.contentOffset.y);
}

- (CGFloat) offsetXInViewBounds:(CGFloat) offsetX
{
    return MIN(MAX(offsetX, 0.0), self.contentSize.width - self.frame.size.width);
}

// -----------------------------------------------------------------
// Touches for items
// -----------------------------------------------------------------
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch  = [[touches allObjects] objectAtIndex:0];
    CGPoint point   = [touch locationInView:self];
    
    for(CAShapeLayer *layer in items)
    {
        CGFloat tolerance = 40.0;
        CGPoint position  = layer.position;
        if(CGRectContainsPoint(CGRectMake(position.x-tolerance, position.y-tolerance, tolerance*2, tolerance*2), point))
        {
            [self.chartDelegate lineChartView:self didPressLayerAtIndex:[items indexOfObject:layer]];
        }
    }
}

// -----------------------------------------------------------------
// UIScrollView delegate
// -----------------------------------------------------------------
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(!isPinchBouncing && [items count] > 1)
    {
        [self reposition];
    }
}

- (void) repositionWithAnimationTime:(NSTimeInterval) timeInterval andExtraPadding:(CGFloat) extraPadding completion:(void(^)())completion
{
    CGFloat offset = self.contentOffset.x;
    CGFloat center = offset + self.frame.size.width/2.0 - _horizontalPadding;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    // Completion block
    if(completion)
    {
        [CATransaction setCompletionBlock:completion];
    }
    
    // -----------------------------------------------------------------
    // Middle Lines
    // -----------------------------------------------------------------
    if([self.datasource respondsToSelector:@selector(numberOfMiddleLinesInLineChartView:)])
    {
        NSUInteger middleCount = [self.datasource numberOfMiddleLinesInLineChartView:self];
        for(int j=0; j<middleCount; j++)
        {
            CGFloat y = [self normalizedYForMiddleLineAtIndex:j];
            CGPoint startPosition   = CGPointMake(-self.frame.size.width, y);
            CGPoint endPosition     = CGPointMake(self.contentSize.width + self.frame.size.width, y);
            
            CAShapeLayer *middleLineLayer = (CAShapeLayer *)[middleLines objectAtIndex:j];
            
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathMoveToPoint(path, NULL, 0.0, 0.0);
            CGPathAddLineToPoint(path, NULL, endPosition.x-startPosition.x, endPosition.y-startPosition.y);
            
            if(timeInterval > 0)
            {
                CABasicAnimation *animatePosition = [CABasicAnimation animationWithKeyPath:@"position"];
                animatePosition.fromValue   = [NSValue valueWithCGPoint:middleLineLayer.position];
                animatePosition.toValue     = [NSValue valueWithCGPoint:startPosition];
                animatePosition.duration    = timeInterval;
                [middleLineLayer addAnimation:animatePosition forKey:@"position"];
                
                UIBezierPath *bezierPath        = [UIBezierPath bezierPathWithCGPath:path];
                
                CABasicAnimation *animateLine   = [CABasicAnimation animationWithKeyPath:@"path"];
                animateLine.fromValue   = [UIBezierPath bezierPathWithCGPath:middleLineLayer.path];
                animateLine.toValue     = bezierPath;
                animateLine.duration    = timeInterval;
                [middleLineLayer addAnimation:animateLine forKey:@"path"];
            }
            
            middleLineLayer.position = startPosition;
            middleLineLayer.path     = path;
            
            CGPathRelease(path);
        }
    }
    
    // -----------------------------------------------------------------
    // Items & connecting lines
    // -----------------------------------------------------------------
    NSUInteger count = [self.datasource numberOfItemsInLineChartView:self];
    for(int i=0; i<count; i++)
    {
        float baseX             = [self unpaddedXAtIndex:i];
        float baseCenterOffset  = center - baseX;
        
        CAShapeLayer *layer = (CAShapeLayer *)[items objectAtIndex:i];
        CGPoint position = CGPointMake(_horizontalPadding + extraPadding + baseX + scaledOffset(baseCenterOffset), layer.position.y);
        CGPoint oldPosition = layer.position; // Needed for lineLayer
        
        // Animate layer position
        if(timeInterval > 0)
        {
            CABasicAnimation *animateItem = [CABasicAnimation animationWithKeyPath:@"position"];
            animateItem.fromValue   = [NSValue valueWithCGPoint:layer.position];
            animateItem.toValue     = [NSValue valueWithCGPoint:position];
            animateItem.duration    = timeInterval;
            [layer addAnimation:animateItem forKey:@"position"];
        }
    
        layer.position          = position;
        
        if([self.datasource respondsToSelector:@selector(textAtIndex:)])
        {
            // Text position
            CATextLayer *textLayer  = [texts objectAtIndex:i];
            CGPoint textPosition    = [self textPositionAtIndex:i forPosition:position andSize:textLayer.frame.size];
            
            // Animate text layer position
            if(timeInterval > 0)
            {
                CABasicAnimation *animateText = [CABasicAnimation animationWithKeyPath:@"position"];
                animateText.fromValue   = [NSValue valueWithCGPoint:textLayer.position];
                animateText.toValue     = [NSValue valueWithCGPoint:textPosition];
                animateText.duration    = timeInterval;
                [textLayer addAnimation:animateText forKey:@"position"];
            }
            
            textLayer.position = textPosition;
        }
        
        if(i < count - 1)
        {
            float nextBaseX             = [self unpaddedXAtIndex:i+1];
            float nextBaseCenterOffset  = center - nextBaseX;
            
            CAShapeLayer *lineLayer = (CAShapeLayer *)[lines objectAtIndex:i];
            CGPoint nextPosition = CGPointMake(_horizontalPadding + extraPadding + nextBaseX + scaledOffset(nextBaseCenterOffset), [self normalizedYAtIndex:i+1]);
            
            // Line position
            lineLayer.position = position;
            
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathMoveToPoint(path, NULL, 0.0, 0.0);
            CGPathAddLineToPoint(path, NULL, nextPosition.x-position.x, nextPosition.y-position.y);
            
            // Animate lineLayer position / path
            if(timeInterval > 0)
            {
                CABasicAnimation *animatePosition = [CABasicAnimation animationWithKeyPath:@"position"];
                animatePosition.fromValue   = [NSValue valueWithCGPoint:oldPosition];
                animatePosition.toValue     = [NSValue valueWithCGPoint:position];
                animatePosition.duration    = timeInterval;
                [lineLayer addAnimation:animatePosition forKey:@"position"];
                
                UIBezierPath *bezierPath        = [UIBezierPath bezierPathWithCGPath:path];
                
                CABasicAnimation *animateLine   = [CABasicAnimation animationWithKeyPath:@"path"];
                animateLine.fromValue   = [UIBezierPath bezierPathWithCGPath:lineLayer.path];
                animateLine.toValue     = bezierPath;
                animateLine.duration    = timeInterval;
                [lineLayer addAnimation:animateLine forKey:@"path"];
            }
            
            // Line path
            lineLayer.path  = path;
            CGPathRelease(path);
        }
    }
    
    [CATransaction commit];
}

- (void) reposition
{
    [self repositionWithAnimationTime:0.0 andExtraPadding:0.0 completion:nil];
}

// -----------------------------------------------------------------
// Position calculations
// -----------------------------------------------------------------
- (CGFloat) normalizedY:(CGFloat) y
{
    float height        = self.frame.size.height;
    float paddedHeight  = height - 2*_verticalPadding;
    float normalY = (maxY > minY)   ? (y - minY)/(maxY - minY) * paddedHeight
                                    : paddedHeight/2.0;  // Center
    
    return height - (normalY + _verticalPadding); // invert coordinates
}

- (CGFloat) normalizedYAtIndex:(NSUInteger) index
{
    return [self normalizedY:[self.datasource yAtIndex:index]];
}

- (CGFloat) normalizedYForMiddleLineAtIndex:(NSUInteger) index
{
    return [self normalizedY:[self.datasource yForMiddleLineAtIndex:index]];
}

- (CGFloat) unpaddedXAtIndex:(NSUInteger) index
{
    return ([items count] == 1) ? (self.frame.size.width/2.0 - _horizontalPadding) : index*graphSpacing;
}

- (CGFloat) xAtIndex:(NSUInteger) index
{
    return _horizontalPadding + [self unpaddedXAtIndex:index];
}

- (CGPoint) pointAtIndex:(NSUInteger) index
{
    return CGPointMake([self xAtIndex:index], [self normalizedYAtIndex:index]);
}

// -----------------------------------------------------------------
// Weight calculations
// -----------------------------------------------------------------
- (CGFloat) radiusAtIndex:(NSUInteger) index
{
    // If datasource implements sizeAtIndex, we can use dynamic radius. Else stick with standard size.
    if([self.datasource respondsToSelector:@selector(sizeAtIndex:)])
    {
        NSAssert(_minimumItemRadius < _maximumItemRadius, @"maximumItemRadius must be greater than minimumItemRadius. Have you setted them?");
        
        // In case there is only one type of weight, return medium size.
        if(maxSize == minSize)
        {
            return _maximumItemRadius;
        }
        else
        {
            return (([self.datasource sizeAtIndex:index] - minSize)/(maxSize - minSize) * (_maximumItemRadius - _minimumItemRadius)) + _minimumItemRadius;
        }
    }
    else
    {
        NSAssert(_maximumItemRadius > 0, @"maximumItemRadius must be greater than 0");
        return _maximumItemRadius;
    }
}
@end
