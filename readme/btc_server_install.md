
### 1. INSTALL BITCOIN SERVER

  - sudo add-apt-repository ppa:bitcoin/bitcoin
  - sudo apt-get update
  - sudo apt-get install bitcoind

#### Configure
  - mkdir -p ~/.bitcoin
  - touch ~/.bitcoin/bitcoin.conf
  - vim ~/.bitcoin/bitcoin.conf

Insert the following lines into the bitcoin.conf
```
  rpcuser=bitcoin-rpc-user
  rpcpassword=bitcoin-rpc-PassWord
  server=1
  daemon=1
  testnet=0
  rpcthreads=1000
  rpctimeout=300
  addrindex=1
  rpcport=8332  #testnet: 18332
  rpcallowip=0.0.0.0/0
  rescan=1

  # Notify when receiving coins
   walletnotify=/usr/local/sbin/rabbitmqadmin publish routing_key=btc-notification payload='{"txid":"%s", "channel_key":"satoshi"}'
```

#### Start bitcoin server
  - bitcoind

### 2. INSTALL RabbitMQ to public message
  - echo 'deb http://www.rabbitmq.com/debian/ testing main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list
  - wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo apt-key add - sudo apt-get update
  - sudo apt-get install rabbitmq-server
  - sudo rabbitmq-plugins enable rabbitmq_management
  - sudo service rabbitmq-server restart
  - wget http://localhost:15672/cli/rabbitmqadmin
  - chmod +x rabbitmqadmin
  - sudo mv rabbitmqadmin /usr/local/sbin
#### CREATE Admin and Queue
##### 1. Create account admin
  - rabbitmqctl add_user test test
  - rabbitmqctl set_user_tags test administrator
  - rabbitmqctl set_permissions -p / test ".*" ".*" ".*"
##### 2. Declare Queue
  - rabbitmqadmin declare queue name=my-new-queue durable=true
##### 3. Publish message to queue
  - rabbitmqadmin publish routing_key="queue" payload="hello, world"
##### 4. Get message from queue
  - rabbitmqadmin get queue=test requeue=false
##### 5. Delete queue
  - rabbitmqadmin delete queue name=btg-notification
