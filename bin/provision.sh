#! /bin/bash
# from: https://github.com/sensu/sensu-build/blob/master/para-vagrant.sh
#
# depends on:
# GNU parallel, installed if not already installed
#
# modifications:
# * vm list generated from TARGET_VM_COUNT
ensure_parallel () {
    echo "1" |parallel echo "" >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        (wget -O - pi.dk/3 || curl pi.dk/3/ || fetch -o - http://pi.dk/3) |bash
    fi
}
ensure_parallel

parallel_provision () {
    while read box; do
        echo $box
    done | parallel $MAX_PROCS -I"BOX" -q \
        sh -c 'LOGFILE="logs/BOX.out.txt" ;                                 \
        printf  "[BOX] Provisioning. Log: $LOGFILE, Result: " ;     \
        vagrant provision BOX >$LOGFILE 2>&1 ;                      \
        RETVAL=$? ;                                                 \
        if [ $RETVAL -gt 0 ]; then                                  \
            echo " FAILURE";                                        \
            tail -12 $LOGFILE | sed -e "s/^/[BOX]  /g";             \
            echo "[BOX] ---------------------------------------------------------------------------";   \
            echo "FAILURE ec=$RETVAL" >>$LOGFILE;                   \
        else                                                        \
            echo " SUCCESS";                                        \
            tail -5 $LOGFILE | sed -e "s/^/[BOX]  /g";              \
            echo "[BOX] ---------------------------------------------------------------------------";   \
            echo "SUCCESS" >>$LOGFILE;                              \
        fi;                                                         \
        exit $RETVAL'

    failures=$(egrep  '^FAILURE' logs/*.out.txt | sed -e 's/^logs\///' -e 's/\.out\.txt:.*//' -e 's/^/  /')
    successes=$(egrep '^SUCCESS' logs/*.out.txt | sed -e 's/^logs\///' -e 's/\.out\.txt:.*//' -e 's/^/  /')

    echo
    echo "Failures:"
    echo '------------------'
    echo "$failures"
    echo
    echo "Successes:"
    echo '------------------'
    echo "$successes"
}

## -- main -- ##

# cleanup old logs
mkdir logs >/dev/null 2>&1
rm -f logs/*.out.txt

# ensure OSX box is present, if needed
if ! vagrant box list |grep osx >/dev/null 2>&1; then
    vagrant box add http://files.dryga.com/boxes/osx-yosemite-0.2.1.box --name osx-yosemite
fi

# start boxes sequentially to avoid vbox explosions
echo ' ==> Calling "vagrant up" to boot the boxes...'
vagrant up --no-provision

# but run provision tasks in parallel
echo " ==> Beginning parallel 'vagrant provision' processes ..."
for i in $(seq 1 $TARGET_VM_COUNT); do echo "riak$i"; done | parallel_provision
