# coding: utf-8

require_relative '../lib/voicebox'

# シンプルに再生するサンプル

vvc = VoiceVox.new(play_cmd: 'paplay')
vvc.speak(speaker: 1, text: 'こんにちは')
