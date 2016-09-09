package App::CheckArchiveFilename;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{check_archive_filename} = {
    v => 1.1,
    summary => 'Return information about archive types from filenames',
    args => {
        filenames => {
            schema => ['array*', of=>'filename*', min_len=>1],
            'x.name.is_plural' => 1,
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },
};
sub check_archive_filename {
    require Filename::Archive;

    my %args = @_;
    my $filenames = $args{filenames};

    my @res;
    for my $filename (@$filenames) {
        my $rec = {filename => $filename};
        my $fres = Filename::Archive::check_archive_filename(
            filename => $filename);
        if ($fres) {
            $rec->{is_archive} = 1;
            for (qw/archive_name compressor_info/) {
                $rec->{$_} = $fres->{$_};
            }
            $rec->{is_compressed} = $fres->{compressor_info} ? 1:0;
        } else {
            $rec->{is_archive} = 0;
        }
        push @res, $rec;
    }

    [200, "OK", \@res, {
        'table.fields' => [qw/filename is_archive is_compressed/],
    }];
}

1;
# ABSTRACT:
