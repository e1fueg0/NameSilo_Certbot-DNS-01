# NameSilo_Certbot-DNS-01
Hook script helpers for obtaining [LetsEncrypt](https://letsencrypt.org/) certificates, using [Certbot](https://certbot.eff.org/) with [manual](https://certbot.eff.org/docs/using.html#manual) DNS-01 validation against [NameSilo](https://www.namesilo.com/) DNS.

#### Dependency
Make sure that you have xmllint installed on your system. On Ubuntu:
```
 $ apt-get install libxml2-utils
```
#### Example Setup
Add your NameSilo API key to at the top of `config.sh` and create a writable `tmp` folder in the directory that this file is in.  

To make this the default setting for Certbot, add the following to your Certbot config at `/etc/letsencrypt/cli.ini`

```
server = https://acme-v02.api.letsencrypt.org/directory
authenticator = manual
preferred-challenges = dns-01
manual-auth-hook = /path/to/hook.sh
manual-cleanup-hook /path/to/cleanup.sh
```
Note: The server above **must** be set for DNS validation.  

Another option is to just add the hook scripts along with any other options when calling Certbot like so:
```
$ certbot renew --manual-auth-hook /path/to/hook.sh --manual-cleanup-hook /path/to/cleanup.sh
```
#### Note: There is a 15 minute wait for DNS propagation.

Debug data will be printed in case of error response from NameSilo.
