#!/bin/bash
# wcq 2021/10/24

# ****************** start ******************
publish_rep=qygame/docker-publish # repository where publish
src_rep=${GITHUB_REPOSITORY#$GITHUB_REPOSITORY_OWNER/} # repository from where
deploy_tag=${GITHUB_REF#refs/tags/}

env_rep_sdir=/third_sites

deploy_ret=-1 #默认值
step=1

# ****************** color ******************
export TERM=xterm

# 以下方案都不生效, 不知道原因 TODONOW
#echo "\033[36mCompling \033[35m==> \033[33mthis is a test\033[0m"

# 好像带\n的都不生效比如
#printf '\nthis is a test'
#echo -e "\nthis is a test"

# 好像只对一行生效, 第二行的就不生效了


# ****************** fun ******************
fun_git_cfg(){
    git config --global user.email "3@q.com"
    git config --global user.name "wcq"
}

# make qybase9/net
fun_make_qybase_net(){
    echo ""
    tput setaf 3
    printf 'step%-2s fun_make_qybase9/net\n' $((step++))
    tput sgr0

    cd /
    # 1. git clone qybase9/net
    remote_url="https://$INPUT_QYGAME_TOKEN@github.com/qybase9/net.git"
    git clone $remote_url net && cd net

    # 2. make
    make

    # 3. mv net dire => /env_rep_sdir/net
    if ! [ -d $env_rep_sdir ];then
	echo "err: there is no env_rep_sdir"
	exit 2
    fi

    if ! [ -d "_depends" ];then
	echo "err: there is no net/_depends"
	exit 2
    fi

    mv _depends $env_rep_sdir/net   

    tput setaf 2
    echo "make qybase9/net success"
    tput sgr0
}

# docker-publish
fun_deploy_to_publish_tag(){
    echo ""
    tput setaf 3
    printf 'step%-2s fun_deploy_to_publish_tag\n' $((step++))
    tput sgr0

    cd /
    if ! [ -d $env_rep_sdir ];then
	echo "err: there is no env_rep_sdir"
	exit 2
    fi

    # 1. copy file
    cp /for_rep_server_env.sh $env_rep_sdir/env.sh #环境env.sh
    cd $env_rep_sdir

    # 2. 初始化仓库
    git init

    # 3. git commit
    git add .
    git commit -m "$src_rep-$deploy_tag <$GITHUB_SHA>" > /dev/null 2>&1

    # 4. git push
    remote_url="https://$INPUT_QYGAME_TOKEN@github.com/$publish_rep.git"
    git remote add my_origin $remote_url
    git tag $deploy_tag
    msg1=`git push -q my_origin --tags`

    # 5. check push status
    if [[ $msg1 != "" ]];then
	deploy_ret=2
	tput setaf 1
	echo "git push tag to publish fail"
	tput sgr0
    else
	deploy_ret=0
	tput setaf 2
	echo "git push tag to publish  success"
	tput sgr0
    fi
}

# dc -- docker-compose
fun_deploy_to_dc_branch_and_dc_tag(){
    echo ""
    tput setaf 3
    printf 'step%-2s fun_deploy_to_dc_branch_and_dc_tag\n' $((step++))
    tput sgr0

    cd $GITHUB_WORKSPACE
    git checkout docker-compose
    git tag docker-compose_$deploy_tag
    msg1=`git push -q --tags`
    if [[ $msg1 != "" ]];then
	deploy_ret=3
	tput setaf 1
	echo "git push tag to docker-compose fail"
	tput sgr0
    else
	deploy_ret=0
	tput setaf 2
	echo "git push tag to docker-compose success"
	tput sgr0
    fi
}

# qyaction
fun_deploy_to_qyaction_branch_and_qyaction_tag(){
    echo ""
    tput setaf 3
    printf 'step%-2s fun_deploy_to_dc_branch_and_dc_tag\n' $((step++))
    tput sgr0

    cd $GITHUB_WORKSPACE
    git checkout qyaction

    # 修改DockerFile中 ARG tag=$deploy_tag
    sed -i "/tag=/ c\ARG tag=$deploy_tag" Dockerfile

    git commit -am "auto-update to qyaction_$deploy_ret"
    git tag qyaction_$deploy_tag
    msg1=`git push -q --tags`
    if [[ $msg1 != "" ]];then
	deploy_ret=3
	tput setaf 1
	echo "git push qyaction_$deploy_tag fail"
	tput sgr0
    else
	deploy_ret=0
	tput setaf 2
	echo "git push qyaction_$deploy_tag success"
	tput sgr0
    fi

    msg1=`git push -q`
    if [[ $msg1 != "" ]];then
	deploy_ret=3
	tput setaf 1
	echo "git push qyaction branch fail"
	tput sgr0
    else
	deploy_ret=0
	tput setaf 2
	echo "git push qyaction branch success"
	tput sgr0
    fi
}

# k8s
fun_deploy_to_k8s_branch_and_k8s_tag(){
    :
}
# ****************** main ******************
# 没有传递token, 有可能是使用./build env来本地测试运行的
if [[ $INPUT_QYGAME_TOKEN == "" ]];then
    echo "No INPUT_QYGAME_TOKEN, exit 0"
    exit 0
fi
   
fun_git_cfg
# 在Dockerfile中没法传递QYGAME_TOKEN(TODO 也可能是我不知道怎么传递) 所以放到了docker中处理
fun_make_qybase_net

#
fun_deploy_to_publish_tag
fun_deploy_to_dc_branch_and_dc_tag
fun_deploy_to_qyaction_branch_and_qyaction_tag
fun_deploy_to_k8s_branch_and_k8s_tag


# 返回错误信息给github action
if [ $deploy_ret -eq 0 ];then
    echo ""
    tput setaf 3
    echo "Everything is ready, enjoy it!"
    tput sgr0
else
    tput setaf 1
    echo "err: there is something wrong! ret=$deploy_ret"
    tput sgr0
fi

exit $deploy_ret
