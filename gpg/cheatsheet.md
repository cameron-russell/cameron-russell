# GPG things
## import public key
```shell
gpg --import 70B042AC6B4D834E9918B8065F9CCBC9E37CC44B.asc
```

## list public keys
```shell
gpg --list-keys
```

## export public key
```shell
gpg --armor --export 0D12B2F0E40EF557
```

## export private key
```shell
gpg --list-secret-keys --keyid-format=long
gpg --output private_key_output.pgp --armor --export-secret-key 0D12B2F0E40EF557 # <-- from above command
```

## encrypt a file
### 
```shell
gpg --output output.csv.gpg --encrypt --sign --default-key cameron.russell@sky.uk \
--recipient jan.zlamal@showmax.com \
--recipient marian.mrozek@showmax.com \
--recipient michal.sladek@showmax.com \
--recipient ntsizwa.sishange@multichoice.co.za \
--recipient filip.kratochvil@showmax.com \
output.csv
```

## decrypt a file
```shell
gpg --output output.csv --decrypt input.csv.gpg
```

