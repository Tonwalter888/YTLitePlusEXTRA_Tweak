#import <PSHeader/Misc.h>
#import <YouTubeHeader/YTSettingsGroupData.h>
#import <YouTubeHeader/YTSettingsSectionItem.h>
#import <YouTubeHeader/YTSettingsSectionItemManager.h>
#import <YouTubeHeader/YTSettingsViewController.h>

#define Prefix @"YTWKS"

#define _LOC(b, x) [b localizedStringForKey:x value:nil table:nil]
#define LOC(x) _LOC(tweakBundle, x)

static const NSInteger YTWKSSection = 'ytwk';  // Use integer between YTUHD and YouPiP

@interface YTSettingsSectionItemManager (YTweaks)
- (void)updateYTWKSSectionWithEntry:(id)entry;
@end

NSUserDefaults *defaults;

NSBundle *YTWKSBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"YTWKS" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:tweakBundlePath ?: PS_ROOT_PATH_NS(@"/Library/Application Support/" Prefix ".bundle")];
    });
    return bundle;
}

%hook YTSettingsGroupData

- (NSArray <NSNumber *> *)orderedCategories {
    if (self.type != 1 || class_getClassMethod(objc_getClass("YTSettingsGroupData"), @selector(tweaks)))
        return %orig;
    NSMutableArray *mutableCategories = %orig.mutableCopy;
    // Check if YTWKSSection already exists to avoid duplicates
    NSNumber *sectionNumber = @(YTWKSSection);
    if (![mutableCategories containsObject:sectionNumber]) {
        [mutableCategories insertObject:sectionNumber atIndex:0];
    }
    return mutableCategories.copy;
}

%end

%hook YTAppSettingsPresentationData

+ (NSArray <NSNumber *> *)settingsCategoryOrder {
    NSArray <NSNumber *> *order = %orig;
    NSUInteger insertIndex = [order indexOfObject:@(1)];  // Find "Tweaks" section (1)
    if (insertIndex != NSNotFound) {
        NSMutableArray <NSNumber *> *mutableOrder = [order mutableCopy];
        // Check if YTWKSSection already exists to avoid duplicates
        NSNumber *sectionNumber = @(YTWKSSection);
        if (![mutableOrder containsObject:sectionNumber]) {
            // Find YTUHD section ('ythd') and YouPiP section (200) to insert between them
            NSInteger ytuhdSection = 'ythd';
            NSInteger youpipSection = 200;
            NSUInteger ytuhdIndex = [mutableOrder indexOfObject:@(ytuhdSection)];
            NSUInteger youpipIndex = [mutableOrder indexOfObject:@(youpipSection)];
            
            if (ytuhdIndex != NSNotFound && youpipIndex != NSNotFound && ytuhdIndex < youpipIndex) {
                // Insert after YTUHD, before YouPiP
                [mutableOrder insertObject:sectionNumber atIndex:ytuhdIndex + 1];
            } else if (ytuhdIndex != NSNotFound) {
                // YTUHD exists, insert after it
                [mutableOrder insertObject:sectionNumber atIndex:ytuhdIndex + 1];
            } else if (youpipIndex != NSNotFound) {
                // YouPiP exists, insert before it
                [mutableOrder insertObject:sectionNumber atIndex:youpipIndex];
            } else {
                // Neither exists, insert after "Tweaks" section
                [mutableOrder insertObject:sectionNumber atIndex:insertIndex + 1];
            }
        }
        order = mutableOrder.copy;
    }
    return order;
}

%end

%hook YTSettingsSectionItemManager

%new(v@:@)
- (void)updateYTWKSSectionWithEntry:(id)entry {
    NSMutableArray *sectionItems = [NSMutableArray array];
    NSBundle *tweakBundle = YTWKSBundle();
    Class YTSettingsSectionItemClass = %c(YTSettingsSectionItem);

    // Fullscreen to the Right
    YTSettingsSectionItem *fullscreenToRight = [YTSettingsSectionItemClass switchItemWithTitle:LOC(@"FULLSCREEN_TO_THE_RIGHT")
        titleDescription:LOC(@"FULLSCREEN_TO_THE_RIGHT_DESC")
        accessibilityIdentifier:nil
        switchOn:[defaults boolForKey:@"fullscreenToTheRight_enabled"]
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [defaults setBool:enabled forKey:@"fullscreenToTheRight_enabled"];
            [defaults synchronize];
            return YES;
        }
        settingItemId:0];
    [sectionItems insertObject:fullscreenToRight atIndex:0];

    // Fullscreen to the Left
    YTSettingsSectionItem *fullscreenToLeft = [YTSettingsSectionItemClass switchItemWithTitle:LOC(@"FULLSCREEN_TO_THE_LEFT")
        titleDescription:LOC(@"FULLSCREEN_TO_THE_LEFT_DESC")
        accessibilityIdentifier:nil
        switchOn:[defaults boolForKey:@"fullscreenToTheLeft_enabled"]
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [defaults setBool:enabled forKey:@"fullscreenToTheLeft_enabled"];
            [defaults synchronize];
            return YES;
        }
        settingItemId:1];
    [sectionItems insertObject:fullscreenToLeft atIndex:1];

    // A/B Testing: iOS Floating Miniplayer
    YTSettingsSectionItem *enableIosFloatingMiniplayer = [YTSettingsSectionItemClass switchItemWithTitle:LOC(@"ENABLE_IOS_FLOATING_MINIPLAYER")
        titleDescription:LOC(@"ENABLE_IOS_FLOATING_MINIPLAYER_DESC")
        accessibilityIdentifier:nil
        switchOn:[defaults boolForKey:@"enableIosFloatingMiniplayer"]
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [defaults setBool:enabled forKey:@"enableIosFloatingMiniplayer"];
            [defaults synchronize];
            return YES;
        }
        settingItemId:2];
    [sectionItems insertObject:enableIosFloatingMiniplayer atIndex:2];

    YTSettingsViewController *delegate = [self valueForKey:@"_dataDelegate"];
    NSString *title = @"YTweaks";
    if ([delegate respondsToSelector:@selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:)]) {
        YTIIcon *icon = [%c(YTIIcon) new];
        icon.iconType = YT_MAGIC_WAND;
        [delegate setSectionItems:sectionItems
            forCategory:YTWKSSection
            title:title
            icon:icon
            titleDescription:nil
            headerHidden:NO];
    } else
        [delegate setSectionItems:sectionItems
            forCategory:YTWKSSection
            title:title
            titleDescription:nil
            headerHidden:NO];
}

- (void)updateSectionForCategory:(NSUInteger)category withEntry:(id)entry {
    if (category == YTWKSSection) {
        [self updateYTWKSSectionWithEntry:entry];
        return;
    }
    %orig;
}

%end

%ctor {
    defaults = [NSUserDefaults standardUserDefaults];
    %init;
}
