#!/usr/bin/perl

use v5.10;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';
use XML::Twig;
use LWP;
use HTTP::Date qw(time2str parse_date str2time);
use Getopt::Long;


#set command args
my $days = 1; #default amount of days to look for videos from channels
my $rawdogflag;
my $debugflag;
GetOptions('rawdog' => \$rawdogflag, 'debug' => \$debugflag, 'days=i' => \$days);

my $currenttime = time;
my $cutoffdate = $currenttime - ($days * 24 *60 *60);	# max date to retrieve youtube videos
say time2str(time);
say time2str($cutoffdate);

unlink glob "*.debug"; # delete all debug output
my $inputfile = "subscription_manager.opml";	# the input opml file from youtube google takeout
unless (-e $inputfile){
	die "YouTube opml input file does not exist!"
}
my $twig = XML::Twig->new(
	pretty_print => 'indented',
	);
$twig->parsefile($inputfile) or die "no input file found";

my $root = $twig->root;

#sprint $root->name . "\n";

# if rawdog option is set, output rawdog compatible file converted from youtube opml file
my $rawdogfh;
if ($rawdogflag){
	open($rawdogfh,'>',"rawdog.txt"); # create file for rawdog
}

# parse the opml file to get youtube channel URLs
my ($body, $outline, $outlineurl, @channels, $changetype);
foreach $body ($root->children){
	foreach $outline ($body->children){
			foreach $outlineurl ($outline->children){
					if ($rawdogflag){
							say $rawdogfh "feed 30m ". $outlineurl->att('xmlUrl');
					}

					push @channels, $outlineurl->att('xmlUrl');
				}
		}
}


# download and process each channel's rss file
my $browser = LWP::UserAgent->new;
my ($rssfileurl, $response);

foreach $rssfileurl (@channels) {
	say $rssfileurl;
	my $response = $browser->get($rssfileurl);
		die "Can't get $rssfileurl -- ", $response->status_line
		unless $response->is_success;

	#print $response->content;
	my $t = XML::Twig->new(
					twig_handlers =>
						{entry => \&entry }
						);
	$t->parse($response->content);
}

if ($debugflag){
	open(DEBUGALLVIDS,">allvids.debug"); # all video URLs, descriptions retrieved from all RSS files
	open(DEBUGSELECTEDVIDS,">selectedvids.debug");	# video URLs, descriptions that are within the cut off time
}


open(YTDL,">ytdl.txt"); #youtube-dl input file
my @vidlinks;
my @sorted_links = reverse(sort(@vidlinks));
foreach (@sorted_links)
	{
		my ($timestamp,$link,$thumbnail, $vtitle) = split(/\t/,$_);
		if (str2time($timestamp) >= $cutoffdate){
			say YTDL $link; # final output file

			if ($debugflag){	say DEBUGSELECTEDVIDS $_;	}

			}
	if ($debugflag){	say DEBUGALLVIDS $_;	}
	}

############################################
sub entry
	{
	my ($twig, $entry) = @_;

	my $vidlink = $entry->first_child('link')->att('href');
	my $publishdate = $entry->first_child('published')->text;
	my $vidtitle = $entry->first_child('title')->text;
	my $media_group = $entry->first_child('media:group');
	my $media_thumbnail = $media_group->first_child('media:thumbnail')->att('url');
	my $media_description = $media_group->first_child('media:description')->text;
		$media_description =~ s/\t//g;
		$media_description =~ s/\n/\x1f/g; #store new lines as separator to convert them to <br> in html output
	my $author = $entry->first_child('author');
	my $authorname = $author->first_child('name')->text;
	my $channellink = $author->first_child('uri')->text;
	my $concat = "$publishdate\t$vidlink\t$media_thumbnail\t$vidtitle\t$authorname\t$channellink\t$media_description";
	push @vidlinks, $concat;

	}

exit;
