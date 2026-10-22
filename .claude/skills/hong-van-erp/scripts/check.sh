#!/usr/bin/env bash
# Kiểm tra nhanh Hong_Van_ERP_Demo_Fixed.html sau mỗi lần sửa.
#   bash .claude/skills/hong-van-erp/scripts/check.sh            # cú pháp + test vai trò
#   bash .claude/skills/hong-van-erp/scripts/check.sh --shot     # thêm ảnh chụp màn hình đăng nhập + trang đầu mỗi vai trò
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
HTML="$ROOT/Hong_Van_ERP_Demo_Fixed.html"
OUT="${TMPDIR:-/tmp}/hongvan-erp-check"; mkdir -p "$OUT"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 1. Cú pháp JS
python3 -I -c "import re,sys;s=open(sys.argv[1],encoding='utf-8').read();open(sys.argv[2],'w').write(re.search(r'<script>(.*)</script>',s,re.S).group(1))" "$HTML" "$OUT/app.js"
node --check "$OUT/app.js" && echo "OK  cú pháp JS"

[ -x "$CHROME" ] || { echo "SKIP không tìm thấy Google Chrome"; exit 0; }

# 2. Đăng nhập từng vai trò, in trang đầu, menu, nút trên trang và lỗi JS nếu có
python3 -I - "$HTML" "$OUT/test.html" <<'EOF'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
t='''<script>window.__err=[];window.addEventListener('error',e=>__err.push(e.message));
window.addEventListener('load',()=>{let out=[];try{for(const u of Object.keys(users)){login(u);
out.push(u+' | trang đầu='+state.page+' | menu='+[...document.querySelectorAll('#nav button')].map(b=>b.textContent.trim()).join(', '));
out.push('   nút: '+[...document.querySelectorAll('#content button')].map(b=>b.textContent.trim()).join(', '));
for(const p of users[u].allowed){go(p);if(state.page!==p)out.push('   LỖI không mở được '+p)}
logout();}}catch(e){out.push('EXCEPTION '+e.message)}
if(__err.length)out.push('JS ERRORS: '+__err.join(' | '));
document.body.innerHTML='<pre id=R>'+out.join('\\n').replace(/</g,'&lt;')+'</pre>';});</script></body>'''
open(sys.argv[2],'w',encoding='utf-8').write(s.replace('</body>',t))
EOF
"$CHROME" --headless=new --disable-gpu --dump-dom "file://$OUT/test.html" 2>/dev/null \
  | sed -n '/<pre id="R">/,/<\/pre>/p' | sed -e 's/<[^>]*>//g' -e 's/&amp;/\&/g' -e 's/&gt;/>/g' -e 's/&lt;/</g'

# 3. Ảnh chụp (tùy chọn)
if [ "${1:-}" = "--shot" ]; then
  "$CHROME" --headless=new --disable-gpu --window-size=1280,800 --screenshot="$OUT/login.png" "file://$HTML" 2>/dev/null
  for u in lanhdao kinhdoanh khaithac tonghop; do
    python3 -I -c "import sys;s=open(sys.argv[1],encoding='utf-8').read();open(sys.argv[2],'w',encoding='utf-8').write(s.replace('</body>','<script>login(\"'+sys.argv[3]+'\")</script></body>'))" "$HTML" "$OUT/shot_$u.html" "$u"
    "$CHROME" --headless=new --disable-gpu --window-size=1280,800 --screenshot="$OUT/$u.png" "file://$OUT/shot_$u.html" 2>/dev/null
  done
  echo "Ảnh chụp: $OUT/{login,lanhdao,kinhdoanh,khaithac,tonghop}.png"
fi
