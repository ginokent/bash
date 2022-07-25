#!/bin/bash

# MEMO:
# "text": "blocks が在れば通知本文 / 無ければメッセージ本文",
# "attachments": [
#   {
#     "pretext": "アタッチメントの外側に付けられる説明文",
#     "image_url": "https://github.com/ginokent.png", でかい添付画像
#     "thumb_url": "https://github.com/ginokent.png", 右側に控えめに表示される小さい画像


TITLE='👏全体のタイトル👏'
MESSAGE='これは本文🙆\nすごい本文だこれは\n概要とかを書くべき'

cat <<PAYLOAD | curl -X POST -H "Content-Type: application/json" -d @- "${SLACK_WEBHOOK_URL:?}"
{
  "username": "通知ユーザー",
  "icon_emoji": ":airplane:",
  "channel": "lab-hooks",
  "text": "${TITLE:?}\n${MESSAGE:?}",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "${TITLE:?}",
        "emoji": true
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "${MESSAGE:?}"
      }
    },
    {
      "type": "divider"
    }
  ],
  "attachments": [
    {
      "pretext": "アタッチメントの外側に付けられる説明文",
      "title": "アタッチメントのタイトル",
      "title_link": "https://api.slack.com/",
      "text": "アタッチメントへの説明文の概要",
      "fallback": "アタッチメントへの説明文の概要",
      "author_name": "Gino Kent",
      "author_link": "https://github.com/ginokent",
      "author_icon": "https://github.com/ginokent.png",
      "color": "good",
      "fields": [
        {
          "title": "Aについて",
          "value": "aaa",
          "short": true
        },
        {
          "title": "Bについて",
          "value": "bbb",
          "short": true
        },
        {
          "title": "Cについて",
          "value": "ccc",
          "short": true
        },
        {
          "title": "Dについて",
          "value": "ddd",
          "short": true
        },
        {
          "title": "長いフィールド",
          "value": "横1行に渡って何かを書きたいときなどに使う？",
          "short": false
        }
      ],
      "footer_icon": "https://github.com/ginokent.png?size=32",
      "footer": "フッター文字列",
      "ts": 1577934245
    }
  ]
}
PAYLOAD
