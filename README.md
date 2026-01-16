# Github Actions Padavan RM2100

- Padavan源码是[MeIsReallyBa/padavan-4.4](https://github.com/MeIsReallyBa/padavan-4.4)。
- Github Actions参考自[Ljzkirito/Actions-Padavan_Redmi-AC2100](https://github.com/Ljzkirito/Actions-Padavan_Redmi-AC2100)。
- 编译目标为Redmi-AC2100
- 默认登陆地址[192.168.2.1](http://192.168.5.1),登录名admin/admin
- 开启插件`shadowsocks`,`xray-26.1.13`

## 其它路由器型号也可以刷

- 更换对应的配置文件(RM2100.config)
- 修改`.github/workflows/build-Padavan.yml` 环境变量为对应型号
- 这里提供的是`mips32le`版本，根据自己路由器cpu架构选择更换xray二进制文件
```
支持xtls-rprx-vision,reality,utls
注意！此版本xray比较吃内存，开启后剩余内存约为30MB
```

# 截图
- ![](https://raw.githubusercontent.com/FishInShallow/Padavan_RM2100/MelsReallyBa/screenshot1.png)
- ![](https://raw.githubusercontent.com/FishInShallow/Padavan_RM2100/MelsReallyBa/screenshot2.png)

