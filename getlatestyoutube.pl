#!/usr/bin/perl

use XML::Twig;
use LWP;
use v5.10;
use HTTP::Date;
use HTTP::Date qw(parse_date);
use strict;
use warnings;

my $currenttime = time;
my $days = 1;
my $cutoffdate = $currenttime - ($days * 24 *60 *60);	# max date to retrieve youtube videos

say time2str(time);
say time2str($cutoffdate);

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

open(my $rawdog,'>',"rawdog.txt"); # create file for rawdog
my ($body, $outline, $outlineurl, @channels, $changetype);
foreach $body ($root->children){
	#print $body->name ."\n";
		foreach $outline ($body->children){
			#print $outline->name ."---------------"."\n";
				foreach $outlineurl ($outline->children){
					#print $outlineurl->name ."--\n";
					#print $outlineurl->att('text') ."\n";
					print $rawdog "feed 30m ". $outlineurl->att('xmlUrl')."\n";
					push @channels, $outlineurl->att('xmlUrl');
				}
		}
}
open (my $fh_out, '>', "sub_out.xml");
$twig->print($fh_out);


# process each channel's rss
my $browser = LWP::UserAgent->new;
my ($rssfileurl, $response);

foreach $rssfileurl (@channels) {
	print $rssfileurl ."\n";
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

open(FH2,">downloadlist.txt"); # all video URLs retrieved from
open(FH3,">filterlist.txt");	# video URLs that are within the cut off time
open(FH4,">ytdl.txt");
my @vidlinks;
my @sorted_links = reverse(sort(@vidlinks));
foreach (@sorted_links)
	{
		my ($timestamp,$link,$thumbnail, $vtitle) = split(/\t/,$_);
		if (str2time($timestamp) >= $cutoffdate){
			say FH3 $_;
			say FH4 $link;
			}
	print FH2 $_ ."\n";
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
