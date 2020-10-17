This script is no longer used because we mostly don't use Tiki.

If we decided we want to use it, /srv/lojban/tiki-svn/lib/wiki-plugins/wikiplugin_jvs.php  is going to have to change because it expects to be able to see the same directories as jbovlaste.

Obvious fix is instead of grepping a local file, wget these files from the jbovlaste web server and grep that; should be very simple.

    #*****************************************************************************************************************
    # WordDump Script
    #
    # Used to give a list of words to the Tiki jbovlaste hack
    #
    # This used to live in the jvs repo, but it's now moved here.
    #
    # The Tiki end is at
    # /srv/lojban/tiki-svn/lib/wiki-plugins/wikiplugin_jvs.php
    #*****************************************************************************************************************

    # The script itself
    file { '/usr/local/bin/worddump.sh':
      owner  => root,
      group  => root,
      mode   => '0755',
      source => 'puppet:///modules/jbovlaste/worddump.sh',
    }

    # Cron to run it
    cron { 'jbovlaste worddump cron':
      command => '/usr/local/bin/worddump.sh',
      user    => 'apache',
      minute  => '58',
      require => File['/usr/local/bin/worddump.sh'],
    }
