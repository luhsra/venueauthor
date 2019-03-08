# $Id: venueauthors.pl 18919 2019-03-08 22:02:33Z lohmann $
#
# Extracts author names for all papers published in @venues / @years using DBLP.
#
# Results are written to STDOUT in the format
# 		<full author name> ; <venue 1>[, <venue2>, ...]
#
# Statistics and progress information is written to STDERR
#
#

# Venues to retrieve (DBLP venue names)
# See http://dblp.uni-trier.de/search/publ/
my @venues = ('ACNS', 'ARCS', 'ASAP', 'ASP-DAC', 'ASPLOS', 'CASES', 'CC', 'CODES+ISSS', 'DAC', 'DATE', 'Euro-Par', 'EuroSys', 'PARCO', 'USENIX_Annual_Technical_Conference', 'SOSP', 'VEE', 'DASIP', 'Humanoids', 'NDSS');

# Years to retrieve
my @years  = (2017,2016,2015);

use strict;
use XML::Simple;
use LWP::Simple;
use Data::Dumper;
	$Data::Dumper::Useperl = 1;
use utf8;
	binmode STDOUT, 'utf8';

use LWP::UserAgent;


# Build Query for DBLP CompleteSearch
# See http://dblp.uni-trier.de/search/publ/
my $query	 = sprintf( 'venue:%s:|' x @venues, @venues );
	chop $query;
	$query .= ' ' . sprintf( 'year:%s:|' x @years, @years );
	chop $query;

	# sanitize for URL
	$query =~s/:/%3A/g;
	$query =~s/ /%20/g;
	$query =~s/\+/%2B/g;

# Use it to build the complete URL for DBLP request 
my $dblp	 = "http://dblp.uni-trier.de/search/publ/api?q=$query&h=1000&format=xml";

# Retrieve XML data from DBLP
print  STDERR "\n";
print  STDERR "(2) Accessing DBLP to retrieve authors for\n         ";
printf STDERR "%s, " x @venues, @venues;
print  STDERR "\n    in years\n        ";
printf STDERR "%s, " x @years, @years;
print  STDERR "\n    DBLP queries";
print  STDERR "\n";

my $first 			= 0;	# index of first record to retrieve
my $computed		= 0;	# total records sent so far
my $sent 				= 0; 	# records send by last query (max 1000)
my $total 			= 0;  # total number of records

my $xmlstring;
my $xmldb;
my %db = ();

do {
	$xmlstring = get( $dblp . "&f=$computed") or die "Could not retrieve XML Data!\n Query: $dblp\n";
	$xmldb = XMLin( $xmlstring, ForceArray => ['author'] );

# get dataset statistics
	$first = $xmldb->{hits}->{first};
	$sent = $xmldb->{hits}->{sent};
	$total = $xmldb->{hits}->{total};
	$computed = $first+$sent;

	printf STDERR "        got entries %04d -- %04d of %04d\n", $first, $computed,  $total;

# expand dataset 
	%db = (%db, %{$xmldb->{hits}->{hit}});

} while( $computed < $total );

print STDERR "        in total " . scalar keys( %db ) . " entires retrieved (should be $total)\n";

# Create author hash
my $authors = {};
foreach my $entry (keys %db ) {
	my $e = $db{$entry}->{info};
	foreach my $a (@{$db{$entry}->{info}->{authors}->{author}}) {
		unless( exists $authors->{$a} ) { 
			$authors->{$a}->{venues} = ();
		}
		push @{$authors->{$a}->{venues}}, $e->{venue}.$e->{year};
	}
}

print STDERR "\n    match completed!\n\n";

foreach my $a (sort keys %{$authors}) {
	print "$a; " . join(', ', @{$authors->{$a}->{venues}} ). "\n";
}

# print out statistics
my $t = scalar( keys ( %{$authors} ) );
print  STDERR "\nQuery was: ";
printf STDERR "%s, " x @venues, @venues;
printf STDERR " in %s " x @years, @years;
print  STDERR "\n";

print  STDERR "\nResults: I have found $t unique authors\n";
print  STDERR "\n";

