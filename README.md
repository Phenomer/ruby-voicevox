# VOICEVOX ruby client
## これはなに?

無料で使える中品質な音声読み上げソフトウェア
[VOICEVOX Engine](https://github.com/VOICEVOX/voicevox_engine)をRubyから操作するためのライブラリです。

これ単体では動作しません。**VOICEVOX engineサーバが必要です。**

## VOICEVOX engineサーバの導入
[VOICEVOX Engineのreleases](https://github.com/VOICEVOX/voicevox_engine/releases)から、
最新バージョンのEngineをダウンロードし展開・実行してください。実行方法は公式のマニュアルを参照してください。
動作確認を行っているバージョンは、2022年8月11日時点で最新の0.12.4です。

例として、NVIDIAのGPUが利用できないWSL上で動作させたい場合は下記の手順となります。


```sh
$ wget https://github.com/VOICEVOX/voicevox_engine/releases/download/0.12.4/linux-cpu.7z.001
$ 7zz x linux-cpu.7z.001
$ cd linux-cpu
$ chmod +x run
$ ./run
```

## インストール
(まだ準備中です。)

```sh
$ gem install voicevox
```

## 使い方

合成したい話者のIDを探し、そのIDと合成したいテキストを`speak`メソッドに渡します。


```ruby
require 'voicebox'

speaker_id = 1

# `play_cmd`の標準入力にwavファイルストリームが渡され、音声が再生される
vvc = VoiceVox.new(play_cmd: 'paplay')
vvc.speak(speaker: speaker_id, text: 'こんにちは')

```

話者一覧は`speakers`メソッドで得られます。


```ruby
require 'voicebox'

vvc = VoiceVox.new(play_cmd: 'paplay')
pp(vvc.speakers)

```

## ライセンス
このライブラリはMITライセンスです。
Engineと音声ライブラリのライセンスは別ですのでご注意ください。
