---
title: "PhantomData<T>とtrait境界"
date: 2022-05-15T11:29:48Z
lastmod: 2022-05-15T11:29:48Z
draft: false
---

いつもだったらTwitterで「にゃーん」といっておしまいにしてしまう些細な引っ掛かりを，敢えて書き起こしてみる．

## TL:DR

`PhantomData<T>`の`T`のtrait境界のせいで実装した（と思った）`Clone`, `Copy`がはがされて悲しかった😢という話．

[playgroundのサンプルコード](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=24830c5237335c4e896c747592892413)．

## 導入

例えば，様々なエンティティのIDとなる型をジェネリクスを使って定義したとする．
`PhantomData`はその名の通り実態のない型である．（[Rust By Example参照](https://doc.rust-jp.rs/rust-by-example-ja/generics/phantom.html)）

```rust
#[derive(Debug, Clone, Copy, PertialEq, Eq, Ord, PertialOrd, Hash)]
pub struct Id<T> {
    id: u32,
    _marker: PhantomData<T>,
}
```

`User`というエンティティの場合，以下のように`Id`を利用する．

```rust
#[derive(Debug)]
pub struct User {
    pub id: Id<Self>,
    pub name: String,
}
```

このイディオム？を利用すると大量の`SomeEntityId`みたいなstructの定義をサボることができる．

## 悲しかったこと

これが出来ない．

```rust
fn main() {
    let user = User::new();
    let user_id = user.id.clone();
    println!("{:?}, {:?}", user, user_id);
}
```

こんなエラーを吐く．

```
error[E0599]: the method `clone` exists for struct `Id<User>`, but its trait bounds were not satisfied
  --> src/main.rs:39:27
   |
6  | pub struct Id<T> {
   | ----------------
   | |
   | method `clone` not found for this
   | doesn't satisfy `Id<User>: Clone`
...
21 | pub struct User {
   | --------------- doesn't satisfy `User: Clone`
...
39 |     let user_id = user.id.clone();
   |                           ^^^^^ method cannot be called on `Id<User>` due to unsatisfied trait bounds
   |
note: the following trait bounds were not satisfied because of the requirements of the implementation of `Clone` for `_`:
      `User: Clone`
  --> src/main.rs:5:17
   |
5  | #[derive(Debug, Clone, Copy, PartialEq, Eq, Ord, PartialOrd, Hash)]
   |                 ^^^^^
   = help: items from traits can only be used if the trait is implemented and in scope
   = note: the following trait defines an item `clone`, perhaps you need to implement it:
           candidate #1: `Clone`
   = note: this error originates in the derive macro `Clone` (in Nightly builds, run with -Z macro-backtrace for more info)
help: consider annotating `User` with `#[derive(Clone)]`
   |
21 | #[derive(Clone)]
   |
```

要は，`Id<T>`には`Clone`が実装されているが，`User`には`Clone`が実装されていないため，`Id<User>`では，
`Clone`がはがされて？怒られている．（これは`Copy`や，そのたderiveしたはずのtraitでも同様である．）

つまり，`Id<User>`の中の，`_marker: PhantomData<User>`に`Clone`が実装されていないことが問題となっている[^1]．
しかし，PhantomDataは実態のない型であって，実際のところ `id: u32`が`Clone`できるのだから，`Clone`出来てしまって欲しかった😢
（これが出来てしまったらそれはそれで問題な気もするが，どう問題になるのかまでは考えていない）

## おわりに

というわけで，このケースで`Clone`する裏ワザがあったら教えてください (`Id<T>`をやめる，`impl Clone for User`，`impl Clone for Id<User>`を除く)．

[^1]: このサンプルでは，`User`に`Clone`を実装すれば解決するが，`User`のフィールドに `Clone`できないものがある場合など，`User`に`Clone`を実装できない場合も考えられる．
