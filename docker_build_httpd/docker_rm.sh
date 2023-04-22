cid=$(docker ps -a |grep jb-httpd-centos7|awk '{print $1}')
echo $cid
echo docker rm $cid
docker rm $cid
