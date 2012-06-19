#!/usr/bin/perl --

use strict;
use warnings;

$| = 1;

BEGIN {
	use File::Basename;
	
	use lib dirname($0).'/lib';
	
	my $nativesha = 1;
	unless (eval "use Digest::SHA ; 1") {
		warn "Digest::SHA not found. using Digest::SHA::PurePerl.\n";
		eval "use Digest::SHA::PurePerl";
		$nativesha = undef;
	}
	sub is_nativesha {
		return $nativesha;
	}
}

use Encode;
use File::Find;
use MP3::Tag;
use MP4::Info;
use Text::Ngram::MySQL::FullText;

my $nativesha = is_nativesha();

my $target_path = $ARGV[0] ? $ARGV[0] : './';

my @found_files = &traverse_files($target_path);

foreach my $file (@found_files) {
	my %meta;
	if (my $mp4 = get_mp4tag($file->[2])){
		$meta{'title'} = $mp4->{TITLE};
		$meta{'artist'} = $mp4->{ARTIST};
		$meta{'album'} = $mp4->{ALBUM};
		$meta{'comment'} = $mp4->{CMT};
		$meta{'year'} = $mp4->{YEAR};
		$meta{'genre'} = $mp4->{GENRE};
		$meta{'time'} = $mp4->{SECS};
		$meta{'bpm'} = $mp4->{TMPO};
		$meta{'track'} = $mp4->{TRKN}->[0];
		$meta{'tracktotal'} = $mp4->{TRKN}->[1];
		$meta{'disk'} = $mp4->{DISK}->[0];
		$meta{'disktotal'} = $mp4->{DISK}->[1];
	}
	elsif (my $mp3 = MP3::Tag->new($file->[2])) {
		my $track;
		($meta{'title'},
		$track,
		$meta{'artist'},
		$meta{'album'},
		$meta{'comment'},
		$meta{'year'},
		$meta{'genre'}) = $mp3->autoinfo();
		($meta{'track'},$meta{'tracktotal'}) = split('/',$track,2);
		if (exists $mp3->{ID3v2}) {
			$meta{'publisher'} = ($mp3->{ID3v2}->get_frame("TPUB"))[0];
			$meta{'bpm'} = ($mp3->{ID3v2}->get_frame("TBPM"))[0];
			$meta{'key'} = ($mp3->{ID3v2}->get_frame("TKEY"))[0];
			$meta{'time'} = ($mp3->{ID3v2}->get_frame("TIME"))[0];
			$meta{'isrc'} = ($mp3->{ID3v2}->get_frame("TSRC"))[0];
			if (my $tit2 = ($mp3->{ID3v2}->get_frame("TIT2"))[0]) {
				$meta{'title'} = $tit2;
			}
			$meta{'subtitle'} = ($mp3->{ID3v2}->get_frame("TIT3"))[0];
		}
		$mp3->close();
	}
	else {
		next;
	}
	
	warn "[".$file->[2]."]\n";
	
	my $sha;
	if ($nativesha) {
		$sha = Digest::SHA->new(224);
	}
	else {
		$sha = Digest::SHA::PurePerl->new(224);
	}
	$sha->addfile($file->[2]);
	$meta{'sha2hex'} = $sha->hexdigest();
	my ($relative_path,$escaped_target_path);
	if ($^O eq 'MSWin32') {
		$relative_path = Encode::decode('cp932',$file->[2]);
		$escaped_target_path = Encode::decode('cp932',$target_path);
	}
	else {
		$relative_path = $file->[2];
		$escaped_target_path = $target_path;
	}

	$escaped_target_path =~ s/\\/\\\\/g;
	$relative_path =~ s/${escaped_target_path}//;
	$meta{'path'} = $relative_path;

	&build_sql(\%meta);
}

sub build_sql {
	no warnings;
	my $ngram = Text::Ngram::MySQL::FullText->new();
	$_[0]{'ngram_title'} = $ngram->to_fulltext($_[0]{'title'});
	$_[0]{'ngram_subtitle'} = $ngram->to_fulltext($_[0]{'subtitle'});
	$_[0]{'ngram_artist'} = $ngram->to_fulltext($_[0]{'artist'});
	$_[0]{'ngram_album'} = $ngram->to_fulltext($_[0]{'album'});
	
	my $pairs;
	foreach my $k (keys %{$_[0]}) {
		if (defined $_[0]->{$k}) {
			$_[0]->{$k} =~ s/'/''/g;
			$_[0]->{$k} =~ s/"/\"/g;
			$_[0]->{$k} =~ s/\\/\\\\/g;
			$_[0]->{$k} =~ s/\x00/\\x00/g;
			$_[0]->{$k} =~ s/\n//g;
			$_[0]->{$k} =~ s/\r/\\r/g;
			$_[0]->{$k} =~ s/\x1a/\\x1a/g;
			$pairs .= '`'.$k.'`=\''.$_[0]->{$k}.'\',';
		}
		else {
			$pairs .= '`'.$k.'`=NULL,';
		}
	}
	chop $pairs;
my $table_name = $ARGV[1] ? $ARGV[1] : 'songs';

my $sql =<<__EOS__;
INSERT INTO $table_name SET
$pairs
ON DUPLICATE KEY UPDATE
$pairs;
__EOS__
	
	print $sql;
}

sub traverse_files {
	my @found_files;
	find(sub {
		return if $_ !~ /\.mp3$|\.m4a$|\.mp4$/;
		push @found_files,[$File::Find::dir,$_,$File::Find::name];
	}, ($_[0]));
	return @found_files;
}
