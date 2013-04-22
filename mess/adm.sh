sudo cp -r --preserve=all original_directory_name copied_directory_name

-------------------------
ssh -X iiisclient@10.10.0.201
gedit
gnome-terminal
-------------------------

#change the hostname
vi /etc/hostname
#####################
vi /etc/hosts
127.0.1.1
#####################
sudo /etc/init.d/hostname.sh start?????? no exist


#find the key word
###content
find . | xargs grep logo.png
find . -name "*" | xargs grep "test"
###filename
find . -name "*hello*"

cat aaa | xargs -i{} echo {} | xargs -i{} quantum router-delete {}

quantum router-list -F id -f csv | sed 's/["\n]//g' | xargs -i{} quantum router-delete {}

useradd -m xiangyong -s /bin/bash
usermod -aG sudo xiangyong

gpasswd -d xiangyong sudo

#find the content from all the file under a directory
grep "192.168.10.51" -rl /etc


