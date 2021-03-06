package HTTP::Engine::Middleware::Profile::Runtime;
use Any::Moose;
with 'HTTP::Engine::Middleware::Profile::Role';

use Time::HiRes qw(time);

has 'start_time'  => ( is => 'rw' );
has 'end_time'    => ( is => 'rw' );
has 'send_header' => (
    is      => 'rw',
    default => 0,
);
has 'header_name' => (
    is      => 'rw',
    default => 'X-Runtime',
);


sub start {
    shift->start_time( time() );
}

sub end {
    shift->end_time( time() );
}

sub report {
    my($self, $c, $profile, $req, $res) = @_;

    my $elapsed = $self->end_time - $self->start_time;
    my $message = "Request handling execution time: $elapsed secs\n";
    $profile->log( $message );

    return unless $self->send_header;
    $res->header( $self->header_name => $elapsed );
}

__PACKAGE__->meta->make_immutable;1;
