AsciiDoc Trial
==============

# ビルドまでにやること

* 源真ゴシック( http://jikasei.me/font/genshin/ )をインストールする
* Ricty( https://rictyfonts.github.io/ )をインストールする

```
$ brew cask install java
$ bundle install
$ bundle exec asciidoctor-pdf-cjk-kai_gen_gothic-install
$ gem pristine numo-narray --version 0.9.1.6
$ npm install
```

# ビルド

```
$ bundle exec rake pdf
```

# 参考にした情報

https://qiita.com/machu/items/4a133e83f58f82459e56
https://qiita.com/toshimin/items/cb9b0581f557b132ac50
