#import <substrate.h>
#import <UIKit/UIKit.h>

// Forward declaration for YTWatchViewController
@class YTWatchViewController;

// Fullscreen to the Right (iPhone-Exclusive) - @arichornlover & @bhackel
// WARNING: Please turn off any "Portrait Fullscreen" or "iPad Layout" Options while "Fullscreen to the Right" is enabled.
%hook YTWatchViewController
- (UIInterfaceOrientationMask)allowedFullScreenOrientations {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"fullscreenToTheRight_enabled"]) {
        UIInterfaceOrientationMask orientations = UIInterfaceOrientationMaskLandscapeRight;
        return orientations;
    }
    if ([defaults boolForKey:@"fullscreenToTheLeft_enabled"]) {
        UIInterfaceOrientationMask orientations = UIInterfaceOrientationMaskLandscapeLeft;
        return orientations;
    }
    return %orig;
}
%end

%ctor {
    [[NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/Frameworks/Module_Framework.framework", [[NSBundle mainBundle] bundlePath]]] load];
    %init;
}
