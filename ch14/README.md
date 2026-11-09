# 第14章　不正アクセスされたEC2を隔離し、Detectiveで調査して復旧する

本の第14章を終えた時点のファイルです。本のコードの枠の上の「サンプルコード　ch14/…」は、このフォルダのファイルを指します。このフォルダには、それまでの章で使ったファイルもすべて入っています。

この章でできるようになること:

- スナップショットで証拠を残してから、不正アクセスされた EC2 を隔離できる
- IAM ロールの古いセッションを無効にし、Detective で範囲を調べられる
- 点検の一覧表を完成させ、検証環境をすべて削除できる

第13章の後に検証環境を削除したときは、第13章のコードで作り直してから進めます。Detective にはリージョンごと、アカウントごとに30日間の無料トライアルがあります。

## この章での使い方

コマンドは、Windows は PowerShell、Mac はターミナルで実行します。本では、第1章で作る作業用フォルダ `aws-security-book` のファイルを書き換えながら進みます。このフォルダは書き換えた後の状態なので、自分のファイルとの比較に使います。AWS の料金は読者の負担で、攻撃の手順は自分が管理する AWS アカウントのリソースにだけ実行します（[リポジトリのトップ](../README.md)の「最初に読んでください」）。途中の章から始めるときは、トップの「途中の章から始めるとき」を見てください。

1. 本の手順で、作業用フォルダのファイルを書き換えて `terraform apply` を実行します。書き換えた結果は、このフォルダのファイルと同じになります。

2. 本の最後の作業です。作業用フォルダで次のコマンドを実行し、`yes` と入力して検証環境を削除します。Detective の動作グラフも削除され、元に戻せません。

   ```text
   terraform destroy
   ```

3. リソースが残っていないことを確かめます。WAF のログのバケットは us-east-1 にあるので、東京リージョンと us-east-1 の両方を確かめます。Windows と Mac で同じコマンドです。

   ```text
   aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=aws-security-book --query "ResourceTagMappingList[].ResourceARN" --output text
   aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=aws-security-book --query "ResourceTagMappingList[].ResourceARN" --output text --region us-east-1
   aws ec2 describe-snapshots --owner-ids self --filters "Name=tag:Project,Values=aws-security-book" --query "Snapshots[].SnapshotId" --output text
   aws detective list-graphs --query "GraphList[].Arn" --output text
   ```

## うまくいったかの確かめ方

- 手順4のコマンドで何も表示されなければ、削除は完了です

動作しないときは、本の第14章の「うまくいかないとき」を見てください。

<details>
<summary>第13章からの変更（追加・変更したファイル 1 個）</summary>

- 追加: [`detective.tf`](detective.tf)

</details>

← [ch13](../ch13)　｜　[一覧](../README.md)
