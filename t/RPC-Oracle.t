#!/usr/bin/perl -I ../lib

use Test::More;
BEGIN { plan tests => 7 };
use RPC::Oracle;
ok(1); # If we made it this far, we're ok.

use Test::More;
use Term::ReadKey;
use DBI;

$|=1;

$SIG{INT} = sub { exit };

diag <<EOT;

Need to login to oracle database to continue testing.
 Hit CTRL-C to skip (will not fail tests)

NOTE: This user must have EXECUTE privilege on DBMS_SQL.
      Most users should have this, as it is a very common.
      package. The test will include running the following
      SQL query:

        SELECT COUNT(*) FROM ALL_TABLES;

      If you're not okay with that, hit CTRL-C now!

EOT


print STDERR "Username: ";
my $username = <>;
chomp $username;

print STDERR "Password: ";
ReadMode(2);
my $pass = <>;
chomp $pass;
print "\n";
ReadMode(0);

print STDERR "Oracle SID [" . ($ENV{ORACLE_SID} || "") . "]: ";
my $sid = <>;
chomp $sid;

# use default if given and set to ORACLE_SID
$sid = "" if $sid && $sid eq $ENV{ORACLE_SID};

my $dbh = DBI->connect('dbi:Oracle:' || $sid, $username, $pass, { RaiseError => 1, AutoCommit => 1 });

my $oracle = RPC::Oracle->new($dbh, "dbms_sql");

# test package variables
my $v7 = $oracle->v7;
ok($v7, 'get value of dbms_sql.v7');

# test changing schema
$oracle->schema("sys.dbms_sql");
ok($oracle->v7, 'get value of dbms_sql.v7 ');

# test constant()
ok($oracle->constant('v7'), 'get value of dbms_sql');

# test function call
my $cursor_id = $oracle->open_cursor;
ok($cursor_id, 'get cursor_id');

# test procedure call (long arguments)
$oracle->parse({ c => $cursor_id, statement => "select count(*) from all_tables", language_flag => $v7 });

$oracle->define_column_char($cursor_id, 1, undef, 255);

my $result = $oracle->execute_and_fetch($cursor_id);
ok($result, 'execute_and_fetch');

# test out variable
my $value;
$oracle->column_value_char($cursor_id, 1, \$value);
ok(defined($value), 'OUT variable');



