# Protected legacy client assets

The desktop client can load `Tibia.dat` and `Tibia.spr` from an authenticated
container named `assets.sec`. Protected builds always prefer the container;
ordinary development builds continue to use the plain files.
Production packages should ship only this layout:

```text
data/things/781/assets.sec
data/things/781/tibia.otfi
```

The container uses AES-256-GCM independently for each 1 MiB block. Its header,
asset kind, block index, and plaintext size are authenticated as additional
data. Decrypted DAT/SPR bytes stay in memory and are never written to disk.

## Build the packer

Configure with `OTCLIENT_BUILD_ASSET_PACKER=ON` and build the
`otclient_asset_packer` target. Provide the key through the environment, not a
command-line argument:

```sh
export OTCLIENT_ASSET_KEY_HEX='<64 hexadecimal characters>'
otclient_asset_packer Tibia.dat Tibia.spr assets.sec
```

## Build the production client

Use the exact same key at configure time. The presets support Windows x64 and
macOS Apple Silicon; protected desktop builds package their runtime resources
and remove every plaintext `.dat`/`.spr` from the generated application:

```sh
cmake -S . -B build/protected \
  -DOTCLIENT_PROTECTED_ASSETS=ON \
  -DOTCLIENT_ASSET_KEY_HEX="$OTCLIENT_ASSET_KEY_HEX"
```

Do not enable `OTCLIENT_BUILD_ASSET_PACKER` in a production build. Keep the key
out of source control and CI logs. The key must exist in the executable for the
client to read the assets, so this protects against casual extraction and
tampering but cannot make client-side resources impossible to recover.

## Custom 7.81 visual IDs

`visualIdsU16` is enabled for the current `Nosso Servidor/Servidor-7.81`, which
transmits magic-effect and distance-effect IDs as `uint16`. Do not use this client
with an older server executable that still transmits these fields as one byte.
Outfit IDs already use `GameLooktypeU16` for client version 7.81.
