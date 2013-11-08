# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

PYTHON_COMPAT=( python{2_6,2_7} )

inherit git-r3 python-single-r1 systemd user

DESCRIPTION="Server for the Electrum thin Bitcoin client"
HOMEPAGE="http://electrum.org"
EGIT_REPO_URI="git://github.com/3M3RY/electrum-server.git \
			 https://github.com/3M3RY/electrum-server.git"
EGIT_BRANCH="mainline_bitcoind"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}
		 dev-python/jsonrpclib
		 dev-python/py-leveldb
		 dev-python/pyopenssl
		 net-p2p/bitcoind"

pkg_setup() {
	enewuser electrum -1 -1 /var/db/electrum
}

src_prepare() {
	python-single-r1_pkg_setup
	python_fix_shebang server.py

	sed -i -e 's:/path/to/your/database:/var/db/electrum:' electrum.conf.sample
}

src_install() {
	python_moduleinto ${PN}
	python_domodule backends processor.py server.py transports utils version.py

	python_export PYTHON_SITEDIR
	exeinto "${PYTHON_SITEDIR}/${python_moduleroot}"
	doexe server.py
	dosym "${PYTHON_SITEDIR}/${python_moduleroot}/server.py" /usr/bin/${PN}

	insinto /etc
	newins electrum.conf.sample electrum.conf

	newinitd "$FILESDIR"/${PN}.initd ${PN}
	newconfd "$FILESDIR"/${PN}.confd ${PN}
	systemd_dounit "$FILESDIR"/${PN}.service

	keepdir /var/db/electrum
}

pkg_postinst() {
	einfo "Existing blockchain datasets are available at "
	einfo "http://foundry.electrum.org/"
	einfo "The Electrum database is stored at /var/db/electrum."
}
