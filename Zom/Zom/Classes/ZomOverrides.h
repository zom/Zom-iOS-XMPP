//
//  ZomOverrides.h
//  Zom
//
//  Created by N-Pex on 2016-05-17.
//
//

@import ChatSecureCore;

extern NSString *const kOTRXLFormShowAdvancedTag;

@interface OTRAppDelegate (ZomOverride)
@property (nonatomic, strong) OTRSplitViewCoordinator *splitViewCoordinator;
@property (nonatomic, strong) OTRSplitViewControllerDelegateObject *splitViewControllerDelegate;
@end

@interface OTRMessagesViewController (ZomOverride)
- (void)refreshTitleView;
@end

@interface OTRInviteViewController (ZomOverride)
- (void)skipPressed:(id)sender;
- (void)qrButtonPressed:(id)sender;
- (void)linkShareButtonPressed:(id)sender;
@end

@interface OTRConversationViewController (ZomOverride)
- (void)settingsButtonPressed:(id)sender;
- (void)composeButtonPressed:(id)sender;
@end

@interface OTRBaseLoginViewController (ZomOverride)
- (void)loginButtonPressed:(id)sender;
@end