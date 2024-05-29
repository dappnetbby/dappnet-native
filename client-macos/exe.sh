set -ex
clang -framework Foundation -framework Cocoa -framework WebKit -framework QuartzCore dappnet.m -o dappnet && ./dappnet
