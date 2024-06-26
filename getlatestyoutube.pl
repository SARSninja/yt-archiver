#!/usr/bin/perl

use v5.10;
use List::Util qw(shuffle);
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';
use XML::Twig;
use LWP;
use HTTP::Date qw(time2str parse_date str2time time2isoz);
use Getopt::Long;


#set command args
my $days = undef;
my $hours = undef;
my $rawdogflag;
my $debugflag;
my $tstampflag;
my $wgetflag;
GetOptions('rawdog' => \$rawdogflag, 'wget' => \$wgetflag, 'debug' => \$debugflag, 'days=f' => \$days, 'hours=f' => \$hours, 'tstamp' => \$tstampflag);

if (!$days){
	$days = 1;
	if (!$hours){
		$hours=24;
	}
}
if (!$hours){
	$hours=24;
}

my $currenttime = time;
my $cutoffdate = $currenttime - ($days * $hours *60 *60);	# max date to retrieve youtube videos
if ($debugflag){
	say "DEBUG mode enabled: ALL VIDEOS DUMPED FROM RSS!";
	$cutoffdate = 0;
}

if ($tstampflag){
	say "using ytdl.html last modify time";
	die "ytdl.html not found, rerun program without -tstamp argument" unless -e "ytdl.html";
	my $modtime= (stat("ytdl.html"))[10];
	#say $modtime;
	#say time2str($modtime);
	$cutoffdate = $modtime;
}
my $lct = localtime($currenttime);
my $lcot = localtime($cutoffdate);

system("rm dlist*");
system("rm log*.txt");

say "begin:\t$lcot";
say "end:\t$lct";
say "range:\t". (($currenttime - $cutoffdate)/(3600*24)) ." days";
say "range:\t". (($currenttime - $cutoffdate)/3600) ." hrs";
say "range:\t". (($currenttime - $cutoffdate)/60)." min";

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
my ($body, $outline, $outlineurl, @channels, $changetype, %opmltitlehash);
foreach $body ($root->children){
	foreach $outline ($body->children){
			foreach $outlineurl ($outline->children){
					if ($rawdogflag){
							say $rawdogfh "feed 30m ". $outlineurl->att('xmlUrl');
					}
					push @channels, $outlineurl->att('xmlUrl');
					my $t = $outlineurl->att('title');
					my $u = $outlineurl->att('xmlUrl');
					$opmltitlehash{$u} = $t;
				}
		}
}


# download and process each channel's rss file
my $browser = LWP::UserAgent->new;
my ($rssfileurl, $response);

@channels = shuffle(@channels);

foreach $rssfileurl (@channels) {
	say $opmltitlehash{$rssfileurl};
	#say $rssfileurl;
	
	if ($wgetflag){
		my $cfh;
		system("wget --no-check-certificate $rssfileurl -O channel.out");
		open $cfh, '<', 'channel.out' or die "Can't open file $!";
		read $cfh, my $file_content, -s $cfh;
		my $t = XML::Twig->new(
					twig_handlers =>
						{entry => \&entry }
						);
		$t->parse($file_content);
		undef $file_content;
		close $cfh;
	} 
	else {
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


#	my $response = $browser->get($rssfileurl);
#		die "Can't get $rssfileurl -- ", $response->status_line
#		unless $response->is_success;

	#print $response->content;
	


}




# output final youtube-dl input file
open(YTDL,">ytdl.txt"); #youtube-dl input file
my %videohash;
my @vidlinks;

foreach (reverse(sort { $videohash{$a}{publishdate} cmp $videohash{$b}{publishdate}} keys %videohash)){
	#reverse sort links by date
	if ($debugflag){
		say YTDL $videohash{$_}{videolink};
	}
	elsif (str2time($videohash{$_}{publishdate}) >= $cutoffdate){
		say YTDL $videohash{$_}{videolink};
	}
}

say "youtube-dl --continue --ignore-errors --no-overwrites -f \"[filesize<200M]\" --batch-file ytdl.txt";

# HTML file output
my $gentime = time2isoz(time);
open(my $outputxml,'>', "ytdl.html");

say $outputxml "<html><title>RSS HTML Subscription list generated $gentime</title><body><center><h1>YT RSS Feeds generated $gentime</h1>";
say $outputxml "<h3>".localtime."</h3>";
if ($debugflag){
	say $outputxml "<h2 style=color:red;>DEBUG mode enabled: ALL VIDEOS DUMPED FROM RSS</h2><br>";
}
my $counter = 0;
foreach (reverse(sort { $videohash{$a}{publishdate} cmp $videohash{$b}{publishdate}} keys %videohash)){

		my $timestamp = $videohash{$_}{publishdate};
		my $vidlink = $videohash{$_}{videolink};
		my $vidtitle = $videohash{$_}{title};
		my $thumbnail = $videohash{$_}{thumbnail};
		my $vidauthor = $videohash{$_}{author};
		my $channellink = $videohash{$_}{channellink};
		my $viddescription = $videohash{$_}{description};
		my $lts = localtime(str2time($timestamp));

		if (str2time($videohash{$_}{publishdate}) >= $cutoffdate){
			say $outputxml "<table border=1 width=90%>";
			say $outputxml "<tr valign=top>";
			say $outputxml "<td width=500px><h2>[<a href=\"$channellink\">$vidauthor</a>] - $vidtitle</h2>";
			say $outputxml "$vidlink<br><br>";
			say $outputxml "<em>$timestamp</em><br>";
			say $outputxml "<em>$lts</em><br>";
			say $outputxml "<a href=\"".$vidlink."\"><img src=\"".$thumbnail."\"></a><br>";
			say $outputxml "</td>";
			$viddescription =~ s/\n/\<br\>/g;
			say $outputxml "<td>$viddescription</td></tr></table><br>";
		$counter++;
		}
	}

say $outputxml "<h1>$counter videos</h1>";
say $outputxml "</body></html>";
say $outputxml time;

############################################
sub entry
	{
	my ($twig, $entry) = @_;
	my $id = $entry->first_child('yt:videoId');
	my $vidlink = $entry->first_child('link')->att('href');
	my $publishdate = $entry->first_child('published')->text;
	my $vidtitle = $entry->first_child('title')->text;
	my $media_group = $entry->first_child('media:group');
	my $media_thumbnail = $media_group->first_child('media:thumbnail')->att('url');
	my $media_description = $media_group->first_child('media:description')->text;
	#	$media_description =~ s/\t//g;
 	#	$media_description =~ s/\n/\x1f/g; #store new lines as separator to convert them to <br> in html output
	my $author = $entry->first_child('author');
	my $authorname = $author->first_child('name')->text;
	my $channellink = $author->first_child('uri')->text;

	$videohash{$id}{publishdate} = $publishdate;
	$videohash{$id}{videolink} = $vidlink;
	$videohash{$id}{title} = $vidtitle;
	$videohash{$id}{thumbnail} = $media_thumbnail;
	$videohash{$id}{author} = $authorname;
	$videohash{$id}{channellink} = $channellink;
	$videohash{$id}{description} = $media_description;
	}

exit;
