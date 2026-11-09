# 第9章　Amazon InspectorとPatch Managerで脆弱性を検出・修正する

本の第9章を終えた時点のファイルです。本のコードの枠の上の「サンプルコード　ch09/…」は、このフォルダのファイルを指します。このフォルダには、それまでの章で使ったファイルもすべて入っています。

この章でできるようになること:

- Inspector で EC2 の OS とライブラリの脆弱性を調べられる
- 修正されたバージョンにライブラリを更新し、Patch Manager で OS にパッチを適用できる

検証環境の料金は、1時間あたり約 0.14 USD です（2026年11月時点）。Inspector は、有効にした日から15日間は無料で試せます。Inspector は以前の方式に戻せない変更に関わる可能性があるので、既に本番で Inspector を使っているアカウントでは実行しません。

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

2. 本の手順で作業用フォルダのファイルを書き換えます。`app/requirements.txt` を更新したら、新しいバージョンのパッケージをダウンロードしてから `terraform apply` を実行し、`yes` と入力します。

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

3. 作業を終えるときは、`terraform destroy` を実行して `yes` と入力します。Inspector は、試用が終わった後に料金がかからないよう、無効にします。

   ```text
   terraform destroy
   aws inspector2 disable --resource-types EC2 --region ap-northeast-1
   ```

## うまくいったかの確かめ方

- `app/wheels` に `jinja2-3.1.6` と `requests-2.34.2` で始まるファイルができる
- 本の第4節の確かめで、更新したライブラリの検出結果が無くなる

動作しないときは、本の第9章の「うまくいかないとき」を見てください。

<details>
<summary>第8章からの変更（追加・変更したファイル 2 個）</summary>

- 変更: [`app/requirements.txt`](app/requirements.txt)
- 変更: [`user_data.sh.tftpl`](user_data.sh.tftpl)

</details>

← [ch08](../ch08)　｜　[一覧](../README.md)　｜　[ch10](../ch10) →
