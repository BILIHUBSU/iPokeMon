//
//  UtilityBallMenuViewController.m
//  iPokeMon
//
//  Created by Kaijie Yu on 2/1/12.
//  Copyright (c) 2012 Kjuly. All rights reserved.
//

#import "AbstractCenterMenuViewController.h"

#import "KYCircleMenu.h"

@interface AbstractCenterMenuViewController () {
 @private
  NSInteger buttonCount_;
  CGRect    buttonOriginFrame_;
  BOOL      isClosed_;
}

- (void)_closeCenterMenuView:(NSNotification *)notification;
- (void)_computeAndSetButtonLayoutWithTriangleHypotenuse:(CGFloat)triangleHypotenuse;
- (void)_setButtonWithTag:(NSInteger)buttonTag origin:(CGPoint)origin;

@end


@implementation AbstractCenterMenuViewController

@synthesize centerMenu     = centerMenu_;
@synthesize isOpening      = isOpening_;
@synthesize isInProcessing = isInProcessing_;

-(void)dealloc {
  self.centerMenu = nil;
  // Remove Notification Observer
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kKYNCircleMenuClose object:nil];
  [super dealloc];
}

- (id)initWithButtonCount:(NSInteger)buttonCount {
  if (self = [self initWithNibName:nil bundle:nil]) {
    isInProcessing_ = NO;
    buttonCount_    = buttonCount; // Min: 1, Max: 6
    isOpening_      = NO;
    isClosed_       = YES;
  }
  return self;
}

- (id)init {
  self = [super init];
  return self;
}

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
  UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, kViewWidth, kViewHeight)];
  
  // Center Menu View
  CGRect centerMenuFrame = CGRectMake((kViewWidth - kCenterMenuSize) / 2, (kViewHeight - kCenterMenuSize) / 2, kCenterMenuSize, kCenterMenuSize);
  UIView * centerMenu = [[UIView alloc] initWithFrame:centerMenuFrame];
  self.centerMenu = centerMenu;
  [centerMenu release];
  [self.centerMenu setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:kPMINMainMenuBackground]]];
  [self.centerMenu setOpaque:NO];
  [self.centerMenu setAlpha:0.f];
  [view addSubview:self.centerMenu];
  
  // Add buttons to |ballMenu_|, set it's origin frame to center
  buttonOriginFrame_ = CGRectMake((kCenterMenuSize - kCenterMainButtonSize) / 2,
                                  (kCenterMenuSize - kCenterMainButtonSize) / 2,
                                  kCenterMenuButtonSize,
                                  kCenterMenuButtonSize);
  for (int i = 0; i < buttonCount_;) {
    UIButton * button = [[UIButton alloc] initWithFrame:buttonOriginFrame_];
    [button setOpaque:NO];
    [button setTag:++i];
    [button addTarget:self action:@selector(runButtonActions:) forControlEvents:UIControlEventTouchUpInside];
    [self.centerMenu addSubview:button];
    [button release];
  }
  
  self.view = view;
  [view release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Add Observer for close self
  // If |centerMainButton_| post cancel notification, do it
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_closeCenterMenuView:)
                                               name:kKYNCircleMenuClose
                                             object:nil];
}

- (void)viewDidUnload {
  [super viewDidUnload];
  self.centerMenu = nil;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  // Return YES for supported orientations
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Publich Button Action

// Run action depend on button, it'll be implemented by subclass
- (void)runButtonActions:(id)sender {}

// Push View Controller
- (void)pushViewController:(id)viewController {
  [UIView animateWithDuration:.3f
                        delay:0.f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^{
                     // Slide away buttons in center view & hide them
                     [self _computeAndSetButtonLayoutWithTriangleHypotenuse:300.f];
                     [self.centerMenu setAlpha:0.f];
                     
                     // Show Navigation Bar
                     [self.navigationController setNavigationBarHidden:NO];
                     CGRect navigationBarFrame = self.navigationController.navigationBar.frame;
                     if (navigationBarFrame.origin.y < 0) {
                       navigationBarFrame.origin.y = 0;
                       [self.navigationController.navigationBar setFrame:navigationBarFrame];
                     }
                   }
                   completion:^(BOOL finished) {
                     [self.navigationController pushViewController:viewController animated:YES];
                   }];
}

// Check device's system, it it's lower than iOS5.0, methods like |viewWillAppear:| will not be called
// So, manually send them
- (void)checkDeviceSystemFor:(id)viewController {
  if (SYSTEM_VERSION_LESS_THAN(@"5.0"))
    [viewController viewWillAppear:YES];
}

// Open center menu view
- (void)openCenterMenuView {
  if (isOpening_)
    return;
  isInProcessing_ = YES;
  // Show buttons with animation
  [UIView animateWithDuration:.3f
                        delay:0.f
                      options:(UIViewAnimationOptions)UIViewAnimationCurveEaseInOut
                   animations:^{
                     [self.centerMenu setAlpha:1.f];
                     // Compute buttons' frame and set for them, based on |buttonCount|
                     [self _computeAndSetButtonLayoutWithTriangleHypotenuse:125.f];
                   }
                   completion:^(BOOL finished) {
                     [UIView animateWithDuration:.1f
                                           delay:0.f
                                         options:(UIViewAnimationOptions)UIViewAnimationCurveEaseInOut
                                      animations:^{
                                        [self _computeAndSetButtonLayoutWithTriangleHypotenuse:112.f];
                                      }
                                      completion:^(BOOL finished) {
                                        isOpening_ = YES;
                                        isClosed_ = NO;
                                        isInProcessing_ = NO;
                                      }];
                   }];
}

// Change |centerMainButton_|'s status in main view
- (void)changeCenterMainButtonStatusToMove:(CenterMainButtonStatus)centerMainButtonStatus {
  // |centerMainButtonStatus : 1|, move |centerMainButton_| to view bottom
  NSDictionary * userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                             [NSNumber numberWithInt:centerMainButtonStatus], @"centerMainButtonStatus", nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:kPMNChangeCenterMainButtonStatus
                                                      object:self
                                                    userInfo:userInfo];
  [userInfo release];
  
  // If change |centerMainButton_|'s status to normal,
  // do |recoverButtonsLayoutInCenterView| (this method was removed)
  if (centerMainButtonStatus == kCenterMainButtonStatusNormal)
    [UIView animateWithDuration:.3f
                          delay:0.f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       // Show buttons & slide in to center
                       [self.centerMenu setAlpha:1.f];
                       [self _computeAndSetButtonLayoutWithTriangleHypotenuse:100.f];
                     }
                     completion:^(BOOL finished) {
                       [UIView animateWithDuration:.1f
                                             delay:0.f
                                           options:UIViewAnimationOptionCurveEaseInOut
                                        animations:^{
                                          [self _computeAndSetButtonLayoutWithTriangleHypotenuse:112.f];
                                        }
                                        completion:nil];
                     }];
}

#pragma mark - Private Methods

// Close center menu view
- (void)_closeCenterMenuView:(NSNotification *)notification {
  if (isClosed_)
    return;
  isInProcessing_ = YES;
  // Hide buttons with animation
  [UIView animateWithDuration:.3f
                        delay:0.f
                      options:(UIViewAnimationOptions)UIViewAnimationCurveEaseIn
                   animations:^{
                     for (UIButton * button in [self.centerMenu subviews])
                       [button setFrame:buttonOriginFrame_];
                     [self.centerMenu setAlpha:0.f];
                   }
                   completion:^(BOOL finished) {
                     if (self.navigationController)
                       [self.navigationController.view removeFromSuperview];
//                       [self.navigationController removeFromParentViewController];
                     else
                       [self.view removeFromSuperview];
//                       [self removeFromParentViewController];
                     isClosed_       = YES;
                     isOpening_      = NO;
                     isInProcessing_ = NO;
                   }];
}

// Compute buttons' layout based on |buttonCount|
- (void)_computeAndSetButtonLayoutWithTriangleHypotenuse:(CGFloat)triangleHypotenuse {
  //
  //  Triangle Values for Buttons' Position
  // 
  //      /|      a: triangleA = c * COSx 
  //   c / | b    b: triangleB = c * SINx
  //    /)x|      c: triangleHypotenuse
  //   -----      x: degree
  //     a
  //
  CGFloat centerBallMenuHalfSize = kCenterMenuSize / 2.f;
  CGFloat buttonRadius           = kCenterMenuButtonSize / 2.f;
  if (! triangleHypotenuse) triangleHypotenuse = 112.f; // Distance to Ball Center
  
  //
  //      o       o   o      o   o     o   o     o o o     o o o
  //     \|/       \|/        \|/       \|/       \|/       \|/
  //  1 --|--   2 --|--    3 --|--   4 --|--   5 --|--   6 --|--
  //     /|\       /|\        /|\       /|\       /|\       /|\
  //                           o       o   o     o   o     o o o
  //
  switch (buttonCount_) {
    case 1:
      [self _setButtonWithTag:1 origin:CGPointMake(centerBallMenuHalfSize - buttonRadius,
                                                  centerBallMenuHalfSize - triangleHypotenuse - buttonRadius)];
      break;
      
    case 2: {
      CGFloat degree    = M_PI / 4.0f; // = 45 * M_PI / 180
      CGFloat triangleB = triangleHypotenuse * sinf(degree);
      CGFloat negativeValue = centerBallMenuHalfSize - triangleB - buttonRadius;
      CGFloat positiveValue = centerBallMenuHalfSize + triangleB - buttonRadius;
      [self _setButtonWithTag:1 origin:CGPointMake(negativeValue, negativeValue)];
      [self _setButtonWithTag:2 origin:CGPointMake(positiveValue, negativeValue)];
      break;
    }
      
    case 3: {
      // = 360.0f / self.buttonCount * M_PI / 180.0f;
      // E.g: if |buttonCount_ = 6|, then |degree = 60.0f * M_PI / 180.0f|;
      // CGFloat degree = 2 * M_PI / self.buttonCount;
      //
      CGFloat degree    = M_PI / 3.0f; // = 60 * M_PI / 180
      CGFloat triangleA = triangleHypotenuse * cosf(degree);
      CGFloat triangleB = triangleHypotenuse * sinf(degree);
      [self _setButtonWithTag:1 origin:CGPointMake(centerBallMenuHalfSize - triangleB - buttonRadius,
                                                  centerBallMenuHalfSize - triangleA - buttonRadius)];
      [self _setButtonWithTag:2 origin:CGPointMake(centerBallMenuHalfSize + triangleB - buttonRadius,
                                                  centerBallMenuHalfSize - triangleA - buttonRadius)];
      [self _setButtonWithTag:3 origin:CGPointMake(centerBallMenuHalfSize - buttonRadius,
                                                  centerBallMenuHalfSize + triangleHypotenuse - buttonRadius)];
      break;
    }
      
    case 4: {
      CGFloat degree    = M_PI / 4.0f; // = 45 * M_PI / 180
      CGFloat triangleB = triangleHypotenuse * sinf(degree);
      CGFloat negativeValue = centerBallMenuHalfSize - triangleB - buttonRadius;
      CGFloat positiveValue = centerBallMenuHalfSize + triangleB - buttonRadius;
      [self _setButtonWithTag:1 origin:CGPointMake(negativeValue, negativeValue)];
      [self _setButtonWithTag:2 origin:CGPointMake(positiveValue, negativeValue)];
      [self _setButtonWithTag:3 origin:CGPointMake(negativeValue, positiveValue)];
      [self _setButtonWithTag:4 origin:CGPointMake(positiveValue, positiveValue)];
      break;
    }
      
    case 5: {
      CGFloat degree    = M_PI / 2.5f; // = 72 * M_PI / 180
      CGFloat triangleA = triangleHypotenuse * cosf(degree);
      CGFloat triangleB = triangleHypotenuse * sinf(degree);
      [self _setButtonWithTag:1 origin:CGPointMake(centerBallMenuHalfSize - triangleB - buttonRadius,
                                                  centerBallMenuHalfSize - triangleA - buttonRadius)];
      [self _setButtonWithTag:2 origin:CGPointMake(centerBallMenuHalfSize - buttonRadius,
                                                  centerBallMenuHalfSize - triangleHypotenuse - buttonRadius)];
      [self _setButtonWithTag:3 origin:CGPointMake(centerBallMenuHalfSize + triangleB - buttonRadius,
                                                  centerBallMenuHalfSize - triangleA - buttonRadius)];
      
      degree    = M_PI / 5.0f;  // = 36 * M_PI / 180
      triangleA = triangleHypotenuse * cosf(degree);
      triangleB = triangleHypotenuse * sinf(degree);
      [self _setButtonWithTag:4 origin:CGPointMake(centerBallMenuHalfSize - triangleB - buttonRadius,
                                                  centerBallMenuHalfSize + triangleA - buttonRadius)];
      [self _setButtonWithTag:5 origin:CGPointMake(centerBallMenuHalfSize + triangleB - buttonRadius,
                                                  centerBallMenuHalfSize + triangleA - buttonRadius)];
      break;
    }
      
    case 6: {
      CGFloat degree    = M_PI / 3.0f; // = 60 * M_PI / 180
      CGFloat triangleA = triangleHypotenuse * cosf(degree);
      CGFloat triangleB = triangleHypotenuse * sinf(degree);
      [self _setButtonWithTag:1 origin:CGPointMake(centerBallMenuHalfSize - triangleB - buttonRadius,
                                                  centerBallMenuHalfSize - triangleA - buttonRadius)];
      [self _setButtonWithTag:2 origin:CGPointMake(centerBallMenuHalfSize - buttonRadius,
                                                  centerBallMenuHalfSize - triangleHypotenuse - buttonRadius)];
      [self _setButtonWithTag:3 origin:CGPointMake(centerBallMenuHalfSize + triangleB - buttonRadius,
                                                  centerBallMenuHalfSize - triangleA - buttonRadius)];
      [self _setButtonWithTag:4 origin:CGPointMake(centerBallMenuHalfSize - triangleB - buttonRadius,
                                                  centerBallMenuHalfSize + triangleA - buttonRadius)];
      [self _setButtonWithTag:5 origin:CGPointMake(centerBallMenuHalfSize - buttonRadius,
                                                  centerBallMenuHalfSize + triangleHypotenuse - buttonRadius)];
      [self _setButtonWithTag:6 origin:CGPointMake(centerBallMenuHalfSize + triangleB - buttonRadius,
                                                  centerBallMenuHalfSize + triangleA - buttonRadius)];
      break;
    }
      
    default:
      break;
  }
}

// Set Frame for button with special tag
- (void)_setButtonWithTag:(NSInteger)buttonTag origin:(CGPoint)origin {
  UIButton * button = (UIButton *)[self.centerMenu viewWithTag:buttonTag];
  [button setFrame:CGRectMake(origin.x, origin.y, kCenterMenuButtonSize, kCenterMenuButtonSize)];
  button = nil;
}

@end
