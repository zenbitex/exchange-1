-------------------------------------
### INSTALL SERVER ETHEREUM
#### 0. Ref
 - https://ethereum.gitbooks.io/frontier-guide/content/connecting.html
 - https://github.com/ethereum/wiki/wiki/JSON-RPC
 - https://github.com/ethereum/go-ethereum/wiki/Managing-your-accounts
 - https://coinsutra.com/ethereum-gas-limit-gas-price-fees/
 - Ether = Tx Fees = Gas Limit * Gas Price
 - Usually: 21000 * 20Gwei
 - https://ethgasstation.info/ #check gas live
#### 1. INSTALL SERVER FOLLOW LINK
##### 1. Ethereum:
  https://github.com/ethereum/go-ethereum/wiki/Installation-Instructions-for-Ubuntu

  ```
  sudo apt-get install software-properties-common
  sudo add-apt-repository -y ppa:ethereum/ethereum
  sudo apt-get update
  sudo apt-get install ethereum
  ```
##### 2. Ethereum Classic:
https://github.com/ethereumproject/go-ethereum/releases

##### Download package (Ethereum Classic Geth) flow:
###### Step 1:
- Download package with curl:
Example:
`curl --remote-name https://github.com/ethereumproject/go-ethereum/releases/download/v4.0.0/geth-classic-linux-v4.0.0.tar.gz`
###### Step 2:
- Extract file tar.gz:
Example:
`tar xvf geth-classic-linux-v4.0.0.tar.gz`
##### Step 3:
- Change file geth to geth_classic
##### Step 4:
- Move file geth_classic to /usr/bin

#### 2. RUN NODE ON BACKGROUND

###### Step 1:
- Setup `supervisror` for run node automatically
 `sudo apt-get install supervisor`
###### Step 2:
- Configure file .conf run node :
 Ethereum: `sudo vim /etc/supervisor/conf.d/geth.conf`
```
[program:geth]
command=/usr/bin/geth --fast --rpc --rpcaddr 0.0.0.0 --port 30303 --rpcapi "eth,net,personal,web3" --rpcport 8545 --cache=1024
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/geth.err.log
stdout_logfile=/var/log/supervisor/geth.out.log
```
 Ethereum Classic: `sudo vim /etc/supervisor/conf.d/geth_classic.conf`
```
[program:geth_classic]
command=/usr/bin/geth_classic --fast --rpc --rpcaddr 0.0.0.0 --port 30305 --rpcapi "eth,net,personal,web3" --rpcport 8646 --cache=1024
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/geth_classic.err.log
stdout_logfile=/var/log/supervisor/geth_classic.out.log
 ```
 #### options:
 `command=/usr/bin/geth --fast --rpc --rpcaddr 0.0.0.0 --port 30303 --rpcapi "eth,net,personal,web3" --rpcport 8545`
  - --rpc:  Enable the JSON-RPC server
  - --rpcaddr "127.0.0.1":  Listening address for the JSON-RPC server
  - --rpcport "8545":   Port on which the JSON-RPC server should listen
  - --rpcapi "db,eth,net,web3":  Specify the API's which are offered over the HTTP RPC interface

###### Step 3: Suppervisor
- Start `Supervisor`:
  ` supervisorctl start all `

- Reload `Supervisor`:
  `supervisorctl reload `

- Check status:
 `sudo supervisorctl status`

#### 3. ACCESS NODE ETHEREUM AND ETHEREUM CLASSIC
##### ACCESS TO SEVER
###### Interactive JavaScript environment (connect to node):
```
  geth attach http://localhost:8545
  >eth.blockNumber
  >personal.newAccount('password')
```
###### ETHEREUM CLASSIC:
`geth attach http://localhost:8646`
##### CHECK BLOCK ETHERUM (ETHEREUM CLASSIC)
`eth.blockNumber`
Link API: https://github.com/ethereum/wiki/wiki/JavaScript-API

#### 4. BACKINGUP keystore
  - Nơi lưu trữ thông tin của các account (address)
  - Các file trong folder sẽ có dạng: UTC--2015-09-18T14-07-57.023663538Z--da78c8721e4ede42cf488304551eb596dd5f93e23

  - Các file trong này được mã hóa, bảo về bằng password
  - Nếu dữ liệu của folder này bị xóa -> die
  - Chỉ nên backup dữ liệu của phần keystore content mà thôi, không nên store toàn bộ dữ liệu của folder, vì nó sẽ bao gồm chaindata file > 2GB
  - Để inport các wallet file đã lưu, chỉ đơn giản là copy chúng vào folder keystore trên hệ thống mới.
  - Trước khi xóa key files phải đảm bảo là các key files đc import trên hệ thống mới hoạt động được, chỉ cần spend 1 ít ETH là có thể kiểm tra được
