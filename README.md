AsciiDoc Trial
==============

# ビルドまでにやること

## フォントを入れる

* 源真ゴシック( http://jikasei.me/font/genshin/ )をインストールする
* Ricty( https://rictyfonts.github.io/ )をインストールする

※ Font Book を起動し、フォントリストが表示されているところに TTF ファイルをまとめて drag & drop でOK。

## Java を新しくする。

openjdk-14 にしたい。

```
$ brew cask list java
```

とすると

```
==> Generic Artifacts
/Library/Java/JavaVirtualMachines/openjdk-14.0.1.jdk (443 files, 308.4MB)
```

などと出力される。これが 14.0 より古い場合、

```
$ brew cask install java
```

あるいは

```
$ brew cask reinstall java
```

として、 openjdk-14 か、それ以降(これを書いている時点では 14.0.1 が最新)にする。

## asciidoctor 等

asciidoctor 等 を入れる。

```
$ brew cask install java
$ bundle install
$ bundle exec asciidoctor-pdf-cjk-kai_gen_gothic-install
$ npm install
```

`npm install` は要らないかも(未確認)

# ビルド

```
$ bundle exec rake pdf
```

→ `public/book.pdf` ができる。

# 参考にした情報

* https://qiita.com/machu/items/4a133e83f58f82459e56
* https://qiita.com/toshimin/items/cb9b0581f557b132ac50
