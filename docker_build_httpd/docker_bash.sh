cid=$(docker ps -a |grep jb-httpd-centos7|awk '{print $1}')
echo $cid
echo docker exec -it $cid bash
docker exec -it $cid bash
