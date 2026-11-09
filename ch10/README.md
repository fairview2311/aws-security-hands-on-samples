# 第10章　KMSで暗号化し、AWS Backupでランサムウェアから復旧する

本の第10章を終えた時点のファイルです。本のコードの枠の上の「サンプルコード　ch10/…」は、このフォルダのファイルを指します。このフォルダには、それまでの章で使ったファイルもすべて入っています。

この章でできるようになること:

- KMS のカスタマー管理キーで、S3・RDS・EBS を暗号化できる
- RDS への接続を TLS にし、証明書を確かめられる
- ボールトロックで保護したバックアップから、データを復元できる

第9章の終わりに検証環境を削除したので、この章では変更を先に書いてから構築します。約1時間使うと、0.2 USD ほどかかります（2026年11月時点）。

## この章での使い方

コマンドは、Windows は PowerShell、Mac はターミナルで実行します。本では、第1章で作る作業用フォルダ `aws-security-book` のファイルを書き換えながら進みます。このフォルダは書き換えた後の状態なので、自分のファイルとの比較に使います。AWS の料金は読者の負担で、攻撃の手順は自分が管理する AWS アカウントのリソースにだけ実行します（[リポジトリのトップ](../README.md)の「最初に読んでください」）。途中の章から始めるときは、トップの「途中の章から始めるとき」を見てください。

1. 本の手順で作業用フォルダのファイルを書き換え、`terraform apply` を実行して `yes` と入力します。20分ほどかかります。

   ```text
   terraform apply
   ```

2. データの削除と復元を試した後、次の順で削除します。`--recovery-point-arn` は、控えた値に置き換えます。1行目の後は、`wait` が終わるまで数分待ちます。最後の `terraform destroy` では `yes` と入力します。Windows と Mac で同じコマンドです。

   ```text
   aws rds delete-db-instance --db-instance-identifier aws-security-book-db-restored --skip-final-snapshot
   aws rds wait db-instance-deleted --db-instance-identifier aws-security-book-db-restored
   aws backup delete-backup-vault-lock-configuration --backup-vault-name aws-security-book-vault
   aws backup delete-recovery-point --backup-vault-name aws-security-book-vault --recovery-point-arn arn:aws:rds:ap-northeast-1:123456789012:snapshot:awsbackup:job-0123abcd
   terraform destroy
   ```

## うまくいったかの確かめ方

- `terraform apply` の前の確認で `Plan: 60 to add, 0 to change, 0 to destroy.` と表示される
- 復元したデータベースからデータが戻る（本の第4節）

動作しないときは、本の第10章の「うまくいかないとき」を見てください。

<details>
<summary>第9章からの変更（追加・変更したファイル 7 個）</summary>

- 追加: [`app/rds-ca.pem`](app/rds-ca.pem)
- 追加: [`backup.tf`](backup.tf)
- 追加: [`kms.tf`](kms.tf)
- 変更: [`app/app/db.py`](app/app/db.py)
- 変更: [`ec2.tf`](ec2.tf)
- 変更: [`rds.tf`](rds.tf)
- 変更: [`s3.tf`](s3.tf)

</details>

← [ch09](../ch09)　｜　[一覧](../README.md)　｜　[ch11](../ch11) →
