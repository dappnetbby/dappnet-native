set -ex

base=$(pwd)

cd torrent/
cd cmd/torrent

export GOOS=darwin
export GOARCH=arm64

go build -o torrent-$GOOS-$GOARCH
cp torrent-$GOOS-$GOARCH $base/client-macos/bin

export GOOS=darwin
export GOARCH=amd64

go build -o torrent-$GOOS-$GOARCH
cp torrent-$GOOS-$GOARCH $base/client-macos/bin

