# coding: utf-8

require_relative '../lib/voicebox'

vvc = VoiceVox.new(play_cmd: 'paplay')

# AquesTalk 記法で取得・編集してから再生
query = vvc.audio_query(speaker: 1, text: 'こんにちは')
# ここで編集
pp query
query['accent_phrases'] = vvc.accent_phrases(speaker: 1, text: query['kana'], is_kana: true)
query
wav_stream = vvc.synthesis(speaker: 1, query: query)
vvc.player(stream: wav_stream)
