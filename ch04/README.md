# 第4章　Secrets Managerでパスワードを管理し、自動でローテーションする

本の第4章を終えた時点のファイルです。本のコードの枠の上の「サンプルコード　ch04/…」は、このフォルダのファイルを指します。このフォルダには、それまでの章で使ったファイルもすべて入っています。

この章でできるようになること:

- データベースのパスワードを RDS に管理させ、7日ごとにローテーションしている
- 設定ファイル・起動スクリプト・Terraform の state にパスワードが残らない
- シークレットはリソースポリシーで、使うロールだけが取り出せる

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

2. 本の第4章の手順で、作業用フォルダのファイルを書き換えます。`secrets.tf` は、このフォルダのファイルと同じ内容です。`terraform.tfvars` からは、`db_password` と `app_password` の2行を削除します（`terraform.tfvars.example` を参照）。

3. 変更を2回に分けて反映します。`yes` と入力します。先に RDS を変更し、RDS のシークレットができてから残りを反映するためです。

   ```text
   terraform apply '-target=aws_db_instance.main'
   terraform apply
   ```

4. 作業を終えるときは、作業用フォルダで次のコマンドを実行し、`yes` と入力して検証環境を削除します。

   ```text
   terraform destroy
   ```

## うまくいったかの確かめ方

- マネジメントコンソールの Secrets Manager で、シークレットのローテーションが7日ごとに設定されている（本の図4-7）

動作しないときは、本の第4章の「うまくいかないとき」を見てください。

<details>
<summary>第3章からの変更（追加・変更したファイル 10 個）</summary>

- 追加: [`secrets.tf`](secrets.tf)
- 変更: [`app/app/db.py`](app/app/db.py)
- 変更: [`app/app/settings.py`](app/app/settings.py)
- 変更: [`app/tests/test_settings.py`](app/tests/test_settings.py)
- 変更: [`ec2.tf`](ec2.tf)
- 変更: [`outputs.tf`](outputs.tf)
- 変更: [`rds.tf`](rds.tf)
- 変更: [`terraform.tfvars.example`](terraform.tfvars.example)
- 変更: [`user_data.sh.tftpl`](user_data.sh.tftpl)
- 変更: [`variables.tf`](variables.tf)

</details>

← [ch03](../ch03)　｜　[一覧](../README.md)　｜　[ch05](../ch05) →
