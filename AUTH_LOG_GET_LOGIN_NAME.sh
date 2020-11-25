#!/bin/bash
TMP1=".tmp1.$$"
TMP2=".tmp2.$$"
TMP3=".tmp3.$$"
trap "rm -f $TMP1 $TMP2 $TMP3" EXIT SIGINT SIGTERM
function get_KeyFile()
{
read -p  "Enter the LOGIN user name : " loginUser
[[ ! -z $(id $loginUser 2> /dev/null) ]] && echo "The authorized keys under $loginUser will be inspected" || \
{ echo "No such user $loginUser exists !!!!"; exit; }
echo "Checking the authorized_keys file" 
USER_DIR=$(eval echo ~$loginUser)
[ -d $USER_DIR ] &&  DIR_FOUND="YES" || DIR_FOUND="NO"
if [[ $DIR_FOUND == "NO" ]] 
then
    echo "Could not find home directory for $loginUser"
else
	echo "The directory found : $USER_DIR"
fi
echo "Searching for file $USER_DIR/.ssh/authorized_keys"
KEY_FILE="$USER_DIR/.ssh/authorized_keys"
[ -e $KEY_FILE ] && echo "Authorized key file found"
[[ ! -e $KEY_FILE || -z $(cat $KEY_FILE) ]] && \
	{
		echo "Could not find $KEY_FILE or is empty"
read -p "Would you like to proceed [Y/N] : " choice
if [[ $choice =~ ^([Yy][eE][sS]|[Yy])$ ]]
then
    read -p "Enter the complete path of the file : " FILE_PATH
    [ -e "$FILE_PATH" ] && echo "Valid file path" || { echo "Not a valid path"; exit; }
    [[ -z $(cat $FILE_PATH) ]] && echo "$FILE_PATH is empty" && exit
    KEY_FILE="$FILE_PATH"
else
     echo "You have chosen to quit. Bye !!!"
     exit
fi
}
}
function generate_key_ofPublicKey()
{
	echo "Generating key for the available Public keys"
ssh-keygen -lf $KEY_FILE > $TMP1
[[ $? -ne 0 ||  ! -e $TMP1 || -z $(cat $TMP1) ]] && echo  "Generating SHA keys from public keys failed" && exit
}
function matchWithAuthLog()
{       LOG_FILE="/var/log/auth.log"
	read -p "Default log file is $LOG_FILE. Do you want to change it? [Y/N] " choice
	case "$choice" in
		[Yy][eE][sS]|[Yy]) read -p "Enter the full path of the file : " file1
			[[ ! -e $file1 || -z $(cat $file1) ]] && { echo "No such file"; exit; } || LOG_FILE=$file1

			;;
		[Nn][oO]|[Nn]) echo "No changes made. Log file is $LOG_FILE"
			;;
		*) echo "Invalid choice"
			;;
	esac
	 cat $LOG_FILE | grep sshd| grep publickey|awk {'print $1,$2,$3,$9,$11,$16 '} > $TMP2
	 [[  $? -ne 0 || ! -e $TMP2 || -z $(cat $TMP2) ]]  && echo "Could not extract sshd entries,ABORT!!!!" && exit
	 while IFS= read -r line;do keyVal=$(echo $line | awk {'print $6'} ); keyName=$(cat $TMP1| grep $keyVal|sort|uniq|awk {'print $3'});echo $line :$keyName;done < <(cat $TMP2) 2> /dev/null > $TMP3
		 cat $TMP3
 }
function main()
{
	get_KeyFile
	generate_key_ofPublicKey
	matchWithAuthLog
}

main
