package client::launch::updater;
#
#    The main script of the rsu-client, this takes care of overhead stuff
#    Copyright (C) 2011-2013  HikariKnight
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
####
# All files(except jagexappletviewer.jar) and modules used by this script
# uses the same license stated above unless something else is specified
# in their header. External commands use their own license
####
#################################
#   Contributors in this file   #
#################################
# HikariKnight - Main developer #
# Fallen Unia - Zenity support  #
#################################

my $windowsurl = "http://www.runescape.com/downloads/runescape.msi";
my $macurl = "http://www.runescape.com/downloads/runescape.dmg";
my $updateurl = "http://dl.dropbox.com/u/11631899/opensource/Perl/runescape_unix_client/update.tar.gz";

# Be strict to avoid messy code
use strict;

# Use FindBin module to get script directory
use Cwd;

# Get script directory
my $cwd = getcwd;

# Include perl modules in ./modules/client_modules/extra
#use lib $FindBin::RealBin."/modules/client_modules/extra";
# Require rsu_zenity so we can make dialog windows if zenity is installed
use updater::gui::zenity;

# Make a variable to contain the client directory
my $clientdir = $cwd;

# Detect the current OS
my $OS = "$^O";

# Make a variable to contain the temponairly %PATH% variable
my $win32path;

# Make a variable to contain if the user ran script as root or not
my $isroot;

# Make a variable to contain the users home folder
my $HOME;

# If we are running on windows then
if ($OS =~ /MSWin32/)
{
	# Replace / with \\
	$cwd =~ s/\//\\\\/g;
	
	# Path variable to set in windows
	$win32path = "set PATH=$cwd\\win32\\perl\\bin;$cwd\\win32\\gnu\\;$cwd\\win32\\7-zip\\;%PATH%";
}
# Else we are on unix
else
{
	# Check if we are root
	$isroot = `whoami`;
	
	# Get users homefolder
	$HOME = $ENV{"HOME"};
}


# Make variable to contain the 7zip binary name
my $zipbin = "7z";
	
# command to fetch the p7zip source
my $fetchcommand = "wget -O";

# Define the variable to wait for the user to press Enter to exit
my $exit;
			
# If we are on mac osx we need to use curl
if ($OS =~ /darwin/)
{
	# Curl command equalent to the wget command
	$fetchcommand = "curl -L -o";
}
# Else if STATEMENT
elsif($OS =~ /MSWin32/)
{
	# Set the temponairly PATH environment variable and add wget to the fetchcommand
	$fetchcommand = "$win32path && wget -O";
}
# Else if /usr/bin contains wget
elsif(`ls /usr/bin | grep wget` =~  /wget/)
{
	# Use wget command to fetch files
	$fetchcommand = "wget -O";
}
# Else if /usr/bin contains curl
elsif(`ls /usr/bin | grep curl` =~  /curl/)
{
	# Curl command equalent to the wget command to fetch files
	$fetchcommand = "curl -L -o";
}

# Make a variable to control if we are going to use zenity or not
my $usezenity = updater::gui::zenity::checkfor_zenity();

# If we are inside an interactive shell then
if (-t STDOUT || $usezenity =~ /1/)
{
	
	# If this script have been installed systemwide
	if ($cwd =~ /^(\/usr\/s?bin|\/opt\/|\/usr\/local\/s?bin)/)
	{
		# change $clientdir to ~/.config/runescape
		$clientdir = "$HOME/.config/runescape/";
		
		# Make the client folders
		system "mkdir -p \"$HOME/.config/runescape/bin\" && mkdir -p \"$HOME/.config/runescape/share\"";
	}

	# run the script
	main();
}
# else
else
{
	# run script in xterm so we can get input from user
	system ("xterm -e \"perl $cwd/update-runescape-client\"");
}

sub main
{
	# Place the main message in a variable
	my $updatetext = "Due to Legal Reasons the file jagexappletviewer.jar is not \navailable/downloadable in certain countries. For this script \nto work you must be able to download at LEAST one of the \nOfficial RuneScape Clients for extraction!\n\n";
	
	# Make a variable to contain the answers
	my $answer;
	
	# If zenity is not installed, print all text to the console
	if ($usezenity =~ /0/)
	{
		# Show the updatetext
		print $updatetext;
		
		# Ask what type of update to run
		print "What type of update do you want to run?\n [1] Update jagexappletviewer.jar(from Jagex) by using the\n     official Windows client, then ask to update the scripts. (default)\n\n [2] Update jagexappletviewer.jar(from Jagex) by using the\n     official MacOSX client(EXPERIMENTAL! but smaller download),\n     then ask to update the scripts.\n\n";
		
		# If the script is not located in /opt
		if ($cwd !~ /^(\/usr\/s?bin|\/opt\/|\/usr\/local\/s?bin)/)
		{
			# Show the 3rd option
			print " [3] Update the rsu-client scripts (from HikariKnight)\n\n";
		}
		
		# Complete the message
		print "Enter the number for your choice:";
		
		# Get user input
		$answer = <STDIN>;
	}
	# Else use zenity
	else
	{
		# Make a variable to contain the update script option for zenity
		my $updatescriptoption;
		
		# If the script is not located in /opt
		if ($cwd !~ /^(\/usr\/s?bin|\/opt\/|\/usr\/local\/s?bin)/)
		{
			# Show the 3rd option
			$updatescriptoption = 'FALSE "Update the rsu-client scripts (from HikariKnight)"';
		}
		
		# Display the message and options though zenity
		$answer = updater::gui::zenity::zenity_radiolist("Information", "$updatetext\n\nWhat type of update do you want to run?", "TRUE \"Update the jagexappletviewer.jar \(Extract from Windows client\)\" 0 \"Update the jagexappletviewer.jar \(Extract from Mac client\)\" $updatescriptoption");
		
		# If user choose update from jagexappletviewer.jar from the windows client
		if ($answer =~ /Windows client/)
		{
			$answer = "1";
		}
		# Else if user choose update from jagexappletviewer.jar from the mac client
		elsif($answer =~ /Mac client/)
		{
			$answer = "2";
		}
		# Else if user choose update the rsu-client scripts
		elsif($answer =~ /rsu-client scripts/)
		{
			$answer = "3";
		}
		# Else cancel was clicked
		else
		{
			exit;
		}
	}
	
	
	# If user answered 2 then run the script updater and exit
	if ($answer =~ /^3/ && $cwd !~ /\/opt\/runescape/)
	{
		# Execute script updater
		runscriptupdater();
		
		# Make a done message
		my $donemessage = "Done running the update process!";
		
		if ($usezenity =~ /0/)
		{
			# Tell user the update is done
			print "\n$donemessage\nPress Enter/Return to exit:";
			
			# Wait for user to press enter
			$exit = <STDIN>;
		}
		else
		{
			# Tell the user that the update is done
			updater::gui::zenity::zenity_info("Update Done!", "$donemessage\nYou should now have the latest version of RSU-Client installed!");
		}
		
		# Exit script
		exit;
	}
	
	# If we are on windows
	if ($OS =~ /MSWin32/)
	{
		# Make updating folder
		system "mkdir \"$clientdir\\.updating\"";
	}
	# Else we are on unix
	else
	{
		# Make updating folder
		system "mkdir \"$clientdir/.updating\"";
		
		# Check if p7zip-full is installed, otherwise compile it
		checkfor_p7zip();
	}
	
	# If user entered "2" on the choices of what to update from
	if ($answer =~ /^2/)
	{
		# Download and extract the jagexappletviewer from the official MacOSX client
		updatefrommacclient();
	}
	# Else
	else
	{
		# Download and extract the jagexappletviewer from the official windows client
		updatefromwindowsclient();
	}
		
	# Clean up based on operatingsystem
	# If we are on windows
	if ($OS =~ /MSWin32/)
	{
		# Remove the .updating directory
		system "cd \"$clientdir\" && rmdir /S /Q \"$clientdir\\.updating\"";
	}
	# Else we are on unix
	else
	{
		system "cd \"$clientdir\" && rm -rf \"$clientdir/.updating/\"";
	}
	
	# If the script is not located in a read only location for the user
	if ($cwd !~ /^(\/usr\/s?bin|\/opt\/|\/usr\/local\/s?bin)/)
	{
		# Make a variable to hold the users answer
		my $updatescripts = "n";
		
		if ($usezenity =~ /0/)
		{
			# Ask user if we shall update the scripts too
			print "\nDo you want to update the RuneScape UNIX Client scripts too?\n[y/n] (default = y):";
			
			# Get user input
			$updatescripts = <STDIN>;
		}
		# Else zenity is installed
		else
		{
			# Display a question asking the user if they want to update the scripts too (displaying a question in zenity makes it use the return code as output meaning system will be able to get it)
			$updatescripts = updater::gui::zenity::zenity_question("Update Scripts Too?", "Do you want to update the RuneScape UNIX Client scripts too?");
		}
		
		# If user said yes or choose the default
		if ($updatescripts !~ /^(n|N)/)
		{
			# Execute script updater
			runscriptupdater();
		}
	}
	
	# Make a done message
	my $donemessage = "Done running the update process!";
	
	# If zenity is not installed
	if ($usezenity =~ /0/)
	{
		# Tell user the update is done
		print "\n$donemessage\nPress Enter/Return to exit:";
		
		# Wait for user to press enter
		$exit = <STDIN>;
	}
	else
	{
		# Tell the user that the update is done
		updater::gui::zenity::zenity_info("Update Done!", "$donemessage\nYou should now have the latest version of the jagexappletviewer.jar!");
	}
	
	# Exit the script
	exit;
}

#
#---------------------------------------- *** ----------------------------------------
#

# Read contents from a file and put it into a pointer
sub ReadFile 
{
	# Gets passed data from the function call
	my ($filename) = @_;

	# Makes an array to keep the inputdata
	my @inputdata;

	# Opens the passed file, if error it dies with the message "Can't open filename"
	open (my $FILE, "$filename") || die "Can not open $_!";

	# While there is something in the file
	while(<$FILE>)
	{
		# Skip problematic lines in the 7zip makefile
		next if /^\s*\$\(MAKE\) -C CPP\/7zip\/Compress\/Rar/;
		
		# Push data into the inputdata array
		push(@inputdata, $_)
	}

	# Close the file
	close($FILE);

	# Return the pointer to the datafile inputdata
	return(\@inputdata);
}

#
#---------------------------------------- *** ----------------------------------------
#

sub runscriptupdater
{
	# Make a newline so the output looks nicer
	print "\n";
	
	startupdate();
}

#
#---------------------------------------- *** ----------------------------------------
#

sub get_p7zip
{
	# If we are running on freebsd we need to tell the user to install p7zip manually
	if($OS =~ /freebsd/)
	{
		# Tell the user to install p7zip-full/p7zip from ports then re run this script
		# p7zip have different makefiles for each freebsd version, the bsd ports include
		# a freebsd prepared source unless p7zip-full is already installed by default
		print "You are running a version of FreeBSD that comes without p7zip-full installed!\nPlease install p7zip/p7zip-full from ports,\nthen re run this script.\n\nPress ENTER/RETURN to exit:";
		my $exit = <STDIN>;
		exit;
	}
			
	# Tell user that we did not find the 7z binary and offer to download and compile a local copy
	print "I was unable to find the 7z binary!
Please install the package p7zip-full from your package manager
if you want it to be installen across your system.
For compability reasons this script can download and compile
p7zip-full for local usage of the client updater only!
Doing so requires the packages gcc, make and g++.

Is it ok for me to try download and compile the binary 
for use in this and later updates?
Answer (default = y) [y/n]:";
	# Get users reply for the question above
	my $installp7zip = <STDIN>;
	
	#If user said no then
	if ($installp7zip =~ /(n|No)/i)
	{
		# Show user a final message and ask them to press ENTER/RETURN to exit
		print "\nPlease use your package manager to install p7zip-full\nso that you can update the client.\nIf you cannot find p7zip-full then try install p7zip\nand then try run the command \"7z\".\nIf it is found then you have installed p7zip-full.\n\nPress ENTER/RETURN to exit:";
		my $exit = <STDIN>;
		exit;
	}
			
	# Run the commands
	system "mkdir \"$clientdir/p7zip-source\" && mkdir -p \"$clientdir/modules/7-zip/$OS/\$(uname -p)\" && $fetchcommand \"$clientdir/p7zip-source/p7zip_9.20.1_src_all.tar.bz2\" http://downloads.sourceforge.net/project/p7zip/p7zip/9.20.1/p7zip_9.20.1_src_all.tar.bz2 && cd \"$clientdir/p7zip-source/\" && tar -xvf \"$clientdir/p7zip-source/p7zip_9.20.1_src_all.tar.bz2\"";
			
	# Copy the correct makefile "header" to makefile.machine so it will build on our current system(p7zip default is linux)
	# If we are on darwin/macosx
	if ($OS =~ /darwin/)
	{
		# Use the 32bit makefile header, since the 64bit one lacks some libraries by default
		system "cp \"$clientdir/p7zip-source/p7zip_9.20.1/makefile.macosx_32bits_asm\" \"$clientdir/p7zip-source/p7zip_9.20.1/makefile.machine\"";
	}
	# Else if we are on solaris (solaris comes with p7zip-full installed but still having this just incase)
	elsif($OS =~ /solaris/)
	{
		# Check if we are on the sparc architecture
		my $solarisarch = `uname -a`;
				
		# If we are on a sparc processor
		if ($solarisarch =~ /sparc/)
		{
			# Use the sparc makefile "header"
			system "cp \"$clientdir/p7zip-source/p7zip_9.20.1/makefile.solaris_sparc_CC_32\" \"$clientdir/p7zip-source/p7zip_9.20.1/makefile.machine\"";
		}
		# Else we are on either i386/i586/i686 or x86_64 processor
		else
		{
			# Use the solaris makefile x86 header(the x86 version of solaris can run x64 code if the processor is capable of it)
			system "cp \"$clientdir/p7zip-source/p7zip_9.20.1/makefile.solaris_x86\" \"$clientdir/p7zip-source/p7zip_9.20.1/makefile.machine\"";
		}
	}
			
			
	# Now we need to "repair" the makefile and remove some stuff
	# we cannot use (like rar support since it is not in the source)
	# Read the makefile using ReadFile function that will skip the problematic lines
	my $makefile = ReadFile("$clientdir/p7zip-source/p7zip_9.20.1/makefile");
			
	# Write the new makefile, overwriting the old one
	#WriteFile("@$makefile", ">", "$cwd/p7zip-source/p7zip_9.20.1/makefile");
	system "echo $makefile > \"$clientdir/p7zip-source/p7zip_9.20.1/makefile\"";
			
	# Compile the 7-zip source
	system "cd \"$clientdir/p7zip-source/p7zip_9.20.1\" && make clean && make all3 && cp -v \"$clientdir/p7zip-source/p7zip_9.20.1/bin/\"* \"$clientdir/modules/7-zip/$OS/\$(uname -p)/\" && rm -rf \"$clientdir/p7zip-source/\"";
}

#
#---------------------------------------- *** ----------------------------------------
#

sub updatefromwindowsclient
{
	# If zenity is not installed
	if ($usezenity =~ /0/)
	{
		# Download the windows client
		system "$fetchcommand \"$clientdir/.updating/runescape.msi\" $windowsurl";
	}
	# Else zenity is installed
	else
	{
		# Download the mac client and show the user a zenity dialog while the file is being downloaded
		updater::gui::zenity::zenity_dl("$fetchcommand \"$clientdir/.updating/runescape.msi\" $windowsurl", "Downloading jagexappletviewer.jar", "Downloading and updating the jagexappletviewer.jar\nBy extracting it from the Official Windows Client.", "");
	}
	
	# If we are on anything but windows
	if ($OS !~ /MSWin32/)#/(darwin|freebsd|netbsd|openbsd|solaris|linux)/)
	{
		# Prepare the directory for p7zip (it requires the library to be
		# in the same directory we are in unless i make a wrapper
		# (but the .updating folder is getting removed anyway once we are done)
		system "cd \"$clientdir/.updating/\" && ln -s \"$clientdir/7-zip/$OS/\$(uname -p)/\"* ./";
		
		# Check if we can extract the jagexappletviewer.jar directly
		my $jarfile = `export PATH=\$PATH:$clientdir/modules/7-zip/$OS/\$(uname -p)/ && cd \"$clientdir/.updating/\" && $zipbin l runescape.msi | grep "JagexAppletViewerJarFile*" | cut -c54-1000`;
		# Remove newlines
		$jarfile =~ s/(\n|\r|\r\n)//g;
		
		# If we did not get the jagexappletviewer.jar listed then
		if ($jarfile !~ /JagexAppletViewerJarFile*/)
		{
			# Extract rslauncher.cab from runescape.msi
			system "export PATH=\$PATH:$clientdir/modules/7-zip/$OS/\$(uname -p)/ && cd \"$clientdir/.updating/\" && sleep 3 && $zipbin e runescape.msi rslauncher.cab ";
		
			# Find the name of the jar file
			$jarfile = `export PATH=\$PATH:$clientdir/modules/7-zip/$OS/\$(uname -p)/ && cd \"$clientdir/.updating/\" && $zipbin l rslauncher.cab | grep "JagexAppletViewerJarFile*" | cut -c54-1000`;
			# Remove newlines
			$jarfile =~ s/(\n|\r|\r\n)//g;
		
			# Extract jagexappletviewer.jar and move it into place
			system "export PATH=\$PATH:$clientdir/modules/7-zip/$OS/\$(uname -p)/ && cd \"$clientdir/.updating/\" && $zipbin e rslauncher.cab $jarfile && cp -v \"$clientdir/.updating/$jarfile\" \"$clientdir/bin/jagexappletviewer.jar\"";
		}
		# Else just extract the file directly
		else
		{
			# Extract jagexappletviewer.jar and move it into place
			system "export PATH=\$PATH:$clientdir/modules/7-zip/$OS/\$(uname -p)/ && cd \"$clientdir/.updating/\" && $zipbin e runescape.msi $jarfile";
			system "cp -v \"$clientdir/.updating/$jarfile\" \"$clientdir/bin/jagexappletviewer.jar\"";
		}
	}
	# Else we are on windows
	else
	{
		# Extract the jagexappletviewer.jar and place it into the client bin folder
		system "cd \"$cwd\\.updating\\\" && $win32path && 7z e runescape.msi JagexAppletViewerJarFile.* && ren JagexAppletViewerJarFile.* jagexappletviewer.jar && copy /Y \"$cwd\\.updating\\jagexappletviewer.jar\" \"$cwd\\bin\\jagexappletviewer.jar\"";
	}
	
}

#
#---------------------------------------- *** ----------------------------------------
#

sub updatefrommacclient
{
	# If zenity is not installed
	if ($usezenity =~ /0/)
	{
		# Download the Mac client
		system "$fetchcommand \"$clientdir/.updating/runescape.dmg\" $macurl";
	}
	# Else zenity is installed
	else
	{
		# Download the mac client and show the user a zenity dialog while the file is being downloaded
		updater::gui::zenity::zenity_dl("$fetchcommand \"$clientdir/.updating/runescape.dmg\" $macurl", "Downloading jagexappletviewer.jar", "Downloading and updating the jagexappletviewer.jar\nBy extracting it from the Official Mac Client.", "");
	}
	
	# If we are on anything but windows
	if ($OS !~ /MSWin32/)#/(darwin|freebsd|netbsd|openbsd|solaris|linux)/)
	{
		# Prepare the directory for p7zip (it requires the library to be
		# in the same directory we are in unless i make a wrapper
		# (but the .updating folder is getting removed anyway once we are done)
		system "cd \"$clientdir/.updating/\" && ln -s \"$clientdir/modules/7-zip/$OS/\$(uname -p)/\"* ./";
		
		# Extract the 2.hfs filesystem from the dmg file
		system "export PATH=\$PATH:$clientdir/modules/7-zip/$OS/\$(uname -p)/ && cd \"$clientdir/.updating/\" && $zipbin e runescape.dmg *.hfs";
		
		# Extract the hfs filesystem
		system "export PATH=\$PATH:$clientdir/modules/7-zip/$OS/\$(uname -p)/ && cd \"$clientdir/.updating/\" && $zipbin e *.hfs -y";
		
		# Copy the jagexappletviewer into place
		system "cp -v \"$clientdir/.updating/jagexappletviewer.jar\" \"$clientdir/bin/jagexappletviewer.jar\"";
	}
	# Else we are on windows
	else
	{
		# Extract and move jagexappletviewer.jar to the client bin folder
		system "cd \"$cwd\\.updating\\\" && $win32path && 7z e runescape.dmg *.hfs && 7z e *.hfs -y && copy \"$cwd\\.updating\\jagexappletviewer.jar\" \"$cwd\\bin\\jagexappletviewer.jar\"";
	}
	
}

#
#---------------------------------------- *** ----------------------------------------
#



sub checkfor_p7zip
{
	# Test for system installed 7zip
	my $test7zsys = `7z`;
	
	# Disable warnings for now to avoid a warning message if the 7z command returned nothing
	no warnings;
	
	# If we do not have 7zip, check if we have a compiled version from earlier
	if ($test7zsys !~ /7-Zip/)
	{
		# Tell user that the warning is bogus
		print "\n\n";
		
		# Set a new testpath
		my $test7z = `export PATH=\$PATH:$clientdir/modules/7-zip/$OS/\$(uname -p)/ && 7z`;
		
		# If we do not have 7zip at all
		if ($test7z !~ /7-Zip/)
		{
			# If zenity is not installed
			if ($usezenity =~ /0/)
			{
				# Download and compile p7zip-full from source
				get_p7zip();
			}
			# Else zenity is installed
			else
			{
				# Since it will be hard to effectively show the compile process in zenity
				# We will just tell the user to install p7zip themselves
				updater::gui::zenity::zenity_error("No p7zip found.", "I was unable to find the p7zip binary\\!\nPlease install the p7zip binary and re-run this script to continue.\n\n--Install Commands--\nUbuntu/Debian/Mint: sudo apt-get install p7zip-full\nFedora: su -c \\\"yum install p7zip-plugins\\\"\nArch-Linux: pacman -Syu p7zip");
				exit;
			}
		}
	}
	
	# Enable warnings again
	use warnings;
}

#
#---------------------------------------- *** ----------------------------------------
#

sub startupdate
{
	# Fetch the update.tar.gz and extract it
	if ($OS =~ /MSWin32/)
	{
		system "cd \"$cwd\" && $fetchcommand \"$cwd\\update.tar.gz\" $updateurl && 7z e update.tar.gz && 7z x -y update.tar && del /Q update.tar.gz && del /Q update.tar";
	}
	else
	{
		# If zenity is not installed
		if ($usezenity =~ /0/)
		{
			# Download the update and extract the files
			system "cd \"$cwd\" && $fetchcommand \"$cwd/update.tar.gz\" $updateurl && tar -zxvf update.tar.gz && rm update.tar.gz";
			
			# Show exit message
			print "\nPress ENTER/RETURN to exit:";
	
			# Wait for user to press enter
			my $exit = <STDIN>;
		}
		# Else zenity is installed
		else
		{
			# Download the update.tar.gz and show a zenity window for the user while the update process is running
			updater::gui::zenity::zenity_dl("cd \"$cwd\" && $fetchcommand \"$cwd/update.tar.gz\" $updateurl", "Updating the RSU-Client", "Downloading and updating the RSU-Client scripts.", "&& tar -zxvf update.tar.gz && rm update.tar.gz");
		}
	}
	
	# Exit script
	exit;
}

#
#---------------------------------------- *** ----------------------------------------
#

1;