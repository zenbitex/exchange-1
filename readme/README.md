
```sh
notifier = Slack::Notifier.new(Rails.application.config.slack_webhook_url)
notifier.ping("HELLO")
```
-------------------------------------
### BACKUP WALLET
##### 1. GPG SECURE WALLET.DAT FILE
1. ` gpg --gen-key`  #gen public and secret key
2. Look into GPG's import and export functions.
- So, on the old computer
  `gpg --export -a 'YOUR_NAME' > public.txt`
  `gpg --export-secret-keys -a 'YOUR_NAME' > secret.txt`

- On the new computer:
  `gpg --import public.txt`
  `gpg --import secret.txt`
  `gpg --edit-key 'YOUR_NAME'`

##### 2. SETUP s3cmd
- `apt-get install s3cmd`
- `s3cmd --configure`   #config access_key & secret_key
- `s3cmd put -f submit.text 's3:server-bit/wallet'`   #puts file to your bucket

##### 3. BACKUP EVERY 1:00 AM
`sudo touch /var/log/wallet_backup.log`
`sudo chmod 777 /var/log/wallet_backup.log`
`0 1 * * * /usr/local/bin/backupwallet.sh >> /var/log/wallet_backup.log 2>&1`
##### 4. Note
```
GPG_USER='YOUR_NAME'
BITCOIN=bitcoin-cli
CP='s3cmd put --force'
CP_DEST='s3://bit-trade-server/wallet/'
```
-------------------------------------
### Overview

1. Install [Ruby](https://www.ruby-lang.org/en/)
2. Install [MySQL](http://www.mysql.com/)
3. Install [Redis](http://redis.io/)
4. Install [RabbitMQ](https://www.rabbitmq.com/)
5. Install [Bitcoind](https://en.bitcoin.it/wiki/Bitcoind)
6. Install [PhantomJS](http://phantomjs.org/)
7. Install JavaScript Runtime
8. Install ImageMagick
9. Configure BitStation


### Step 1: Install Ruby

Make sure your system is up-to-date.

    sudo apt-get update
    sudo apt-get upgrade

Installing [rbenv](https://github.com/sstephenson/rbenv) using a Installer

    sudo apt-get install git-core curl zlib1g-dev build-essential \
                         libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 \
                         libxml2-dev libxslt1-dev libcurl4-openssl-dev \
                         python-software-properties libffi-dev

    cd
    git clone git://github.com/sstephenson/rbenv.git .rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    exec $SHELL

    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
    exec $SHELL

Install Ruby through rbenv:

    rbenv install 2.2.1
    rbenv global 2.2.1

Install bundler

    echo "gem: --no-ri --no-rdoc" > ~/.gemrc
    gem install bundler
    rbenv rehash

### Step 2: Install MySQL

    sudo apt-get install mysql-server  mysql-client  libmysqlclient-dev

### Step 3: Install Redis

    sudo add-apt-repository ppa:chris-lea/redis-server
    sudo apt-get update
    sudo apt-get install redis-server

### Step 4: Install RabbitMQ

Please follow instructions here: https://www.rabbitmq.com/install-debian.html

    echo 'deb http://www.rabbitmq.com/debian/ testing main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list
    wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install rabbitmq-server

    sudo rabbitmq-plugins enable rabbitmq_management
    sudo service rabbitmq-server restart
    wget http://localhost:15672/cli/rabbitmqadmin
    chmod +x rabbitmqadmin
    sudo mv rabbitmqadmin /usr/local/sbin

### Step 5: Install Bitcoind

    sudo add-apt-repository ppa:bitcoin/bitcoin
    sudo apt-get update
    sudo apt-get install bitcoind

**Configure**

    mkdir -p ~/.bitcoin
    touch ~/.bitcoin/bitcoin.conf
    vim ~/.bitcoin/bitcoin.conf

Insert the following lines into the bitcoin.conf, and replce with your username and password.

    server=1
    daemon=1

    # If run on the test network instead of the real bitcoin network
    testnet=1

    # You must set rpcuser and rpcpassword to secure the JSON-RPC api
    # Please make rpcpassword to something secure, `5gKAgrJv8CQr2CGUhjVbBFLSj29HnE6YGXvfykHJzS3k` for example.
    # Listen for JSON-RPC connections on <port> (default: 8332 or testnet: 18332)
    rpcuser=INVENT_A_UNIQUE_USERNAME
    rpcpassword=INVENT_A_UNIQUE_PASSWORD
    rpcport=18332

    # Notify when receiving coins
    walletnotify=/usr/local/sbin/rabbitmqadmin publish routing_key=bit-station.deposit.coin payload='{"txid":"%s", "channel_key":"satoshi"}'

**Start bitcoin**

    bitcoind

### Step 6: Install PhantomJS

Bit-station uses Capybara with PhantomJS to do the feature tests, so if you want to run the tests. Install the PhantomJS is neccessary.

    sudo apt-get update
    sudo apt-get install build-essential chrpath git-core libssl-dev libfontconfig1-dev
    cd /usr/local/share
    PHANTOMJS_VERISON=1.9.8
    sudo wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERISON-linux-x86_64.tar.bz2
    sudo tar xjf phantomjs-$PHANTOMJS_VERISON-linux-x86_64.tar.bz2
    sudo ln -s /usr/local/share/phantomjs-$PHANTOMJS_VERISON-linux-x86_64/bin/phantomjs /usr/local/share/phantomjs
    sudo ln -s /usr/local/share/phantomjs-$PHANTOMJS_VERISON-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs
    sudo ln -s /usr/local/share/phantomjs-$PHANTOMJS_VERISON-linux-x86_64/bin/phantomjs /usr/bin/phantomjs

### Step 7: Install JavaScript Runtime

A JavaScript Runtime is needed for Asset Pipeline to work. Any runtime will do but Node.js is recommended.

    curl -sL https://deb.nodesource.com/setup | sudo bash -
    sudo apt-get install nodejs


### Step 8: Install ImageMagick

    sudo apt-get install imagemagick

### Step 9: Configure Bit-station

**Clone the project**

    git clone https://gitlab-new.bap.jp/RUBY-TEAM/bit-itrade
    cd bit-itrade
    bundle install

**Prepare configure files**

    bin/init_config

**Setup Pusher**

* Bit-station depends on [Pusher](http://pusher.com). A development key/secret pair for development/test is provided in `config/application.yml` (uncomment to use). PLEASE USE IT IN DEVELOPMENT/TEST ENVIRONMENT ONLY!

More details to visit [pusher official website](http://pusher.com)

    # uncomment Pusher related settings
    vim config/application.yml

**Setup bitcoind rpc endpoint**

    # replace username:password and port with the one you set in
    # username and password should only contain letters and numbers, do not use email as username
    # bitcoin.conf in previous step
    vim config/currencies.yml

**Config database settings**

    vim config/database.yml

    # Initialize the database and load the seed data
    bundle exec rake db:setup

**Run Daemons**

    # start all daemons
    bundle exec rake daemons:start

    # or start daemon one by one
    bundle exec rake daemon:matching:start
    ...

    # Daemon trade_executor can be run concurrently, e.g. below
    # line will start four trade executors, each with its own logfile.
    # Default to 1.
    TRADE_EXECUTOR=4 rake daemon:trade_executor:start

    # You can do the same when you start all daemons:
    TRADE_EXECUTOR=4 rake daemon:start

When daemons don't work, check `log/#{daemon name}.rb.output` or `log/bit-station:amqp:#{daemon name}.output` for more information (suffix is '.output', not '.log').

**Run Project**

    # start server
    bundle exec rails server

# https://github.com/flightjs/flight

# https://github.com/flightjs/flight/tree/master/doc  
