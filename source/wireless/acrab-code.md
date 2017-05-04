# 無線制御(Acrabの実装解説)
- 書いた人: Kenichi Ito(nichiden_27)
- 更新日時: 2017/04/18
- 実行に必要な知識・技能: Web制作、JavaScript
- 難易度: 3/練習・勉強が必要
- 情報の必須度: 4/担当者には必須

## 概要
[無線制御(Acrab)](acrab.html)から`Acrab`の具体的な実装の解説を分離した記事です。

`Acrab`のソースコードを読む、あるいは書き換える際に参考にしてください。

## acrab_conf.json
`Acrab`の設定ファイルである。
JSONファイルのため構造の概略のみ示す。
```
├── "ip" [Pisciumとの通信用]
│   ├── "N" [北天受信機のIPアドレス]
│   └── "S" [南天受信機のIPアドレス]
├── "port" [出力ポート用]
│   ├── "And" [星座or投影機名の三文字コード]
│   │   ├── "name" [ボタンに表示する名前]
│   │   ├── "box" [北天なら"N"/南天なら"N"/両方なら"NS"]
│   │   └── "pin" [投影機とピン番号の対応]
│   └── (以下同様)
└── "group" [星座や投影機のグループを定義]
    ├── "Set" [全点灯の三文字コード]
    │   └── "name" [ボタンに表示する名前]
    ├── "Cle" [全消灯の三文字コード]
    │   └── "name" [ボタンに表示する名前]
    ├── "Spc" [グループ名の三文字コード]
    │   ├── "name" [ボタンに表示する名前]
    │   └── "value" [配列: グループに属する星座or投影機を列挙]
    └── (以下同様)
```
三文字コードというのは、プログラム中で**星座・投影機・そのグループ**を区別するため一意に割り振った三文字を指す。
星座にはもともと[この形式の略符が用意されている](http://www.nao.ac.jp/new-info/constellation2.html)こともあり、文字数を統一して可読性を高めることを目指した。

例えば星座絵のピン番号を入れ替える際には、`port.(星座名).pin`を書き換えれば良い。
`Piscium`側に設定を反映させるためページをリロードすること。

## acrab_main.js
`Acrab`全体に関わるコードや、「メイン」画面で使用するコードを記述した。

### 読み込み時の処理
ページを読み込んだ後に一度だけ実行したい処理がある。
JSはスクリプト言語なので、main関数のようなものはなくコードの頭から順に読み込まれる。

通常は関数を定義しても呼び出されるまで何も起こらないが、`(function(){})()`の形式のものは読み込んだ時点で実行される。
これを**即時関数**といい、初期設定の適用などに使える。

また、コード中に`$(function(){})`もあるが、これは即時関数ではない。
$がついたものはjQueryの**readyイベント**といい、**HTMLが全てロードされた時点で実行される**。
ページを書き換えるような処理ではページが読み込まれていないと意味がないので、こちらを使うようにしよう。

即時関数・readyイベントで行っている処理は以下の通り。

- `acrab_conf.json`の取得とパース
    - `$.getJSON()`を使うだけ
- `port`と`group`の`name`をボタンに表示
    - `$.each()`で配列の全要素にループ処理できる
- ピン番号の設定を`Piscium`に送信(`pinSettingSend()`)
- 各ボタンにclickイベントを追加
    - `.main_button`というクラスの要素を取得して`$.each()`
    - HTMLに手作業で書くのが面倒なので、クラスからボタンの種類を判定して最適な関数を実行する仕組み
- 更新ボタン、明るさスライダーの処理を追加
- タブの切り替え
    - 各タブの画面はそれぞれ`.content`クラスに入っている
    - 一度全てを非表示にした後、押したタブの順番と同じ順番の画面のみ表示する

開発の途中に順次追加したのでかなりグチャグチャになっている。
自由に読みやすく変更して構わない。

本番まで気づかなかったため未修正だが、実は**コード先頭の即時関数もreadyイベントにすべき**である。
「`port`と`group`の`name`をボタンに表示」する処理がHTML読み込み後でないとできないからだ。
稀にだが`acrab_conf.json`が読み込まれない不具合はこれが原因と思われる。

### getRequest(address, data)
`address`にURLパラメータとして`data`を付けて送信する関数。
jQueryの`get()`や`Deferred`を使用している。
```js
data = data || {}
console.info(address + ': ' + JSON.stringify(data));
var deferred = $.Deferred(); // 非同期通信なので完了時にデータを渡す処理
$.get({
  url: address, dataType: 'json', timeout: 1000, data: data
}).done(function(res) {
  console.debug(res);
  if(address.match(ip.N)) $('#wifi-icons #north').text('正常受信中').removeClass('error');
  else if(address.match(ip.S)) $('#wifi-icons #south').text('正常受信中').removeClass('error');
  deferred.resolve(res);
}).fail(function(xhr) {
  console.error(xhr.status+' '+xhr.statusText);
  if(address.match(ip.N)) $('#wifi-icons #north').text('接続なし').addClass('error');
  else if(address.match(ip.S)) $('#wifi-icons #south').text('接続なし').addClass('error');
  deferred.reject;
});
return deferred;
```
`$.get()`は、指定したURLにGETリクエストを送信する。
`data`に連想配列を指定するとURLパラメータに整形してくれる嬉しい機能付きだ。
また、通信が切れている時に固まらないよう、1000msのタイムアウトを設定している。

その後の`.done()`や`.fail()`にはそれぞれ通信成功時・失敗時の処理を書く。
ここでは通信するたびにブラウザコンソールに結果を出力し、受信状況の欄を更新するようになっている。

さて、`Piscium`にコマンドを送ると、**各ポートの状態を0か1で表したjsonデータ** が返る。
`dataType: 'json'`としておけばパースまでやってくれるようだ。
これを関数の戻り値としたいが、これには工夫が必要になる。

`$.get()`のようなAjax通信は**非同期処理**を採用しており、リクエストを送った後応答を待たずに関数が終了してしまう。
そのため、送られてくるはずのデータを戻り値に入れることができない。

そこで、`$.Deferred`を利用する。
ググれば出てくるため詳細は省くが、Deferredオブジェクトを一旦返し**通信が終了してからデータを格納する**ことができる。
また、通信が失敗した場合`deferred.reject`すると以上終了させることもできる。

### checkStatus(stat)
`Piscium`から送られてくるjsonをパースしたオブジェクトから**各星座絵・投影機のオンオフ状況を確認する**。
基本的に`getRequest()`で通信した後はこれを呼ぶようにして、表示を常に最新に保つべきである。
`getRequest()`は非同期関数なので、以下のコード片のように`.done()`を使う。
```js
getRequest(address, data).done(function(res){checkStatus(res)});
```
ボタンはHTML側で以下のように三文字コードのIDが振られている。
````HTML
<!-- index.html -->
<button class="main_button constellation" id="And">And</button>
````
三文字コードは`port`や`group`に入っているので、`$.each()`ループを回して巡回する。
各ボタンに`on`クラスを追加すると色などが変わる仕組みだ。
```js
  $.each(port, function(key){ // 星座|投影機ごと
    if(stat[key] === 1) $('[id='+key+']').addClass('on');
    else if(stat[key] === 0) $('[id='+key+']').removeClass('on');
  });
```
`group`に関しても基本は変わらないが、こちらは**属している星座絵全てが点灯していなければオンにならない**。
例えば、「夏の大三角」ボタンを押すと「こと/わし/はくちょう」が点灯するが、このうち一つでも消すと「夏の大三角」もオフの表示になる。
```js
  $.each(group, function(key){ // 星座グループごと
    if(!this.value) return;
    var isOn = true;
    $.each(this.value, function(){isOn &= $('#'+this).hasClass('on');}); // 各星座がオンかどうかのANDをとる
    if(isOn) $('[id='+key+']').addClass('on');
    else $('[id='+key+']').removeClass('on');
  });
  return;
}
```

### pinSettingSend()
`Piscium`には、`(ip)/setConstellationName/status.json`にアクセスすることでピンごとに名前を設定する機能がある。
これで`(ip)/setPort/status.json?And=0`のように三文字コードをURLに使えるようになり、ユーザが見てもわかりやすい。

`acrab_conf.json`が読み込まれた後のタイミングで実行される。
`port.(三文字コード).pin`の中身を順に取得して`getRequest()`に渡すという流れである。

### buttonオブジェクト
メイン画面のボタンは、**星座絵/投影機/全点(消)灯/グループ** の四種類ある。
それぞれに合った処理をするため、`button`オブジェクトを作成し必要なメソッドをまとめるようにした。

#### 星座絵: button.constellation(obj)
星座絵は南天か北天に分かれている。
南北は`port[(三文字コード)].box`から判定し、受信機のアドレスを`ip[(NかS)]`で取得する。

また、ボタンのオンオフ状態と逆の真偽値を`data`に入れておく。
後は`getRequest()`を呼んで終了する。
```js
var address = ip[port[obj.id].box] + 'setPort/status.json';
var data = {}
data[obj.id] = button.stat(obj);
getRequest(address, data).done(function(res){checkStatus(res)});
return;
```

#### 投影機: button.projector(obj)
星座絵以外の投影機は南北両方に付いているのが普通である。
そのため**受信機の数だけ同じリクエストを送る**必要がある。
`ip`の各要素について`$.each()`を回すことでこれを実現する。
```js
$.each(ip, function(){
  var address = this + 'setPort/status.json';
  var data = {};
  data[obj.id] = button.stat(obj);
  getRequest(address, data).done(function(res){checkStatus(res)});
});
return;
```

#### 全点(消)灯: button.all(obj)
`Piscium`側の全点灯(allSet)・全消灯(allClear)を使う場合。
コードは`button.projector(obj)`と似ているので省略。

`Piscium`側の負荷の関係で、今のところ全点灯は使うべきでないようだ。

#### グループ: button.group(obj)
「夏の大三角」「黄道十二星座」と言った星座のグループ。
実はこれが一番面倒である。
理由は**各星座絵が南北にばらけていることがある**ため。

そのため、

1. `ip`からIPアドレスを取得してURLを作成
1. `group[(三文字コード).value]`で`$.each()`を回し、南北判定していずれかの`data`に追加
1. `req`オブジェクトに南北それぞれのデータを入れ、`getRequest()`

という手順を踏んでいる。

実は、本番前にさらに一段階手順を増やした。
星座絵を10個弱同時に点灯すると電源が不安定化する事象を確認したため、回避のため**少数ずつ分けて点灯する**よう変更したのである。
このため新たに`each_slice()`と`sleep_ms()`という関数を定義した。
これらの詳細は後述する。

#### ボタンの状態を取得する: button.stat(obj)
ボタンがオンかオフかは、`on`クラスを持っているかどうかで分かる。
`stat()`にボタンのオブジェクトを渡すと、現在の状態の逆の値を返す。
```js
return ($(obj).hasClass('on') ? 0 : 1);
```

### each_slice(obj, n)
投影機を複数点灯・消灯する際一回あたりの数を抑えるのに使用する。
`obj`にオブジェクトを、`n`に最大数を指定すると`obj`をn要素ごとに切り分けたオブジェクトの配列を返す。
```js
each_slice({"Ari":1,"Cnc":1,"Gem":1,"Leo":1,"Aqr":1,"Cap":1,"Psc":1},3)
-> [{"Ari":1,"Cnc":1,"Gem":1},{"Leo":1,"Aqr":1,"Cap":1},{"Psc":1}]
```
ただし、例外として"St1"と"St2"をキーにもつ場合は1要素のオブジェクトに分ける。
これは、こうとうの負荷があまりに大きいため他の投影機と同時に点灯することを避けるためである。

アルゴリズムとしては、n要素ずつ切ったものをfor文内でオブジェクトに追加していくだけなのでコードは省略する。

### sleep_ms(T)
`getRequest()`が`each_slice()`により複数回に別れる場合に、間隔を十分取るための関数。
これがマイコンならば`delay()`のような関数が標準で用意されるところだが、ブラウザにはそんなものはないので作るしかない。
下のコードを見れば分かるように、ひたすら時刻を取得して最初との差が`T`を超えたら抜けるという作戦になっている。
```js
var d = new Date().getTime();
var dd = new Date().getTime();
while(dd < d+T) dd = new Date().getTime();
```

遅らせる時間だが、100 msとした。
LEDの突入電流が流れる時間は数ms程度なので、十分大きくかつ人間には長すぎない程度と判断している。

## scenarioディレクトリ
`scenario/`以下には、0.jsonから連番のJSONファイルが入っている。
これは、番組の指示書を`Acrab`から読み取れるようJSON形式に変換したものである。

### n.json
JSONファイルの構造を簡単に示す。
```
├── "info" [番組情報]
│   ├── "day" [(ライブ解説の場合)何日目か]
│   ├── "title" [番組名]
│   └── "name" [担当者名]
└── "script" [配列: 指示が入る部分]
    ├── 0
    │   ├── "word" [セリフ: 0番目は空欄にする]
    │   ├── "timing" [タイミング: 0番目は空欄にする]
    │   └── "projector" [投影機]
    │       ├── "(三文字コード)" [点灯なら1/消灯なら0]
    │       └── (以下同様)
    ├── 1
    │   ├── "word" [セリフ]
    │   ├── "timing" [タイミング]
    │   └── "projector" [投影機]
    │       ├── "(三文字コード)" [点灯なら1/消灯なら0]
    │       └── (以下同様)
    └── (以下同様)
```
`info`オブジェクト内には、番組のメタデータに相当する情報が入っている。
番組選択画面で番組を選びやすくする為、`day`に**公演日**の情報も入れるようにした。
なお、ソフトは駒場祭を通じて上演されるので実際には(ソフト,一日目,二日目,三日目)の四つに分かれる。

`script`以下が**セリフやタイミング**を格納する部分である。
配列の形で並べてあり、上から順番に時系列で並んでいる必要がある。

配列の0番目は特別な部分で、公演の**開始前から点灯**したい投影機に使用する。
このため、先頭のセリフとタイミングは空欄にする必要がある。

`timing`に`pre`を指定すると「(セリフ)の**言い始め**」、`post`を指定すると「(セリフ)の**言い終り**」と画面に表示される。
セリフの前後以外のタイミングを指定したければ、「〜の」につながる形で**自由に書けばそのまま表示**される。

最後に、JSONファイルの例を示しておく。
```json
{
  "info": {
    "day": "sample",
    "title": "とてもわかりやすい星座解説",
    "name": "星見太郎"
  },
  "scenario":[
    {
      "timing": "",
      "word": "",
      "projector": {
        "Fst": 1,
        "Gxy": 1
      }
    }, {
      "timing": "post",
      "word": "プラネタリウムはいかがでしょう",
      "projector": {
        "St1": 1,
        "St2": 1
      }
    }
  ]
 }
```

### csv/jsonify.py
CSVで記述した指示書データをJSONに変換するスクリプト。
CSVファイル側は、タイミングや投影機などのフィールドをJSON変換用に準備しておく必要がある([Acrabの記事](acrab.html)も参照)。

(CSVの記述例)
```
word,timing,projector
,,"{""Fst"": 1, ""Gxy"": 1}"
プラネタリウムはいかがでしょう,post,"{""St1"": 1, ""St2"": 1}"
```
文字コードがUTF-8になっているのを確認したら、`jsonify.py`で変換しよう。
```python
# jsonify.py
# change encode to utf-8 with iconv etc.
import codecs,csv,json
result = str([json.dumps(l, ensure_ascii=False) for l in csv.DictReader(codecs.open('1.csv', 'rU'))])
print(result.replace('\'','"').replace('\\"','"').replace('"{','{').replace('}"','}').replace('"}','}').decode('string-escape'))
```
筆者がPythonに慣れてないのでわざわざCSVのファイル名をコードに書く必要がある。
改良等ご自由に。

`codecs.open()`のオプションに"rU"とつけているのは改行文字対策(らしい、多分コピペした)。
あとは[pythonでcsv-jsonの変換ツールを作るときに困ったこと](http://qiita.com/hakuaneko/items/768da80393545ec67073)あたりを参考にJSONに変換している。
`ensure_ascii=False`は日本語の文字化けを防ぐため必要のようだ。

この時点の`result`の中身は、例えば次のようになっている(改行は見やすくするため挿入)。
```python
[
    '{"timing": "", "word": "", "projector": "{\"Fst\": 1, \"Gxy\": 1}"}',
    '{"timing": "post", "word": "プラネタリウムはいかがでしょう", "projector": "{\"St1\": 1, \"St2\": 1}"}'
]
```
このままでは**JSONとして読むことはできない**。
まず、Pythonで使われる**シングルクオート**(`'`)は、JSONでは使用が認められていない。
また、CSVの中に無理やり複数項目を書いていた部分が、**バックスラッシュ**(`\`)でエスケープ(ただの文字として扱うこと)されてしまった。

うまい方法を思いつかないので、文字列置換の繰り返しで対応することにした。
置換が全て終わると、以下のような文字列が吐き出される。
```json
[
    {"timing": "", "word": "", "projector": {"Fst": 1, "Gxy": 1}},
    {"timing": "post", "word": "プラネタリウムはいかがでしょう", "projector": {"St1": 1, "St2": 1}}
]
```
これならJSONとしてそのまま読み込める。
実際には、`info`の部分などを付け足して`Acrab`用JSONファイルの完成となる。

## acrab-scenario.js
「公演用画面」のためのコード。
分量が多くなったためmainと分けることにした。
(執筆中)
### 指示書ファイルの読み込み
前述の通り、指示書は番組ごとに連番のJSONファイルに分けて`scenario/`以下に保存されている。
`acrab_main.js`と同様に、jQueryの`$.getJSON()`を用いて取得とパースを行っている。

問題は`Acrab`がブラウザ側だけで動作していることで、サーバに**いくつの指示書ファイルがあるか取得できない。**
苦肉の策として`SCENARIO_COUNT`という定数にファイル数を事前に入れておくことで対応した。
あまり良い方法とは言えないので、「**設定ファイルの一覧を書く設定ファイル**」を配置しておくなど拡張性の高い方法に変更すべきだろう。
これなら、ファイル名を連番の数字にする必要もなくなる。
```js
for(var i=0;i<SCENARIO_COUNT;i++) scenario_file[i] = $.getJSON('scenario/'+ i +'.json');
```

指示書ファイルを取得したら、番組選択メニューにタイトルと担当者名を追加する。
`<option>`や`<optgroup>`というのはHTMLのセレクトボックス用のタグで、前者が選択項目、後者が項目をまとめる見出しだ。
特に工夫したわけではないので特に解説はしない。
ググりながらコードを読んで理解してほしい。

最後の`$('select#select').change()`は、セレクトボックスが更新された際に呼ばれるメソッドを指定している。
`getScenarioData()`については後述するが、指示書のデータを画面に表示するものである。
```js
  /*** Initialize select box ***/
  $.when.apply($, scenario_file).done(function(){ // シナリオファイルが全部取得できたら<option>と<optgroup>追加
    $.each(arguments, function(index){ // argumentsに取得したjsonが全部入ってるのでそれぞれ読む
      var init_info = this[0].info;
      var $dayGroup = $('#select > optgroup[label='+init_info.day+']'); // <option>を入れる<optgroup>
      if(!$dayGroup[0]){
        $('#select').append($('<optgroup>', {label: init_info.day}));
        $dayGroup = $('#select > optgroup[label='+init_info.day+']');
      }
      $dayGroup.append($('<option>', {
        value: index,
        text: init_info.name + ' -  ' + init_info.title
      }));
    });
    $('select#select').change(function(){
      getScenarioData($(this).val());
    });
  }).fail(function(xhr){console.error(xhr.status+' '+xhr.statusText);});
  getScenarioData(0);
```

```js
function getScenarioData(num){
  console.debug('getScenarioData called. num: '+num);
  $.when($.getJSON('scenario/'+ num +'.json')).done(function(data){
    info = data.info;
    scenario = data.scenario;
    scenarioInit();
  });
}

function scenarioInit(){
  $('#scenario_prev').html('(前のシーンが表示されます)').addClass('scenario0').attr('onclick', 'goPrev();').prop('disabled', true);
  viewScript('#scenario_now', 0);
  $('#scenario_now').addClass('scenario1').prop('disabled', true);
  viewScript('#scenario_next', 1);
  $('#scenario_next').addClass('scenario2').attr('onclick', 'goNext();').prop('disabled', true);
  $('#scenario_number').html('1/' + scenario.length);
  $('#progress_bar progress').attr('pass_time', '00:00:00');
}

var timer_button = new function(){
  this.start = function(){
    sendComm(0, 0);
    $('#select').prop('disabled', true);
    $('#scenario_next').prop('disabled', false);
    timer = setInterval(function(){pass_time++; readTime();}, 1000);
    $('#timer_start').hide();
    $('#timer_stop').show();
    $('#timer_reset').prop('disabled', true);
  };
  this.stop = function(){
    clearInterval(timer);
    $('#timer_stop').hide();
    $('#timer_restart').show();
    $('#timer_reset').prop('disabled', false);
  };
  this.restart = function(){
    timer = setInterval(function(){pass_time++; readTime();}, 1000);
    $('#timer_restart').hide();
    $('#timer_stop').show();
    $('#timer_reset').prop('disabled', true);
  };
  this.reset = function(){
    pass_time = 0;
    readTime();
    scenarioInit();
    $('#select').prop('disabled', false);
    $('#timer_restart').hide();
    $('#timer_start').show();
    $('#timer_reset').prop('disabled', true);
    $('#scenario_prev').removeClass(function(index, className) {
          return (className.match(/\bscenario\S+/g) || []).join(' ');
    });
    $('#scenario_now').removeClass(function(index, className) {
          return (className.match(/\bscenario\S+/g) || []).join(' ');
    });
    $('#scenario_next').removeClass(function(index, className) {
          return (className.match(/\bscenario\S+/g) || []).join(' ');
    });
  };
  var pass_time = 0;
  var readTime = function(){
    var hour     = toDoubleDigits(Math.floor(pass_time / 3600));
    var minute   = toDoubleDigits(Math.floor((pass_time - 3600*hour) / 60));
    var second   = toDoubleDigits((pass_time - 3600*hour - 60*minute));
    $('#progress_bar progress').attr('pass_time', hour + ':' + minute + ':' + second);
    var progress = Math.min(pass_time / 1500.0, 1); // 25 minutes
    $('#progress_bar progress').attr('value', progress);
    return;
  };
  var toDoubleDigits = function(num){return ('0' + num).slice(-2);}; // sliceで時刻要素の0埋め
};

function goNext(){
  $.each(['scenario_prev', 'scenario_now', 'scenario_next'], function(){
    var num = $('#'+this).get(0).className.match(/\d/g).join('') / 1; // 数字だけ取り出して渡す(型変換しないとうまくいかなかった)
    $('#'+this).removeClass($('#'+this).get(0).className).addClass('scenario' + (num+1));
    if(num+1 > scenario.length) $('#'+this).html('(原稿の最後です)').prop('disabled', true);
    else{
      if(this == 'scenario_now') sendComm(num, 0);
      viewScript('#'+this, num);
    }
  });
  $('#scenario_number').html($('#scenario_now').get(0).className.match(/\d/g).join('') + '/' + scenario.length);
}

function goPrev(){
  $.each(['scenario_prev', 'scenario_now', 'scenario_next'], function(){
    var num = $('#'+this).get(0).className.match(/\d/g).join('') / 1; // 数字だけ取り出して渡す(型変換しないとうまくいかなかった)
    $('#'+this).removeClass($('#'+this).get(0).className).addClass('scenario' + (num-1));
    if(num-1 <= 0) $('#'+this).html('(前のシーンが表示されます)').prop('disabled', true);
    else{
      if(this == 'scenario_now') sendComm(num-1, 1);
      viewScript('#'+this, num-2);
    }
  });
  $('#scenario_number').html($('#scenario_now').get(0).className.match(/\d/g).join('') + '/' + scenario.length);
}

function sendComm(index, reverse){
  var data = $.extend(true, {}, scenario[index].projector);
  if(reverse) $.each(data, function(key){
    data[key] = this == 1 ? 0 : 1;
  });
  $.each(ip, function(){
    address = this + 'setPort/status.json';
    sliced_data = each_slice(data, 5);
    $.each(sliced_data, function(){
      getRequest(address, this).done(function(res){checkStatus(res)});
      sleep_ms(100);
    });
  });
}

function viewScript(id, index){
  if($(id).is(':disabled'))$(id).prop('disabled', false);
  $(id).html(function(){
    var res = ''
    if(!scenario[index].word) res += '開始前'
    else {
      res += '「'+scenario[index].word+'」の';
      switch(scenario[index].timing){
        case 'pre': res += '言い始め'; break;
        case 'post': res += '言い終り'; break;
        default: res +=  scenario[index].timing; break;
      }
    }
    res += '<br>';
    $.each(scenario[index].projector, function(key,index){
      res += '[' +port[key].name + (this == 1 ? '点灯' : '消灯') + '] ';
    });
    return res;
  });
}
```