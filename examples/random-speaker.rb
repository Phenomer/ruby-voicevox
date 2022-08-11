# coding: utf-8

require_relative '../lib/voicebox'

vvc = VoiceVox.new(play_cmd: 'paplay')
speakers = vvc.speakers.reduce([]) do |ary, spcs|
  ary += spcs['styles'].collect do |vo|
    vo['cname'] = spcs['name']; vo
  end
end

if ARGV[0]
  speaker = speakers.select{|c| c['id'] == ARGV[0].to_i}[0]
  if speaker.nil?
    printf("Unknown Speaker ID: %s\n", ARGV[0])
    exit 1
  end
else
  speaker = speakers.sample
end

pp(speaker)

# シンプルに再生
#vvc.speak(speaker: speaker['id'], text: 'こんにちは')

# AquesTalk 記法で取得・編集してから再生
query = vvc.audio_query(speaker: speaker['id'], text: 'こんにちは') do |text|
  # ここで編集
  pp text
  text
end
wav_stream = vvc.synthesis(speaker: speaker['id'], query: query)
vvc.player(stream: wav_stream)
