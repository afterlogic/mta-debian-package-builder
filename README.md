# DEB package builder for MTA products
Scripts for building DEB packages for Aurora Corporate (MTA / all-in-one) and MailSuite Pro

The scripts are run as follows:

`./build-aurora-mta.sh`
or
`./build-mailsuite.sh`

to build DEB packages for Aurora Corporate MTA and MailSuite Pro, respectively. 

The packages are saved under `web` directory with their short names (`aurora-corporate-mta.deb` and `mailsuite-pro.deb`), they're also saved under `out` directory with full names suitable for placing to APT repository (for example, `aurora-corporate-mta_stable_9.7.8.build11_all.deb` or `mailsuite-pro_stable_9.7.8.build11_all.deb`).

