package App::Mobirc::Web::C::Static;
use Mouse;
use App::Mobirc::Web::C;
use App::Mobirc::Util;
use Path::Class;

sub dispatch_deliver {
    my ($class, $req, $args) = @_;
    my $path = $args->{filename};
    die "invalid path: $path" unless $path =~ m{^[a-z0-9-]+\.(?:css|js|png)$};

    my $file = file(config->{global}->{assets_dir}, 'static', $path);
    my $ct = 'text/html';
    $ct = 'text/css' if ($path =~ /\.css$/);
    $ct = 'text/javascript' if ($path =~ /\.js$/);
    $ct = 'image/png' if ($path =~ /\.png$/);

    HTTP::Engine::Response->new(
        status       => 200,
        content_type => $ct,
        body         => $file->openr(),
    );
}

1;
