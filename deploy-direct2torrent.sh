set -ex
export HOST=3.64.252.173

rsync -e "ssh -i /Users/liamz/Downloads/LightsailDefaultKey-eu-central-1.pem" -RacP --copy-links --filter=':- .gitignore' --filter='- .git' vps ec2-user@3.64.252.173:vps

ssh -i /Users/liamz/Downloads/LightsailDefaultKey-eu-central-1.pem -T ec2-user@$HOST <<'EOL'
    cd vps/vps
    nvm use 16
    npm run build
    node --no-warnings build/index.js start --port 8082 --dir ./downloads
EOL