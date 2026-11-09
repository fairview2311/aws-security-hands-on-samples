# AWSセキュリティ対策の教科書 サンプルコード

書籍『AWSセキュリティ対策の教科書 乗っ取り・情報漏洩・脆弱性を最新の設定で防ぐハンズオン』（早瀬 透）のサンプルコードです。

## 最初に読んでください（免責事項と料金）

- **攻撃の手順は、自分が管理する AWS アカウントのリソースにだけ実行してください。** 他人のシステムに実行すると、不正アクセス禁止法などの法律に触れます。手順に書かれたリクエストの数を増やしたり、ほかの宛先に送ったりしないでください。DoS・DDoS、ポートフラッディング、リクエストフラッディングなどは、[AWS の侵入テストの方針](https://aws.amazon.com/jp/security/penetration-testing/)で禁止されています
- **AWS の利用料金は読者の負担です。** 削除を忘れたリソースの料金も同じです。検証環境は、構築している間ずっと料金がかかります
- **この本専用の検証用アカウントを新しく作成することを強く推奨します。** 脆弱な設定のある環境を意図的に構築するので、会社や本番のアカウントでは実施しないでください
- **章の終わりに `terraform destroy` を実行してください。** 手順は、各章のフォルダの README と本の各章の終わりにあります。途中でエラーが出て止まったときも、削除してから休んでください
- この本の手順を実施しても、攻撃や不正アクセス、情報漏洩を完全に防げるとは限りません。それらによって生じた損害について、著者は責任を負いません
- **このコードは、学習のために意図的に脆弱な設定を含みます。本番環境に流用しないでください。** コードは現状のまま提供し、動作や安全性を保証しません（ライセンスは [LICENSE](LICENSE) のとおりです）
- AWS の画面・機能・料金は変わることがあります。本の内容は、2026年11月時点で確かめたものです

料金の目安は、2026年11月時点の東京リージョンで、第1章の構成が1時間あたり約 0.08 USD、CloudFront と AWS WAF を追加した第8章と第9章の構成が1時間あたり約 0.14 USD です。全章を通した総額は、進める速さと無料期間の有無で変わります。第1章で設定する AWS Budgets の通知で、実際の料金を確認しながら進めてください。予算の通知は料金の上限ではなく、予算を超えても AWS のリソースは止まりません。

AWS Shield Advanced は有効にしないでください。1年間の契約が条件で、月額 3,000 USD がかかります。

## このリポジトリの中身

本では、架空の会社「みどり文具株式会社」の顧客管理アプリを、わざと脆弱な設定を残した状態で AWS に構築し、章ごとに攻撃を試して対策します。このリポジトリには、**各章を終えた時点の Terraform のコードとアプリ**が、章ごとのフォルダ（`ch01`〜`ch14`）に入っています。実在の会社・人物とは関係ありません。

- 書いたコードが動かないとき、本のとおりのファイルと比較する
- 本のコードを打つ代わりに、ここからコピーして貼り付ける
- 途中の章から読み始めるとき、前の章の終わりの状態をそろえる

といった使い方をしてください。

## 書籍

『AWSセキュリティ対策の教科書 乗っ取り・情報漏洩・脆弱性を最新の設定で防ぐハンズオン』（早瀬 透）

## 動かすのに必要なもの

- Windows か Mac のパソコン
- AWS アカウント（この本専用の検証用アカウントを推奨）
- Terraform と AWS CLI（AWS CLI は `aws login` が使える 2.32.0 以上）
- Python 3.12 以上と pip
- テキストエディター（VS Code など。Windows のメモ帳は、保存すると名前の後ろに `.txt` を付けることがあるので使いません）

インストールと設定の手順は、本の第1章にあります。本の手順は、次のバージョンで確かめました（2026年11月8日時点）。

- Terraform 1.17.1
- Terraform の AWS プロバイダー 6.72.0
- AWS CLI 2.38.5
- Python 3.15.2

## ダウンロードと置き場所

このページの上の緑の［Code］を押し、［Download ZIP］を押します。ZIP ファイル（`aws-security-hands-on-samples-main.zip`）を展開すると、`ch01`〜`ch14` が並んだフォルダができます。`git clone` で取得してもかまいません。

1つのファイルだけを見たい・コピーしたいときは、下の表の章のフォルダを押し、ファイル名を押して開きます。中身の右上の、四角が2つ重なったボタン（マウスポインターを合わせると「Copy raw file」と表示されます）でコピーできます。

本では、サンプルコードのフォルダの外に、作業用フォルダ `aws-security-book` を1つだけ作って、最後までそこで作業します。パスワードを書くファイルを、サンプルコードと混ぜないためです。

```text
ホームフォルダ
├── aws-security-book          ← 作業用フォルダ（第1章で ch01 をコピーして作る）
│   ├── *.tf                   ← 各章で書き換える Terraform のコード
│   ├── terraform.tfvars       ← 自分の値を書くファイル
│   ├── terraform.tfstate      ← Terraform が作ったリソースの記録
│   └── app/wheels             ← 第1章でダウンロードするパッケージ
└── （展開した場所）aws-security-hands-on-samples-main
    └── ch01 〜 ch14           ← このリポジトリ。章を終えた時点のファイル
```

## 本のコードとファイルの対応

本のコードの枠の上には、次のような行があります。

```text
サンプルコード　ch04/secrets.tf
```

この行は、そのコードの枠が、このリポジトリの `ch04` フォルダの `secrets.tf` と同じ内容であることを示します。「（一部）」と付いた枠は、ファイルの一部だけを見せています。前後の行は、フォルダのファイルで確かめてください。

## 章ごとのフォルダ

`chNN` フォルダには、**第N章を終えた状態のファイル**が、それまでの章の分も含めてすべて入っています。**その章での使い方は、各フォルダを開くと下に表示されます。**

| 章 | 章を終えた状態 | フォルダ |
|---|---|---|
| 第1章　責任共有モデルを理解し、Terraformで検証環境を構築する | 脆弱な設定を残した検証環境と、操作の記録（CloudTrail） | [ch01](ch01) |
| 第2章　ルートユーザーとIAMユーザーをMFAで保護する | MFA が無い操作を拒否するポリシーを追加 | [ch02](ch02) |
| 第3章　アクセスキーを廃止し、一時的な認証情報に切り替える | 試しに使う顧客名簿を追加 | [ch03](ch03) |
| 第4章　Secrets Managerでパスワードを管理し、自動でローテーションする | パスワードを Secrets Manager に移した | [ch04](ch04) |
| 第5章　IAMポリシーを最小権限にし、IAM Access Analyzerで検証する | アプリのロールを最小権限に絞った | [ch05](ch05) |
| 第6章　S3ブロックパブリックアクセスとバケットポリシーで情報漏洩を防ぐ | バケットの公開をやめ、署名付き URL で画像を表示する | [ch06](ch06) |
| 第7章　IMDSv2・セキュリティグループ・Session ManagerでEC2を保護する | IMDSv2 だけを許し、EC2 をプライベートサブネットに移した | [ch07](ch07) |
| 第8章　CloudFrontとAWS WAFでSQLインジェクションとXSSをブロックする | CloudFront と AWS WAF を追加し、アプリのコードも直した | [ch08](ch08) |
| 第9章　Amazon InspectorとPatch Managerで脆弱性を検出・修正する | ライブラリを修正されたバージョンに更新した | [ch09](ch09) |
| 第10章　KMSで暗号化し、AWS Backupでランサムウェアから復旧する | KMS の暗号化と、ボールトロック付きのバックアップを追加 | [ch10](ch10) |
| 第11章　CloudTrail・VPCフローログ・WAFのログをAthenaで分析する | ログを S3 に集め、Athena で調べられる | [ch11](ch11) |
| 第12章　GuardDutyで脅威を検出し、EventBridgeで通知する | GuardDuty の検出結果をメールで受け取れる | [ch12](ch12) |
| 第13章　Security Hubのセキュリティ標準でアカウント全体を評価する | Security Hub と FSBP の標準を Terraform で有効にし、不合格の項目を直した | [ch13](ch13) |
| 第14章　不正アクセスされたEC2を隔離し、Detectiveで調査して復旧する | Detective を追加した | [ch14](ch14) |

## 最初から進めるとき

1. 本の第1章のとおり、AWS アカウント・作業用の IAM ユーザー・Terraform・AWS CLI を準備します
2. `ch01` をコピーして、作業用フォルダ `aws-security-book` を作ります（手順は本の第1章）
3. 各章で、本の手順どおりに作業用フォルダのファイルを書き換え、`terraform apply` を実行します
4. うまくいかないときは、その章のフォルダのファイルと比較します
5. 章を終えて続きを別の日にするときは、`terraform destroy` で検証環境を削除します。次の章は、その章の1つ前のフォルダのファイルで作り直せます

## 途中の章から始めるとき

1つ前の章のフォルダを使います。第5章から読むなら `ch04` です。本の第1章の AWS アカウント・作業用の IAM ユーザー・AWS CLI の準備を済ませてから、次の順に進めます。

1. サンプルコードを展開したフォルダ（`ch01` などのフォルダが並んでいるフォルダ）に `cd` で移動し、1つ前の章のフォルダを作業用フォルダとしてコピーします。次の例は `ch04` のときです。`aws-security-book` がすでにあると、その中に入れ子でできてしまいます。古い作業用フォルダで `terraform destroy` を実行してから、名前を変更します。

   Windows（PowerShell）:

   ```text
   Copy-Item -Recurse ch04 $HOME\aws-security-book
   cd $HOME\aws-security-book
   ```

   Mac（ターミナル）:

   ```text
   cp -R ch04 ~/aws-security-book
   cd ~/aws-security-book
   ```

2. `terraform.tfvars.example` を `terraform.tfvars` という名前でコピーし（Windows は `Copy-Item`、Mac は `cp`）、エディターで自分の値を書きます。書く値は、フォルダによって違います。

   - `ch01`〜`ch03` — `allowed_cidr`・`ssh_public_key`・`db_password`・`app_password`
   - `ch04`〜`ch06` — `allowed_cidr`・`ssh_public_key`
   - `ch07`〜`ch11` — `allowed_cidr`
   - `ch12`〜`ch14` — `allowed_cidr`・`alert_email`

   `allowed_cidr` は、https://checkip.amazonaws.com に表示される自分の IP アドレスに `/32` を付けた値です。`ssh_public_key` を書くフォルダでは、本の第1章のとおり `ssh-keygen -t ed25519 -f aws-security-book-key` で鍵を作り、公開鍵の1行を貼ります。

3. EC2 用のパッケージを `app/wheels` にダウンロードします。

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

4. `aws login --profile aws-book --region ap-northeast-1` で接続し、環境変数 `AWS_PROFILE` を設定します（Windows は `$env:AWS_PROFILE = "aws-book"`、Mac は `export AWS_PROFILE=aws-book`）。

5. `terraform init` の後、`terraform apply` を実行し、`yes` と入力します。

## 自分のファイルと比較するとき

次のファイルは、本のとおりに進めても、このリポジトリと違っていて問題ありません。

- `terraform.tfvars`（このリポジトリには、書き方の例の `terraform.tfvars.example` だけを置いています）
- `terraform.tfstate` と `.terraform` フォルダ
- `app/wheels` と SSH の鍵

第6章の `macie.tf` は、章の途中で作って章の中で削除するので、`ch06` フォルダにはありません。

## `terraform destroy` では元に戻らないもの

次のものは、`terraform destroy` を実行しても残ります。本の各章の案内のとおりに扱ってください。

- Amazon Inspector — 第9章の終わりに無効にします（`aws inspector2 disable --resource-types EC2 --region ap-northeast-1`）
- 第14章のスナップショット — 第14章の案内のとおり削除します
- 第6章の S3 のブロックパブリックアクセスと、第7章の IMDS の既定 — アカウント全体の設定です。元に戻すコマンドは第14章にあります
- AWS Budgets の予算と IAM ユーザー — 残します（料金はかかりません）

GuardDuty の検出器と Detective の動作グラフは、`terraform destroy` で削除され、元に戻せません。無料期間は、Macie・Security Hub・GuardDuty・Detective が30日間、Inspector が15日間で、アカウントとリージョンごとに1回だけです。

第9章の手順で使う Amazon Inspector は、以前の方式に戻せない変更（拡張 EC2 スキャンの有効化）に関わる可能性があります。既に本番で Inspector を使っているアカウントでは実行しないでください。

## よくあるエラー

- **`ExpiredToken` が出る** — `aws login` の認証情報の期限が切れています。マネジメントコンソールにサインインし直し、`aws login --profile aws-book` を実行します
- **`aws login` で `Invalid choice` と出る** — AWS CLI が 2.32.0 より古いので、新しくします
- **`aws` や `terraform` が見つからない** — インストールの直後は、ターミナル（PowerShell）を開き直します
- **アプリや管理用の入口に接続できない** — IP アドレスが変わった可能性があります。`allowed_cidr` を書き換えて `terraform apply` を実行します
- **第13章の標準が `INCOMPLETE` のままになる** — `terraform apply -replace=aws_securityhub_standards_subscription.fsbp` で標準を有効にし直します

そのほかのエラーは、本の各章の「うまくいかないとき」を見てください。

## 知っておくこと

- `terraform.tfvars` にはパスワードが平文で入ることがあります（第1章〜第3章のフォルダ）。`.gitignore` で Git の管理から外していますが、人に渡さないよう注意してください
- `allowed_cidr` は `/32`（IP アドレス1つ）だけを受け付けます。自宅と職場のように場所が変わったら、書き換えて `terraform apply` を実行し直します
- コマンドは、Windows は PowerShell、Mac はターミナルで実行します
- 本の内容の誤りや、動作しなかったところは、このリポジトリの Issues で教えていただけると助かります
