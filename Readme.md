SSH-Manager
---

![image](https://github.com/ytlmike/ssh-manager/blob/master/doc/exp.png)

SSH连接管理脚本，使用CSV表格管理连接，支持默认用户、自动输入密码，支持按连接名称、连接标签筛选。

在config.ini中可以自定义CSV表格列标题，CSV的各列顺序不用固定

### 更新日志
#### 2021-09-29
- 添加跳板机配置
  - 现在你可以在config.ini里添加JUMP_开头的跳板机列表，然后再list.csv里指定跳板机
  - 由于sshpass只能输一次密码，所以跳板机一定要用公钥登录。

### 安装

1. 克隆项目
2. 按config.ini.example模板创建你的配置文件
3. 按list.csv.example模板创建你的连接列表文件
4. enjoy

### 使用

- 基本使用：
    ```
    ./manager.sh
    ```
- 按名称筛选
    ```
     ./manager.sh myserver
    ```
- 按标签筛选
    ```
     ./manager.sh -t tag1, tag2
    ```


