# socks5-for-serv00
Install and configure SOCKS5 & nezha-agent on Serv00 and CT8 machines in one step, and use it for cmliu/edgetunnel project to help unlock services such as ChatGPT. Use one-click script to install the agent, use Crontab to keep the process active, and use GitHub Actions to renew and automate account management to ensure long-term stable operation.

## How to use? [Video tutorial](xxx)

### nohup mode
- One-click installation **Newbies use this! **
```bash
bash <(curl -s https://raw.githubusercontent.com/nyeinkokoaung404/socks5-for-serv00/main/install-socks5.sh)
```
----
### ~pm2 mode~
- ~One-click installation~

~`bash <(curl -s https://raw.githubusercontent.com/nyeinkokoaung404/socks5-for-serv00/pm2/install-socks5.sh)`~


- 一Uninstall pm2
```bash
pm2 unstartup && pm2 delete all && npm uninstall -g pm2
```
----
## Github Actions
Add to Secrets.`ACCOUNTS_JSON` variable
```json
[
  {"username": "nkka404", "password": "7HEt(xeRxttdvgB^nCU6", "panel": "panel4.serv00.com", "ssh": "s4.serv00.com"},
  {"username": "nkka2018", "password": "4))@cRP%HtN8AryHlh^#", "panel": "panel7.serv00.com", "ssh": "s7.serv00.com"},
  {"username": "4r885wvl", "password": "%Mg^dDMo6yIY$dZmxWNy", "panel": "panel.ct8.pl", "ssh": "s1.ct8.pl"}
]
```

# Acknowledgements
[RealNeoMan](https://github.com/Neomanbeta/ct8socks)、[k0baya](https://github.com/k0baya/nezha4serv00)、[eooce](https://github.com/eooce)
