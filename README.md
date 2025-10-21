# kompis-os at your services
<p align="right">
<img src="./assets/kompismoln-greeting.svg" alt="Logo" width="200">
</p>

This repository is the central blueprint for Kompismoln.
We're building a set of helper tools and conventions to make managing a cluster of hosts frictionless.

The average NixOS-user will probably feel right at home: The ususal flake,
hosts are assigned modules via roles, sops-nix for secrets etc.

Docs are coming, meanwhile, if you want a guided tutorial, copypaste the content of `org.toml`
into your favorite LLM (e.g. ChatGPT) and let it guide you.

## How to Get Involved
If you're exploring this, have ideas, or just want to know why we did something a certain way, reach out: alex@kompismoln.se.

The best way is to open an issue right here in the repository. Whether it's a question, a bug, or a suggestion, we're friendly and happy to chat!

---

# `org.toml`

Defines all entities, including hosts, users, services, and networks.
This file is consumed by a Nix flake (`flake.nix`) to build NixOS and `home-manager` configurations.
Can be queried with `tools/bin/org-toml.sh`.


## Global Configuration

These top-level keys define the core properties of the organization.

* `name`: The organization's common name ("Kompismoln").
* `domain`: The primary domain (`kompismoln.se`).
* `contact`: A public contact email.
* `inboxes`: A list of critical, domain-level email addresses.
* `timezone`: The default timezone for servers.
* `locale`: The default locale configuration.
* `build-hosts`: A list of hosts designated to build NixOS configurations (referenced in `apply.sh`).
* `root-identities`: A list of root-level identities (e.g., `root-1`) that have ultimate access, particularly for `sops` secret decryption.
* `namespaces`: Defines logical groupings, used in subnet definitions.

---

## `[flake]`

Specifies the source repository for the main NixOS configuration flake itself.

* `type`: The source type (e.g., "github").
* `owner`: The GitHub organization or user ("Kompismoln").
* `repo`: The repository name ("kompis-os").

---

## `[site.*]`

Defines properties for various domains managed by the organization. The key is the domain name (e.g., `[site."kompismoln.se"]`).

* `mailbox`: A boolean flag indicating whether this site is configured to receive mail.

---

## `[public-artifacts]` & `[secrets]`

These sections define path templates for managing credentials and keys.
The `org-toml.sh` script uses these templates
(substituting variables like `$class`, `$entity`, and `$key`) to find or create files.

* **`[public-artifacts]`**: Defines paths for public keys.
    * `default`: The default template for most public keys.
    * `tls-cert`: A specific template for TLS certificate `.pem` files.
* **`[secrets]`**: Defines paths for `sops`-encrypted secret files.
    * `default`: The default path template for entity secrets.
    * `root`: A specific template for root identity keys.

---

## `[class.*]`

These sections define the "schema" or "types" of entities within the organization. Each class specifies the kinds of keys it is expected to possess. This is used by tooling to know what to generate or check for.

* `[class.root]`: For root identities.
* `[class.host]`: For physical or virtual machines.
* `[class.service]`: For software services.
* `[class.user]`: For human users.

---

## `[ops.*]`

Defines automation tasks or "operations" that can be executed against groups of entities. The `org-toml.sh` script (specifically the `ops:` function) reads these to determine which scripts to run against which targets.

The keys are "entity groups" that select which entities to target:
* `*`: All entities.
* `class-*`: All entities of a specific class (e.g., `user-*`).
* `class:role1+role2`: Entities of a specific `class` that have *all* specified `roles` (e.g., `host:luks+server`).
* `entity-name`: A single, specific entity (e.g., `host-lenovo`).

The values are the list of operations to run for that group (e.g., `check:luks-key`).

* `[ops.rebuild]`: Operations to run on rebuild.
* `[ops.align]`: Operations to run when aligning secrets/keys.
* `[ops.check]`: Validation checks.
* `[ops.verify-identities]`, `[ops.verify-users]`, etc.: Verification tasks for different entity classes.

---

## `[root.*]` & `[service.*]`

These sections define specific *instances* of the `root` and `service` classes.

* **`[root.1]`**: Defines the root identity instance named "1".
* **`[service.*]`**: Defines a specific service instance (e.g., `[service.backup]`).
    * `grants`: This list defines which other entities are "granted" access to this service's secrets. The `org-toml.sh` script's `recipients:` function uses this to build the list of `sops` recipients for a service's secret file. For example, `host-*` means all hosts can access this service's secrets.
    * Services can also contain service-specific configuration data (e.g., `account` and `endpoint` for `[service.glesys-api]`).

---

## `[host.*]`

Defines the configuration for each individual host (machine) in the infrastructure. The `flake.nix` file iterates over `org.host` to build the final `nixosConfigurations`.

Example: `[host.stationary]`

* `id`: A unique numeric ID for the host.
* `roles`: A list of roles this host performs. These roles map directly to NixOS modules in the flake (e.g., `roles/nixos.nix`, `roles/webserver.nix`).
* `endpoint`: The host's fully qualified domain name, if applicable.
* `subnets`: A list of network subnets this host belongs to (see `[subnet.*]`).
* `system`: The system architecture (e.g., `x86_64-linux`).
* `stateVersion`: The NixOS `system.stateVersion`.

---

## `[home-manager.*]`

Defines configurations for `home-manager`. The `flake.nix` file iterates over `org.home-manager` to build `homeConfigurations`.

The key (e.g., `"alex@debian"`) is parsed by the flake to extract the `username` ("alex") and `hostname` ("debian").

* `system`: The system architecture.
* `stateVersion`: The `home-manager.users.USER.stateVersion`.
* `roles`: A list of roles that map to `home-manager` modules (e.g., `home-manager/roles/workstation.nix`).

---

## `[user.*]`

Defines specific instances of human users.

* `grants`: A list of entity groups (e.g. `host-*`) granted access to user, used to generate .sops.yaml.
* `description`: The user's full name.
* `email`: The user's primary email, defaults to `user@$domain`.
* `inboxes`: A list of other inboxes managed by this user.

---

## `[subnet.*]`

Defines network subnets (by interface like `wg0` and `wg1`).

* `enable`: Toggles the subnet.
* `address`: The CIDR address for the subnet. (`10.0.0.0/24`)
* `port`: The WireGuard listening port. (`51820`)
* `gateway`: The entity name of the host (e.g., "helsinki") acting as the gateway for this subnet.
* `namespace`: The local top-domain (e.g. `.local`, makes fqdn with entity name).
* `dns`: List of DNS servers for this subnet.
* `peerAddress`: A template for assigning peer addresses.

---

## `[theme.*]`

Defines a visual theme (fonts and colors) for the organization.
This is passed into `home-manager` and NixOS configurations by `flake.nix` to consistently style applications, terminals, and other UI elements.

* `[theme.fonts]`: Specifies preferred fonts for different categories.
* `[theme.colors]`: Defines a named color palette.
