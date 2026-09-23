#!/bin/zsh
# 깃허브에 올리고 Vercel에 배포합니다. 맥에서 실행해야 합니다(키체인 인증 사용).
cd "${0:A:h}"
git push origin main || exit 1
npm_config_cache=/tmp/npmcache npx --yes vercel@latest --prod --yes
