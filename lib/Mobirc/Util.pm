package Mobirc::Util;
use strict;
use warnings;
use base 'Exporter';
use Carp;

our @EXPORT = qw/DEBUG compact_channel_name canon_name add_message daemonize/;

sub DEBUG($) { ## no critic.
    my $txt = shift;
    print "$txt\n" if $ENV{DEBUG};
}

# -------------------------------------------------------------------------
# shorten channel name

sub compact_channel_name {
    local ($_) = shift;

    # #name:*.jp to %name
    if (s/:\*\.jp$//) {
        s/^#/%/;
    }

    # 末尾の単独の @ は取る (plumプラグインのmulticast.plm対策)
    s/\@$//;

    $_;
}

# -------------------------------------------------------------------------

sub canon_name {
    local ($_) = shift;
    tr/A-Z[\\]^/a-z{|}~/;
    $_;
}

# -------------------------------------------------------------------------

sub add_message {
    my ( $poe, $channel, $who, $msg ) = @_;

    DEBUG "ADD MESSAGE TO $channel";

    unless (Encode::is_utf8($msg)) {
        croak "$msg shuld be flagged utf8";
    }
    unless (Encode::is_utf8($channel)) {
        croak "$channel shuld be flagged utf8";
    }

    my $heap = $poe->kernel->alias_resolve('irc_session')->get_heap;

    my $config = $heap->{config} or die "missing config in heap";

    my $message;
    if ( length $who ) {
        $message = sprintf( '%s %s> %s', _now(), $who, $msg );
    }
    else {
        $message = sprintf( '%s %s', _now(), $msg );
    }

    my $canon_channel = canon_name($channel);
    my @tmp = split( "\n", $heap->{channel_buffer}->{$canon_channel} || '' );
    push @tmp, $message;

    my @tmp2 = split( "\n", $heap->{channel_recent}->{$canon_channel} || '' );
    push @tmp2, $message;

    if ( @tmp > $config->{httpd}->{lines} ) {
        $heap->{channel_buffer}->{$canon_channel} =
          join( "\n", splice( @tmp, -$config->{httpd}->{web_lines} ) );
    }
    else {
        $heap->{channel_buffer}->{$canon_channel} = join( "\n", @tmp );
    }

    if ( @tmp2 > $config->{httpd}->{lines} ) {
        $heap->{channel_recent}->{$canon_channel} =
          join( "\n", @tmp2[ 1 .. $config->{httpd}->{lines} ] );
    }
    else {
        $heap->{channel_recent}->{$canon_channel} = join( "\n", @tmp2 );
    }

    $heap->{channel_mtime}->{$canon_channel} = time;

    # unread lines
    $heap->{unread_lines}->{$canon_channel} = scalar(@tmp2);

    if ( $heap->{unread_lines}->{$canon_channel} > $config->{httpd}->{lines} ) {
        $heap->{unread_lines}->{$canon_channel} = $config->{httpd}->{lines};
    }
}

sub _now {
    my ( $sec, $min, $hour ) = localtime(time);
    sprintf( '%02d:%02d', $hour, $min );
}

# -------------------------------------------------------------------------

sub daemonize {
    my $pid_fname = shift;

    require Proc::Daemon;
    Proc::Daemon::Init();
    if ( defined $pid_fname ) {
        open \my $pid, '>', $pid_fname or die "cannot open pid file: $pid_fname";
        $pid->print("$$\n");
        close $pid;
    }
}

1;
