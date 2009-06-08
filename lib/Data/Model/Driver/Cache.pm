package Data::Model::Driver::Cache;
use strict;
use warnings;
use base 'Data::Model::Driver';

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;

use Storable ();

sub fallback { shift->{fallback} }
sub cache    { shift->{cache} }

sub _as_sql_hook {
    my $self = shift;
    $self->{fallback}->_as_sql_hook(@_);
}

sub add_to_cache            { Carp::croak("NOT IMPLEMENTED") }
sub update_cache            { Carp::croak("NOT IMPLEMENTED") }
sub remove_from_cache       { Carp::croak("NOT IMPLEMENTED") }
sub get_from_cache          { Carp::croak("NOT IMPLEMENTED") }

sub get_multi_from_cache {
    my($self, $keys) = @_;

    my %got;
    while (my($key, $id) = each %{ $keys }) {
        my $obj = $self->get_from_cache($id->[1]) or next;
        $got{$key} = $obj;
    }
    \%got;
}

sub remove_multi_from_cache {
    my($self, $keys) = @_;
    $self->remove_from_cache($_) for @{ $keys };
}

sub init {
    my $self = shift;
    my %param = @_;
    $self->SUPER::init(@_);
#    $self->cache($param{cache})
#        or Carp::croak("cache is required");
    $self->fallback($param{fallback})
        or Carp::croak("fallback is required");
    $self;
}

# lookupは真面目にキャッシュする
sub lookup {
    my $self = shift;
    return $self->{fallback}->lookup(@_) if $self->{active_transaction};
    my($schema, $id) = @_;

    my $cache_key = $self->cache_key($schema, $id);
    my $ret = $self->get_from_cache($cache_key);
    unless ($ret) {
        $ret = $self->{fallback}->lookup(@_);
        return unless $ret;
        $self->add_to_cache($cache_key, $ret);
    }
    return $ret;
}

# 先に get_multi でキャッシュデータを全部取ってきて、キャッシュから取って来れなければfallbackして取得
sub lookup_multi {
    my $self = shift;
    return $self->{fallback}->lookup_multi(@_) if $self->{active_transaction};
    my($schema, $ids) = @_;

    my %cache_keys = map { join("\0", @{ $_ }) => [ $_, $self->cache_key($schema, $_) ] } @{ $ids };
    my $results = $self->get_multi_from_cache(\%cache_keys);
    if (scalar(keys %cache_keys) == scalar(keys %{ $results })) {
        return $results;
    }

    # make lookup id list
    my @lookup_keys;
    while (my($key, $id) = each %cache_keys) {
        next if $results->{$key};
        push @lookup_keys, $id->[0];
    }

    my $fallback_results = $self->{fallback}->lookup_multi($schema, \@lookup_keys);
    return unless scalar(%{ $results }) || scalar(%{ $fallback_results });
    return $results unless scalar(%{ $fallback_results });

    while (my($key, $val) = each %{ $fallback_results }) {
        $self->add_to_cache($cache_keys{$key}->[1], $val);
        $results->{$key} = $val;
    }

    $results;
}

# key 指定の検索でないならキャッシュ処理しない (未実装)
sub get {
    my $self = shift;
    return $self->{fallback}->get(@_) if $self->{active_transaction};
    return $self->{fallback}->get(@_);
    my($schema, $key, $columns, %args) = @_;

    return $self->{fallback}->get(@_) unless $key && !$columns;

    my $cache_key = $self->cache_key($schema, $key);
    my $ret = $self->get_from_cache($cache_key);
    return $self->{fallback}->get(@_) unless $ret;
    return $ret;
}

# insertはキャッシュ処理を通さない
sub set { shift->{fallback}->set(@_) }

# key で cache を delete するのみ
sub replace {
    my $self = shift;
    my($schema, $key, $columns, %args) = @_;

    if (scalar(@{ $key }) == scalar(@{ $schema->key })) {
        my $cache_key = $self->cache_key($schema, $key);
        return unless $self->remove_cache($cache_key);
    }
    $self->{fallback}->replace(@_);
}


# delete / update は key を指定した処理を主なターゲットとして
# udate_all / delete_all 的なのとかのkeyが判らない物は、いったんその条件でgetしてから、個別のobjectを処理する
# なので、直接keyを指定しないと、ここの処理のパフォーマンスはキャッシュ無しのがさらに早くなる
sub update {
    my $self = shift;
    my($schema, $old_key, $key, $old_columns, $columns, $changed_columns, %args) = @_;

    if (scalar(@{ $old_key }) == scalar(@{ $schema->key })) {
        my $cache_key = $self->cache_key($schema, $old_key);
        return unless $self->remove_cache($cache_key);
    }

   $self->{fallback}->update(@_);
}

sub _delete_cache {
    my($self, $schema, $key, $columns, %args) = @_;

    my($it, $it_opt) = $self->{fallback}->get($schema, $key, $columns ? Storable::dclone($columns) : $columns, %args);
    if ($it) {
        my $is_return;
        while (my $row = $it->()) {
            my $key = $schema->get_key_array_by_hash($row);
            my $cache_key = $self->cache_key($schema, $key);
            unless ($self->remove_cache($cache_key)) {
                $is_return = 1;
                last;
            }
        }
        $it_opt->{end}->() if exists $it_opt->{end} && ref($it_opt->{end}) eq 'CODE';
        return if $is_return;
    }
    return 1;
}

sub update_direct {
    my $self = shift;
    my($schema, $key, $query, $columns, %args) = @_;

    if ($key && !$columns && scalar(@{ $key }) == scalar(@{ $schema->key })) {
        my $cache_key = $self->cache_key($schema, $key);
        return unless $self->remove_cache($cache_key);
    } else {
        return unless $self->_delete_cache($schema, $key, $query, %args);
    }
    $self->{fallback}->update_direct(@_);
}

sub delete {
    my $self = shift;
    my($schema, $key, $columns, %args) = @_;

    if ($key && !$columns && scalar(@{ $key }) == scalar(@{ $schema->key })) {
        my $cache_key = $self->cache_key($schema, $key);
        return unless $self->remove_cache($cache_key);
    } else {
        return unless $self->_delete_cache(@_);
    }
    $self->{fallback}->delete($schema, $key, $columns, %args);
}


sub remove_cache {
    my($self, $cache_key) = @_;
    if ($self->{active_transaction}) {
        push @{ $self->{transaction_delete_queue} }, $cache_key;
    } else {
        $self->remove_from_cache($cache_key);
    }
}

# for transactions
sub txn_begin {
    my $self = shift;
    $self->{active_transaction} = 1;
    $self->{transaction_delete_queue} = [];
    $self->{fallback}->txn_begin;
}

sub txn_rollback {
    my $self = shift;
    return unless $self->{active_transaction};
    $self->{fallback}->txn_rollback;

    $self->{transaction_delete_queue} = [];
}

sub txn_commit {
    my $self = shift;
    return unless $self->{active_transaction};
    $self->{fallback}->txn_commit;

    # apply delete queue
    $self->remove_multi_from_cache($self->{transaction_delete_queue});

    $self->{transaction_delete_queue} = [];
}

sub txn_end {
    my $self = shift;
    $self->{fallback}->txn_end;
    $self->{active_transaction} = 0;
    $self->{transaction_delete_queue} = [];
}

1;
