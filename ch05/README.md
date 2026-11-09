# 第5章　IAMポリシーを最小権限にし、IAM Access Analyzerで検証する

本の第5章を終えた時点のファイルです。本のコードの枠の上の「サンプルコード　ch05/…」は、このフォルダのファイルを指します。このフォルダには、それまでの章で使ったファイルもすべて入っています。

この章でできるようになること:

- アプリのロールを、使う操作とリソースだけに絞れる
- 使われていない権限を、最終アクセス日時で見つけられる
- ポリシーを、入れる前に `validate-policy` と `check-access-not-granted` で点検できる

検証環境の料金は、1時間あたり約 0.08 USD（2026年11月時点）です。

## この章での使い方

コマンドは、Windows は PowerShell、Mac はターミナルで実行します。本では、第1章で作る作業用フォルダ `aws-security-book` のファイルを書き換えながら進みます。このフォルダは書き換えた後の状態なので、自分のファイルとの比較に使います。AWS の料金は読者の負担で、攻撃の手順は自分が管理する AWS アカウントのリソースにだけ実行します（[リポジトリのトップ](../README.md)の「最初に読んでください」）。途中の章から始めるときは、トップの「途中の章から始めるとき」を見てください。

1. 作業用フォルダに移動して、環境変数を設定し、検証環境を構築します。`yes` と入力します。

   Windows（PowerShell）:

   ```text
   cd $HOME\aws-security-book
   $env:AWS_PROFILE = "aws-book"
   terraform apply
   ```

   Mac（ターミナル）:

   ```text
   cd ~/aws-security-book
   export AWS_PROFILE=aws-book
   terraform apply
   ```

2. 本の手順で、作業用フォルダのファイルを書き換えて `terraform apply` を実行します。書き換えた結果は、このフォルダのファイルと同じになります。

3. 作業を終えるときは、作業用フォルダで次のコマンドを実行し、`yes` と入力して検証環境を削除します。

   ```text
   terraform destroy
   ```

## うまくいったかの確かめ方

- 本の第7節の確かめで、盗んだ権限の操作が `AccessDenied` になる

動作しないときは、本の第5章の「うまくいかないとき」を見てください。

<details>
<summary>第4章からの変更（追加・変更したファイル 2 個）</summary>

- 追加: [`policies/validate-example.json`](policies/validate-example.json)
- 変更: [`ec2.tf`](ec2.tf)

</details>

← [ch04](../ch04)　｜　[一覧](../README.md)　｜　[ch06](../ch06) →
