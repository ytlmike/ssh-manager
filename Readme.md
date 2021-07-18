SSH-Manager
---

![image](https://github.com/ytlmike/ssh-manager/blob/master/doc/exp.png)

SSH连接管理脚本，使用CSV表格管理连接，支持默认用户、自动输入密码，支持按连接名称、连接标签筛选。

在config.ini中可以自定义CSV表格列标题，CSV的各列顺序不用固定

### 安装

1. 克隆项目
2. 按config.ini.example模板创建你的配置文件，注意结尾要有空行
3. 按list.csv.example模板创建你的连接列表文件，注意结尾要有空行
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


