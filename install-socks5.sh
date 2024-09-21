#!/bin/bash

# မိတ်ဆက်အချက်အလက်
echo -e "\e[32m
  ____   ___   ____ _  ______ ____  
 / ___| / _ \ / ___| |/ / ___| ___|  
 \___ \| | | | |   | ' /\___ \___ \ 
  ___) | |_| | |___| . \ ___) |__) |           Don't connect directly
 |____/ \___/ \____|_|\_\____/____/            No after-sales   
 Stitched Monster: 4-0-4 Original authors: RealNeoMan, k0baya, eooce
\e[0m"

# 获取当前用户名
USER=$(whoami)
WORKDIR="/home/${USER}/.nezha-agent"
FILE_PATH="/home/${USER}/.s5"

###################################################

socks5_config(){
# 提示用户输入socks5端口号
read -p "Please enter socks5 port number: " SOCKS5_PORT

# 提示用户输入用户名和密码
read -p "Please enter socks5 username: " SOCKS5_USER

while true; do
  read -p "Please enter the socks5 password (cannot contain @ and:）：" SOCKS5_PASS
  echo
  if [[ "$SOCKS5_PASS" == *"@"* || "$SOCKS5_PASS" == *":"* ]]; then
    echo "The password cannot contain @ and : symbols, please re-enter。"
  else
    break
  fi
done

# config.js文件
  cat > ${FILE_PATH}/config.json << EOF
{
  "log": {
    "access": "/dev/null",
    "error": "/dev/null",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": "$SOCKS5_PORT",
      "protocol": "socks",
      "tag": "socks",
      "settings": {
        "auth": "password",
        "udp": false,
        "ip": "0.0.0.0",
        "userLevel": 0,
        "accounts": [
          {
            "user": "$SOCKS5_USER",
            "pass": "$SOCKS5_PASS"
          }
        ]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    }
  ]
}
EOF
}

install_socks5(){
  socks5_config
  if [ ! -e "${FILE_PATH}/s5" ]; then
    curl -L -sS -o "${FILE_PATH}/s5" "https://github.com/eooce/test/releases/download/freebsd/web"
  else
    read -p "The socks5 program already exists. Do you want to re-download it? (Y/N Enter N)" downsocks5
    downsocks5=${downsocks5^^} # 转换为大写
    if [ "$downsocks5" == "Y" ]; then
      if pgrep s5 > /dev/null; then
        pkill s5
        echo "The socks5 process has been terminated"
      fi
      curl -L -sS -o "${FILE_PATH}/s5" "https://github.com/eooce/test/releases/download/freebsd/web"
    else
      echo "Using an existing socks5 program"
    fi
  fi

  if [ -e "${FILE_PATH}/s5" ]; then
    chmod 777 "${FILE_PATH}/s5"
    nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
	  sleep 2
    pgrep -x "s5" > /dev/null && echo -e "\e[1;32ms5 is running\e[0m" || { echo -e "\e[1;35ms5 is not running, restarting...\e[0m"; pkill -x "s5" && nohup "${FILE_PATH}/s5" -c ${FILE_PATH}/config.json >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32ms5 restarted\e[0m"; }
    CURL_OUTPUT=$(curl -s 4.ipw.cn --socks5 $SOCKS5_USER:$SOCKS5_PASS@localhost:$SOCKS5_PORT)
    if [[ $CURL_OUTPUT =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "The proxy was created successfully and the returned IP is: $CURL_OUTPUT"
      SERV_DOMAIN=$CURL_OUTPUT
      # 查找并列出包含用户名的文件夹
      found_folders=$(find "/home/${USER}/domains" -type d -name "*${USER,,}*")
      if [ -n "$found_folders" ]; then
          if echo "$found_folders" | grep -q "serv00.net"; then
              #echo "找到包含 'serv00.net' 的文件夹。"
              SERV_DOMAIN="${USER,,}.serv00.net"
          elif echo "$found_folders" | grep -q "ct8.pl"; then
              #echo "未找到包含 'ct8.pl' 的文件夹。"
              SERV_DOMAIN="${USER,,}.ct8.pl"
          fi
      fi

      echo "socks://${SOCKS5_USER}:${SOCKS5_PASS}@${SERV_DOMAIN}:${SOCKS5_PORT}"
    else
      echo "Proxy creation failed, please check your input。"
    fi
  fi
}

download_agent() {
    DOWNLOAD_LINK="https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_freebsd_amd64.zip"
    if ! wget -qO "$ZIP_FILE" "$DOWNLOAD_LINK"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
    return 0
}

decompression() {
    unzip "$1" -d "$TMP_DIRECTORY"
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]; then
        rm -r "$TMP_DIRECTORY"
        echo "removed: $TMP_DIRECTORY"
        exit 1
    fi
}

install_agent() {
    install -m 755 ${TMP_DIRECTORY}/nezha-agent ${WORKDIR}/nezha-agent
}

generate_run_agent(){
    echo "Please note the following three variables:"
    echo "Dashboard site address can be written as IP or domain name (domain name cannot be used for CDN); but please do not add prefixes such as http:// or https://, just write IP or domain name directly;"
    echo "Panel RPC port is the RPC port for Agent access set when your Dashboard is installed (default 5555);"
    echo "Agent key needs to be added to the management panel to obtain it."
    printf "Please enter the Dashboard site address:"
    read -r NZ_DASHBOARD_SERVER
    printf "Please enter the panel RPC port:"
    read -r NZ_DASHBOARD_PORT
    printf "Please enter the Agent key:"
    read -r NZ_DASHBOARD_PASSWORD
    printf "Whether to enable SSL/TLS encryption (--tls) for the gRPC port. If necessary, press [Y], which is not required by default. Users who do not understand can press Enter to skip:"
    read -r NZ_GRPC_PROXY
    echo "${NZ_GRPC_PROXY}" | grep -qiw 'Y' && ARGS='--tls'

    if [ -z "${NZ_DASHBOARD_SERVER}" ] || [ -z "${NZ_DASHBOARD_PASSWORD}" ]; then
        echo "error! All options cannot be empty"
        return 1
        rm -rf ${WORKDIR}
        exit
    fi

    cat > ${WORKDIR}/start.sh << EOF
#!/bin/bash
pgrep -f 'nezha-agent' | xargs -r kill
cd ${WORKDIR}
TMPDIR="${WORKDIR}" exec ${WORKDIR}/nezha-agent -s ${NZ_DASHBOARD_SERVER}:${NZ_DASHBOARD_PORT} -p ${NZ_DASHBOARD_PASSWORD} --report-delay 4 --disable-auto-update --disable-force-update ${ARGS} >/dev/null 2>&1
EOF
    chmod +x ${WORKDIR}/start.sh
}

run_agent(){
    nohup ${WORKDIR}/start.sh >/dev/null 2>&1 &
    printf "nezha-agent is ready, please press Enter to start it\n"
    read
    printf "Starting nezha-agent, please wait patiently...\n"
    sleep 3
    if pgrep -f "nezha-agent -s" > /dev/null; then
        echo "nezha-agent has been started!"
        echo "If the panel is not online, please check whether the parameters are filled in correctly, stop the agent process, delete the installed agent and reinstall it!"
        echo "Command to stop the agent process: pgrep -f 'nezha-agent' | xargs -r kill"
        echo "Command to delete the installed agent: rm -rf ~/.nezha-agent"
    else
        rm -rf "${WORKDIR}"
        echo "nezha-agent Startup failed. Please check whether the parameters are correct and reinstall.！"
    fi
}

install_nezha_agent(){
  mkdir -p ${WORKDIR}
  cd ${WORKDIR}
  TMP_DIRECTORY="$(mktemp -d)"
  ZIP_FILE="${TMP_DIRECTORY}/nezha-agent_freebsd_amd64.zip"

  # 如果 start.sh 文件不存在，则生成运行代理的脚本
  if [ ! -e "${WORKDIR}/start.sh" ]; then
    generate_run_agent
  else
    read -p "nezha-agent Configuration information already exists, do you want to reconfigure? (Y/N Enter N)" nezhaagentyn
    nezhaagentyn=${nezhaagentyn^^} # 转换为大写
    if [ "$nezhaagentyn" == "Y" ]; then
      generate_run_agent
    fi
  fi

  # 如果 nezha-agent 文件不存在，则下载并解压代理文件，然后进行安装
  if [ ! -e "${WORKDIR}/nezha-agent" ]; then
    download_agent
    decompression "${ZIP_FILE}"
    install_agent
  else
    read -p "nezha-agent The file already exists. Do you want to re-download the latest version? (Y/N Enter N)" nezhaagentd
    nezhaagentd=${nezhaagentd^^} # 转换为大写
    if [ "$nezhaagentd" == "Y" ]; then
      rm -rf "${ZIP_FILE}"
      if pgrep nezha-agent > /dev/null; then
        pkill nezha-agent
        echo "nezha-agent The process has been terminated"
      fi
      rm -rf "${WORKDIR}/nezha-agent"
      download_agent
      decompression "${ZIP_FILE}"
      install_agent
    fi
  fi

  # 删除临时目录
  rm -rf "${TMP_DIRECTORY}"

  # 如果 start.sh 文件存在，则运行代理
  if [ -e "${WORKDIR}/start.sh" ]; then
      run_agent
  fi

}

########################梦开始的地方###########################

read -p "Do you want to install socks5 (Y/N Enter N): " socks5choice
socks5choice=${socks5choice^^} # 转换为大写
if [ "$socks5choice" == "Y" ]; then
  # 检查socks5目录是否存在
  if [ -d "$FILE_PATH" ]; then
    install_socks5
  else
    # 创建socks5目录
    echo "Creating socks5 directory..."
    mkdir -p "$FILE_PATH"
    install_socks5
  fi
else
  echo "Do not install socks5"
fi

read -p "Do you want to install nezha-agent (Y/N Enter N): " choice
choice=${choice^^} # 转换为大写
if [ "$choice" == "Y" ]; then
  echo "Installing nezha-agent..."
  install_nezha_agent
else
  echo "Do not install nezha-agent"
fi

read -p "Do you want to add a scheduled task to the crontab daemon (Y/N Enter N): " crontabgogogo
crontabgogogo=${crontabgogogo^^} # 转换为大写
if [ "$crontabgogogo" == "Y" ]; then
  echo "Add to crontab scheduled tasks for daemons"
  curl -s https://raw.githubusercontent.com/nyeinkokoaung404/socks5-for-serv00/main/check_cron.sh | bash
else
  echo "Do not add crontab scheduled tasks"
fi

echo "Script execution completed.：RealNeoMan、k0baya、eooce"
