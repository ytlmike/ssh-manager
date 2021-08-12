#!/bin/bash

ROOT_PATH=$(pwd)

MY_TRUE="1"
MY_FALSE="0"

REQUIRED_NAME=""
REQUIRED_TAGS=""
LIST_FILE=""
CONFIG_FILE=""

DEFAULT_USER=""
PASSWORD=""
TITLE_HOST=""
TITLE_PORT=""
TITLE_USER=""
TITLE_TAGS=""
TITLE_NAME=""
TITLE_PASS=""

POS_HOST=0
POS_PORT=0
POS_USER=0
POS_NAME=0
POS_TAGS=0
POS_PASS=0

TMP_FILE="/tmp/ssh-manager-list.csv"
TMP_CONFIG="/tmp/ssh-manager-config.ini"

usage() {
  echo "Usage:"
  echo "$0 [NAME]"
  echo "$0 [-c CONFIG_FILE_PATH] [-l LIST_FILE_PATH] [-t TAG1,TAG2][-n NAME]]"
}

#计算字符串的显示长度
function strDisplayLen() {
  charCount=${#1}
  bytes=0
  if [ "$(uname)" == "Darwin" ]; then
    bytes=$(echo $1 | awk '{print length($0)}')
  else
    bytes=$(expr length $1)
  fi
  ((displayLen = ($bytes - $charCount) / 2 + $charCount))
  echo $displayLen
}

function trim() {
  echo $1
}

function info() {
  echo -e "\033[32m $1 \033[0m"
}

function light() {
  echo -e "\033[33m $1 \033[0m"
}

function selected() {
  echo -e "\033[36m $1 \033[0m"
}

function warn() {
  l=$(strDisplayLen $1)
  s=""
  for ((i = 0; i < l; i++)); do
    s="$s "
  done
  echo -e "\033[43;37m $s \033[0m"
  echo -e "\033[43;37m $1 \033[0m"
  echo -e "\033[43;37m $s \033[0m"
}

function error() {
  l=$(strDisplayLen $1)
  s=""
  for ((i = 0; i < l; i++)); do
    s="$s "
  done
  echo -e "\033[41;37m $s \033[0m"
  echo -e "\033[41;37m $1 \033[0m"
  echo -e "\033[41;37m $s \033[0m"
}

function showTag() {
  hit=$2
  if [ "$hit" == $MY_TRUE ]; then
    echo "\033[36m◀\033[0m\033[46;37m $1 \033[0m"
  else
    echo "\033[32m◀\033[0m\033[42;37m $1 \033[0m"
  fi
}

function showName() {
  hit=$2
  if [ "$hit" == $MY_TRUE ]; then
    echo $(selected "◆ $1")
  else
    echo $(light "◆ $1")
  fi
}

function mustNotEmpty() {
  len=${#1}
  if [ "0" == "$len" ]; then
    error $2
    exit 1
  fi
}

function checkDependency() {
  if ! hash wget >/dev/null 2>&1; then
    error "缺少wget，请自行安装"
    exit 1
  fi
  if ! hash sshpass >/dev/null 2>&1; then
    info "缺少sshpass，正在安装..."
    info "wget https://ytlmike-public.oss-cn-beijing.aliyuncs.com/sshpass-1.08.tar.gz"
    wget https://ytlmike-public.oss-cn-beijing.aliyuncs.com/sshpass-1.08.tar.gz
    info "tar -xvf sshpass-1.08.tar.gz"
    tar -xvf sshpass-1.08.tar.gz
    info "cd sshpass-1.08"
    cd sshpass-1.08 || exit
    info "./configure"
    ./configure
    info "make"
    make
    info "sudo make install"
    sudo make install
    info "cd .."
    cd ..
    info "rm -rf sshpass-1.08"
    rm -rf sshpass-1.08
    info "rm sshpass-1.08.tar.gz"
    rm sshpass-1.08.tar.gz
  fi
  if [ "$(uname)" == "Darwin" ]; then
    if ! hash greadlink >/dev/null 2>&1; then
      echo "缺少greadlink，正在安装..."
      if ! hash brew >/dev/null 2>&1; then
        echo "缺少homebrew，请手动安装：https://docs.brew.sh/Installation"
        exit 1
      fi
      echo "brew install coreutils"
      brew install coreutils
    fi
  fi
}

function readConfig() {
  while read line; do
    OLD_IFS="$IFS"
    IFS="="
    arr=($line)
    IFS="$OLD_IFS"
    case ${arr[0]} in
    "USERNAME")
      DEFAULT_USER=${arr[1]}
      mustNotEmpty ${arr[1]} "缺少默认用户名配置"
      ;;
    "PASSWORD")
      PASSWORD=${arr[1]}
      ;;
    "TITLE_HOST")
      TITLE_HOST=${arr[1]}
      mustNotEmpty ${arr[1]} "缺少主机字段标题配置"
      ;;
    "TITLE_PORT")
      TITLE_PORT=${arr[1]}
      mustNotEmpty ${arr[1]} "缺少端口字段标题配置"
      ;;
    "TITLE_USER")
      TITLE_USER=${arr[1]}
      mustNotEmpty ${arr[1]} "缺少用户字段标题配置"
      ;;
    "TITLE_TAGS")
      TITLE_TAGS=${arr[1]}
      mustNotEmpty ${arr[1]} "缺少标签字段标题配置"
      ;;
    "TITLE_NAME")
      TITLE_NAME=${arr[1]}
      mustNotEmpty ${arr[1]} "缺少用户名字段标题配置"
      ;;
    "TITLE_PASS")
      TITLE_PASS=${arr[1]}
      mustNotEmpty ${arr[1]} "缺少密码字段标题配置"
      ;;
    esac
  done <"$TMP_CONFIG"
}

function locateRows() {
  first=$(head -1 $TMP_FILE)
  OLD_IFS="$IFS"
  IFS=","
  arr=($first)
  len=${#arr[*]}
  for ((i = 0; i < len; i++)); do
    case ${arr[$i]} in
    $TITLE_HOST) POS_HOST=$i ;;
    $TITLE_PORT) POS_PORT=$i ;;
    $TITLE_USER) POS_USER=$i ;;
    $TITLE_NAME) POS_NAME=$i ;;
    $TITLE_TAGS) POS_TAGS=$i ;;
    $TITLE_PASS) POS_PASS=$i ;;
    esac
  done
}

function run() {
  defaultUser=$DEFAULT_USER
  selectedNum=$1

  selected=$MY_FALSE
  numLen=${#selectedNum}
  if [ "0" != "$numLen" ]; then
    selected=$MY_TRUE
  fi

  OLD_IFS="$IFS"
  IFS=","
  selectedTagArr=($REQUIRED_TAGS)
  IFS="$OLD_IFS"
  selectedTagCount=${#selectedTagArr[*]}
  selectedNameLen=${#REQUIRED_NAME}

  i=0
  showedLines=0
  selectSuccess=$MY_FALSE
  lastHost=""
  lastPort=""
  lastUser=""
  lastPass=""
  display=""
  while read line; do
    if [ "$line" == "" ]; then
        continue
    fi

    OLD_IFS="$IFS"
    IFS=","
    arr=($line)

    if [ "0" == "$i" ]; then
      i=1
      continue
    fi

    tags=${arr[$POS_TAGS]}
    host=${arr[$POS_HOST]}
    port=${arr[$POS_PORT]}
    name=${arr[$POS_NAME]}
    user=${arr[$POS_USER]}
    pass=${arr[$POS_PASS]}

    IFS="|"
    tagArr=($tags)
    IFS="$OLD_IFS"

    userLen=${#user}
    if [ "0" == $userLen ]; then
      user=$defaultUser
    fi

    passLen=${#pass}
    if [ "0" == $passLen ]; then
      pass=$PASSWORD
    fi

    portLen=${#port}
    if [ "0" == $portLen ]; then
      port="22"
    fi

    l=$(light "[$i] $user@$host:$port")
    len=${#tagArr[*]}

    #检查限制的名称
    hitName=$MY_FALSE
    if [ "0" != "$selectedNameLen" ]; then
      if [ $REQUIRED_NAME == "$name" ]; then
        hitName=$MY_TRUE
      else
        continue
      fi
    fi

    nameLen=${#name}
    if [ $nameLen -gt 0 ]; then
      l="$l$(showName $name $hitName)"
    fi

    #检查要求的标签存在
    for ((k = 0; k < $selectedTagCount; k++)); do
      hit=$MY_FALSE
      for ((j = 0; j < $len; j++)); do
        if [ ${tagArr[j]} == ${selectedTagArr[k]} ]; then
          hit=$MY_TRUE
          break
        fi
      done
      if [ $hit == $MY_FALSE ]; then
        continue 2
      fi
    done

    #展示标签
    for ((j = 0; j < $len; j++)); do
      hit=$MY_FALSE
      for ((k = 0; k < $selectedTagCount; k++)); do
        if [ ${tagArr[j]} == ${selectedTagArr[k]} ]; then
          hit=$MY_TRUE
          break
        fi
      done
      l="$l $(showTag ${tagArr[j]} $hit)"
    done

    if [ "$i" == "$selectedNum" ]; then
      lastUser=$user
      lastHost=$host
      lastPort=$port
      lastPass=$pass
      selectSuccess=$MY_TRUE
      break
    fi

    if [ $MY_TRUE != $selected ]; then
      display="$display \n$l\n"
      lastUser=$user
      lastHost=$host
      lastPort=$port
      lastPass=$pass
      ((showedLines++))
    fi

    ((i++))
  done <"$TMP_FILE"

  echo -en $display

  if [ $MY_TRUE == $selectSuccess ]; then
    startConnect $lastUser $lastHost $lastPort $lastPass
    exit 0
  fi

  if [ "0" == $showedLines ]; then
    warn "没有符合条件的连接，请检查参数"
    return 1
  fi

  echo ""
  ask=""
  if [ $MY_TRUE == $selected ]; then
    ask="输入无效，请重新输入:"
  else
    if [ "1" == $showedLines ]; then
      startConnect $lastUser $lastHost $lastPort $PASSWORD
      exit 0
    fi
    ask="请输入要连接的服务器序号:"
  fi
  info $ask
  read -p " > " selectedNum
  run "$selectedNum"
}

function startConnect() {
  user=$1
  host=$2
  port=$3
  pass=$4
  pwLen=${#pass}
  info "正在连接：$user@$host:$port"
  echo ""
  if [ $pwLen -gt 0 ]; then
    sshpass -p $pass ssh -tt -o StrictHostKeyChecking=no $user@$host -p $port
  else
    sshpass ssh -tt -o StrictHostKeyChecking=no $user@$host -p $port
  fi
}

#解析参数
while getopts "t:n:c:l:" arg; do
  case $arg in
  t)
    REQUIRED_TAGS=$OPTARG
    ;;
  n)
    REQUIRED_NAME=$OPTARG
    ;;
  c)
    CONFIG_FILE=$OPTARG
    ;;
  l)
    LIST_FILE=$OPTARG
    ;;
  ?)
    usage
    exit 1
    ;;
  esac
done

checkDependency

if [ "$(uname)" == "Darwin" ]; then
  script=$(greadlink -f "$0")
else
  script=$(readlink -f "$0")
fi
ROOT_PATH=$(dirname "$script")

if [ ${#LIST_FILE} -eq 0 ]; then
  LIST_FILE="$ROOT_PATH/list.csv"
fi
if [ ${#CONFIG_FILE} -eq 0 ]; then
  CONFIG_FILE="$ROOT_PATH/config.ini"
fi

arg0=$1
word0=${arg0:0:1}
if [ "-" != "$word0" ]; then
  REQUIRED_NAME=$arg0
fi

if [ ! -f "$CONFIG_FILE" ]; then
  error "未检测到配置文件文件config.ini"
  exit 1
fi

if [ ! -f "$LIST_FILE" ]; then
  error "未检测到列表文件list.csv"
  exit 1
fi

awk '{ gsub(/,[ ]+/,","); print $0 }' $LIST_FILE | awk '{ gsub(/\r/,""); print $0 }' > $TMP_FILE
awk '{ gsub(/\r/,""); print $0 }' $CONFIG_FILE > $TMP_CONFIG

readConfig
locateRows
run
