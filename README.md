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
$ brew cask info java | head -1
```

として、
```
java: 14.0.1,7:以下略
```

よりも古い場合、

```
$ brew cask install java
```

あるいは

```
$ brew cask reinstall java
```

とする。

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
