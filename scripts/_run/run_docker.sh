docker run -it --rm --net=host \
    --volume "/mnt:/mnt:Z" \
    --volume "/home/rawalk:/home/rawalk:Z" \
    -w "/home/rawalk/Desktop/ego/ego_exo/scripts" rawalkhirodkar/aria_data_tools:latest /bin/bash
