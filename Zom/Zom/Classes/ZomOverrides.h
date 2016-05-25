//
//  ZomOverrides.h
//  Zom
//
//  Created by N-Pex on 2016-05-17.
//
//

@import ChatSecureCore;

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
