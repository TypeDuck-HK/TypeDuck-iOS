#!/usr/bin/env python3
# coding=utf-8

# scrapy runspider scrap_ios_emoji.py -O emoji_by_ios_version.json

import scrapy
import re
import json

def codepoint_in_hex_to_chr(codepoint_in_hex):
    return chr(int(codepoint_in_hex, 16))

def is_not_skin_tone_char(codepoint):
    return ord(codepoint) < 0x1F3FB or 0x1F3FF < ord(codepoint)

def load_emoji_cp_dict():
    with open('emoji_cp.json', 'r') as f:
        emoji_cp_tuple_list = json.load(f)
        emoji_cp = dict()
        for tuple in emoji_cp_tuple_list:
            emoji_name = tuple['emoji_name']
            emoji_char = tuple['emoji_char']
            emoji_cp[emoji_name] = emoji_char

    return emoji_cp

class EmojiSpider(scrapy.Spider):
    name = "ios_emoji"
    start_urls = [
        'https://emojipedia.org/apple/ios-12.1/show_all/#more',
        'https://emojipedia.org/apple/ios-13.2/show_all/#more',
        'https://emojipedia.org/apple/ios-14.2/show_all/#more',
        'https://emojipedia.org/apple/ios-14.5/show_all/#more',
        'https://emojipedia.org/apple/ios-15.4/show_all/#more',
    ]

    emoji_cp = load_emoji_cp_dict()

    def parse(self, response):
        url = response.url
        ios_version_match = re.search(r'ios-(\d+\.\d+)', url)
        if not ios_version_match:
            return
        ios_version = ios_version_match.groups()[0]

        emoji_png_imgs = response.css('.emoji-grid > li > a > img')

        for emoji_png_img in emoji_png_imgs:
            # print(emoji_png_img)

            emoji_name = emoji_png_img.attrib.get('title')
            if not emoji_name:
                continue
            if emoji_name in self.emoji_cp:
                emoji = self.emoji_cp[emoji_name]
                codepoints = list(emoji)
            else:
                if 'data-src' in emoji_png_img.attrib:
                    emoji_png_url = emoji_png_img.attrib['data-src']
                else:
                    emoji_png_url = emoji_png_img.attrib.get('src')
                if not emoji_png_url:
                    continue
                # print(emoji_png_url)
                codepoints_match = re.search(r'_([0-9a-f\-]+)(?:_.+)?\.png', emoji_png_url)
                if not codepoints_match:
                    continue
                codepoints_in_hex = codepoints_match.groups()[0].split('-')
                codepoints = list(map(codepoint_in_hex_to_chr, codepoints_in_hex))
                emoji = ''.join(codepoints)

            emoji_without_skin_tone = ''.join(filter(is_not_skin_tone_char, codepoints))

            output = {
                'ios_version': ios_version,
                'emoji': emoji,
            }

            if emoji != emoji_without_skin_tone:
                output['group'] = emoji_without_skin_tone

            # print(emoji)
            yield output
            # break
