#import <Cocoa/Cocoa.h>
#include <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface CustomSchemeHandler : NSObject <WKURLSchemeHandler>
@end

@implementation CustomSchemeHandler

// OLD CODE
// DAPPNET CLASSIC GATEWAY
// 
// 

// - (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
//     NSURL *url = urlSchemeTask.request.URL;
//     // Check if the URL is what you need to handle
//     if ([url.host hasSuffix:@".eth"]) {
//         // Fetch data for the URL    
//         // get the path from the URL and add it onto the local gateway URL
//         NSString *path = url.path;
//         NSString *gatewayURL = [NSString stringWithFormat:@"http://localhost:10422%@", path];
//         NSLog(@"Load host=%@ gateway=%@", url.host, gatewayURL);


//         NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:gatewayURL]];
//         request.HTTPMethod = @"POST"; // non-idempotent
//         [request setValue:url.host forHTTPHeaderField:@"Host"];
//         NSURLSession *session = [NSURLSession sharedSession];
//         NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//             if (error) {
//                 [urlSchemeTask didFailWithError:error];
//             } else {
//                 [urlSchemeTask didReceiveResponse:response];
//                 [urlSchemeTask didReceiveData:data];
//                 [urlSchemeTask didFinish];
//             }
//         }];
//         [task resume];
//     } else {
//         [urlSchemeTask didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
//     }
// }



// NEW CODE
// DAPPNET NATIVE GATEWAY
// 
// 

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    NSURL *url = urlSchemeTask.request.URL;
    
    
    // Check if the URL is what you need to handle
    if ([url.host hasSuffix:@".eth"]) {
        // Fetch data for the URL    
        // get the path from the URL and add it onto the local gateway URL
        NSString *path = url.path;
        NSString *gatewayURL = [NSString stringWithFormat:@"http://localhost:10422%@", path];
        NSLog(@"Load host=%@ gateway=%@", url.host, gatewayURL);


        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:gatewayURL]];
        request.HTTPMethod = @"POST"; // non-idempotent
        [request setValue:url.host forHTTPHeaderField:@"Host"];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                [urlSchemeTask didFailWithError:error];
            } else {
                [urlSchemeTask didReceiveResponse:response];
                [urlSchemeTask didReceiveData:data];
                [urlSchemeTask didFinish];
            }
        }];
        [task resume];
    } else {
        [urlSchemeTask didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    }
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    // Handle stopping tasks if necessary
}

@end




NSString *stringFromFileAtPath(NSString *path) {
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (fileContents == nil) {
        NSLog(@"Error reading file at %@: %@", path, error.localizedDescription);
        return nil;
    }
    return fileContents;
}







@interface DappnetWebView : WKWebView <WKNavigationDelegate, WKScriptMessageHandler>
@end

@implementation DappnetWebView

- (instancetype)initWithFrame:(NSRect)frame configuration:(WKWebViewConfiguration *)configuration {

    [configuration.userContentController addScriptMessageHandler:self name:@"nativeHandler"];

// webkit.messageHandlers.nativeHandler.postMessage('Your message here');

    NSString *js = stringFromFileAtPath(@"wallet/wallet.ts");
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [configuration.userContentController addUserScript:userScript];

    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        self.navigationDelegate = self;
    }
    return self;
}


// Receive messages from JavaScript
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"nativeHandler"]) {
        NSLog(@"Received message: %@", message.body);
        // Handle the message
    }
}

@end



@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) NSWindow *window;

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSMenu *menu;

@end

@implementation AppDelegate

- (void) quitApp {
    [NSApp terminate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    // Set up the main menu
    [self setupMainMenu];

    // Set up and display the main window
    [self setupMainWindow];


    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        NSImage *iconImage = [NSImage imageNamed:@"output.png"];

    self.statusItem.button.image = iconImage;

    self.menu = [[NSMenu alloc] init];
    [self.menu addItemWithTitle:@"Dappnet" action:nil keyEquivalent:@""];
    [self.menu addItem:[NSMenuItem separatorItem]];  // Separator
    [self.menu addItemWithTitle:@"Quit" action:@selector(quitApp) keyEquivalent:@"q"];
    [self.menu addItemWithTitle:@"About" action:@selector(showAbout) keyEquivalent:@""];
    [self.menu addItemWithTitle:@"Launch Browser" action:@selector(setupMainWindow) keyEquivalent:@""];
    [self.menu addItemWithTitle:@"Wallet: 0 ETH (0x...)" action:nil keyEquivalent:@""];
    [self.menu itemAtIndex:4].enabled = NO;  // Gray out the wallet balance

    self.statusItem.menu = self.menu;
}

- (void)setupMainMenu {
    // Create the main menu bar
    NSMenu *mainMenu = [[NSMenu alloc] init];

    // Edit menu
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""];
    [mainMenu addItem:editMenuItem];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenuItem setSubmenu:editMenu];

    // Add Copy
    NSMenuItem *copyItem = [[NSMenuItem alloc] initWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [copyItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [editMenu addItem:copyItem];

    // Add Paste
    NSMenuItem *pasteItem = [[NSMenuItem alloc] initWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [pasteItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [editMenu addItem:pasteItem];

    // Add Cut
    NSMenuItem *cutItem = [[NSMenuItem alloc] initWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [cutItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [editMenu addItem:cutItem];

    // Add Undo
    NSMenuItem *undoItem = [[NSMenuItem alloc] initWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [undoItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [editMenu addItem:undoItem];

    // Add Select All
    NSMenuItem *selectAllItem = [[NSMenuItem alloc] initWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    [selectAllItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [editMenu addItem:selectAllItem];
    
    NSMenuItem *toolsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Tools" action:nil keyEquivalent:@""];
    [mainMenu addItem:toolsMenuItem];
    NSMenu *toolsMenu = [[NSMenu alloc] initWithTitle:@"Tools"];
    [toolsMenuItem setSubmenu:toolsMenu];

    // Adding "Open URL Dialog" menu item with Command-K shortcut
    NSMenuItem *openURLItem = [[NSMenuItem alloc] initWithTitle:@"Open URL" action:@selector(promptForURL:) keyEquivalent:@"k"];
    [openURLItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [toolsMenu addItem:openURLItem];

    // Create the application menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:appMenuItem];
    NSMenu *appMenu = [[NSMenu alloc] init];
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                                        action:@selector(terminate:)
                                                keyEquivalent:@"q"];
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];

    // Assign the menu to the application
    [[NSApplication sharedApplication] setMainMenu:mainMenu];
}

- (void)setupMainWindow {
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];

    // Load the icon image
    NSString *iconPath = @"curve.png";
    // NSImage *iconImage = [NSImage imageNamed:@"curve.png"];
    // NSImage *iconImage = [NSImage imageNamed:@"output.png"];

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/sips"];
    [task setArguments:@[@"-Z", @"128", iconPath, @"--out", @"tmp-icon.png"]];
    [task launch];
    [task waitUntilExit];
    // handle task errors
    if ([task terminationStatus] != 0) {
        NSLog(@"Failed to resize the application icon.");
    }

    NSImage *iconImage = [NSImage imageNamed:@"tmp-icon.png"];
    if (!iconImage) {
        NSLog(@"Failed to load the application icon.");
    }

    // Set the application icon for Dock and Alt-Tab
    [NSApp setApplicationIconImage:iconImage];
    // [[NSApp dockTile] setBadgeLabel:@"Curve"];


    // Define the URL to fetch favicon from
    // NSURL *faviconURL = [NSURL URLWithString:@"https://uniswap.org/favicon.ico"];
    
    // // Create an NSURLSession task to download the favicon
    // NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:faviconURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    //     NSLog(@"check.");

    //     if (data && !error) {
    //         NSImage *favicon = [[NSImage alloc] initWithData:data];
    //         NSLog(@"Favicon downloaded successfully.");

    //         if (favicon) {
    //             dispatch_async(dispatch_get_main_queue(), ^{
    //                 // Set the downloaded image as the application icon
    //                 [NSApp setApplicationIconImage:favicon];
    //             });
    //         }
    //     } else {
    //         NSLog(@"Error downloading favicon: %@", error.localizedDescription);
    //     }
    // }];

    // [task resume];


    NSRect frame = NSMakeRect(0, 0, 800, 600);
    NSUInteger windowStyle = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;

    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:windowStyle
                                                        backing:NSBackingStoreBuffered
                                                        defer:NO];
    [window setOpaque:NO];
    [window setBackgroundColor:[NSColor clearColor]];
    [window setTitle:@"Dappnet"];
    [window makeKeyAndOrderFront:nil];
    [window makeKeyAndOrderFront:nil];

    // NSURL *url = [NSURL URLWithString:@"dappnet://uniswap.eth"];
    NSURL *url = [NSURL URLWithString:@"https://app.uniswap.org"];
    // NSURL *url = [NSURL URLWithString:@"https://jmcph4.dev"];
    // NSURL *url = [NSURL URLWithString:@"dappnet://vitalik.eth"];
    // NSURL *url = [NSURL URLWithString:@"dappnet://1inch.eth/"];
    // NSURL *url = [NSURL URLWithString:@"http://localhost:8087"];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    CustomSchemeHandler *schemeHandler = [[CustomSchemeHandler alloc] init];
    [config setURLSchemeHandler:schemeHandler forURLScheme:@"dappnet"];

    DappnetWebView *webView = [[DappnetWebView alloc] initWithFrame:frame configuration:config];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    // wait 200ms.
    [NSThread sleepForTimeInterval:0.4f];


    [window setContentView:webView];

    // NSString *appPath = @"ipfs-apps/bafybeifzk2sizlcd6xiowyo6xzktbwl4sadwedxwau53umuyzgjy2y5h4y/";
    // NSString *appIndexPath = [appPath stringByAppendingPathComponent:@"/index.html"];

    // Get the current working directory
    // NSString *currentDirectory = [[NSFileManager defaultManager] currentDirectoryPath];

    // Append the relative path to the current directory path
    // appPath = [currentDirectory stringByAppendingPathComponent:appPath];
    // appIndexPath = [currentDirectory stringByAppendingPathComponent:appIndexPath];

    // Create the NSURL from the full path
    // NSURL *fileURL = [NSURL fileURLWithPath:appIndexPath];
    // NSURL *dirURL = [NSURL fileURLWithPath:appPath];
    
    // NSLog(@"URL: %@", fileURL);
    // NSLog(@"Dir: %@", dirURL);
    // [webView loadFileURL:fileURL allowingReadAccessToURL:dirURL];
    
}


- (void)promptForURL:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Enter URL";
    alert.informativeText = @"Type the URL you want to open:";
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];

    NSTextField *inputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [inputField setPlaceholderString:@"vitalik.eth"];
    [alert setAccessoryView:inputField];

    NSWindow *mainWindow = [NSApp mainWindow];
    [alert beginSheetModalForWindow:mainWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            NSString *urlString = [inputField stringValue];
            NSLog(@"URL entered: %@", urlString);

            // format URL into dappnet://xxx
            // replace http and https
            urlString = [urlString stringByReplacingOccurrencesOfString:@"http://" withString:@"dappnet://"];
            urlString = [urlString stringByReplacingOccurrencesOfString:@"https://" withString:@"dappnet://"];

            // if not dappnet://, add dappnet://
            if (![urlString hasPrefix:@"dappnet://"]) {
                urlString = [NSString stringWithFormat:@"dappnet://%@", urlString];
            }

            NSURL *url = [NSURL URLWithString:urlString];
            if (url) {
                // Load in webview
                DappnetWebView *webView = (DappnetWebView *)mainWindow.contentView;
                [webView loadRequest:[NSURLRequest requestWithURL:url]];

            } else {
                NSLog(@"Invalid URL entered.");
            }


        } else {
            NSLog(@"URL entry canceled.");
        }
    }];

    [mainWindow performSelector:@selector(makeFirstResponder:) withObject:inputField afterDelay:0];

    dispatch_async(dispatch_get_main_queue(), ^{
        [inputField becomeFirstResponder];
    });

}

@end






int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        AppDelegate *appDelegate = [[AppDelegate alloc] init];

        NSDictionary * defaults = 
        [NSDictionary dictionaryWithContentsOfFile:
        [[NSBundle mainBundle] 
        pathForResource:@"Defaults" ofType:@"plist"]];
        [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // Get Info.plist
        NSDictionary * xxx = 
        [NSDictionary dictionaryWithContentsOfFile:
        [[NSBundle mainBundle] 
        pathForResource:@"Info" ofType:@"plist"]];
        NSLog(@"Info.plist: %@", xxx);

        // NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"] = @"Dappnet";
        
        // Set the app name
        // NSBundle.mainBundle.infoDictionary = @"Dappnet";
        
        // [[NSBundle mainBundle] infoDictionary]

        // [@"CFBundleName"] = @"New Program Name";

        application.delegate = appDelegate;
        [application run];
    }
    return 0;
}

