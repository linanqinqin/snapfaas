#!/usr/bin/env bash

if [ ! -d /ssd ]; then
    echo '/ssd must exists'
    exit 1
fi

# only source the environment file when invoked directly from command line
if [ $(ps -o stat= -p $PPID) == 'Ss' ]; then
	source ./default_env
fi
appfsDir='../snapfaas-images/appfs'
echo 'Building full-app snapshots...'
for language in "${RUNTIMES[@]}"
do
    for app in $(ls $appfsDir/$language)
    do
        echo "- $SSDSNAPSHOTDIR/$app-$language"
        [ ! -d $SSDSNAPSHOTDIR/$app-$language ] && mkdir $SSDSNAPSHOTDIR/$app-$language
        sudo $MEMBINDIR/fc_wrapper \
            --vcpu_count 1 \
            --mem_size 128 \
            --network 'tap0/aa:bb:cc:dd:ff:00' \
            --kernel $KERNEL \
            --firerunner $MEMBINDIR/firerunner \
            --rootfs $SSDROOTFSDIR/$app-$language.ext4 \
            --dump_dir $SSDSNAPSHOTDIR/$app-$language \
            --force_exit >/dev/null
        [ $? -ne 0 ] && echo '!! failed' && exit 1

        echo "- $MEMSNAPSHOTDIR/$app-$language"
        [ ! -d $MEMSNAPSHOTDIR/$app-$language ] && mkdir $MEMSNAPSHOTDIR/$app-$language
        cp $SSDSNAPSHOTDIR/$app-$language/* $MEMSNAPSHOTDIR/$app-$language
    done
done
