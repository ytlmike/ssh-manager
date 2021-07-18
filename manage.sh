#!/bin/bash

ROOT_PATH=$(pwd)

MY_TRUE="1"
MY_FALSE="0"

REQUIRED_NAME=""
REQUIRED_TAGS=""
LIST_FILE="$ROOT_PATH/list.csv"
CONFIG_FILE="$ROOT_PATH/config.ini"

DEFAULT_USER=""
PASSWORD=""
TITLE_HOST=""
TITLE_PORT=""
TITLE_USER=""
TITLE_TAGS=""
TITLE_NAME=""

POS_HOST=0
POS_PORT=0
POS_USER=0
POS_NAME=0
POS_TAGS=0

usage() {
  echo "Usage:"
  echo "$0 [NAME]"
  echo "$0 [-c CONFIG_FILE_PATH] [-l LIST_FILE_PATH] [-t TAG1,TAG2][-n NAME]]"
}

trim() {
  echo $1 | grep -o "[^ ]\+\( \+[^ ]\+\)*"
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
  echo ""
  echo -e "\033[43;37m $1 \033[0m"
}

function error() {
  echo -e "\033[41;37m\n\n $1 \n\033[0m"
}

function showTag() {
  hit=$2
  if [ $hit == $MY_TRUE ]; then
    echo "\033[36m◀\033[0m\033[46;37m $1 \033[0m"
  else
    echo "\033[32m◀\033[0m\033[42;37m $1 \033[0m"
  fi
}

function showName() {
  len=${#1}
  if [ "0" == "$len" ]; then
    return 1
  fi
  hit=$2
  if [ $hit == $MY_TRUE ]; then
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
  hash sshpass >/dev/null 2>&1
  if [ "$?" != "0" ]; then

    wget https://ytlmike-public.oss-cn-beijing.aliyuncs.com/sshpass-1.08.tar.gz
    tar -xvf sshpass-1.08.tar.gz
    cd sshpass-1.08
    ./configure
    make
    sudo make install
    cd ..
    rm -rf sshpass-1.08
    rm sshpass-1.08.tar.gz
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
    esac
  done <"$CONFIG_FILE"
}

function locateRows() {
  first=$(head -1 $LIST_FILE)
  OLD_IFS="$IFS"
  IFS=","
  arr=($first)
  len=${#arr[*]}
  for ((i = 0; i < len; i++)); do
    title=$(trim ${arr[$i]})
    case $title in
    $TITLE_HOST) POS_HOST=$i ;;
    $TITLE_PORT) POS_PORT=$i ;;
    $TITLE_USER) POS_USER=$i ;;
    $TITLE_NAME) POS_NAME=$i ;;
    $TITLE_TAGS) POS_TAGS=$i ;;
    *)
      error "无效的csv标题：$title"
      exit 1
      ;;
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
  while read line; do
    OLD_IFS="$IFS"
    IFS=","
    arr=($line)

    if [ "0" == "$i" ]; then
      i=1
      continue
    fi

    tags=$(trim ${arr[$POS_TAGS]})
    host=$(trim ${arr[$POS_HOST]})
    port=$(trim ${arr[$POS_PORT]})
    name=$(trim ${arr[$POS_NAME]})
    user=$(trim ${arr[$POS_USER]})

    IFS="|"
    tagArr=($tags)
    IFS="$OLD_IFS"

    userLen=${#user}
    if [ "0" == $userLen ]; then
      user=$defaultUser
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
      if [ $REQUIRED_NAME == $name ]; then
        hitName=$MY_TRUE
      else
        continue
      fi
    fi
    l="$l$(showName $name $hitName)"

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
      startConnect $user $host $port $PASSWORD
      return 0
    fi

    if [ $MY_TRUE != $selected ]; then
      echo ""
      echo -e $l
      ((showedLines++))
    fi

    ((i++))
  done <"$LIST_FILE"

  echo ""
  ask=""
  if [ $MY_TRUE == $selected ]; then
    ask="输入无效，请重新输入:"
  else
    ask="请输入要连接的服务器序号:"
    if [ "1" == $showedLines ]; then
      startConnect $user $host $port $PASSWORD
      return 0
    fi
  fi
  info $ask
  read -p " > " selectedNum
  echo "选择的序号：$selectedNum"
  run "$selectedNum"
}

function startConnect() {
  user=$1
  host=$2
  port=$3
  pass=$4
  cmd="sshpass"
  pwLen=${#pass}
  if [ $pwLen -gt 0 ]; then
    cmd="$cmd -p $pass"
  fi
  cmd="$cmd ssh -o StrictHostKeyChecking=no $user@$host -p $port"
  info "正在连接：$user@$host:$port"
  bash -c $cmd
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

arg0=$1
word0=${arg0:0:1}
if [ "-" != "$word0" ]; then
  REQUIRED_NAME=$arg0
fi

if [ ! -f "$CONFIG_FILE" ]; then
  error "未检测到配置文件文件config.ini"
fi

if [ ! -f "$LIST_FILE" ]; then
  error "未检测到列表文件list.csv"
fi

checkDependency
readConfig
locateRows
run
