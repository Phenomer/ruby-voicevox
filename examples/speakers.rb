require_relative '../lib/voicebox'

vvc = VoiceVox.new(play_cmd: 'paplay')
pp(vvc.speakers)

