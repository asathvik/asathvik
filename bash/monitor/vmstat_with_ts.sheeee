   
# Created: 2012-10-17
# Credit goes to http://www.thegeekstuff.com/2009/08/how-to-add-timestamp-to-unix-vmstat-command-output/ and Milan Cvejic for an idea on how to do this in a simple method.

# Capture vmstat with timestamp information. vmstat version 3.2.8 (maybe even older) support "-t" option, which displays timestamp information.

options=$@

vmstat -n $options | while read line
do
	echo "$(date +'%Y-%m-%d %H:%M:%S') $line"
done
