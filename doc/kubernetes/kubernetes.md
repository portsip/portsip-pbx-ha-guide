# 自动化安装kuberentes
版本 1.18
工具kubeadm
前置条件
必须关闭swap
关闭selinux
关闭防火墙

# 添加节点

```
pass
```
# 设置master可调度 
```
kubectl patch nodes nodename -p '{"spec":{"taints":[]}}'
```


# 添加master
```
pass

```





