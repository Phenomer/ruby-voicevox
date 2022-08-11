# coding: utf-8

require_relative '../lib/voicebox'


vvc = VoiceVox.new

# blockでquery編集、wavファイルストリームを得る
wave = vvc.speak_wav_stream(speaker: 1, text: 'こんにちは') do |query|
  pp query
  # query['accent_phrases'] = vvc.accent_phrases(speaker: speaker['id'], text: query['kana'], is_kana: true)
  query
end

p wave.length
