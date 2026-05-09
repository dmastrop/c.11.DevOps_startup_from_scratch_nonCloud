#!/usr/bin/env bash

set -x

write_results_to_db() {
    echo "insert into list (date, target, start_time, end_time, status) values (\"$1\", \"$2\", \"$3\", \"$4\", \"$5\");" | mysql -h localhost -u backup_script -p"${db_backups_password}" backups
}

script_dir=$(dirname "$(readlink -f "$0")")
. "${script_dir}"/.env
container_name="${container_name}"
db_backups_password="${db_backups_password}"
mounted_backups_directory="${mounted_backups_directory}"
backups_directory_app="${backups_directory_app}"
backups_directory_secrets="${backups_directory_secrets}"

date=$(date -I)
target="${target}"
start_time=$(date +"%T")

# add the upgrade to this script
docker pull ${docker_image}:${docker_image_tag}
docker exec -t "${container_name}" gitlab-backup create && \
docker exec -t "${container_name}" gitlab-ctl backup-etc --backup-path /secret/gitlab/backups/ && cd "${script_dir}" && docker-compose down && docker-compose up -d 
end_time=$(date +"%T")

if [[ $? -eq 0 ]]; then
    status="success"

    last_backup=$(ls -t ${mounted_backups_directory} | head -1)
    mv ${mounted_backups_directory}/"${last_backup}" ${backups_directory_app}


    # Keep exactly 2 newest app backups
    #ls -1t "${backups_directory_app}"/*.tar | tail -n +3 | xargs -r rm --

    # Keep exactly 2 newest secrets backups
    #ls -1t "${backups_directory_secrets}"/*.tar | tail -n +3 | xargs -r rm --


    # Keep exactly 1 newest app backup
    ls -1t "${backups_directory_app}"/*.tar | tail -n +2 | xargs -r rm --

    # Keep exactly 1 newest secrets backup
    ls -1t "${backups_directory_secrets}"/*.tar | tail -n +2 | xargs -r rm --




    # Get rid of mtime method of deleteing these EXTERNAL gitlab backups. The above will just retain 2 copies no matter what
    # timing. The mtime +1 was retaining 3 files for a short period of time between backup and clearance resulting in 
    # volume /mnt/storage filling up. The above will resolve this issue. 
   
    #find ${backups_directory_app} -mtime +1 -delete
    #find ${backups_directory_secrets} -mtime +1 -delete

else
    status="fail!"
fi

write_results_to_db "${date}" "${target}" "${start_time}" "${end_time}" "${status}"
