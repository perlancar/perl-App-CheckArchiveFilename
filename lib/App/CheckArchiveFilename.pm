package App::CheckArchiveFilename;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{check_archive_filename} = {
    v => 1.1,
    summary => 'Return information about archive & compressor types from filenames',
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
    require Filename::Compressed;

    my %args = @_;
    my $filenames = $args{filenames};
    my ($has_errors, $has_success);

    my @res;
    for my $filename (@$filenames) {
        unless (-f $filename) {
            warn "No such file: $filename\n";
            $has_errors++;
            next;
        };
        my $rec = {filename => $filename};
        my $ares = Filename::Archive::check_archive_filename(
            filename => $filename);
        if ($ares) {
            $rec->{is_archive} = 1;
            $rec->{archive_name} = $ares->{archive_name};
            if ($ares->{compressor_info}) {
                $rec->{is_compressed} = 1;
                # we'll just display the outermost compressor (e.g. compressor
                # for file.tar.gz.bz2 is bzip2). this is rare though.
                $rec->{compressor_name}   = $ares->{compressor_info}[0]{compressor_name};
                $rec->{compressor_suffix} = $ares->{compressor_info}[0]{compressor_suffix};
            }
        } else {
            $rec->{is_archive} = 0;
            my $cres = Filename::Compressed::check_compressed_filename(
                filename => $filename);
            if ($cres) {
                $rec->{is_compressed} = 1;
                $rec->{compressor_name}   = $cres->{compressor_name};
                $rec->{compressor_suffix} = $cres->{compressor_suffix};
            }
        }
        push @res, $rec;
        $has_success++;
    }

    my ($status, $msg);
    if ($has_errors && !$has_success) {
        ($status, $msg) = (500, "Error");
    } else {
        ($status, $msg) = (200, "OK");
    }
    [$status, $msg, \@res, {
        'table.fields' => [qw/filename is_archive is_compressed/],
    }];
}

1;
# ABSTRACT:
