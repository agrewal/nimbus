//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "RootViewController.h"

static const CGFloat kFramePadding = 10;
static const CGFloat kTextBottomMargin = 10;
static const CGFloat kImageDimensions = 93;
static const CGFloat kImageSpacing = 10;


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation RootViewController


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NINetworkImageView *)networkImageView {
  UIImage* initialImage = [UIImage imageWithContentsOfFile:
                           NIPathForBundleResource(nil, @"nimbus64x64.png")];

  NINetworkImageView* networkImageView = [[[NINetworkImageView alloc] initWithImage:initialImage]
                                          autorelease];
  networkImageView.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
  networkImageView.layer.borderColor = [[UIColor colorWithWhite:1 alpha:0.2] CGColor];
  networkImageView.layer.borderWidth = 1;
  networkImageView.delegate = self;

  return networkImageView;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutImageViewsForOrientation:(UIInterfaceOrientation)orientation {
  CGRect frame = _scrollView.bounds;

  CGFloat maxRightEdge = 0;
  CGFloat currentX = kFramePadding;
  CGFloat currentY = kFramePadding;
  for (NINetworkImageView* imageView in _networkImageViews) {
    imageView.frame = CGRectMake(currentX, currentY, kImageDimensions, kImageDimensions);

    maxRightEdge = MAX(maxRightEdge, currentX + kImageDimensions);

    currentX += kImageDimensions + kImageSpacing;

    if (currentX + kImageDimensions >= frame.size.width - kFramePadding) {
      currentX = kFramePadding;
      currentY += kImageDimensions + kImageSpacing;
    }
  }

  if (currentX == kFramePadding) {
    currentY -= kImageDimensions + kImageSpacing;
  }

  CGFloat contentWidth = (maxRightEdge + kFramePadding);
  CGFloat contentPadding = floorf((frame.size.width - contentWidth) / 2);

  for (NINetworkImageView* imageView in _networkImageViews) {
    CGRect imageFrame = imageView.frame;
    imageFrame.origin.x += contentPadding;
    imageView.frame = imageFrame;
  }

  _scrollView.contentSize = CGSizeMake(self.view.frame.size.width,
                                       currentY + kImageDimensions+ kFramePadding);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadView {
  [super loadView];

  self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];

  // Try experimenting with the maximum number of concurrent operations. By making it one,
  // we force the network operations to happen serially. This can be useful for avoiding
  // thrashing of the disk and network.
  // Watch how the app works with a max of 1 versus not defining a max at all and allowing the
  // device to spin off as many threads as it wants to.
  //
  // Spoiler alert! When the max is 1, the first image loads and then all of the others load
  //                instantly.
  //                When the max is unset, all of the images take a bit longer to load.

  [[Nimbus globalNetworkOperationQueue] setMaxConcurrentOperationCount:1];


  // Try experimenting with this value to see how the total number of pixels is affected.

  //[[Nimbus globalImageMemoryCache] setMaxNumberOfPixels:94*94];


  _memoryUsageLabel = [[UILabel alloc] init];
  _memoryUsageLabel.backgroundColor = self.view.backgroundColor;
  _memoryUsageLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1];
  _memoryUsageLabel.shadowColor = [UIColor colorWithWhite:1 alpha:1];
  _memoryUsageLabel.shadowOffset = CGSizeMake(0, 1);
  _memoryUsageLabel.font = [UIFont boldSystemFontOfSize:14];
  _memoryUsageLabel.text = @"Fetching the images...";
  [_memoryUsageLabel sizeToFit];
  _memoryUsageLabel.frame = CGRectMake(kFramePadding, kFramePadding,
                                       _memoryUsageLabel.frame.size.width,
                                       _memoryUsageLabel.frame.size.height);

  [self.view addSubview:_memoryUsageLabel];

  _networkImageViews = [[NSMutableArray alloc] init];

  _scrollView = [[[UIScrollView alloc] initWithFrame:
                  NIRectShift(self.view.bounds,
                              0, CGRectGetMaxY(_memoryUsageLabel.frame) + kTextBottomMargin)]
                 autorelease];
  _scrollView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
  _scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
  _scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                  | UIViewAutoresizingFlexibleHeight);

  for (NSInteger ix = UIViewContentModeScaleToFill; ix <= UIViewContentModeBottomRight; ++ix) {
    if (UIViewContentModeRedraw == ix) {
      // Unsupported mode.
      continue;
    }
    NINetworkImageView* networkImageView = [self networkImageView];

    networkImageView.contentMode = ix;

    // From: http://www.flickr.com/photos/thonk25/3929945380/
    [networkImageView setPathToNetworkImage:
     @"http://farm3.static.flickr.com/2484/3929945380_deef6f4962_z.jpg"
                             forDisplaySize: CGSizeMake(kImageDimensions, kImageDimensions)];

    [_scrollView addSubview:networkImageView];
    [_networkImageViews addObject:networkImageView];
  }

  [self.view addSubview:_scrollView];

  [self layoutImageViewsForOrientation:NIInterfaceOrientation()];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidUnload {
  NI_RELEASE_SAFELY(_networkImageViews);
  _scrollView = nil;

  [super viewDidUnload];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [_scrollView flashScrollIndicators];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return NIIsSupportedOrientation(toInterfaceOrientation);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
                                         duration: (NSTimeInterval)duration {
  [super willAnimateRotationToInterfaceOrientation: toInterfaceOrientation
                                          duration: duration];
  [self layoutImageViewsForOrientation:toInterfaceOrientation];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

  [_scrollView flashScrollIndicators];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NINetworkImageViewDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)networkImageView:(NINetworkImageView *)imageView didLoadImage:(UIImage *)image {
  _memoryUsageLabel.text = [NSString stringWithFormat:@"In-memory cache size: %d pixels",
                            [[Nimbus globalImageMemoryCache] numberOfPixels]];
  [_memoryUsageLabel sizeToFit];
  _memoryUsageLabel.frame = CGRectMake(kFramePadding, kFramePadding,
                                       _memoryUsageLabel.frame.size.width,
                                       _memoryUsageLabel.frame.size.height);
}


@end