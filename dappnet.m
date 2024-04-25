#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface CustomSchemeHandler : NSObject <WKURLSchemeHandler>
@end

@implementation CustomSchemeHandler

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






@interface DappnetWebView : WKWebView <WKNavigationDelegate>
@end

@implementation DappnetWebView

- (instancetype)initWithFrame:(NSRect)frame configuration:(WKWebViewConfiguration *)configuration {
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        self.navigationDelegate = self;
    }
    return self;
}

@end



@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    // Set up the main menu
    [self setupMainMenu];

    // Set up and display the main window
    [self setupMainWindow];
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
    // Load the icon image
    // NSImage *iconImage = [NSImage imageNamed:@"AppNameIcon"];  // Ensure "AppNameIcon" is in your assets
    // if (!iconImage) {
    //     NSLog(@"Failed to load the application icon.");
    // }

    // // Set the application icon for Dock and Alt-Tab
    // [NSApp setApplicationIconImage:iconImage];

    // Define the URL to fetch favicon from
    NSURL *faviconURL = [NSURL URLWithString:@"https://uniswap.org/favicon.ico"];
    
    // Create an NSURLSession task to download the favicon
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:faviconURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"check.");

        if (data && !error) {
            NSImage *favicon = [[NSImage alloc] initWithData:data];
            NSLog(@"Favicon downloaded successfully.");

            if (favicon) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Set the downloaded image as the application icon
                    [NSApp setApplicationIconImage:favicon];
                });
            }
        } else {
            NSLog(@"Error downloading favicon: %@", error.localizedDescription);
        }
    }];

    [task resume];


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

    // NSURL *url = [NSURL URLWithString:@"dappnet://uniswap.eth"];
    // NSURL *url = [NSURL URLWithString:@"https://app.uniswap.org"];
    // NSURL *url = [NSURL URLWithString:@"https://messenger.com"];
    // NSURL *url = [NSURL URLWithString:@"dappnet://vitalik.eth"];
    // NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:8080/ipfs/QmPCRt8v4iLrE8mgtPvYrDKj28jyoZMWdnGzXgQCBk59EV/#/1/swap/ETH/DAI"];
    NSURL *url = [NSURL URLWithString:@"dappnet://1inch.eth/"];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    CustomSchemeHandler *schemeHandler = [[CustomSchemeHandler alloc] init];
    [config setURLSchemeHandler:schemeHandler forURLScheme:@"dappnet"];

    DappnetWebView *webView = [[DappnetWebView alloc] initWithFrame:frame configuration:config];

    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    [window setContentView:webView];
    
    [window makeKeyAndOrderFront:nil];
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
        application.delegate = appDelegate;
        [application run];
    }
    return 0;
}

