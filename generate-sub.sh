#!/bin/bash

echo "🔗 Enter your VLESS/VMess/Trojan links one by one."
echo "ℹ️  When you're done, type 'done' and press Enter."

LINKS=()

while true; do
  read -rp "Enter link (or 'done'): " link
  if [[ "$link" == "done" ]]; then
    break
  elif [[ -n "$link" ]]; then
    LINKS+=("$link")
  fi
done

if [[ ${#LINKS[@]} -eq 0 ]]; then
  echo "⚠️  No links provided. Exiting."
  exit 1
fi

echo "📝 Writing links to sub.txt..."
> sub.txt
for l in "${LINKS[@]}"; do
  echo "$l" >> sub.txt
done

echo "🗜 Encoding to Base64..."
base64 -w0 sub.txt > sub.b64

echo "✅ Subscription generated successfully!"
echo ""
echo "➡️  Here is your base64 content (you can paste it on your web server or GitHub Pages):"
echo ""
cat sub.b64
echo ""
echo "ℹ️  Then, in your client use subscription URL like:"
echo ""
echo "http://yourdomain.com/path/to/sub.b64"
echo ""
