# 第7章　IMDSv2・セキュリティグループ・Session ManagerでEC2を保護する

本の第7章を終えた時点のファイルです。本のコードの枠の上の「サンプルコード　ch07/…」は、このフォルダのファイルを指します。このフォルダには、それまでの章で使ったファイルもすべて入っています。

この章でできるようになること:

- EC2 に IMDSv2 だけを許し、SSRF での認証情報の窃取を止められる
- EC2 をプライベートサブネットに移し、SSH を閉じられる
- EC2 に Session Manager で接続できる

検証環境の料金は、1時間あたり約 0.08 USD に、この章で追加する VPC エンドポイントの分の約 0.04 USD を加えた額です（2026年11月時点）。IMDS の既定は、`terraform destroy` では元に戻りません。

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

2. 作業用フォルダの `terraform.tfvars` から `ssh_public_key` の行を削除します。残すのは `allowed_cidr` の行だけです（`terraform.tfvars.example` を参照）。

3. 本の手順で、作業用フォルダのファイルを書き換えて `terraform apply` を実行します。書き換えた結果は、このフォルダのファイルと同じになります。

4. 作業を終えるときは、作業用フォルダで次のコマンドを実行し、`yes` と入力して検証環境を削除します。

   ```text
   terraform destroy
   ```

## うまくいったかの確かめ方

- 本の第6節の確かめで、IMDS へのトークンなしの要求が `401` になる

動作しないときは、本の第7章の「うまくいかないとき」を見てください。

<details>
<summary>第6章からの変更（追加・変更したファイル 10 個）</summary>

- 変更: [`app/app/storage.py`](app/app/storage.py)
- 変更: [`app/tests/conftest.py`](app/tests/conftest.py)
- 変更: [`app/tests/test_storage.py`](app/tests/test_storage.py)
- 変更: [`ec2.tf`](ec2.tf)
- 変更: [`network.tf`](network.tf)
- 変更: [`outputs.tf`](outputs.tf)
- 変更: [`security_groups.tf`](security_groups.tf)
- 変更: [`terraform.tfvars.example`](terraform.tfvars.example)
- 変更: [`user_data.sh.tftpl`](user_data.sh.tftpl)
- 変更: [`variables.tf`](variables.tf)

</details>

← [ch06](../ch06)　｜　[一覧](../README.md)　｜　[ch08](../ch08) →
