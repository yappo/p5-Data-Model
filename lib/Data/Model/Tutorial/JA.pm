=encoding utf8

=head1 NAME

Data::Model::Tutorial::JA - Data::Model::Tutorial日本語版

=head1 Data::Model とは

id:yappo さんがつくっている O/R Mapper。新興のものでチュートリアル的なものがない
ので自分でかいてみることにしました。

とはいえ、Data::Model 自体がまだまだαクオリティですので、チュートリアルもてぬき
です。

=head1 つかってみる

=head2 DBI を対象につかってみる

Data::Model は、Data::Model のスキーマ定義からCREATE TABLE 文を発行することができ
ます。なので、まずはスキーマ定義を Perl で書きます。

  # lib/Neko/DB/User.pm
  package Neko::DB::User;
  use strict;
  use warnings;
  use base 'Data::Model';
  use Data::Model::Schema sugar => 'myapp';
  use Neko::Columns;
  
  install_model user => schema {
      # primary key
      key 'id';
  
      # カラム定義
      column 'user.id' => { auto_increment => 1 };
      utf8_column 'user.name';
  };
  1;

カラムの詳細な定義は、別ファイルにします。

  # lib/Neko/Columns.pm
  package Neko::Columns;
  use strict;
  use warnings;
  use Data::Model::Schema sugar => 'myapp';
  
  column_sugar 'user.id'
      => int => {
          required => 1,
          unsigned => 1,
      };
  column_sugar 'user.name'
      => 'varchar' => {
          required => 1,
          size     => 255,
      };
  1;

カラムの定義を別ファイルにするというところは、他の O/R Mapper とのおおきな違いで
すね。これによって得られるメリットは「カラム定義の共通化」ですね。たとえば、レコー
ドの作成日付を保存する created_on なんていうのは複数のテーブルで同じ定義をつかい
たいものですから、共通化できると便利です。

=head2 スキーマ定義を実際につかう

これをよびだし、CREATE TABLE 文を発行するには、

  # script/dump_schema.pl
  use strict;
  use warnings;
  use Neko::DB::User;
  use Data::Model::Driver::DBI;
  
  my $dm = Neko::DB::User->new();
  
  do {
      # ドライバ情報をつっこむ
      my $driver = Data::Model::Driver::DBI->new(
          dsn => 'dbi:SQLite:'
      );
      $dm->set_base_driver($driver);
  };
  
  for my $target ($dm->schema_names) {
      for my $sql ($dm->as_sqls($target)) {
          print "$sql\n";
      }
  }

のようにします。driver を各 schema に対して発行するというあたりがポイントになる
かとおもいます。わずらわしいですが、ここはぐっと我慢しましょう。

  # script/crud.pl
  use strict;
  use warnings;
  use Test::More tests => 10;
  use Neko::DB::User;
  use Data::Model::Driver::DBI;
  
  my $dm = Neko::DB::User->new();
  
  # ドライバ情報をつっこむ
  {
      my $driver = Data::Model::Driver::DBI->new(
          dsn => 'dbi:SQLite:'
      );
      $dm->set_base_driver($driver);
  }
  
  # schema のセットアップ
  for my $target ($dm->schema_names) {
      my $dbh = $dm->get_driver($target)->rw_handle;
      for my $sql ($dm->as_sqls($target)) {
          $dbh->do($sql);
      }
  }
  
  # INSERT 文の発行
  $dm->set( 'user' => {
      name => 'yappo'
  });
  $dm->set('user' => {
      name => 'ukonmanaho'
  });
  
  # SELECT 文の発行
  #  スカラコンテキストのときはイテレータ
  {
      my $iterator = $dm->get('user' => {
          order => {'id' => 'ASC'}
      });
      my @names;
      while (my $row = $iterator->next) {
          push @names, $row->name;
      }
      is join(',', @names), 'yappo,ukonmanaho';
  }
  
  # リストコンテキストのときは配列
  {
      my @users = $dm->get('user' => {order => { 'id' => 'DESC' }});
      is scalar(@users), 2;
      is $users[0]->name, 'ukonmanaho';
      is $users[1]->name, 'yappo';
  }
  
  # 条件つきで検索
  {
      my @users = $dm->get('user' => {
          where => [
              name => 'yappo'
          ],
      });
      is scalar(@users), 1;
      is $users[0]->name, 'yappo';
  }
  
  # update
  {
      my ($ukon, ) = $dm->get('user' => {
          where => [
              name => 'ukonmanaho'
          ],
      });
      is $ukon->name, 'ukonmanaho';
      $ukon->name('jack');
      $ukon->update;
  }
  
  # delete
  {
      my $count_users = sub {
          scalar(my @users = $dm->get('user'));
      };
  
      is $count_users->(), 2;
  
      my ($jack, ) = $dm->get('user' => {
          where => [
              name => 'jack'
          ],
      });
      is $jack->name, 'jack';
      $jack->delete;
  
      is $count_users->(), 1;
  }

に、簡単な SELECT/INSERT/UPDATE/DELETE の例をのせておきました。

=head2 Memcached をつかってみる

Data::Model ではストレージとして SQLite の他に memcached protocol によるデータの
保存にも対応しています。ここではいわゆる hash database 的なものをつかうことが想定
されています。Tokyo Tyrant などをストレージとして、Data::Model でデータをあつかえ
るということです。

Memcached をつかう場合の例は下記のスクリプトにおいてあります。

  # script/memcached.pl
  use strict;
  use warnings;
  use Test::More tests => 2;
  use Neko::DB::User;
  use Data::Model::Driver::Memcached;
  use Cache::Memcached::Fast;
  
  my $dm = Neko::DB::User->new();
  
  # ドライバ情報をつっこむ
  {
      my $driver = Data::Model::Driver::Memcached->new(
          memcached => Cache::Memcached::Fast->new({
              servers => [
                  '127.0.0.1:11211',
              ],
          }),
      );
      warn $dm->set_base_driver($driver);
  }
  
  # INSERT
  warn $dm->set( 'user' => 1, {
      name => 'yappo'
  });
  warn $dm->set('user' => 2, {
      name => 'ukonmanaho'
  });
  
  # SELECT
  {
      my ($yappo) = $dm->get('user' => 1);
      warn $yappo;
      is $yappo->name, 'yappo';
  }
  {
      my ($ukonmanaho) = $dm->get('user' => 2);
      warn $ukonmanaho;
      is $ukonmanaho->name, 'ukonmanaho';
  }

=head2 キャッシュを使ってみる

DBI や Memcached のストレージへのアクセスするさいに Memcached などのキャッシュを
挟む事が出来ます。の、予定。

=head2 Q4M

=head1 カラム定義の詳細

=head1 クエリメソッドのオプションや絞り込み方法など

=head2 get

=head2 lookup

=head2 lookup_multi

=head2 set

=head2 replace

=head2 update

=head2 delete

=head1 Mixin について

=head1 trigger について

=head1 このドキュメントの作者

tokuhirom (original http://github.com/tokuhirom/data-model-tutorial/tree/master)

yappo (加筆修正)

=cut
