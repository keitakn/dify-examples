# Terraformによるインフラ管理

インフラ環境をTerraformで管理しています。

## Getting Started

環境構築手順はMacOSを前提としています。

これらの作業は `dify-examples/terraform/` ディレクトリで行います。

### Terraformのインストール

Terraformをインストールを実行します。

バージョンは以下のファイルを参考にします。

terraform/providers/google/environments/dev/10-dify/versions.tf

基本的に複数バージョンを管理出来るほうが良いので `asdf` 等を使ってバージョン管理を行うことをお勧めします。

```bash
brew install asdf

asdf plugin add terraform

asdf install terraform 1.9.8

asdf local terraform 1.9.8
```

### ディレクトリ構成の説明

```
dify-examples/
  ├ modules/
  │  └ google/
  └ providers/
     └ google/
       └ environments/
         ├ dev/
         │ ├ 10-dify/
         │ ├ 11-xxxx/
         │ └ 22-xxxx/
         └ prod/
           ├ 10-dify/
           ├ 11-xxxx/
           └ 22-xxxx/
```

### 環境分割

本番環境とステージング・開発環境など複数環境に構築するケースを想定し `environments/` 配下に環境ごとのディレクトリを作成しています。

#### 依存関係

`providers` の頭の数字に注目して下さい。

`.tfstate` はこれらのディレクトリ配下毎に存在しますが、数字の大きなディレクトリは数字が小さなディレクトリに依存しています。

その為、必ず数字が小さいディレクトリから `terraform apply` を実行する必要があります。

### Terraformの初期化

#### Google Cloud の認証

TerraformのtfstateはGoogle Cloud上に保存されています。

その為Google Cloudの認証が必要です。


#### GoogleCloudの認証&サービスの有効化

だいたいの人はそうだと思いますが自分は複数のプロジェクトを管理しているので以下のようにプロジェクト毎にGoogleCloudの認証設定を追加しておくと便利です。

#### 1. 各プロジェクト用の設定を作成

```bash
gcloud config configurations create [任意のプロジェクト名]
```

#### 2. 各設定にアカウントとプロジェクトを紐付ける

```bash
gcloud config configurations activate [任意のプロジェクト名]
gcloud auth login [利用するGmailのメールアドレス]
gcloud config set project [GOOGLE_CLOUD_PROJECT_ID]
```

#### 3. 各設定でApplication Default Credentialsを設定

```bash
gcloud config configurations activate [任意のプロジェクト名]
gcloud auth application-default login
gcloud auth application-default set-quota-project [GOOGLE_CLOUD_PROJECT_ID]
```

コマンドの実行前に `gcloud config configurations activate [任意のプロジェクト名]` を実行して対象プロジェクトの認証設定が有効になっている事を確認します。

現在の設定は以下のコマンドで確認可能です。

```bash
gcloud config configurations list
```
ここまで出来たら以下のコマンドを実行してCloudRunに必要な以下のサービスを有効化します。（既に有効化している場合は省略可能です）

```
gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com secretmanager.googleapis.com
```

`gcloud` コマンドが利用出来ない場合は以下でインストールを実施します。

```bash
brew install --cask google-cloud-sdk
```

#### `terraform init` の実行

`terraform/providers/google/environments/dev/10-dify/` ディレクトリに移動して以下のコマンドを実行します。
※ 他の `environments/環境名/◯◯/` ディレクトリでも同様の手順を実施してください。

```bash
terraform init
```

以下のような表示が出力されれば成功です。

```
Initializing the backend...

Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing modules...
Initializing provider plugins...
- Finding hashicorp/google versions matching "6.10.0"...
- Installing hashicorp/google v6.10.0...
- Installed hashicorp/google v6.10.0 (signed by HashiCorp)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

`terraform plan` や `terraform apply` を実行していきます。

## 設計方針

- 今はGoogleのみだが、他のproviderが増えても大丈夫なように providers/ を作ってあります
- 各moduleには特定のリージョンに依存した値はハードコードしない（AZの名前とか）
- 各moduleには特定の環境に依存した値はハードコードしない
- マルチリージョンでの運用にも耐えられるディレクトリ設計

## コーディング規約

以下の命名規則に従って命名します。

| 項目名                   | 命名規則       |
| ------------------------ | -------------- |
| ファイル名               | ケバブケース   |
| ディレクトリ名           | ケバブケース   |
| リソース、データソース名 | スネークケース |
| リソースID               | ケバブケース   |
| 変数名                   | スネークケース |

リソース名とは `resource` や `data` 等のTerraformの予約語に付けられる名前です。

下記の例だと `dify_repo` がそれに該当します。

```hcl
resource "google_artifact_registry_repository" "dify_repo" {
  location        = var.region
  repository_id   = "${var.env}-dify-repo"
  description     = "Artifact Registry for Dify"
  format          = "DOCKER"
}
```

リソースIDとはそのリソースの中で一意になっている必要がある値です。

下記の例だと `repository_id` がそれに該当します。

```hcl
resource "google_artifact_registry_repository" "dify_repo" {
  location        = var.region
  repository_id   = "${var.env}-dify-repo"
  description     = "Artifact Registry for Dify"
  format          = "DOCKER"
}
```

他にもタグ名を良く付ける事がありますが、それもこちらのルールの通りケバブケースで命名します。

このようなややこしい規則になっている理由ですが、RDSCluster等、一部のリソース名で `_` が禁止文字に設定されている為です。

他にもインデント等細かいルールがありますが、こちらに関しては `terraform fmt -recursive` を実行すれば自動整形されるのでこれを利用すれば良いでしょう。

`terraform fmt -recursive` は必ずプロジェクトルートで実行を行ってください。

そうしないと全ての `.tf` ファイルに修正が適応されません。
