#!/bin/bash

if [ $(whoami) != 'root' ]; then
    echo "Must be root to run $0"
    exit
fi

if [ -z `find / | grep -i autotools/move.php` ]; then
    echo "Move.php not found. You must install the Autotools plugin before running this script."
    exit
fi

ask_user(){
while true
  do
    read answer
    case $answer in [Yy]* ) return 0 ;;
                    [Nn]* ) return 1 ;;
                        * ) echo "Enter y or n";;
    esac
done
}

autotools=1
while [ $autotools = 1 ];
  do
    echo -n "Before proceeding ensure you have enabled Autotools. Refer to the screenshot in Section 3. Have you enabled Autotools? y/n "
    if ask_user; then
    autotools=0
    fi
done

confirm_name=1
while [ $confirm_name = 1 ];
  do
    read -p "Enter your username: " answer
    user=$answer
    echo -n "Is your username $answer? y/n "
    if ask_user; then
    confirm_name=0
    fi
done

movie_label=1
while [ $movie_label = 1 ];
  do
    read -p "Enter your movie label: " answer
    movie=$answer
    echo -n "Is your movie label $answer? y/n "
    if ask_user; then
    movie_label=0
    fi
done

tv_label=1
while [ $tv_label = 1 ];
  do
    read -p "Enter your TV label: " answer
    tv=$answer
    echo -n "Is your TV label $answer? y/n "
    if ask_user; then
    tv_label=0
    fi
done

read -r -p "Do you want Filebot to fetch artwork? y/n " response
response=${response,,}
if [[ $response =~ ^(yes|y)$ ]]; then
    art=y
else
    art=n
fi

home=$(eval echo "~$user")
path=`find / | grep -i autotools/move.php`

cd $home

echo "Installing Grive"
apt-get -y install git cmake build-essential libgcrypt11-dev libyajl-dev libboost-all-dev libcurl4-openssl-dev libexpat1-dev libcppunit-dev binutils-dev
git clone https://github.com/vitalif/grive2.git
cd grive2
mkdir build
cd build
cmake ..
make -j4
make install
cd $home
rm -rf grive2
mkdir gdrive
chown $user: gdrive
chmod 775 gdrive

echo "Installing Filebot"
if [[ `add-apt-repository` == 'Error: need a repository as argument' ]]; then
    true
else
    apt-get -y install software-properties-common
fi
add-apt-repository -y ppa:webupd8team/java
apt-get -y update
apt-get -y install oracle-java8-installer

if [ `uname -m` = "i686" ]; then
    wget -O filebot-i386.deb 'http://filebot.sourceforge.net/download.php?type=deb&arch=i386'
else
    wget -O filebot-amd64.deb 'http://filebot.sourceforge.net/download.php?type=deb&arch=amd64'
fi
dpkg --force-depends -i filebot-*.deb
rm filebot-*.deb

echo "Configuring scripts"
echo '#!/bin/bash

cd "$sync_folder"
while [ -f queue ]; do sleep 1; done

if [ "$skipped" == "no" ]; then
   readarray -t filebot <<< "$renamed"
   for folder in "${filebot[@]}"; do
     grive -s "$folder"
     rm -rf "$folder"
   done
   mkdir "Upload Completed"
   grive -s "Upload Completed"
   rm -rf "Upload Completed"
   readarray -t extractedfiles <<< "$(find "$base_path" -name '*.rar' -or -name '*.zip' | rev | cut -f 2- -d '.' | rev)"
   rm -rf "${extractedfiles[@]}"
   echo "sleep 60 && rm queue" >> queue
   bash queue &
   exit
fi

if [[ -f "$base_path/$name" ]]; then
 if [[ "$name" = *.rar || "$name" = *.zip ]] && [[ "$label" =~ "$movie_label" ]]; then
   mkdir "symlinks"
   mkdir "$name (MV)"
   unrar e -r -o- "$name" "$sync_folder/symlinks"
   unzip "$name" -d "$sync_folder/symlinks"
   unrar e -r -o- "$sync_folder/symlinks/*.rar" "$sync_folder/symlinks"
   unzip "$sync_folder/symlinks/*.zip" -d "$sync_folder/symlinks"
   find "$sync_folder/symlinks" -not -type d -not -name '*.zip' -not -name '*.r*' -exec ln -s {} "$sync_folder/$name (MV)" \;
   grive -s "$name (MV)"
   mkdir "Upload Completed"
   grive -s "Upload Completed"
   rm -rf "Upload Completed"
   rm -rf "symlinks"
   rm -rf "$name (MV)"
   echo "sleep 60 && rm queue" >> queue
   bash queue &
   exit
 elif [[ "$name" = *.rar || "$name" = *.zip ]] && [[ "$label" =~ "$tv_label" ]]; then
   mkdir "symlinks"
   mkdir "$name (TV)"
   unrar e -r -o- "$name" "$sync_folder/symlinks"
   unzip "$name" -d "$sync_folder/symlinks"
   unrar e -r -o- "$sync_folder/symlinks/*.rar" "$sync_folder/symlinks"
   unzip "$sync_folder/symlinks/*.zip" -d "$sync_folder/symlinks"
   find "$sync_folder/symlinks" -not -type d -not -name '*.zip' -not -name '*.r*' -exec ln -s {} "$sync_folder/$name (TV)" \;
   grive -s "$name (TV)"
   mkdir "Upload Completed"
   grive -s "Upload Completed"
   rm -rf "Upload Completed"
   rm -rf "symlinks"
   rm -rf "$name (TV)"
   echo "sleep 60 && rm queue" >> queue
   bash queue &
   exit
 elif [[ "$name" != *.rar || "$name" != *.zip ]] && [[ "$label" =~ "$movie_label" ]]; then
   mkdir "$name (MV)"
   ln -s "$base_path/$name" "$sync_folder/$name (MV)"
   grive -s "$name (MV)"
   mkdir "Upload Completed"
   grive -s "Upload Completed"
   rm -rf "Upload Completed"
   rm -rf "$name (MV)"
   echo "sleep 60 && rm queue" >> queue
   bash queue &
   exit
 elif [[ "$name" != *.rar || "$name" != *.zip ]] && [[ "$label" =~ "$tv_label" ]]; then
   mkdir "$name (TV)"
   ln -s "$base_path/$name" "$sync_folder/$name (TV)"
   grive -s "$name (TV)"
   mkdir "Upload Completed"
   grive -s "Upload Completed"
   rm -rf "Upload Completed"
   rm -rf "$name (TV)"
   echo "sleep 60 && rm queue" >> queue
   bash queue &
   exit
fi
fi

if [[ -d "$base_path" && "$label" =~ "$movie_label" ]]; then
   mkdir "symlinks"
   mkdir "$name (MV)"
   unrar e -r -o- "$base_path/*.rar" "$sync_folder/symlinks"
   unzip "$base_path/*.zip" -d "$sync_folder/symlinks"
   find "$sync_folder/symlinks" -not -type d -not -name '*.zip' -not -name '*.r*' -exec ln -s {} "$sync_folder/$name (MV)" \;
   find "$base_path" -not -type d -not -name '*.zip' -not -name '*.r*' -exec ln -s {} "$sync_folder/$name (MV)" \;
   grive -s "$name (MV)"
   mkdir "Upload Completed"
   grive -s "Upload Completed"
   rm -rf "Upload Completed"
   rm -rf "symlinks"
   rm -rf "$name (MV)"
   echo "sleep 60 && rm queue" >> queue
   bash queue &
   exit
 elif [[ -d "$base_path" && "$label" =~ "$tv_label" ]]; then
   mkdir "symlinks"
   mkdir "$name (TV)"
   unrar e -r -o- "$base_path/*.rar" "$sync_folder/symlinks"
   unzip "$base_path/*.zip" -d "$sync_folder/symlinks"
   find "$sync_folder/symlinks" -not -type d -not -name '*.zip' -not -name '*.r*' -exec ln -s {} "$sync_folder/$name (TV)" \;
   find "$base_path" -not -type d -not -name '*.zip' -not -name '*.r*' -exec ln -s {} "$sync_folder/$name (TV)" \;
   grive -s "$name (TV)"
   mkdir "Upload Completed"
   grive -s "Upload Completed"
   rm -rf "Upload Completed"
   rm -rf "symlinks"
   rm -rf "$name (TV)"
   echo "sleep 60 && rm queue" >> queue
   bash queue &
   exit
fi' > gdrive.sh

chown $user: gdrive.sh
chmod +x gdrive.sh

echo '#!/bin/bash

export sync_folder=$1
export skipped=$2
export base_path=$3
export name=$4
export label=$5
export movie_label=$6
export tv_label=$7
export renamed=$8

while pgrep -fl gdrive.sh; do sleep 60; done
mv ~/gqueue/* ~/gdrive
bash ~/gdrive.sh &' > gqueue.sh

chown $user: gqueue.sh
chmod +x gqueue.sh

mkdir gqueue
chown $user: gqueue
chmod 775 gqueue

sed -i '/Debug( "--- end ---" );/i \
$tv_label = "'"$tv"'";\
$movie_label = "'"$movie"'";\
$bash_script = "'"$home"'/gqueue.sh";\
$queue_folder = "'"$home"'/gqueue";\
$sync_folder = "'"$home"'/gdrive";\
\
if (strpos($base_path, $movie_label) !== false || strpos($base_path, $tv_label) !== false) {\
   $filebot = shell_exec("filebot -script fn:amc --output \\"$queue_folder\\" --action symlink --conflict skip -non-strict --def unsorted=y artwork='"$art"' excludeList=.excludes ut_dir=\\"$base_path\\" ut_kind=multi ut_title=\\"$name\\" ut_label=\\"$label\\" movieFormat=\\"{n} ({y}) (MV)/{n} - ({fn})\\" seriesFormat=\\"{n} (TV)/Season {s.pad(2)}/Episode {e.pad(2)}/{s00e00} - ({fn})\\" exec=\\"Operation Successful {folder}\\"");\
if (strpos($filebot, "Execute: Operation Successful") === false) {\
   $skipped = "yes";\
   exec("bash \\"$bash_script\\" \\"$sync_folder\\" \\"$skipped\\" \\"$base_path\\" \\"$name\\" \\"$label\\" \\"$movie_label\\" \\"$tv_label\\" > /dev/null 2>&1 &");\
}  else {\
   $skipped = "no";\
   $renamed1 = explode("\\n", $filebot);\
   $renamed2 = preg_grep("/Execute: Operation Successful/", $renamed1);\
   $renamed3 = str_replace("Execute: Operation Successful $queue_folder/", "", $renamed2);\
   $renamed4 = preg_replace('"'/"'\\'"/(.*)/'"', "", $renamed3);\
   $renamed5 = array_unique($renamed4);\
   $renamed6 = implode("\\n", $renamed5);\
   exec("bash \\"$bash_script\\" \\"$sync_folder\\" \\"$skipped\\" \\"$base_path\\" \\"$name\\" \\"$label\\" \\"$movie_label\\" \\"$tv_label\\" \\"$renamed6\\" > /dev/null 2>&1 &");\
}\
}\
' $path

echo "Configuring Grive"
cd gdrive
echo "After you have entered your code, press Ctrl + C when \"Reading remote server file list\" displays"
grive -a

echo "Script completed successfully"
