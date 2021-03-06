package updater::download::sysdload;

# This function provides a way to download files if the binary version of rsu-query is not installed
# (meaning the system perl might not be compatible with the other commands)
sub sysdownload
{
	# Get the passed data
	my ($url, $downloadto) = @_;
	
	# Get the platform we are on
	my $OS = "$^O";
	
	# If we are not on windows
	if ($OS !~ /MSWin32/)
	{
		# Make a variable which will contain the download command we will use
		my $fetchcommand = "wget --connect-timeout=3 -O";
		
		# If /usr/bin contains wget
		if(`ls /usr/bin | grep wget` =~  /wget/)
		{
			# Use wget command to fetch files
			$fetchcommand = "wget --connect-timeout=3 -O";
		}
		# Else if /usr/bin contains curl
		elsif(`ls /usr/bin | grep curl` =~  /curl/)
		{
			# Curl command equalent to the wget command to fetch files
			$fetchcommand = "curl -L --connect-timeout 3 -# -o";
		}
		
		# Split the url by /
		my @filename = split /\//, $url;
		
		# Download the file
		system "$fetchcommand \"$downloadto\" \"$url\"";
	}
	# Else
	else
	{
		# Use LWP::Simple
		eval "use LWP::UserAgent";
		
		# Make a handle for LWP
		my $lwp = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
		
		# Enable the "progressbar"
		$lwp->show_progress(1);
		
		# Download the file
		$lwp->get($url, ':content_file' => "$downloadto", 8192);
	}
}

#
#---------------------------------------- *** ----------------------------------------
#

sub readurl
{
	# Get the passed data
	my ($url, $max_time) = @_;
	
	# Load the HTTP::Tiny module
	use HTTP::Tiny;
	
	# Set the timeout in seconds
	my $timeout = 10;
	$timeout = $max_time if defined $max_time;
	
	# If the url starts with https
	if ($url =~ /^https/)
	{
		# Use the old readurl function
		my $response = readurl_https($url,$timeout);
		
		# Return the content
		return $response;
	}
	else
	{
		# Make a new http object
		my $http = HTTP::Tiny->new(timeout => $timeout, verify_SSL => "false");
		
		# Make a variable to contain the http response
		my $response = $http->get($url);
		
		# Return the content
		return $response->{content};
	}
}

sub readurl_https
{
	# Get the passed data
	my ($url, $timeout) = @_;
	
	# Get the current OS
	my $OS = "$^O";
	
	# Make a variable to contain the output
	my $output;
	
	# If we are on Windows
	if ($OS =~ /MSWin32/)
	{
		# Use LWP::Simple
		eval "use LWP::UserAgent";
		
		# Make a handle for LWP
		my $lwp = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
		
		# Set the timeout
		$lwp->timeout(3) if !defined $timeout;
		$lwp->timeout($timeout) if defined $timeout;
		
		# Get the content of $url
		my $response = $lwp->get("$url");
		
		# If we successfully got the content
		if ($response->is_success)
		{
			# Decode the content
			$output = $response->decoded_content;
		}
		# Else
		else
		{
			# Make output empty
			$output = "";
		}
	}
	# Else
	else
	{
		# Make a variable which will contain the download command we will use
		my $fetchcommand = "wget -q -O-";
		
		# If /usr/bin contains wget
		if(`ls /usr/bin | grep wget` =~  /wget/)
		{
			# Use wget command to fetch files
			$fetchcommand = "wget -q --connect-timeout=3 -O-" if !defined $timeout;
			$fetchcommand = "wget -q --connect-timeout=$timeout --timeout=$timeout -O-" if defined $timeout;
		}
		# Else if /usr/bin contains curl
		elsif(`ls /usr/bin | grep curl` =~  /curl/)
		{
			# Curl command equalent to the wget command to fetch files
			$fetchcommand = "curl -L --connect-timeout 3 -#" if !defined $timeout;
			$fetchcommand = "curl -L --connect-timeout $timeout -m $timeout -#" if defined $timeout;
		}

		# Read the contents of url
		$output = `$fetchcommand \"$url\"`;
	}
	
	# Return the content of $url
	return $output;
}

#
#---------------------------------------- *** ----------------------------------------
#

1; 
