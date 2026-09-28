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

# the concatenated command is having issues. The backup gives exit code of 1 even though it works fine and thus the secrets backup
# and docker compose segments in the command are not running. De-segment this to separate command (see further below)

#docker exec -t "${container_name}" gitlab-backup create && \
#docker exec -t "${container_name}" gitlab-ctl backup-etc --backup-path /secret/gitlab/backups/ && cd "${script_dir}" && docker-compose down && docker-compose up -d 

# De-segment the commands for better error tolerance:
docker exec -t "${container_name}" gitlab-backup create SKIP=registry
# Use the SKIP registry backup command ENV variable. The registry is not required for gitlab backup and it is very very large using up
# lots of volume space.
#docker exec -t "${container_name}" gitlab-backup create

# This is for the secrets backup
docker exec -t "${container_name}" gitlab-ctl backup-etc --backup-path /secret/gitlab/backups/

cd "${script_dir}"
docker-compose down
docker-compose up -d




end_time=$(date +"%T")

if [[ $? -eq 0 ]]; then
    status="success"

    #last_backup=$(ls -t ${mounted_backups_directory} | head -1)
    #mv ${mounted_backups_directory}/"${last_backup}" ${backups_directory_app}



    # Keep exactly 2 newest app backups
    #ls -1t "${backups_directory_app}"/*.tar | tail -n +3 | xargs -r rm --

    # Keep exactly 2 newest secrets backups
    #ls -1t "${backups_directory_secrets}"/*.tar | tail -n +3 | xargs -r rm --


    # CLEAN ONLY APP BACKUPS BEFORE MOVE This is to prevent the /mnt/storage overlfow issue with the app tarball backup.....
    rm -f "${backups_directory_app}"/*.tar

    # DO NOT CLEAN SECRETS BEFORE MOVE
    # Secrets are created directly in their final directory by gitlab-ctl backup-etc

    # MOVE NEWEST APP BACKUP  revert to original version
    last_backup=$(ls -t ${mounted_backups_directory} | head -1)
    mv ${mounted_backups_directory}/"${last_backup}" ${backups_directory_app}
    
    # RETAIN ONLY 1 APP BACKUP AFTER MOVE
    ls -1t "${backups_directory_app}"/*.tar | tail -n +2 | xargs -r rm --

    # RETAIN ONLY 1 SECRETS BACKUP AFTER MOVE
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
