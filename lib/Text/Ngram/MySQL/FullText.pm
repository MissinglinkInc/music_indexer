package Text::Ngram::MySQL::FullText;
use warnings;
use strict;
use Data::Dumper;
use Encode qw/encode decode is_utf8/;
our $VERSION = '0.03';

sub new {
	my $class = shift;
	return bless {
		window_size => 2,
		column_name => 'myFullTextColumn',
		delimiters  => q{!-\/:-@\[-`\{-~、。，．・：；？！゛゜´｀¨＾￣＿ヽヾゝゞ〃仝々〆〇ー―‐／＼～∥｜…‥‘’“”（）〔〕［］｛｝〈〉《》「」『』【】＋－±×÷＝≠＜＞≦≧∞∴♂♀°′″℃￥＄￠￡％＃＆＊＠§☆★○●◎◇◆□■△▲▽▼※〒→←↑↓〓∈∋⊆⊇⊂⊃∪∩∧∨￢⇒⇔∀∃∠⊥⌒∂∇≡≒≪≫√∽∝∵∫∬Å‰♯♭♪†‡¶◯ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρστυφχψωАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя─│┌┐┘└├┬┤┴┼━┃┏┓┛┗┣┳┫┻╋┠┯┨┷┿┝┰┥┸╂①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩ�㍉㌔㌢㍍㌘㌧㌃㌶㍑㍗㌍㌦㌣㌫㍊㌻㎜㎝㎞㎎㎏㏄㎡㍻〝〟№㏍℡㊤㊥㊦㊧㊨㈱㈲㈹㍾㍽㍼≒≡∫∮∑√⊥∠∟⊿∵∩∪},
                return_bind => 0,
		@_,
	}, $class;
}

sub to_fulltext {
	my $self = shift;
	return $self->_parse('fulltext',@_);
}

sub to_query {
	my $self = shift;
	return $self->_parse('query',@_);
}

sub to_match_sql {
	my $self = shift;
	my $text = shift;
        my $bind = shift || $self->{return_bind};
	return if !defined $text;
	my $ngram = $self->to_query( $text );
        if( $bind ){
            return ( 
                qq{MATCH($self->{column_name}) }
                    .qq{AGAINST(? IN BOOLEAN MODE)},
                $ngram,
            );
        }else{
            return qq{MATCH($self->{column_name}) }
                .qq{AGAINST('$ngram' IN BOOLEAN MODE)};
        }
}

sub _parse {
	my $self = shift;
	my $type = shift || 'fulltext';
	my $text = shift;

	return if !defined $text;
	$text = decode('utf8', $text) unless is_utf8($text);
	
	my $regexp = decode 'utf8', "[$self->{delimiters}]";
	$text =~ s/$regexp/ /g;
	my @chunks = split /[\s　]/, $text;

	my @ngrams;
	foreach (@chunks){
		next if $_ eq '';
                if( $_ =~ /^[a-zA-Z0-9]+$/ ){
                    if( $type eq 'fulltext' ){
                        push @ngrams, $_;
                    }else{
                        push @ngrams, "+$_*";
                    }
		}elsif( $type eq 'fulltext' ){
			push @ngrams, $self->_make_ngram_fulltext( $_ );
		}else{
			push @ngrams, $self->_make_ngram_query( $_ );
		}
	}
	return join(' ', @ngrams);
}

sub _make_ngram_fulltext {
	my $self = shift;
	my $text = shift;
	return if !defined $text;

	my $length = length($text);
	
	return if $text eq '';
	
	if ($length < $self->{window_size}) {
		return $text;
	}
	
	my @ngrams;
	for (my $i = 0; $i < $length - $self->{window_size} + 1; ++$i){
		my $str = substr $text, $i, $self->{window_size};
		#str = encode 'utf8', $str;
		push @ngrams, $str;
	}
	return join(' ', @ngrams);
}

sub _make_ngram_query {
	my $self = shift;
	my $text = shift;
	return if !defined $text;

	if (length $text < $self->{window_size}){
		#my $str = encode 'utf8', $text;
		my $str = $text;
		$str = $self->_make_mysql_escape_string($str);
		return "+$str*";
	}

	my @ngrams;
	for my $i (0 .. length($text) - $self->{window_size}){
		my $str = substr $text, $i, $self->{window_size};
		#$str = encode 'utf8', $str;
		$str = $self->_make_mysql_escape_string($str);
		push @ngrams, "+$str";
	}
	return join(' ', @ngrams);
}

sub _make_mysql_escape_string {
	my $self = shift;
	my $text = shift;
	$text =~ s{\\}{\\\\}g;
	$text =~ s{'}{\\'}g;
	return $text;
}


=head1 NAME

Text::Ngram::MySQL::FullText - create ngram text for fulltext indexes, with non-ascii character support

=head1 SYNOPSIS

Getting Ready - Inserting Record Into Table

    use Text::Ngram::MySQL::FullText;
    my $p = Text::Ngram::MySQL::FullText->new();
    
    my $text = $p->to_fulltext( 'あいうえお' );
    # あい いう うえ えお お

    my $dbh = DBI->connect( ... );
    $dbh->do( qq{ INSERT INTO foo ( id, myText )
    	VALUES( undef, $text ) } );

Table Search - Fast Search Using FullText Index

    use Text::Ngram::MySQL::FullText;
    my $p = Text::Ngram::MySQL::FullText->new();
    my $match_sql = $p->to_match_sql( 'あいうえお' );
	# MATCH( myText ) AGAINST( '+あい +いう +うえ +えお'
	# IN BOOLEAN MODE)

    my $dbh = DBI->connect( ... );
    my $res = $dbh->selectrow_hashref(
    	qq{ SELECT * FROM foo WHERE $match_sql } );
    ...

=head1 AUTHOR

Toshimasa Ishibashi, C<< <iandeth at gmail.com> >>

some modified by Keiya Chinen <keiya_21@yahoo.co.jp>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-ngram-mysql-fulltext at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Ngram-MySQL-FullText>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Ngram::MySQL::FullText

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Ngram-MySQL-FullText>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Ngram-MySQL-FullText>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Ngram-MySQL-FullText>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Ngram-MySQL-FullText>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toshimasa Ishibashi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::Ngram::MySQL::FullText
