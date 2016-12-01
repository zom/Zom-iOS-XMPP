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

@interface OTRComposeViewController (ZomOverride)
- (BOOL)canAddBuddies;
@end

@interface OTRAttachmentPicker (ZomOverride)
- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType;
@end

@interface OTRMessagesViewController (ZomOverride)
- (void)refreshTitleView;
@end

@interface OTRMessagesHoldTalkViewController (ZomOverride)
- (void)setupDefaultSendButton;
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
+ (instancetype)loginViewControllerForAccount:(OTRAccount *)account;
- (IBAction)loginButtonPressed:(id)sender;
- (void)pushInviteViewController;
-(void)configureCell:(XLFormBaseCell*) cell;
@end

@interface OTRSettingsViewController (ZomOverride)
- (void)logoutAccount:(OTRAccount *)account sender:(id)sender;
@end

@interface OTRBuddy (ZomOverride)
- (void)setDisplayName:(NSString *)displayName;
@end
