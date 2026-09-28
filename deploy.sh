#!/bin/zsh
# 깃허브에 올리면 Vercel이 main 브랜치를 운영 환경에 자동 배포합니다(Git 연동).
# 이 스크립트는 푸시한 뒤 Vercel 배포가 끝날 때까지 GitHub 커밋 상태로 기다립니다.
# Vercel CLI 로그인이 필요 없습니다.
cd "${0:A:h}"
repo=99ksy9990-bot/truman-history
site=https://truman-history.vercel.app

git push origin main || exit 1
sha=$(git rev-parse HEAD)
echo "푸시 완료: ${sha[1,7]} — Vercel 배포를 기다립니다."

if ! command -v gh >/dev/null || ! gh auth status >/dev/null 2>&1; then
  echo "gh 로그인이 없어 배포 완료를 확인하지 못했습니다. 1~2분 뒤 $site 를 확인하세요."
  exit 0
fi

for _ in {1..60}; do
  state=$(gh api "repos/$repo/commits/$sha/status" \
    --jq '[.statuses[] | select(.context == "Vercel")][0].state // "none"' 2>/dev/null)
  case $state in
    success) echo "배포 완료: $site"; exit 0 ;;
    failure|error)
      echo "배포 실패:"
      gh api "repos/$repo/commits/$sha/status" --jq '.statuses[] | select(.context == "Vercel") | .target_url'
      exit 1 ;;
  esac
  sleep 5
done
echo "5분이 지나도 배포가 끝나지 않았습니다. Vercel 대시보드를 확인하세요."
exit 1
