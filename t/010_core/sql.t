# based Data::ObjectDriver's t/11-sql.t
use strict;
use warnings;

use Data::Model::SQL;
use Test::More tests => 95;

sub ns { Data::Model::SQL->new }

my $stmt = ns();
ok($stmt, 'Created SQL object');

## Testing FROM
$stmt->from('foo');
is($stmt->as_sql, "FROM foo\n");

$stmt->from('foo', 'bar');
is($stmt->as_sql, "FROM foo, bar\n");

## Testing JOINs
$stmt->from([]);
$stmt->joins([]);
$stmt->add_join(foo => { inner => { baz => 'foo.baz_id = baz.baz_id' }});
is($stmt->as_sql, "FROM foo INNER JOIN baz ON foo.baz_id = baz.baz_id\n");

$stmt->from('bar');
is($stmt->as_sql, "FROM foo INNER JOIN baz ON foo.baz_id = baz.baz_id, bar\n");

$stmt->from([]);
$stmt->joins([]);
$stmt->add_join(foo => [
        { inner => { 'baz b1' => 'foo.baz_id = b1.baz_id AND b1.quux_id = 1' }},
        { left  => { 'baz b2' => 'foo.baz_id = b2.baz_id AND b2.quux_id = 2' }},
    ]);
is $stmt->as_sql, "FROM foo INNER JOIN baz b1 ON foo.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN baz b2 ON foo.baz_id = b2.baz_id AND b2.quux_id = 2\n";

# test case for bug found where add_join is called twice
$stmt->joins([]);
$stmt->add_join(foo => [
    { inner => { 'baz b1' => 'foo.baz_id = b1.baz_id AND b1.quux_id = 1' }},
]);
$stmt->add_join(foo => [
    { left => { 'baz b2' => 'foo.baz_id = b2.baz_id AND b2.quux_id = 2' }},
]);
is $stmt->as_sql, "FROM foo INNER JOIN baz b1 ON foo.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN baz b2 ON foo.baz_id = b2.baz_id AND b2.quux_id = 2\n";

# test case adding another table onto the whole mess
$stmt->add_join(quux => [{ inner => { 'foo f1' => 'f1.quux_id = quux.q_id' }}]);

is $stmt->as_sql, "FROM foo INNER JOIN baz b1 ON foo.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN baz b2 ON foo.baz_id = b2.baz_id AND b2.quux_id = 2 INNER JOIN foo f1 ON f1.quux_id = quux.q_id\n";

## Testing GROUP BY
$stmt = ns();
$stmt->from('foo');
$stmt->group('baz');
is($stmt->as_sql, "FROM foo\nGROUP BY baz\n", 'single bare group by');

$stmt = ns();
$stmt->from('foo');
$stmt->group({ baz => 'DESC' });
is($stmt->as_sql, "FROM foo\nGROUP BY baz DESC\n", 'single group by with desc');

$stmt = ns();
$stmt->from('foo');
$stmt->group([qw/ baz quux /]);
is($stmt->as_sql, "FROM foo\nGROUP BY baz, quux\n", 'multiple group by');

$stmt = ns();
$stmt->from('foo');
$stmt->group( { baz => 'DESC' }, { quux => 'DESC' } );
is($stmt->as_sql, "FROM foo\nGROUP BY baz DESC, quux DESC\n", 'multiple group by with desc');

$stmt = ns();
$stmt->from('foo');
$stmt->group({ baz => 'DESC', quux => 'DESC' });
is($stmt->as_sql, "FROM foo\nGROUP BY baz DESC, quux DESC\n", 'multiple group by with desc');

## Testing ORDER BY
$stmt = ns();
$stmt->from([ 'foo' ]);
$stmt->order({ 'baz' => 'DESC' });
is($stmt->as_sql, "FROM foo\nORDER BY baz DESC\n", 'single order by');

$stmt = ns();
$stmt->from([ 'foo' ]);
$stmt->order([ { baz => 'DESC' }, { quux => 'ASC'  }, ]);
is($stmt->as_sql, "FROM foo\nORDER BY baz DESC, quux ASC\n", 'multiple order by');

## Testing GROUP BY plus ORDER BY
$stmt = ns();
$stmt->from('foo');
$stmt->group('quux');
$stmt->order({ baz => 'DESC' });
is($stmt->as_sql, "FROM foo\nGROUP BY quux\nORDER BY baz DESC\n", 'group by with order by');

## Testing LIMIT and OFFSET
$stmt = ns();
$stmt->from('foo');
$stmt->limit(5);
is($stmt->as_sql, "FROM foo\nLIMIT 5\n");
$stmt->offset(10);
is($stmt->as_sql, "FROM foo\nLIMIT 5 OFFSET 10\n");
$stmt->limit("  15g");  ## Non-numerics should cause an error
{
    my $sql = eval { $stmt->as_sql };
    like($@, qr/Non-numerics/, "bogus limit causes as_sql assertion");
}

## Testing WHERE
$stmt = ns(); $stmt->add_where(foo => 'bar');
is($stmt->as_sql_where, "WHERE (foo = ?)\n");
is(scalar @{ $stmt->bind }, 1);
is($stmt->bind->[0], 'bar');

$stmt = ns(); $stmt->add_where(foo => [ 'bar', 'baz' ]);
is($stmt->as_sql_where, "WHERE (foo IN (?,?))\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 'bar');
is($stmt->bind->[1], 'baz');

$stmt = ns(); $stmt->add_where(foo => { '!=' => 'bar' });
is($stmt->as_sql_where, "WHERE (foo != ?)\n");
is(scalar @{ $stmt->bind }, 1);
is($stmt->bind->[0], 'bar');

$stmt = ns(); $stmt->add_where(foo => \'IS NOT NULL');
is($stmt->as_sql_where, "WHERE (foo IS NOT NULL)\n");
is(scalar @{ $stmt->bind }, 0);

$stmt = ns();
$stmt->add_where(foo => 'bar');
$stmt->add_where(baz => 'quux');
is($stmt->as_sql_where, "WHERE (foo = ?) AND (baz = ?)\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 'bar');
is($stmt->bind->[1], 'quux');

$stmt = ns();
$stmt->add_where(foo => [ { '>' => 'bar' },
                          { '<' => 'baz' } ]);
is($stmt->as_sql_where, "WHERE ((foo > ?) OR (foo < ?))\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 'bar');
is($stmt->bind->[1], 'baz');

$stmt = ns();
$stmt->add_where(foo => [ -and => { '>' => 'bar' },
                                  { '<' => 'baz' } ]);
is($stmt->as_sql_where, "WHERE ((foo > ?) AND (foo < ?))\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 'bar');
is($stmt->bind->[1], 'baz');

$stmt = ns();
$stmt->add_where(foo => [ -and => 'foo', 'bar', 'baz']);
is($stmt->as_sql_where, "WHERE ((foo = ?) AND (foo = ?) AND (foo = ?))\n");
is(scalar @{ $stmt->bind }, 3);
is($stmt->bind->[0], 'foo');
is($stmt->bind->[1], 'bar');
is($stmt->bind->[2], 'baz');

$stmt = ns();
$stmt->add_where(foo => [ -and => 'foo', 'bar', [ 'baz', 'boo' ] ]);
is($stmt->as_sql_where, "WHERE ((foo = ?) AND (foo = ?) AND (foo IN (?,?)))\n");
is(scalar @{ $stmt->bind }, 4);
is($stmt->bind->[0], 'foo');
is($stmt->bind->[1], 'bar');
is($stmt->bind->[2], 'baz');
is($stmt->bind->[3], 'boo');

$stmt = ns();
$stmt->add_where(foo => [ -and => 'foo', 'bar', [ -and => 'baz', 'boo' ] ]);
is($stmt->as_sql_where, "WHERE ((foo = ?) AND (foo = ?) AND ((foo = ?) AND (foo = ?)))\n");
is(scalar @{ $stmt->bind }, 4);
is($stmt->bind->[0], 'foo');
is($stmt->bind->[1], 'bar');
is($stmt->bind->[2], 'baz');
is($stmt->bind->[3], 'boo');

## fulltext search syntax for mysql 
# MATCH(col1, col2, col3) AGAINST('W.... query' IN BOOLEAN MODE)
$stmt = ns();
$stmt->add_where(\"MATCH(col1, col2, col3) AGAINST('W query' IN BOOLEAN MODE)");
is($stmt->as_sql_where, "WHERE (MATCH(col1, col2, col3) AGAINST('W query' IN BOOLEAN MODE))\n");
is(scalar @{ $stmt->bind }, 0);

## regression bug. modified parameters
my %terms = ( foo => [-and => 'foo', 'bar', 'baz']);
$stmt = ns();
$stmt->add_where(%terms);
is($stmt->as_sql_where, "WHERE ((foo = ?) AND (foo = ?) AND (foo = ?))\n");
$stmt->add_where(%terms);
is($stmt->as_sql_where, "WHERE ((foo = ?) AND (foo = ?) AND (foo = ?)) AND ((foo = ?) AND (foo = ?) AND (foo = ?))\n");

$stmt = ns();
$stmt->add_select(foo => 'foo');
$stmt->add_select('bar');
$stmt->from([ qw( baz ) ]);
is($stmt->as_sql, "SELECT foo, bar\nFROM baz\n");

$stmt = ns();
$stmt->add_select(foo => 'fo');
$stmt->add_select("MATCH(col1, col2, col3) AGAINST('W.... query' IN BOOLEAN MODE)");
$stmt->from([ qw( baz ) ]);
is($stmt->as_sql, "SELECT foo fo, MATCH(col1, col2, col3) AGAINST('W.... query' IN BOOLEAN MODE)\nFROM baz\n");

$stmt = ns();
$stmt->add_select(foo => 'fo');
$stmt->add_select("MATCH(col1, col2, col3) AGAINST('W.... query' IN BOOLEAN MODE)" => 'toritonn');
$stmt->from([ qw( baz ) ]);
is($stmt->as_sql, "SELECT foo fo, MATCH(col1, col2, col3) AGAINST('W.... query' IN BOOLEAN MODE) toritonn\nFROM baz\n");

$stmt = ns();
$stmt->add_select('f.foo' => 'foo');
$stmt->add_select('COUNT(*)' => 'count');
$stmt->from([ qw( baz ) ]);
is($stmt->as_sql, "SELECT f.foo, COUNT(*) count\nFROM baz\n");
my $map = $stmt->select_map;
is(scalar(keys %$map), 2);
is($map->{'f.foo'}, 'foo');
is($map->{'COUNT(*)'}, 'count');


# HAVING
$stmt = ns();
$stmt->add_select('foo');
$stmt->add_select('COUNT(*)' => 'count');
$stmt->from([ qw(baz) ]);
$stmt->add_where(foo => 1);
$stmt->group('baz');
$stmt->order({ foo => 'DESC' });
$stmt->limit(2);
$stmt->add_having(count => 2);

is($stmt->as_sql, <<SQL);
SELECT foo, COUNT(*) count
FROM baz
WHERE (foo = ?)
GROUP BY baz
HAVING (COUNT(*) = ?)
ORDER BY foo DESC
LIMIT 2
SQL

# recur and
$stmt = ns();
$stmt->from('table');
$stmt->add_where( -and => [ foo => 1, bar => 2 ] );
is($stmt->as_sql, "FROM table\nWHERE ((foo = ?) AND (bar = ?))\n", 'recur and');
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 1);
is($stmt->bind->[1], 2);

# recur or
$stmt = ns();
$stmt->from('table');
$stmt->add_where( -or => [ foo => 1, bar => 2 ] );
is($stmt->as_sql, "FROM table\nWHERE ((foo = ?) OR (bar = ?))\n", 'recur or');
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 1);
is($stmt->bind->[1], 2);

# recur and ( or and )
$stmt = ns();
$stmt->from('table');
$stmt->add_where(
    -and => [
        -or  => [ foo => 1, bar => 2 ],
        -and => [ baz => 3, lopnor => 4 ],
    ]
);
is($stmt->as_sql, "FROM table\nWHERE (((foo = ?) OR (bar = ?)) AND ((baz = ?) AND (lopnor = ?)))\n", 'recur and ( or and )');
is(scalar @{ $stmt->bind }, 4);
is($stmt->bind->[0], 1);
is($stmt->bind->[1], 2);
is($stmt->bind->[2], 3);
is($stmt->bind->[3], 4);

# add_where_sql
$stmt = ns();
$stmt->from('table');
$stmt->add_where_sql('%s = ? AND %s = ?', foo => '1', bar => '2');
is($stmt->as_sql, "FROM table\nWHERE (foo = ? AND bar = ?)\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 1);
is($stmt->bind->[1], 2);

$stmt = ns();
$stmt->from('table');
$stmt->add_where_sql('(%s = ? AND %s = ?) OR (baz = ?)', foo => '1', bar => '2', baz => 3);
is($stmt->as_sql, "FROM table\nWHERE ((foo = ? AND bar = ?) OR (baz = ?))\n");
is(scalar @{ $stmt->bind }, 3);
is($stmt->bind->[0], 1);
is($stmt->bind->[1], 2);
is($stmt->bind->[2], 3);

