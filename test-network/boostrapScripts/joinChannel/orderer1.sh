FABRIC_CFG_PATH=${PWD}/../../../config/
export channel_name=mychannel
export CORE_PEER_TLS_ENABLED=true
export PEER0_ORG1_CA=${PWD}/../../organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem

export ORDERER_CA=${PWD}/../../organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/../../organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/../../organizations/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/../../organizations/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/server.key
osnadmin channel join --channelID ${channel_name} --config-block ${PWD}/../../channel-artifacts/${channel_name}.block -o localhost:8053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"