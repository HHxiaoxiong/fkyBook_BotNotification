#!/usr/bin/env python
# -*- encoding:utf-8 -*-
import base64
import hashlib
import hmac
from sys import argv
from requests import request
from datetime import datetime


def gen_sign(timestamp, secret):
    # 拼接timestamp和secret
    string_to_sign = '{}\n{}'.format(timestamp, secret)
    hmac_code = hmac.new(string_to_sign.encode("utf-8"),
                         digestmod=hashlib.sha256).digest()
    # 对结果进行base64处理
    sign = base64.b64encode(hmac_code).decode('utf-8')
    return sign


def notification(key, secret, content):
    url = "https://open.feishu.cn/open-apis/bot/v2/hook/"+key
    timestamp = int(datetime.timestamp(datetime.now()))
    sign = gen_sign(timestamp, secret)
    method = 'post'
    headers = {
        'Content-Type': 'application/json'
    }
    json = {
        "msg_type": "interactive",
        "timestamp": timestamp,
        "sign": sign,
        "card": {
            "content": {
                "config": {
                    "wide_screen_mode": True
                },
                "header": {
                    "template": "orange",
                    "title": {
                        "tag": "plain_text",
                        "content": "wgcloud告警通知"
                    }
                },
                "elements": [
                    {
                        "tag": "div",
                        "text": {
                            "tag": "lark_md",
                            "content": content
                        },
                        "extra": {
                            "tag": "img",
                            "img_key": "img_v2_50876f09-1f27-4295-a557-bc018d35c99g",
                            "alt": {
                                "tag": "plain_text",
                                "content": "图片"
                            }
                        }
                    },
                    {
                        "tag": "action",
                        "actions": [
                            {
                                "tag": "button",
                                "text": {
                                    "tag": "plain_text",
                                    "content": "前往监控系统"
                                },
                                "type": "primary",
                                "multi_url": {
                                    "url": "https://wgcloud.sqjzcloud.cn/",
                                    "pc_url": "",
                                    "android_url": "",
                                    "ios_url": ""
                                }
                            }
                        ]
                    },
                    {
                        "tag": "note",
                        "elements": [
                            {
                                "tag": "img",
                                "img_key": "img_v2_041b28e3-5680-48c2-9af2-497ace79333g",
                                "alt": {
                                    "tag": "plain_text",
                                    "content": ""
                                }
                            },
                            {
                                "tag": "plain_text",
                                "content": "来自wgcloud云检测"
                            }
                        ]
                    }
                ]
            }
        }
    }
    rest = request(method=method, url=url, headers=headers, json=json)
    print(rest.text)


if __name__ == "__main__":
    key = "webhook"
    secret = "密钥"
    curr_time = datetime.now()
    time_str = datetime.strftime(curr_time, '%Y-%m-%d %H:%M:%S')
    content = time_str+"----" + \
        bytes(argv[1], 'utf-8').decode('unicode_escape')+"\n"
    notification(key, secret, content)
