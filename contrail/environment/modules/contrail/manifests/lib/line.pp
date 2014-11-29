# Macro to ensure that a line is either presnt or absent in file.
define contrail::lib::line($file, $line, $ensure = 'present') {
    case $ensure {
	default : { err ( "unknown ensure value ${ensure}" ) }
	present: {
	    exec { "/bin/echo '${line}' >> '${file}'":
		unless => "/bin/grep -qFx '${line}' '${file}'",
		logoutput => "true"
	    }
	}
	absent: {
	    exec { "/bin/grep -vFx '${line}' '${file}' | /usr/bin/tee '${file}' > /dev/null 2>&1":
	      onlyif => "/bin/grep -qFx '${line}' '${file}'",
		logoutput => "true"
	    }

	    # Use this resource instead if your platform's grep doesn't support -vFx;
	    # note that this command has been known to have problems with lines containing quotes.
	    # exec { "/usr/bin/perl -ni -e 'print unless /^\\Q${line}\\E\$/' '${file}'":
	    #     onlyif => "/bin/grep -qFx '${line}' '${file}'",
	    #     logoutput => "true"
	    # }
	}
    }
}
# End of macro line

