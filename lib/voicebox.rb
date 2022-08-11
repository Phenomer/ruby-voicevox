# coding: utf-8

require 'net/http'
require 'json'
require 'open3'

# 参考: [https://voicevox.github.io/voicevox_engine/api/]
class VoiceVox
  # VoiceVoxサーバに接続する。
  # * +host+ - サーバホスト名(default: '127.0.0.1')
  # * +port+ - サーバポート番号(default: 50021)
  # * +play_cmd+ - wavストリーム再生用コマンド(default: 'aplay')
  def initialize(host: '127.0.0.1', port: 50021, play_cmd: 'aplay')
    @host, @port = host, port
    @play_cmd = play_cmd
    @http = Net::HTTP.new(@host, @port)
  end

  # 指定されたテキストを音声に変換。
  # * +spearker+ - 話者ID。+speakers+メソッドで得られる。(default: 1)
  # * +text+ - 音声に変換するテキスト文字列。
  def speak(speaker: 1, text:)
    res = audio_query(speaker: speaker, text: text)
    wav_stream = synthesis(speaker: speaker, query: res)
    player(stream: wav_stream)
  end

  # wavファイルのストリームを再生。
  # 再生中はブロックされる。
  # フォーマットはS16LE 24000Hz 1ch
  # * +stream+ - wavファイルストリーム(String)
  def player(stream:)
    sin, sout, serr, wt = Open3.popen3(@play_cmd)
    sin.write(stream)
    sin.close
    wt.join
  end

  # テキストを+synthesis+に渡せるクエリJSON(連想配列)に変換。
  # ブロックを渡すと、クエリのkanaを更新し、アクセントを再生成できる。
  # * +speaker+ - 話者ID。+speakers+メソッドで得られる。(default: 1)
  # * +text+ - クエリに変換するテキスト文字列。
  # * 戻り値 - クエリ連想配列
  def audio_query(speaker: 1, text:, &modify)
    res = @http.post('/audio_query?' + URI.encode_www_form(speaker: speaker, text: text), nil)
    valid_response?(res)
    query = JSON.parse(res.body)
    if modify
      query['kana'] = modify.call(query['kana'])
      query['accent_phrases'] = accent_phrases(speaker: speaker, text: query['kana'], is_kana: true)
    end
    return query
  end

  # テキストからアクセント句を生成。
  # * +speaker+ - 話者ID。+speakers+メソッドで得られる。(default: 1)
  # * +text+ - アクセントに変換する文字列。
  # * +is_kana+ - +text+がAquesTalkライクな記法に従う読み仮名であるか。(+audio_query+で得たkanaなどであればtrue。default: false)
  # 戻り値 - アクセント句配列
  #
  # ==== is_kanaがtrueの時の記法(AquesTalkライク記法)
  # * 全てのカナはカタカナで記述される。
  # * アクセント句は/または、で区切る。、で区切った場合に限り無音区間が挿入される。
  # * カナの手前に_を入れるとそのカナは無声化される。
  # * アクセント位置を'で指定する。全てのアクセント句にはアクセント位置を1つ指定する必要がある。
  # * アクセント句末に？(全角)を入れることにより疑問文の発音ができる。
  def accent_phrases(speaker: 1, text:, is_kana: false)
    res = @http.post('/accent_phrases?' + URI.encode_www_form(speaker: speaker, text: text, is_kana: is_kana), nil)
    valid_response?(res)
    return JSON.parse(res.body)
  end

  # ++audio_query++メソッドなどで得たクエリを元に音声を生成。
  # * +speaker+ - 話者ID。+speakers+メソッドで得られる。(default: 1)
  # * +query+ - 変換を要求するクエリ。
  # * 戻り値 - wavストリーム
  def synthesis(speaker: 1, query:)
    res = @http.post('/synthesis?' + URI.encode_www_form(speaker: speaker),
                     query.to_json, {"Content-Type": "application/json"})
    valid_response?(res)
    return res.body
  end

  # synthesisと同じだが、通信切断時に音声生成がキャンセルされる。
  # このAPIは実験的機能であり、エンジン起動時に引数で+--enable_cancellable_synthesis+を指定しないと有効化されない。
  # * +speaker+ - 話者ID。+speakers+メソッドで得られる。(default: 1)
  # * +query+ - 変換を要求するクエリ。
  # * 戻り値 - wavストリーム
  def cancellable_synthesis(speaker: 1, query:)
    res = @http.post('/cancellable_synthesis?' + URI.encode_www_form(speaker: speaker),
                     query.to_json, {"Content-Type": "application/json"})
    valid_response?(res)
    return res.body
  end

  # ふたりの話者でモーフィングした音声を生成する。
  # (+base_speaker+で指定した話者の音声を、+target_sparker+で指定した話者のものに近づける。)
  # * +base_speaker+ - ベースとなる話者のID。(default: 1)
  # * +target_speaker+ - ターゲットとなる話者のID。(default: 2)
  # * +morph_rate+ - どれだけターゲットに近づけるかを0.0～1.0で指定する。(default: 0.5)
  # * +query+ - 変換を要求するクエリ。
  # * 戻り値 - wavストリーム
  def synthesis_morphing(base_speaker: 1, target_speaker: 2, morph_rate: 0.5, query:)
    res = @http.post('/synthesis_morphing?' +
                     URI.encode_www_form(base_speaker: base_speaker,
                                         target_speaker: target_speaker,
                                         morph_rate: morph_rate),
                     query.to_json, {"Content-Type": "application/json"})
    valid_response?(res)
    return res.body
  end

  # 話者の一覧を取得。
  # * 戻り値 - 話者一覧の配列。
  def speakers
    res = @http.get('/speakers')
    valid_response?(res)
    return JSON.parse(res.body)
  end

  # 話者の追加情報を取得。
  # * +speaker_uuid+ - 話者のUUID。+speakers+メソッドで得られる...はず。
  # * 戻り値 - 話者の詳細情報の連想配列。
  def speaker_info(speaker_uuid:)
    res = @http.get('/speaker_info?' + URI.encode_www_form(speaker_uuid: speaker_uuid))
    valid_response?(res)
    return JSON.parse(res.body)
  end

  # ユーザ辞書の一覧を取得。
  # * 戻り値 - ユーザ辞書内単語一覧の連想配列。
  def user_dict
    res = @http.get('/user_dict')
    valid_response?(res)
    return JSON.parse(res.body)
  end

  # ユーザ辞書に単語を追加。
  # アクセント核位置の参考情報 - [https://tdmelodic.readthedocs.io/ja/latest/pages/introduction.html]
  # * +surface+ - 辞書に登録する単語。
  # * +pronunciation+ - カタカナでの読み方。
  # * +accent_type+ - アクセント核位置、整数。
  # * 戻り値 - 単語のUUID。
  def add_user_dict_word(surface:, pronunciation:, accent_type:)
    res = @http.post('/user_dict_word?' +
                     URI.encode_www_form(surface: surface,
                                         pronunciation: pronunciation,
                                         accent_type: accent_type))
    valid_response?(res)
    return res.body
  end

  # ユーザ辞書の単語情報を更新。
  # * +uuid+ - 更新対象単語のUUID。
  # * +surface+ - 辞書に登録する単語。
  # * +pronunciation+ - カタカナでの読み方。
  # * +accent_type+ - アクセント核位置、整数。
  # * 戻り値 - true。
  def update_user_dict_word(uuid:, surface:, pronunciation:, accent_type:)
    res = @http.put("/user_dict_word/#{uuid}?" +
                    URI.encode_www_form(surface: surface,
                                        pronunciation: pronunciation,
                                        accent_type: accent_type))
    return valid_update_response?(res)
  end

  # ユーザ辞書の単語情報を削除。
  # * +uuid+ - 更新対象単語のUUID。
  # * 戻り値 - true。
  def delete_user_dict_word(uuid:)
    res = @http.delete("/user_dict_word/#{uuid}")
    return valid_update_response?(res)
  end

  # サーバエンジンが保持しているプリセットを取得。
  # * 戻り値 - Array。
  def presets
    res = @http.get('/presets')
    valid_response?(res)
    return JSON.parse(res.body)
  end

  # サーバのバージョンを取得。
  # 戻り値 - バージョン文字列
  def version
    res = @http.get('/version')
    valid_response?(res)
    return JSON.parse(res.body)
  end

  # エンジンコアのバージョンを取得。
  # 戻り値 - バージョン文字列の配列
  def version
    res = @http.get('/version')
    valid_response?(res)
    return JSON.parse(res.body)
  end

  private def valid_response?(res)
    if res.code == '200'
      return true
    else
      err = JSON.parse(res.body)
      err['code'] = res.code
      err['message'] = res.message
      raise ProtocolError, err
    end
  end

  private def valid_update_response?(res)
    if res.code == '204'
      return true
    else
      err = JSON.parse(res.body)
      err['code'] = res.code
      err['message'] = res.message
      raise ProtocolError, err
    end
  end

  # 正常なレスポンスが得られなかった時に発生するエラー。
  class ProtocolError < StandardError; end
end
