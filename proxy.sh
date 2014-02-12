#!/bin/bash
proxy_add=https://proxy22.iitd.ernet.in/cgi-bin/proxy.cgi
username=abc
pass=123
getsessionid()
{
	session_id=`curl $proxy_add -s -k --no-progress-bar | grep -m 1 sessionid[\"=[:alpha:]\ ]*[[:digit:]]* | grep -oh "\"[[:digit:]][[:alnum:]]*\"" | sed 's|"||' | sed 's|"||' `
}

logout()
{
	curl -d "sessionid=$session_id&action=logout" $proxy_add -k -s >/dev/null
	echo ""
	echo "Succesfully Logged Out"
	exit 0
}

login()
{
	logintext=`curl -d "sessionid=$session_id&action=Validate&userid=$username&pass=$pass" $proxy_add -k -s`
}

trap logout SIGINT

retries=1000

mainloop()
{
	getsessionid
	if [ ${#session_id} = 0 ] ;
		then
		echo "Cant get sessionID."
		if [ $retries -gt 0 ] ;
			then
			let "retries -= 1"
			sleep 10
			mainloop
		else
			echo "Cant Connect. Try again later."
			exit 127
		fi
	else
		retries=1000
		login
		if [ $? -gt 0 ]; 
			then
			echo 'Cant Login'
			mainloop
		else
			iflogin=`echo $logintext | grep "logged in successfully"`
			if [ ${#iflogin} = 0 ] ;
				then
				echo "Cant login right now. Maybe another proxy logged in. Retrying."
				sleep 10
				mainloop
			else
				echo "Login Successful"
				while true; do
					sleep 120
					curl -d "sessionid=$session_id&action=Refresh" $proxy_add -k -s >/dev/null
					if [ $? -gt 0 ] ;
						then
						curl -d "sessionid=$session_id&action=logout" $proxy_add -k -s >/dev/null
						mainloop
					else
					echo "Page Refreshed"
					fi
				done
			fi
		fi
	fi
}

mainloop
