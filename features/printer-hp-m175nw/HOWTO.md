# HP LaserJet 100 color MFP M175nw HOWTO

The HP LaserJet 100 color MFP M175nw is one of HP's more troublesome Linux
printers. It requires HP's proprietary HPLIP binary plugin. Without that
plugin, CUPS can report cryptic filter errors, discard jobs, or print only
intermittently. HP lists this model as requiring the plugin.

The `printer-hp-m175nw` feature installs Ubuntu's HPLIP, printer-driver, and
scanner packages only. It deliberately does not install the proprietary
plugin, delete printer queues, or configure the printer.

On Ubuntu 26.04, start from a clean CUPS configuration when an existing setup
is not working.

## 1. Remove the existing printer queue

List configured printers:

```sh
lpstat -p
```

Delete the existing queue, replacing the example name if `lpstat` reports a
different one:

```sh
sudo lpadmin -x LaserJet-100-colorMFP-M175nw-2
```

The following cleanup deletes every installed CUPS PPD, so run it only when
this is the machine's only configured printer:

```sh
sudo rm -rf /etc/cups/ppd/*
sudo systemctl restart cups
```

Skip that PPD cleanup when other printers are configured.

## 2. Install Ubuntu's HPLIP packages

Do not install HP's `.run` installer. Ubuntu's packages are generally more
reliable than HP's installer.

From the docpunct repository, run:

```sh
./bin/docpunct install printer-hp-m175nw
```

The feature installs the equivalent of:

```sh
sudo apt update
sudo apt install hplip hplip-gui printer-driver-hpcups libsane-hpaio
```

## 3. Install the required proprietary plugin

This step is required for this model and is not performed by docpunct. Run:

```sh
hp-plugin
```

If the tool requires explicit root privileges, run:

```sh
sudo hp-plugin
```

Accept HP's license and allow the tool to install the binary plugin.

## 4. Add the printer with hp-setup

Configure the printer with HPLIP instead of GNOME printer settings:

```sh
hp-setup
```

The exact labels vary between HPLIP versions. Select the network printer or
Ethernet/wireless discovery option when offered, let HPLIP discover the
printer, select the recommended HPLIP/hpcups driver, and add the printer.
Using `hp-setup` keeps device discovery, plugin use, and driver selection in
the same HPLIP workflow.

## 5. Prefer a stable network address

If the printer receives a different address after a router or printer restart,
an address-based CUPS queue can stop reaching it. Configure a DHCP reservation
for the printer in the router so it continues to receive the same address.

Replace the example address with the reserved printer address and verify basic
network reachability:

```sh
ping 192.168.x.x
```

A successful ping confirms basic IP reachability, but does not by itself prove
that CUPS or the HPLIP backend is working.

## 6. Diagnose CUPS and HPLIP failures

Inspect CUPS messages from the current boot:

```sh
journalctl -u cups -b
```

Follow only the CUPS journal while submitting a print job:

```sh
journalctl -fu cups
```

Inspect the complete CUPS status and available printer devices:

```sh
lpstat -t
lpinfo -v
```

If the problem remains, collect this focused diagnostic output before asking
for help:

```sh
hp-check
lpstat -t
lpinfo -m | grep -i m175
journalctl -u cups -n 100
```

`lpinfo -m` lists installed CUPS drivers. Driver/PPD-based CUPS interfaces are
deprecated upstream, but this check remains useful for confirming the hpcups
driver required by this legacy HPLIP setup.

## 7. Prefer the HPLIP/hpcups queue

For this model, prefer the dedicated HPLIP/hpcups queue created by `hp-setup`
over an automatically created IPP Everywhere queue. IPP Everywhere is the
normal choice for compatible modern printers, but this older model's printing
path requires HP's HPLIP plugin and driver.

After setup, use `lpstat -t` to confirm which queue and device URI are active.
If the desktop automatically created a second driverless queue, verify that
the HPLIP/hpcups queue works before removing the duplicate.
