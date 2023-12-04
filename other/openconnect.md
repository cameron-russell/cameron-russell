# How to stop having VPN issues

## Prerequisites
 - Install the latest version of Cisco Anyconnect from self-service
 - Let it do a system scan
 - Connect one time in case there's some certificates you're missing

## Give yourself sudo permissions
 - Request admin permissions from self-service
 - Add your username to `/etc/sudoers`:
```shell
sudo vi /etc/sudoers
```
- find the lines that look like these
```
# root and users in group wheel can run anything on any machine as any user
root		ALL = (ALL) ALL
%admin		ALL = (ALL) ALL
```
- add your LDAP credentials to the next line so it looks like this:
```shell
# root and users in group wheel can run anything on any machine as any user
root		ALL = (ALL) ALL
%admin		ALL = (ALL) ALL
xxx00		ALL = (ALL) ALL
```
- save and close the file

## [Optional] Become admin
 - add your LDAP credentials to the the admin usergroup on your mac

```shell
sudo dscl . -append /groups/admin GroupMembership xxx00 
```

## Openconnect
### - Install openconnect
```shell
brew install openconnect
touch /etc/sudoers.d/openconnect
sudo echo "%admin ALL=(ALL) NOPASSWD: /opt/homebrew/bin/openconnect" > /etc/sudoers.d/openconnect
```
### - Install pyqt@5 (might not be needed anymore)
```shell
brew install pyqt@5
```
### - set up pipx (I'm assuming you have python installed)
```shell
pip install --user pipx
```
### - Install [openconnect-sso](https://github.com/vlaci/openconnect-sso/)
```shell
pipx install openconnect-sso
pipx ensurepath
```
### - symlink all items in pyqt@5 site-packages to openconnect-sso site-packages 
**(note your paths may differ slightly to mine and version numbers might change)**
```shell
ln -s /opt/homebrew/Cellar/pyqt@5/5.15.7_2/lib/python3.11/site-packages/* ~/.local/pipx/venvs/openconnect-sso/lib/python3.11/site-packages
```

### - Add the config into the openconnect-sso config.toml file
```shell
tee -a ~/.config/openconnect-sso/config.toml <<EOF
on_disconnect = ""

[default_profile]
address = "https://skyremoteaccess.bskyb.com/SKY-CONNECT-CORPORATE"
user_group = "SKY-CONNECT-CORPORATE"
name = "Sky Connect Corporate"
EOF
```

### - Run openconnect-sso
```shell
openconnect-sso
```

### - [Optional] install tmux so you can run it in the background
```shell
brew install tmux
```
