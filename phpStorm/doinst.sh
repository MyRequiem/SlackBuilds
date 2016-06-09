if [ -f /opt/phpstorm/jre/jre/lib/amd64/libgstreamer-lite.so ]; then
    ( cd usr/lib64 ; rm -rf libgstreamer-lite.so )
    ( cd usr/lib64 ; ln -sf /opt/phpstorm/jre/jre/lib/amd64/libgstreamer-lite.so libgstreamer-lite.so)
fi

