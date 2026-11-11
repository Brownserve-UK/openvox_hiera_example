# OpenVox Example Repository

A simple, working example of an [OpenVox](https://voxpupuli.org/openvox/) control repository that uses Hiera to classify nodes from their trusted certificate extensions.

It's intended as a template: copy it and adapt it to get started with your own configuration.

## Repository layout

| Path | Purpose |
| --- | --- |
| `hiera.yaml` | The full Hiera hierarchy used day to day. |
| `hiera.bootstrap.yaml` | A cut-down hierarchy, see [Bootstrap hierarchy](#bootstrap-hierarchy). |
| `manifests/site.pp` | Looks up `classes` from Hiera and includes them. |
| `data/` | Hiera data (`common/`, `services/`, `bootstrap/`). |
| `modules/openvox_server` | Installs and configures OpenVox Server and, optionally, OpenVoxDB. |
| `modules/common` | Configuration applied to every node. |
| `modules/example_module` | A placeholder module showing a typical layout. |
| `Puppetfile` | Forge module dependencies. |
| `keys/` | Holds your eyaml public key. |

## How it all works

When a node requests its certificate it can embed extra data in the CSR, which then becomes trusted facts. (See the [OpenVox docs on CSR extensions](https://docs.openvoxproject.org/openvox/latest/ssl_attributes_extensions.html).)

We use three of these to classify nodes:

* `pp_service`: what the node is for, e.g. `openvox_server` or `example_node`
* `pp_role`: the node's role within that service
* `pp_environment`: the environment it belongs to, e.g. `live`

`hiera.yaml` builds data paths from these values, from most to least specific, for example:

```text
data/services/<pp_service>/<pp_environment>/<pp_role>/<certname>.eyaml
data/services/<pp_service>/<pp_environment>/<pp_role>.eyaml
data/services/<pp_service>/<pp_environment>/common.eyaml
data/services/<pp_service>/common.eyaml
```

Each file can set a `classes` array. `manifests/site.pp` runs `lookup('classes', Array[String], 'unique', []).include`, so the classes from every matching level are merged and applied. Class parameters are set in the same files, e.g. `openvox_server::openvox_majorversion: 8`.

In this repo, `pp_service: openvox_server` gets `data/services/openvox_server/common.eyaml` and `pp_service: example_node` gets `data/services/example_node/common.eyaml`. The server's data sets `common::manage_puppet: false`, so the `common` class doesn't manage the agent settings that `openvox_server` already controls.

## Bootstrap hierarchy

`hiera.yaml` is the hierarchy for normal runs. It relies on trusted facts and per-node data.

`hiera.bootstrap.yaml` contains only the common data plus `data/bootstrap/production.eyaml`, which classifies the node as `openvox_server` without needing certificate extensions.

OpenVoxDB is switched off in the bootstrap data (`openvox_server::install_openvoxdb: false`). Its SSL certificates don't exist until after the `puppet apply` stage, so it can't be configured yet. With the default (`true`) the normal hierarchy installs it.

## A note on naming

OpenVox is a drop-in replacement for Puppet, so many names are still Puppet-branded. You'll still see the `puppet` command, `puppet.conf`, `/etc/puppetlabs`, the `puppetserver` service and the `puppet` class and modules (such as `theforeman-puppet`) in this repo.

## Encrypting secrets with Hiera-eyaml

This repo makes use of [hiera-eyaml](https://github.com/voxpupuli/hiera-eyaml) to encrypt sensitive values within the configuration data stored in Hiera. (e.g. Passwords, certificates etc)
To be able to encrypt and decrypt these values you need a key pair.

To generate your own:

* Ensure that you have ruby and the `bundler` gem installed for your system.
* From the root of this repository run `bundle install`
* Run `bundle exec eyaml createkeys`
* Two keys should be created in the `keys` directory, `private_key.pkcs7.pem` and `public_key.pkcs7.pem`
* Copy `private_key.pkcs7.pem` and `public_key.pkcs7.pem` to your OpenVox server
* Keep a copy of `private_key.pkcs7.pem` somewhere safe (like a password manager)
* Delete `private_key.pkcs7.pem` from the `keys` directory (don't worry, it is gitignored so you won't commit it by accident)

The location you need to copy the keys to depends on your values for `pkcs7_private_key` and `pkcs7_public_key` in your `hiera.yaml` file. (for this example repo that's `/etc/puppetlabs/puppet/keys`)

>⚠️ Seriously: make sure you have a copy of `private_key.pkcs7.pem` stored somewhere safe (like a password manager). That way if you ever lose your server you can still read your secrets!

By keeping `public_key.pkcs7.pem` in the `keys` directory of this project you can quickly encrypt secrets for use in your Hiera data.
Simply run `bundle exec eyaml encrypt -s 'my_secret_value'` and paste the output into your Hiera data file.
