#!/bin/sh

APP_CFG_FILE=/config/.filebrowser.toml
CERT_PATH=${FB_CERT}
KEY_PATH=${FB_KEY}

[ "$CERT_PATH" = "" ] && CERT_PATH=${GO_ACME_CERT_PATH}
[ "$KEY_PATH" = "" ] && KEY_PATH=${GO_ACME_KEY_PATH}

# Default configuration file
if [ ! -f ${APP_CFG_FILE} ]; then
	echo "init default config ..."
	cp /etc/default/.filebrowser.toml ${APP_CFG_FILE}
fi

test -d /config/ssl || mkdir /config/ssl

if [ ! -s ${CERT_PATH} ]; then
	echo "init default ssl cert ..."
	cp /etc/default/ssl/ssl.crt ${CERT_PATH}
fi

if [ ! -s ${KEY_PATH} ]; then
	echo "init default ssl key ..."
	cp /etc/default/ssl/ssl.key ${KEY_PATH}
fi


echo "setup /config permission ..."
chmod -R 775 /config
chown -R $PUID:$PGID /config && echo "/config owner set to $PUID:$PGID"


# link cfg file (for run fb without -c param, currently this was not used)
ln -sf ${APP_CFG_FILE} /home/app/.filebrowser.toml

echo "init config ..."
sed -i "s|^port=.*|port=${WEB_PORT}|i" ${APP_CFG_FILE}
#the root always /myfiles
sed -i 's|^root=.*|root="/myfiles"|i' ${APP_CFG_FILE}

if [ "${FB_SSL}" = "on" ];then
	echo "https enabled."
	sed -i "s|^cert=.*|cert=\"${CERT_PATH}\"|i" ${APP_CFG_FILE}
	sed -i "s|^key=.*|key=\"${KEY_PATH}\"|i" ${APP_CFG_FILE}
else
	echo "https disabled."
	sed -i "s|^cert=.*|cert=\"\"|i" ${APP_CFG_FILE}
	sed -i "s|^key=.*|key=\"\"|i" ${APP_CFG_FILE}
fi

#20190903 migration
test -d /config/root.bleve && mv /config/root.bleve /config/.root.bleve && echo "index dir migration success"

test -c /dev/dri/renderD128 && chown $PUID:$PGID /dev/dri/renderD128 && chmod a+rx /dev/dri


# prepare env
test -d /etc/envvars || mkdir /etc/envvars
#rm -f /etc/envvars/*
for K in $(env | cut -d= -f1)
do
    VAL=$(eval echo \$$K)
    echo "${VAL}" > /etc/envvars/${K}
done

echo "init config done."
