mailing_list.sh appears to be an old, primitive version of
jbovlaste_mailing_list_refresh.sh ; the latter runs on the mail server and
relies on ./containers/web/src/emails.html to generate the email list.

The goal of both was to allow automated updating of the jbovlaste mailing list in mailman.

They have been broken for months as of this writing (October 2020), and no-one noticed, so not bothering to fix them.

The HTTP bits were:

	<Location "/emails.html">
	  Require ip 192.168.123.0/24 173.13.139.234/29
	</Location>

And the puppet bits were:

	#*****************************************************************************************************************
	# Mailing list updating
	#*****************************************************************************************************************
	
	# The script itself
	file { '/usr/local/bin/jbovlaste_mailing_list_refresh.sh':
	  owner  => root,
	  group  => root,
	  mode   => '0755',
	  source => 'puppet:///modules/jbovlaste/jbovlaste_mailing_list_refresh.sh',
	}
	
	# Cron to run it
	cron { 'jbovlaste mailing list update cron':
	  command => '/usr/local/bin/jbovlaste_mailing_list_refresh.sh',
	  user    => 'root',
	  minute  => '21',
	  hour    => '21',
	  require => File['/usr/local/bin/jbovlaste_mailing_list_refresh.sh'],
	}
