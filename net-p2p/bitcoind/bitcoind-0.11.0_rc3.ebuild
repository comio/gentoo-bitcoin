# Copyright 2010-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

BITCOINCORE_COMMITHASH="afc60de4164dc723f9010da7f3867f8354f81530"
BITCOINCORE_LJR_PV="0.11.0rc3"
BITCOINCORE_LJR_DATE="20150703"
BITCOINCORE_IUSE="examples +ljr logrotate test upnp +wallet zeromq"
BITCOINCORE_POLICY_PATCHES="+cltv +cpfp rbf spamfilter"
BITCOINCORE_NEED_LEVELDB=1
BITCOINCORE_NEED_LIBSECP256K1=1
inherit bash-completion-r1 bitcoincore user systemd

DESCRIPTION="Original Bitcoin crypto-currency wallet for automated services"
LICENSE="MIT"
SLOT="0"
KEYWORDS=""  # reminder: big endian can now be supported

RDEPEND="
	logrotate? (
		app-admin/logrotate
	)
"
DEPEND="${RDEPEND}"

pkg_setup() {
	local UG='bitcoin'
	enewgroup "${UG}"
	enewuser "${UG}" -1 -1 /var/lib/bitcoin "${UG}"
}

src_prepare() {
	sed -i 's/have bitcoind &&//;s/^\(complete -F _bitcoind bitcoind\) bitcoin-cli$/\1/' contrib/${PN}.bash-completion
	bitcoincore_src_prepare
}

src_configure() {
	bitcoincore_conf \
		--with-daemon
}

src_install() {
	bitcoincore_src_install

	insinto /etc/bitcoin
	newins "${FILESDIR}/bitcoin.conf" bitcoin.conf
	fowners bitcoin:bitcoin /etc/bitcoin/bitcoin.conf
	fperms 600 /etc/bitcoin/bitcoin.conf

	newconfd "contrib/init/bitcoind.openrcconf" ${PN}
	newinitd "contrib/init/bitcoind.openrc" ${PN}
	systemd_dounit "${FILESDIR}/bitcoind.service"

	keepdir /var/lib/bitcoin/.bitcoin
	fperms 700 /var/lib/bitcoin
	fowners bitcoin:bitcoin /var/lib/bitcoin/
	fowners bitcoin:bitcoin /var/lib/bitcoin/.bitcoin
	dosym /etc/bitcoin/bitcoin.conf /var/lib/bitcoin/.bitcoin/bitcoin.conf

	dodoc doc/assets-attribution.md doc/bips.md doc/tor.md
	doman contrib/debian/manpages/{bitcoind.1,bitcoin.conf.5}

	newbashcomp contrib/${PN}.bash-completion ${PN}

	if use examples; then
		docinto examples
		dodoc -r contrib/{bitrpc,qos,spendfrom,tidy_datadir.sh}
	fi

	if use logrotate; then
		insinto /etc/logrotate.d
		newins "${FILESDIR}/bitcoind.logrotate-r1" bitcoind
	fi
}
