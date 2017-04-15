# 無線制御(Acrab)
- 書いた人: Kenichi Ito(nichiden_27)
- 更新日時: 2017/04/13
- 実行に必要な知識・技能: Web制作、JavaScript
- タスクの重さ: 3/数週間
- タスクの必須度: 4/毎年やるべき

## 概要
`Acrab`は、27代で開発した投影機無線操作用Webアプリケーションです。
最新のブラウザ(Chrome推奨)があれば、どんな環境でも使うことができます。

名称は、ブラウザで星座絵などを操れることからApplication for Constellation Remote controlling Assistance on Browserの頭文字をとりました。
さそり座β星の固有名でもあります。

## 使い方
### 下準備
まず、[Acrabの各種ファイル](https://github.com/macv35/nichiden27/tree/master/ACRAB)を同じフォルダに配置する。
ファイルの読み込みにAjaxを使っているので、index.htmlをそのまま開いただけ(file:///)では機能が使えない。
回避方法は「Ajax ローカル」などとググれば複数出てくるが、ローカルにWebサーバを立てる方法を解説する。

Windowsでローカルホストを立てるには、[XAMPP](https://www.apachefriends.org/jp/index.html)を使うのが簡単だ。
GUIなので、操作も分かりやすいだろう。
MacならApacheが標準で入っているはずなので、`sudo apachectl start`を打てば`httpd`が動き出す。
設定については、ググれば役に立つ情報が得られる。

### 起動と接続
localhostにアクセスすれば以下のような画面が表示されるはずだ。
もしボタンに日本語が表示されない場合、設定ファイルの読み込みに失敗しているので再読み込みすること。

![Acrabのメイン画面](_media/acrab-main.png)

次に、`Piscium`との接続を確認する。
`Piscium`の電源が入っていて、Wi-Fiネットワークに接続していれば、画面上の「受信状況」が緑色に変わるはずだ。

もし「接続なし」のままなら、PCと`Piscium`が同じLANに接続しているか(PCが別のルーターに接続してしまうミスは結構ある)、受信モジュールのIPアドレスが正しいかなどを確認しよう。
「受信状況」欄右の更新ボタンを押すと、`Piscium`へのリクエストが再送される。

無事接続できたら下に並ぶボタンを押して投影機をオンオフさせてみよう。
投影機を繋いでいなくても、コマンド自体は送ることができる。
`Piscium`から応答が来なかった場合はボタンの色が変わらないので、不具合に気づける。

### 公演用画面
ソフトの指示を次へ・前へのボタンで実行できるモード。
画面上に「公演用」ボタンがあり、押すと画面が切り替わる。

![Acrabの公演用画面](_media/acrab-scenario.png)

左上のメニューから番組名を選べるので、選んでから「開始」ボタンを押すと一番初めのコマンドが送信される。
下にタイミングが表示されるので、緑色の次へボタンを押して番組を進行する。
前へボタンでは、直前と逆の指示を送信できる。

「開始」した後は左のボタンが「停止」「再開」に変化するが、これは右上のタイマーが止まるだけで深い意味はない。
「リセット」ボタンを押すと、タイマーと番組の進行状況が最初に戻る。

誤操作防止のため、「リセット」は「停止」状態でないとできない。
また、番組選択メニューは「リセット」しなければ操作できない。

## プログラム
`Acrab`はWebの技術を使って通信や画面表示を行っている。
画面の情報はHTML、デザインはCSS、内部処理や画面の書き換えはJavaScript(以下JS)という構成だ。

### ファイル構成
以下のようなディレクトリ構成になっている。
ファイルを動かす際はリンク切れに注意すること。
```
ACRAB
├── acrab_conf.json
├── img
│   ├── acrab-banner.svg
│   ├── main_01.png
│   ├── main_02.png
│   └── (省略)
├── index.html
├── js
│   ├── acrab_main.js
│   ├── acrab_scenario.js
│   └── jquery-3.1.0.js
├── scenario
│   ├── 0.json
│   ├── 1.json
│   ├── (省略)
│   └── csv
│       └── (省略)
├── style.css
└── testscript.json
```
`index.html`がAcrabのメインページである。
デザイン関連の記述は`style.css`に分離した。
`acrab_conf.json`には、各種設定が格納されている。

`img/`以下にはページで使用した画像、`js/`以下にはJavaScriptのコードが入っている。
`scenario/`内は、番組の指示書を指定形式で入力したデータ。

### 技術要素
#### HTMLとCSS
最近のWebアプリは、サーバ側でHTMLファイルを動的に生成して送ってくることが多い。
しかし、`Acrab`は**静的なHTMLファイルを準備し、クライアント(ブラウザ)側で書き換える** 方式を採っている。
単に開発が楽であること、サーバ側で作業する必要がないこと、多数のユーザに後悔するような規模でないことがその理由である。

`Acrab`の**ページ構成** を変えたければ`index.html`を、**色やサイズ** なら`style.css`を編集すれば良い。
どちらもググれば分かる程度の機能しか使っていないつもりなので、Webの経験がなくても対応できるだろう。
それぞれの内容についてはここでは触れないが、JS部分と連動する箇所は都度解説する。

#### jQuery
プログラムにはJSを用いていると書いたが、素のJSだけで書くと記述が長くなってしまう。
そこで、jQueryというライブラリを採用している。
動的なページの書き換えやAjaxによるファイル取得などを簡単に書けるようになり、コードを読みやすくできる。

近頃のWebアプリはサーバ側が急速に発展し、jQueryは不要な存在となりつつあるが、`Acrab`はクライアントサイドだけで動作する仕様のためあえて採用した。
数年前の流行りとはいえネット上に解説記事が充実しており、学習が容易であることも採用の理由だ。

jQueryは単一のjsファイルにまとめて配布されるので、最新版をダウンロードして`js/`内に入れておけば使えるようになる。
わざわざダウンロードしておくのは、ネットに接続できない本番ドーム内などでもjQueryを取得できるようにするため。

jQueryの機能は解説しないのでググって補完されたい。
`acrab_main.js`や`acrab_scenario.js`内に頻繁に登場する`$`という文字は、jQueryを呼び出すためのものである。
`$.(メソッド名)`といった形式で各種メソッドを使用できる。

#### JSON
`Acrab`では、各種設定を個別ファイルに分離している。
投影する星座の名称を変えたい、指示書を編集したいと言った要求はいつ来てもおかしくない。
こうした変更に迅速に対応できるよう**JSON**形式の設定ファイルを読み込む方式とした。

JSON(JavaScript Object Notation)は、JavaScriptのオブジェクトの形式でデータを記述するものである。
「JavaScriptのオブジェクト」というのは配列や連想配列を入れ子にした構造を指す。
```js
{
  "hoge": [ 1, null ],
  "fuga": {
    "one": [ true, "tenmon" ],
    "two": "nichiden"
  }
}
```
上の例のように、項目にラベルを付ける、入れ子にするといったことが比較的シンプルな記述で可能になる。
また、オブジェクトなので`.`でラベル名を繋ぐだけでデータを取り出せる(例: `fuga.one[1]`は`"tenmon"`)。
文法がJavaScriptからの流用なので親和性がよく、読み込みが簡単なのも嬉しい。

ただ、文法がたいへん厳しくかつ目で眺めてもミスに気づきにくいので、パースエラーが出ないことを確かめてから使うよう心がけたい。
[JSONLint](http://jsonlint.com/)など、JSONの文法ミスを検出してくれるサービスが存在する。

### acrab_conf.json
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

### acrab_main.js
`Acrab`全体に関わるコードや、「メイン」画面で使用するコードを記述した。

#### 読み込み時の処理
ページを読み込んだ後に一度だけ実行したい処理がある。
JSはスクリプト言語なので、main関数のようなものはなくコードの頭から順に読み込まれる。

通常は関数を定義しても呼び出されるまで何も起こらないが、`(function(){})()`の形式のものは読み込んだ時点で実行される。
これを**即時関数**といい、初期設定の適用などに使える。

また、コード中に`$(function(){})`もあるが、これは即時関数ではない。
$がついたものはjQueryの**readyイベント**といい、**HTMLが全てロードされた時点で実行される**。
ページを書き換えるような処理の場合ページが読み込まれていないと意味がないので、こちらを使うようにしよう。

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

#### getRequest(address, data)
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

#### checkStatus(stat)
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

#### pinSettingSend()
`Piscium`には、`(ip)/setConstellationName/status.json`にアクセスすることでピンごとに名前を設定する機能がある。
これで`(ip)/setPort/status.json?And=0`のように三文字コードをURLに使えるようになり、ユーザが見てもわかりやすい。

`acrab_conf.json`が読み込まれた後のタイミングで実行される。
`port.(三文字コード).pin`の中身を順に取得して`getRequest()`に渡すという流れである。

#### buttonオブジェクト
メイン画面のボタンは、**星座絵/投影機/全点(消)灯/グループ** の四種類ある。
それぞれに合った処理をするため、`button`オブジェクトを作成し必要なメソッドをまとめるようにした。

##### 星座絵: button.constellation(obj)
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

##### 投影機: button.projector(obj)
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

##### 全点(消)灯: button.all(obj)
`Piscium`側の全点灯(allSet)・全消灯(allClear)を使う場合。
コードは`button.projector(obj)`と似ているので省略。

`Piscium`側の負荷の関係で、今のところ全点灯は使うべきでないようだ。

##### グループ: button.group(obj)
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

##### ボタンの状態を取得する: button.stat(obj)
ボタンがオンかオフかは、`on`クラスを持っているかどうかで分かる。
`stat()`にボタンのオブジェクトを渡すと、現在の状態の逆の値を返す。
```js
return ($(obj).hasClass('on') ? 0 : 1);
```

#### each_slice(obj, n)
投影機を複数点灯・消灯する際一回あたりの数を抑えるのに使用する。
`obj`にオブジェクトを、`n`に最大数を指定すると`obj`をn要素ごとに切り分けたオブジェクトの配列を返す。
```js
each_slice({"Ari":1,"Cnc":1,"Gem":1,"Leo":1,"Aqr":1,"Cap":1,"Psc":1},3)
-> [{"Ari":1,"Cnc":1,"Gem":1},{"Leo":1,"Aqr":1,"Cap":1},{"Psc":1}]
```
ただし、例外として"St1"と"St2"をキーにもつ場合は1要素のオブジェクトに分ける。
これは、こうとうの負荷があまりに大きいため他の投影機と同時に点灯することを避けるためである。

アルゴリズムとしては、n要素ずつ切ったものをfor文内でオブジェクトに追加していくだけなのでコードは省略する。

#### sleep_ms(T)
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

### acrab-scenario.js
(執筆中)

## 今後の展望
### 既知の問題
(執筆中)
