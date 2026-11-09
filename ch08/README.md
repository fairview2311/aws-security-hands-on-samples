# 第8章　CloudFrontとAWS WAFでSQLインジェクションとXSSをブロックする

本の第8章を終えた時点のファイルです。本のコードの枠の上の「サンプルコード　ch08/…」は、このフォルダのファイルを指します。このフォルダには、それまでの章で使ったファイルもすべて入っています。

この章でできるようになること:

- アプリの入口を CloudFront だけにし、ALB を内部に置ける
- AWS WAF のマネージドルールで、SQL インジェクションと XSS をブロックできる
- アプリを SQL のプレースホルダーと出力のエスケープで直せる

CloudFront と AWS WAF を合わせて、検証環境の料金は1時間あたり約 0.14 USD です（2026年11月時点）。CloudFront の作成と削除には、それぞれ15分ほどかかります。第6節のカウントからブロックへの切り替えは、本の手順のとおり途中で行います。このフォルダはブロックに切り替えた後の状態です。

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

- 本の第7節の確かめで、ALB の種類が `internal` になり、レート制限で `403` が返る

動作しないときは、本の第8章の「うまくいかないとき」を見てください。

<details>
<summary>第7章からの変更（追加・変更したファイル 10 個）</summary>

- 追加: [`cloudfront.tf`](cloudfront.tf)
- 追加: [`waf.tf`](waf.tf)
- 変更: [`alb.tf`](alb.tf)
- 変更: [`app/app/db.py`](app/app/db.py)
- 変更: [`app/templates/customers.html`](app/templates/customers.html)
- 変更: [`app/tests/test_app.py`](app/tests/test_app.py)
- 変更: [`outputs.tf`](outputs.tf)
- 変更: [`security_groups.tf`](security_groups.tf)
- 変更: [`user_data.sh.tftpl`](user_data.sh.tftpl)
- 変更: [`versions.tf`](versions.tf)

</details>

← [ch07](../ch07)　｜　[一覧](../README.md)　｜　[ch09](../ch09) →
