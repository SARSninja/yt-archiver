#!/usr/bin/perl

use XML::Twig;
use LWP;
use v5.10;
use HTTP::Date;
use HTTP::Date qw(parse_date time2isoz);
use strict;
use warnings;

my $gentime = time2isoz(time);
open(my $outputxml,'>', "ytdl.html");

say $outputxml "<html><title>RSS HTML Subscription list generated $gentime</title><body><center><h1>YT RSS Feeds generated $gentime</h1>";

open(my $inputfile,'<', "filterlist.txt");
#open(my $inputfile,'<', "downloadlist.txt");

my $counter = 0;
while(<$inputfile>){
		chomp;
		my ($timestamp, $vidlink, $thumbnail, $vidtitle, $vidauthor, $channellink, $viddescription)  = split(/\t/, $_);

		say $outputxml "<table border=1 width=90%>";
		say $outputxml "<tr valign=top>";
		say $outputxml "<td width=500px><h2>[<a href=\"$channellink\">$vidauthor</a>] - $vidtitle</h2>";
		say $outputxml "<em>$timestamp</em><br>";
		say $outputxml "<a href=\"".$vidlink."\"><img src=\"".$thumbnail."\"></a><br>";
		say $outputxml "</td>";
		$viddescription =~ s/\x1f/\<br\>/g;
		say $outputxml "<td>$viddescription</td></tr></table><br>";
		$counter++;
	}

say $outputxml "<h1>$counter videos</h1>";
say $outputxml "</body></html>";

exit;
