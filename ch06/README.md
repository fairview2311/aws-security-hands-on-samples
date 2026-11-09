# 第6章　S3ブロックパブリックアクセスとバケットポリシーで情報漏洩を防ぐ

本の第6章を終えた時点のファイルです。本のコードの枠の上の「サンプルコード　ch06/…」は、このフォルダのファイルを指します。このフォルダには、それまでの章で使ったファイルもすべて入っています。

この章でできるようになること:

- バケットとアカウントのブロックパブリックアクセスで、S3 の公開を止められる
- 画面に出す画像は、署名付き URL で短い間だけ見せられる
- SSE-C での書き込みを拒否し、Macie でバケットの中の機密データを探せる

検証環境の料金は、1時間あたり約 0.08 USD（2026年11月時点）です。第8節の `macie.tf` は、確かめ終わったら章の中で削除するので、このフォルダにはありません。アカウント全体のブロックパブリックアクセスは、`terraform destroy` では元に戻りません。

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

- 本の第7節の確かめで、公開バケットの読み出しが `403` になる
- SSE-C の書き込みが `AccessDenied` になる（本の第5節）

動作しないときは、本の第6章の「うまくいかないとき」を見てください。

<details>
<summary>第5章からの変更（追加・変更したファイル 6 個）</summary>

- 追加: [`tools/make_test_cards.py`](tools/make_test_cards.py)
- 変更: [`app/app/main.py`](app/app/main.py)
- 変更: [`app/app/storage.py`](app/app/storage.py)
- 変更: [`app/tests/test_storage.py`](app/tests/test_storage.py)
- 変更: [`ec2.tf`](ec2.tf)
- 変更: [`s3.tf`](s3.tf)

</details>

← [ch05](../ch05)　｜　[一覧](../README.md)　｜　[ch07](../ch07) →
