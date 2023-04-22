cid=$(docker ps -a |grep jb-httpd-centos7|awk '{print $1}')
echo $cid
echo docker start $cid
docker start $cid
