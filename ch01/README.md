# 第1章　責任共有モデルを理解し、Terraformで検証環境を構築する

本の第1章を終えた時点のファイルです。本のコードの枠の上の「サンプルコード　ch01/…」は、このフォルダのファイルを指します。このフォルダには、それまでの章で使ったファイルもすべて入っています。

この章でできるようになること:

- わざと脆弱な設定を残した検証環境を Terraform で構築できる
- CloudTrail の証跡で、すべてのリージョンの操作を記録している

この章で作る検証環境の料金は、東京リージョンで1時間あたり約 0.08 USD（2026年11月時点）です。作業を終えたら、必ず削除します。

## この章での使い方

コマンドは、Windows は PowerShell、Mac はターミナルで実行します。本では、第1章で作る作業用フォルダ `aws-security-book` のファイルを書き換えながら進みます。このフォルダは書き換えた後の状態なので、自分のファイルとの比較に使います。AWS の料金は読者の負担で、攻撃の手順は自分が管理する AWS アカウントのリソースにだけ実行します（[リポジトリのトップ](../README.md)の「最初に読んでください」）。途中の章から始めるときは、トップの「途中の章から始めるとき」を見てください。

1. `ch01` などのフォルダが並んでいるフォルダに `cd` で移動し、作業用フォルダを作ってコピーします。Mac の Finder では「.」で始まるファイルが隠れていて、全部を選んでもコピーされないことがあるので、必ずコマンドでコピーします。

   Windows（PowerShell）:

   ```text
   Copy-Item -Recurse ch01 $HOME\aws-security-book
   cd $HOME\aws-security-book
   ```

   Mac（ターミナル）:

   ```text
   cp -R ch01 ~/aws-security-book
   cd ~/aws-security-book
   ```

2. `terraform.tfvars.example` を `terraform.tfvars` という名前でコピーします。

   Windows（PowerShell）:

   ```text
   Copy-Item terraform.tfvars.example terraform.tfvars
   ```

   Mac（ターミナル）:

   ```text
   cp terraform.tfvars.example terraform.tfvars
   ```

3. SSH の鍵を作ります。パスフレーズを聞かれたら、何も入力せずに Enter（Mac は return）を2回押します。公開鍵の中身は、Windows は `Get-Content aws-security-book-key.pub`、Mac は `cat aws-security-book-key.pub` で表示します。

   ```text
   ssh-keygen -t ed25519 -f aws-security-book-key
   ```

4. エディターで `terraform.tfvars` を開き、4つの値を二重引用符の中に書きます。`allowed_cidr` は https://checkip.amazonaws.com に表示される IP アドレスに `/32` を付けた値、`ssh_public_key` は公開鍵の1行です。`db_password` は8〜128文字で、`/`・`'`・`"`・`@`・空白は使えません。

5. EC2 用のパッケージを `app/wheels` にダウンロードします。最後に `Successfully downloaded` と表示されれば成功です。

   Windows（PowerShell）:

   ```text
   python -m pip download -r app/requirements.txt -d app/wheels --platform manylinux2014_aarch64 --platform manylinux_2_28_aarch64 --platform manylinux_2_17_aarch64 --python-version 3.12 --implementation cp --only-binary=:all:
   ```

   Mac（ターミナル）:

   ```text
   python3 -m pip download -r app/requirements.txt -d app/wheels \
     --platform manylinux2014_aarch64 --platform manylinux_2_28_aarch64 \
     --platform manylinux_2_17_aarch64 --python-version 3.12 \
     --implementation cp --only-binary=:all:
   ```

6. AWS に接続し、環境変数 `AWS_PROFILE` を設定します。`aws login` の前に、作業用のユーザーでマネジメントコンソールにサインインしておきます。AWS アカウント・作業用の IAM ユーザー・`aws-book` の設定は、本の第1章の手順で用意します。ターミナルを開き直したら、環境変数をもう一度設定します。

   Windows（PowerShell）:

   ```text
   aws login --profile aws-book --region ap-northeast-1
   $env:AWS_PROFILE = "aws-book"
   ```

   Mac（ターミナル）:

   ```text
   aws login --profile aws-book --region ap-northeast-1
   export AWS_PROFILE=aws-book
   ```

7. 検証環境を構築します。`terraform apply` では `yes` と入力します。全体で10分ほどかかります。

   ```text
   terraform init
   terraform plan
   terraform apply
   ```

8. 作業を終えるときは、作業用フォルダで次のコマンドを実行し、`yes` と入力して検証環境を削除します。

   ```text
   terraform destroy
   ```

## うまくいったかの確かめ方

- `terraform plan` の最後の行が `Plan: 37 to add, 0 to change, 0 to destroy.` になる
- `aws cloudtrail get-trail-status --name aws-security-book-trail --query IsLogging` で `true` と表示される
- `terraform destroy` の最後に `Destroy complete! Resources: 37 destroyed.` と表示される

動作しないときは、本の第1章の「うまくいかないとき」を見てください。

<details>
<summary>このフォルダのファイル</summary>

第1章の検証環境の Terraform のコードと、顧客管理アプリの `app` フォルダです。`logging.tf` は、この章で確かめる操作の記録（CloudTrail）の設定です。

</details>

[一覧](../README.md)　｜　[ch02](../ch02) →
