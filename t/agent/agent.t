#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use File::Path;
use File::Temp qw(tempdir);
use Test::Deep;
use Test::More;

use FusionInventory::Agent;
use FusionInventory::Agent::Config;
use FusionInventory::Agent::Logger;

plan tests => 30;

my $libdir = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);
push @INC, $libdir;
my $agent = FusionInventory::Agent->new(libdir => $libdir);

my %tasks;

create_file("$libdir/FusionInventory/Agent/Task/Task1", "Version.pm", <<'EOF');
package FusionInventory::Agent::Task::Task1::Version;
use constant VERSION => 42;
1;
EOF
%tasks = $agent->getAvailableTasks();
cmp_deeply (
    \%tasks,
    { 'Task1' => 42 },
    "single task"
);

create_file("$libdir/FusionInventory/Agent/Task/Task2", "Version.pm", <<'EOF');
package FusionInventory::Agent::Task::Task2::Version;
use constant VERSION => 42;
1;
EOF
%tasks = $agent->getAvailableTasks();
cmp_deeply (
    \%tasks,
    {
        'Task1' => 42,
        'Task2' => 42
    },
    "multiple tasks"
);

create_file("$libdir/FusionInventory/Agent/Task/Task3", "Version.pm", <<'EOF');
package FusionInventory::Agent::Task::Task3::Version;
use Does::Not::Exists;
use constant VERSION => 42;
1;
EOF
%tasks = $agent->getAvailableTasks();
cmp_deeply(
    \%tasks,
    {
        'Task1' => 42,
        'Task2' => 42
    },
    "wrong syntax"
);

create_file("$libdir/FusionInventory/Agent/Task/Task5", "Version.pm", <<'EOF');
package FusionInventory::Agent::Task::Task5::Version;
use constant VERSION => 42;
1;
EOF
%tasks = $agent->getAvailableTasks();
cmp_deeply (
    \%tasks,
    {
        'Task1' => 42,
        'Task2' => 42,
        'Task5' => 42
    },
    "multiple tasks"
);

$agent->{config} = FusionInventory::Agent::Config->new(
    options => {
        config  => 'none',
        debug   => 1,
        logger  => 'Test'
    }
);
$agent->{config}->{'no-task'} = ['Task5'];
$agent->{config}->{'tasks'} = ['Task1', 'Task5', 'Task1', 'Task5', 'Task5', 'Task2', 'Task1'];
my %availableTasks = $agent->getAvailableTasks(disabledTasks => $agent->{config}->{'no-task'});
$agent->{logger} = FusionInventory::Agent::Logger->new(config => $agent->{config});
my @availableTasks = keys %availableTasks;
my @plan = $agent->computeTaskExecutionPlan(\@availableTasks);
my $expectedPlan = [
    'Task1',
    'Task1',
    'Task2',
    'Task1'
];
cmp_deeply(
    \@plan,
    $expectedPlan
);

sub create_file {
    my ($directory, $file, $content) = @_;

    mkpath($directory);

    open (my $fh, '>', "$directory/$file")
        or die "can't create $directory/$file: $!";
    print $fh $content;
    close $fh;
}

my $list1 = [
    'elem1',
    'elem2',
    'elem3',
    'elem4'
];
my $list2 = [
    'elem5',
    'elem2',
    'elem1',
    'elem5',
    'elem2',
    'elem6',
    'elem1'
];
my $wanted = [
    'elem1',
    'elem2',
    'elem3',
    'elem4'
];
my @list3 = FusionInventory::Agent::_appendElementsNotAlreadyInList($list1, $list2);
my $i = 0;
while ($i < 4) {
    ok( $list3[$i] eq $wanted->[$i]);
    $i++;
}
my @otherElements = @list3[4..$#list3];
ok( scalar( @otherElements) == 2);
my %otherElements = map { $_ => 1 } @list3[4..$#list3];
ok (defined( $otherElements{'elem5'}));
ok (defined( $otherElements{'elem6'}));

my @tasks = (
    'task1',
    'task2',
    'taskwithoutanumber',
    'task345'
);
my @tasksInConf = (
    'task1',
    'task2',
    'task1',
    'task3',
    'task3'
);
my @tasksExecutionPlan = FusionInventory::Agent::_makeExecutionPlan(\@tasksInConf, \@tasks);
my @expectedExecutionPlan = (
    'task1',
    'task2',
    'task1'
);
cmp_deeply(
    \@tasksExecutionPlan,
    \@expectedExecutionPlan
);
my $ok = 0;
$i = 0;
while ($i < scalar(@expectedExecutionPlan)) {
    $ok = ( defined( $tasksExecutionPlan[$i] ) && ( $expectedExecutionPlan[$i] eq $tasksExecutionPlan[$i] ) );
    if (! $ok) {
        last;
    }
    $i++;
}
ok ($ok);

@tasksInConf = (
    'task1',
    'task2',
    'task1',
    'task3',
    'task3',
    'task3',
    'task5',
    'task1',
    'task2',
    'task2'
);
@tasksExecutionPlan = FusionInventory::Agent::_makeExecutionPlan(\@tasksInConf, \@tasks);
@expectedExecutionPlan = (
    'task1',
    'task2',
    'task1',
    'task1',
    'task2',
    'task2'
);
cmp_deeply(
    \@tasksExecutionPlan,
    \@expectedExecutionPlan
);

@tasksInConf = (
    'task1',
    'task2',
    'task1',
    'task3',
    'task3',
    'task3',
    'task5',
    'task1',
    'task2',
    'task2',
    '...'
);
@tasksExecutionPlan = FusionInventory::Agent::_makeExecutionPlan(\@tasksInConf, \@tasks);
# the first part of execution plan, the ordered part
my @expectedExecutionPlanOrderedPart = (
    'task1',
    'task2',
    'task1',
    'task1',
    'task2',
    'task2',
);
$i = 0;
while ( $i < 6) {
    ok( $tasksExecutionPlan[$i] eq $expectedExecutionPlanOrderedPart[$i]);
    $i++;
}
ok (scalar(@tasksExecutionPlan) == 8);
ok (
    ($tasksExecutionPlan[6] eq 'taskwithoutanumber' && $tasksExecutionPlan[7] eq 'task345')
    || ($tasksExecutionPlan[7] eq 'taskwithoutanumber' && $tasksExecutionPlan[6] eq 'task345')
);

$agent->{datadir} = './share';
$agent->{vardir}  = './var',

# Reset config to be able to run init() method with mandatory options
delete $agent->{config};
my $options = {
    'local' => '.',
    # Keep Test backend on logger as call to init() will reset logger
    'logger' => 'Test',
    # we force config to be loaded from file
    'conf-file' => 'resources/config/sample1',
    'config' => 'file'
};
$agent->init(options => $options);
# after init call, the member 'config' is defined and well blessed
ok (UNIVERSAL::isa($agent->{config}, 'FusionInventory::Agent::Config'));
ok (defined($agent->{config}->{'conf-file'}));
ok (defined($agent->{config}->{'no-task'}));
ok (scalar(@{$agent->{config}->{'no-task'}}) == 2);
ok (
    ($agent->{config}->{'no-task'}->[0] eq 'snmpquery' && $agent->{config}->{'no-task'}->[1] eq 'wakeonlan')
        || ($agent->{config}->{'no-task'}->[1] eq 'snmpquery' && $agent->{config}->{'no-task'}->[0] eq 'wakeonlan')
);
ok (scalar(@{$agent->{config}->{'server'}}) == 0);


@tasks = (
    'Task1',
    'Task2',
    'Taskwithoutanumber',
    'Task345'
);
@tasksInConf = (
    'task1',
    'task2',
    'task1',
    'task3',
    'task3',
    'task3',
    'task5',
    'task1',
    'task2',
    'task2'
);
@tasksExecutionPlan = FusionInventory::Agent::_makeExecutionPlan(\@tasksInConf, \@tasks);
@expectedExecutionPlan = (
    'Task1',
    'Task2',
    'Task1',
    'Task1',
    'Task2',
    'Task2'
);
cmp_deeply(
    \@tasksExecutionPlan,
    \@expectedExecutionPlan
);
