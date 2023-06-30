#!/bin/bash

# 定义可选端口数组
declare -a ports=("30002" "30003" "30005")

# 检查端口输入是否合法
function check_port_input() {
  read -p "请输入需要检测的端口号（只能输入30002、30003、30005）：" port
  for p in "${ports[@]}"; do
    if [[ "$p" == "$port" ]]; then
      echo "端口选择成功！"
      return
    fi
  done
  echo "端口选择错误，请重新输入！"
  check_port_input
}

check_port_input

# 检查bark链接是否合法
function check_bark_link() {
  read -p "请输入bark链接（不可以以/结尾）：" bark_link
  if [[ "$bark_link" == *"/" ]]; then
    echo "bark链接不可以以/结尾，请重新输入！"
    check_bark_link
  else
    echo "正在发送bark链接测试通知，请稍等..."
    curl -G -s "$bark_link/bark链接测试通知/bark链接测试成功?sound=glass"
    read -p "已发送，请在手机上查看消息是否收到，确保bark链接正确，输入y继续，输入其他任意字符重新输入：" confirm
    if [[ "$confirm" == "y" ]]; then
      echo "bark链接确认成功！"
      return
    else
      check_bark_link
    fi
  fi
}

check_bark_link

if [ -f /usr/local/bin/check_port.sh ]; then
  # 检查服务状态
  if systemctl is-active --quiet check_port.service; then
    # 停止服务
    sudo systemctl stop check_port.service >/dev/null 2>&1
  fi
  # 等待服务停止完成
  sleep 3
  # 禁用服务
  sudo systemctl disable check_port.service >/dev/null 2>&1
  # 删除服务文件
  sudo rm -f /etc/systemd/system/check_port.service >/dev/null 2>&1
  # 删除脚本文件
  sudo rm -f /usr/local/bin/check_port.sh >/dev/null 2>&1
fi

# 生成监测脚本文件
sudo tee /usr/local/bin/check_port.sh >/dev/null <<EOF
#!/bin/bash
while true
do
  if ! nc -z localhost $port; then
    curl -G -s "$bark_link/端口 $port 无数据传输，请检查！/端口 $port 无数据传输，请检查！?sound=glass"
  fi
  sleep 30
done
EOF

chmod +x /usr/local/bin/check_port.sh
echo "端口监测脚本生成成功！"

# 生成/etc/systemd/system/check_port.service文件
sudo tee /etc/systemd/system/check_port.service >/dev/null <<EOF
[Unit]
Description=Check if a specific port is open and sending alerts using Bark

[Service]
ExecStart=/bin/bash /usr/local/bin/check_port.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd服务
sudo systemctl daemon-reload >/dev/null 2>&1
# 启动check_port.service服务
sudo systemctl enable check_port.service >/dev/null 
echo "端口监测服务自启动设置完成！"
echo "------------------------"
echo "|端口监测服务安装成功！|"
echo "------------------------"
