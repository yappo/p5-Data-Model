use t::Utils;
use Test::More;

my $is_running = 0;
plan skip_all => "Set TEST_Q4M environment variable to run this test"
    unless $ENV{TEST_Q4M};
$is_running = 1;

use Data::Model::Driver::Queue::Q4M;

plan tests => 46;

my $dsn = $ENV{Q4M_DSN} || 'dbi:mysql:database=test';
my $driver = Data::Model::Driver::Queue::Q4M->new(
    dsn      => $dsn,
    username => '',
    password => '',
    timeout  => 2, # quickly
);

{
    package MyQueue;
    use base 'Data::Model::Extend::Queue::Q4M';
    use Data::Model::Schema;

    base_driver $driver;

    install_model smtp => schema {
        column id
            => char => {};
        column data
            => int => {};
    };

    install_model pop => schema {
        column id
            => char => {};
        column data
            => int => {};
    };
}

my $model = MyQueue->new;
teardown_schema($dsn, $model->schema_names);
setup_schema( $dsn => MyQueue->as_sqls );


# illegal parameter
do {
    eval {
        $model->queue_running(
            1,
        );
    };
    like $@, qr/illegal parameter/, 'illegal parameter';
};

# required is callback handler
do {
    eval {
        $model->queue_running( pop => 1 );
    };
    like $@, qr/required is callback handler/, 'required is callback handler';
};

# missing model name error
do {
    eval {
        $model->queue_running(
            table => sub {},
        );
    };
    like $@, qr/'table' is missing model name/, 'missing model name';

    eval {
        $model->queue_running(
            pop   => sub {},
            table => sub {},
        );
    };
    like $@, qr/'table' is missing model name/, 'missing model name';
};

# timeout
do {
    my $retval = $model->queue_running(
        smtp => sub {},
        pop  => sub {},
    );
    ok(!$retval, 'timeout');
};


# select queue once
do {
    $model->set(
        smtp => {
            id   => 'foo',
            data => 1,
        }
    );
    my $retval = $model->queue_running(
        smtp => sub {
            my $row = shift;
            is($row->id, 'foo', 'id: foo');
            is($row->data, 1, 'data: 1');
        },
    );
    is($retval, 'smtp', 'queue running is success: smtp');
};

# select queue conditional
do {
    $model->set(
        smtp => {
            id   => 'foo',
            data => 100,
        }
    );
    my $retval = $model->queue_running(
        'smtp:data>50' => sub {
            my $row = shift;
            is($row->id, 'foo', 'id: foo');
            is($row->data, 100, 'data: 100');
        },
    );
    is($retval, 'smtp', 'queue running is success: smtp');
};

# select queue
do {
    for my $table (qw/ smtp pop /) {
        for my $i (1..5) {
            $model->set(
                $table => {
                    id   => "foo: $table",
                    data => $i,
                }
            );
        }
    }

    for my $i (1..10) {
        my $retval = $model->queue_running(
            smtp => sub {
                my $row = shift;
                is($row->id, 'foo: smtp', 'id: foo: smtp');
                is($row->data, $i, "data: $i");
            },
            pop  => sub {
                my $row = shift;
                is($row->id, 'foo: pop', 'id: foo: pop');
                is($row->data, $i - 5, "data: $i");
            },
        );
        my $table = ($i < 6) ? 'smtp' : 'pop';
        is($retval, $table, "queue running is success: $table");
    }
};

# queue_abort
do {
    $model->set(
        smtp => {
            id   => 'abort',
            data => 20,
        }
    );

    eval {
        $model->queue_running(
            smtp => sub { die 'ouffu' }
        );
    };
    like($@, qr/ouffu/, 'aborting queue_running');

    my $retval = $model->queue_running(
        smtp => sub {
            my $row = shift;
            ok($row, 'running queue');
        },
    );
    is($retval, 'smtp', 'queue_running is success');
};

# overraide timeout
do {
    eval {
        local $SIG{ALRM} = sub { ok(1, 'timeout'); die 'timeout'; };
        alarm(3);
        $model->queue_running(
            smtp    => sub {},
            timeout => 10,
        );
    };
    like($@, qr/timeout/, 'timeout queue_running');
};


END {
    teardown_schema($dsn, $model->schema_names)
        if $is_running;
}
